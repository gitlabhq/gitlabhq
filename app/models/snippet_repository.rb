# frozen_string_literal: true

class SnippetRepository < ApplicationRecord
  include EachBatch
  include Shardable

  DEFAULT_EMPTY_FILE_NAME = 'snippetfile'
  EMPTY_FILE_PATTERN = /^#{DEFAULT_EMPTY_FILE_NAME}(\d+)\.txt$/.freeze

  CommitError = Class.new(StandardError)
  InvalidPathError = Class.new(CommitError)
  InvalidSignatureError = Class.new(CommitError)

  belongs_to :snippet, inverse_of: :snippet_repository

  delegate :repository, :repository_storage, to: :snippet

  class << self
    def find_snippet(disk_path)
      find_by(disk_path: disk_path)&.snippet
    end
  end

  def multi_files_action(user, files = [], **options)
    return if files.nil? || files.empty?

    lease_key = "multi_files_action:#{snippet_id}"

    lease = Gitlab::ExclusiveLease.new(lease_key, timeout: 120)
    raise CommitError, 'Snippet is already being updated' unless uuid = lease.try_obtain

    options[:actions] = transform_file_entries(files)

    capture_git_error { repository.multi_action(user, **options) }
  ensure
    Gitlab::ExclusiveLease.cancel(lease_key, uuid)
  end

  private

  def capture_git_error(&block)
    yield block
  rescue Gitlab::Git::Index::IndexError,
         Gitlab::Git::CommitError,
         Gitlab::Git::PreReceiveError,
         Gitlab::Git::CommandError,
         ArgumentError => error

    logger.error(message: "Snippet git error. Reason: #{error.message}", snippet: snippet.id)

    raise commit_error_exception(error)
  end

  def transform_file_entries(files)
    next_index = get_last_empty_file_index + 1

    files.map do |file_entry|
      file_entry[:file_path] = file_path_for(file_entry, next_index) { next_index += 1 }
      file_entry[:action] = infer_action(file_entry) unless file_entry[:action]
      file_entry[:action] = file_entry[:action].to_sym

      if only_rename_action?(file_entry)
        file_entry[:infer_content] = true
      elsif empty_update_action?(file_entry)
        # There is no need to perform a repository operation
        # When the update action has no content
        file_entry = nil
      end

      file_entry
    end.compact
  end

  def file_path_for(file_entry, next_index)
    return file_entry[:file_path] if file_entry[:file_path].present?
    return file_entry[:previous_path] if reuse_previous_path?(file_entry)

    build_empty_file_name(next_index).tap { yield }
  end

  # If the user removed the file_path and the previous_path
  # matches the EMPTY_FILE_PATTERN, we don't need to
  # rename the file and build a new empty file name,
  # we can just reuse the existing file name
  def reuse_previous_path?(file_entry)
    file_entry[:file_path].blank? &&
      EMPTY_FILE_PATTERN.match?(file_entry[:previous_path])
  end

  def infer_action(file_entry)
    return :create if file_entry[:previous_path].blank?

    file_entry[:previous_path] != file_entry[:file_path] ? :move : :update
  end

  def get_last_empty_file_index
    repository.ls_files(snippet.default_branch).inject(0) do |max, file|
      idx = file[EMPTY_FILE_PATTERN, 1].to_i
      [idx, max].max
    end
  end

  def build_empty_file_name(index)
    "#{DEFAULT_EMPTY_FILE_NAME}#{index}.txt"
  end

  def commit_error_exception(err)
    if invalid_path_error?(err)
      InvalidPathError.new('Invalid file name') # To avoid returning the message with the path included
    elsif invalid_signature_error?(err)
      InvalidSignatureError.new(err.message)
    else
      CommitError.new(err.message)
    end
  end

  def invalid_path_error?(err)
    err.is_a?(Gitlab::Git::Index::IndexError) &&
      err.message.downcase.start_with?('invalid path', 'path cannot include directory traversal')
  end

  def invalid_signature_error?(err)
    err.is_a?(ArgumentError) &&
      err.message.downcase.match?(/failed to parse signature/)
  end

  def only_rename_action?(action)
    action[:action] == :move && action[:content].nil?
  end

  def empty_update_action?(action)
    action[:action] == :update && action[:content].nil?
  end
end

SnippetRepository.prepend_mod_with('SnippetRepository')

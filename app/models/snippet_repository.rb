# frozen_string_literal: true

class SnippetRepository < ApplicationRecord
  include Shardable

  DEFAULT_EMPTY_FILE_NAME = 'snippetfile'
  EMPTY_FILE_PATTERN = /^#{DEFAULT_EMPTY_FILE_NAME}(\d+)\.txt$/.freeze

  CommitError = Class.new(StandardError)

  belongs_to :snippet, inverse_of: :snippet_repository

  delegate :repository, to: :snippet

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
         Gitlab::Git::CommandError => e
    raise CommitError, e.message
  end

  def transform_file_entries(files)
    next_index = get_last_empty_file_index + 1

    files.each do |file_entry|
      file_entry[:action] = infer_action(file_entry) unless file_entry[:action]

      if file_entry[:file_path].blank?
        file_entry[:file_path] = build_empty_file_name(next_index)
        next_index += 1
      end
    end
  end

  def infer_action(file_entry)
    return :create if file_entry[:previous_path].blank?

    file_entry[:previous_path] != file_entry[:file_path] ? :move : :update
  end

  def get_last_empty_file_index
    repository.ls_files(nil).inject(0) do |max, file|
      idx = file[EMPTY_FILE_PATTERN, 1].to_i
      [idx, max].max
    end
  end

  def build_empty_file_name(index)
    "#{DEFAULT_EMPTY_FILE_NAME}#{index}.txt"
  end
end

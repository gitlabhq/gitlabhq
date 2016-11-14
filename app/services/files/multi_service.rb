require_relative "base_service"

module Files
  class MultiService < Files::BaseService
    class FileChangedError < StandardError; end

    def commit
      repository.multi_action(
        user: current_user,
        branch: @target_branch,
        message: @commit_message,
        actions: params[:actions],
        author_email: @author_email,
        author_name: @author_name,
        source_branch: @source_branch
      )
    end

    private

    def validate
      super

      params[:actions].each_with_index do |action, index|
        unless action[:file_path].present?
          raise_error("You must specify a file_path.")
        end

        regex_check(action[:file_path])
        regex_check(action[:previous_path]) if action[:previous_path]

        if project.empty_repo? && action[:action] != :create
          raise_error("No files to #{action[:action]}.")
        end

        validate_file_exists(action)

        case action[:action]
        when :create
          validate_create(action)
        when :update
          validate_update(action)
        when :delete
          validate_delete(action)
        when :move
          validate_move(action, index)
        else
          raise_error("Unknown action type `#{action[:action]}`.")
        end
      end
    end

    def validate_file_exists(action)
      return if action[:action] == :create

      file_path = action[:file_path]
      file_path = action[:previous_path] if action[:action] == :move

      blob = repository.blob_at_branch(params[:branch_name], file_path)

      unless blob
        raise_error("File to be #{action[:action]}d `#{file_path}` does not exist.")
      end
    end

    def last_commit
      Gitlab::Git::Commit.last_for_path(repository, @source_branch, @file_path)
    end

    def regex_check(file)
      if file =~ Gitlab::Regex.directory_traversal_regex
        raise_error(
          'Your changes could not be committed, because the file name, `' +
          file +
          '` ' +
          Gitlab::Regex.directory_traversal_regex_message
        )
      end

      unless file =~ Gitlab::Regex.file_path_regex
        raise_error(
          'Your changes could not be committed, because the file name, `' +
          file +
          '` ' +
          Gitlab::Regex.file_path_regex_message
        )
      end
    end

    def validate_create(action)
      return if project.empty_repo?

      if repository.blob_at_branch(params[:branch_name], action[:file_path])
        raise_error("Your changes could not be committed because a file with the name `#{action[:file_path]}` already exists.")
      end
    end

    def validate_delete(action)
    end

    def validate_move(action, index)
      if action[:previous_path].nil?
        raise_error("You must supply the original file path when moving file `#{action[:file_path]}`.")
      end

      blob = repository.blob_at_branch(params[:branch_name], action[:file_path])

      if blob
        raise_error("Move destination `#{action[:file_path]}` already exists.")
      end

      if action[:content].nil?
        blob = repository.blob_at_branch(params[:branch_name], action[:previous_path])
        blob.load_all_data!(repository) if blob.truncated?
        params[:actions][index][:content] = blob.data
      end
    end

    def validate_update(action)
      if file_has_changed?
        raise FileChangedError.new("You are attempting to update a file `#{action[:file_path]}` that has changed since you started editing it.")
      end
    end
  end
end

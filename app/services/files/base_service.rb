module Files
  class BaseService < Commits::CreateService
    FileChangedError = Class.new(StandardError)

    def initialize(*args)
      super

      @author_email = params[:author_email]
      @author_name = params[:author_name]
      @commit_message = params[:commit_message]
      @last_commit_sha = params[:last_commit_sha]

      @file_path = params[:file_path]
      @previous_path = params[:previous_path]

      @file_content = params[:file_content]
      @file_content = Base64.decode64(@file_content) if params[:file_content_encoding] == 'base64'
    end

    def file_has_changed?(path, commit_id)
      return false unless commit_id

      last_commit = Gitlab::Git::Commit
        .last_for_path(@start_project.repository, @start_branch, path)

      return false unless last_commit

      last_commit.sha != commit_id
    end
  end
end

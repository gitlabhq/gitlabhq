module Files
  class BaseService < Commits::CreateService
    def initialize(*args)
      super

      @author_email = params[:author_email]
      @author_name = params[:author_name]
      @commit_message = params[:commit_message]

      @file_path = params[:file_path]
      @previous_path = params[:previous_path]

      @file_content = params[:file_content]
      @file_content = Base64.decode64(@file_content) if params[:file_content_encoding] == 'base64'
    end
  end
end

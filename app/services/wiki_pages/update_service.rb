module WikiPages
  class UpdateService < WikiPages::BaseService
    def execute(page)
      if page.update(@params[:content], format: @params[:format], message: @params[:message], last_commit_sha: @params[:last_commit_sha])
        execute_hooks(page, 'update')
      end

      page
    end
  end
end

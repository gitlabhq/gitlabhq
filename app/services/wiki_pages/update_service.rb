module WikiPages
  class UpdateService < WikiPages::BaseService
    def execute(page)
      if page.update(@params[:content], @params[:format], @params[:message])
        execute_hooks(page, 'update')
      end

      page
    end
  end
end

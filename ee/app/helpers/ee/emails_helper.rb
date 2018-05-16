module EE
  module EmailsHelper
    extend ::Gitlab::Utils::Override

    override :action_title
    def action_title(url)
      return "View Epic" if url.split("/").include?('epics')

      super
    end
  end
end

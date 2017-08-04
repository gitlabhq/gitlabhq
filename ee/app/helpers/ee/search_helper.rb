module EE
  module SearchHelper
    def search_filter_input_options(type)
      options = super
      options[:data][:'multiple-assignees'] = 'true' if search_multiple_assignees?(type)

      options
    end

    private

    def search_multiple_assignees?(type)
      context = @project.presence || @group

      type == :issues &&
        context.feature_available?(:multiple_issue_assignees)
    end
  end
end

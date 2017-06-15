module EE
  module SearchHelper
    def search_filter_input_options(type)
      options = super
      options[:data][:'multiple-assignees'] = 'true' if (type == :issues) && @project.feature_available?(:multiple_issue_assignees)

      options
    end
  end
end

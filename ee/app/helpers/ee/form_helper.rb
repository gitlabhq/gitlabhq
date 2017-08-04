module EE
  module FormHelper
    def issue_assignees_dropdown_options
      options = super

      if @project.feature_available?(:multiple_issue_assignees)
        options[:title] = 'Select assignee(s)'
        options[:data][:'dropdown-header'] = 'Assignee(s)'
        options[:data].delete(:'max-select')
      end

      options
    end
  end
end

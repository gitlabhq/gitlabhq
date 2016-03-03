module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor < Banzai::ReferenceExtractor
    attr_accessor :project, :current_user, :author

    def initialize(project, current_user = nil, author = nil)
      @project = project
      @current_user = current_user
      @author = author

      @references = {}

      super()
    end

    def analyze(text, context = {})
      super(text, context.merge(project: project))
    end

    %i(user label milestone merge_request snippet commit commit_range).each do |type|
      define_method("#{type}s") do
        @references[type] ||= references(type, reference_context)
      end
    end

    def issues
      if project && project.jira_tracker?
        @references[:external_issue] ||= references(:external_issue, reference_context)
      else
        @references[:issue] ||= references(:issue, reference_context)
      end
    end

    private

    def reference_context
      { project: project, current_user: current_user, author: author }
    end
  end
end

require 'gitlab/markdown'

module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor
    attr_accessor :project, :current_user, :load_lazy_references

    def initialize(project, current_user = nil, load_lazy_references: true)
      @project = project
      @current_user = current_user
      @load_lazy_references = load_lazy_references

      @texts = []
      @references = {}
    end

    def analyze(text, options = {})
      @texts << Gitlab::Markdown.render(text, options.merge(project: project))
    end

    %i(user label merge_request snippet commit commit_range).each do |type|
      define_method("#{type}s") do
        @references[type] ||= pipeline_result(type)
      end
    end

    def issues
      if project && project.jira_tracker?
        @references[:external_issue] ||= pipeline_result(:external_issue)
      else
        @references[:issue] ||= pipeline_result(:issue)
      end
    end

    private

    # Instantiate and call HTML::Pipeline with a single reference filter type,
    # returning the result
    #
    # filter_type - Symbol reference type (e.g., :commit, :issue, etc.)
    #
    # Returns the results Array for the requested filter type
    def pipeline_result(filter_type)
      filter = Gitlab::Markdown::ReferenceFilter[filter_type]

      context = {
        pipeline: :reference_extraction,

        project:      project,
        current_user: current_user,

        # ReferenceGathererFilter
        load_lazy_references: false,
        reference_filter:     filter
      }

      values = @texts.flat_map do |html|
        text_context = context.dup
        result = Gitlab::Markdown.render_result(html, text_context)
        result[:references][filter_type]
      end.uniq

      if @load_lazy_references
        values = Gitlab::Markdown::ReferenceFilter::LazyReference.load(values).uniq
      end

      values
    end
  end
end

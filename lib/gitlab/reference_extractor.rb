module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor
    attr_accessor :project, :current_user, :references

    def initialize(project, current_user = nil)
      @project = project
      @current_user = current_user
    end

    def analyze(text)
      @_text = text.dup
    end

    def users
      result = pipeline_result(:user)
      result[:references][:user].flatten.compact.uniq
    end

    def labels
      result = pipeline_result(:label)
      result[:references][:label].compact.uniq
    end

    def issues
      # TODO (rspeicher): What about external issues?

      result = pipeline_result(:issue)
      result[:references][:issue].compact.uniq
    end

    def merge_requests
      result = pipeline_result(:merge_request)
      result[:references][:merge_request].compact.uniq
    end

    def snippets
      result = pipeline_result(:snippet)
      result[:references][:snippet].compact.uniq
    end

    def commits
      result = pipeline_result(:commit)
      result[:references][:commit].compact.uniq
    end

    def commit_ranges
      result = pipeline_result(:commit_range)
      result[:references][:commit_range].compact.uniq
    end

    private

    # Instantiate and call HTML::Pipeline with a single reference filter type,
    # returning the result
    #
    # filter_type - Symbol reference type (e.g., :commit, :issue, etc.)
    #
    # Returns the results Hash
    def pipeline_result(filter_type)
      klass  = filter_type.to_s.camelize + 'ReferenceFilter'
      filter = "Gitlab::Markdown::#{klass}".constantize

      context = {
        project: project,
        current_user: current_user,
        # We don't actually care about the links generated
        only_path: true
      }

      pipeline = HTML::Pipeline.new([filter], context)
      pipeline.call(@_text)
    end
  end
end

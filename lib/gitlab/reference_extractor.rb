require 'gitlab/markdown'

module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor
    attr_accessor :project, :current_user

    def initialize(project, current_user = nil)
      @project = project
      @current_user = current_user
    end

    def analyze(text)
      references.clear
      @text = Gitlab::Markdown.render_without_gfm(text)
    end

    %i(user label issue merge_request snippet commit commit_range).each do |type|
      define_method("#{type}s") do
        references[type]
      end
    end

    private

    def references
      @references ||= Hash.new do |references, type|
        type = type.to_sym
        return references[type] if references.has_key?(type)

        references[type] = pipeline_result(type).uniq
      end
    end

    # Instantiate and call HTML::Pipeline with a single reference filter type,
    # returning the result
    #
    # filter_type - Symbol reference type (e.g., :commit, :issue, etc.)
    #
    # Returns the results Array for the requested filter type
    def pipeline_result(filter_type)
      klass  = filter_type.to_s.camelize + 'ReferenceFilter'
      filter = Gitlab::Markdown.const_get(klass)

      context = {
        project: project,
        current_user: current_user,
        # We don't actually care about the links generated
        only_path: true,
        ignore_blockquotes: true
      }

      pipeline = HTML::Pipeline.new([filter], context)
      result = pipeline.call(@text)

      result[:references][filter_type]
    end
  end
end

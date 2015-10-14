require 'gitlab/markdown'

module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor
    attr_accessor :project, :current_user, :load_lazy_references

    def initialize(project, current_user = nil, load_lazy_references: true)
      @project = project
      @current_user = current_user
      @load_lazy_references = load_lazy_references
    end

    def analyze(text)
      references.clear

      @document = Gitlab::Markdown.render(text, project: project)
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

        references[type] = pipeline_result(type)
      end
    end

    # Instantiate and call HTML::Pipeline with a single reference filter type,
    # returning the result
    #
    # filter_type - Symbol reference type (e.g., :commit, :issue, etc.)
    #
    # Returns the results Array for the requested filter type
    def pipeline_result(filter_type)
      klass  = "#{filter_type.to_s.camelize}ReferenceFilter"
      filter = Gitlab::Markdown.const_get(klass)

      context = {
        project:              project,
        current_user:         current_user,
        load_lazy_references: false,
        reference_filter:     filter
      }

      result = self.class.pipeline.call(@document, context)

      values = result[:references][filter_type].uniq

      if @load_lazy_references
        values = Gitlab::Markdown::ReferenceFilter::LazyReference.load(values).uniq
      end

      values
    end

    def self.pipeline
      @pipeline ||= HTML::Pipeline.new([Gitlab::Markdown::ReferenceGathererFilter])
    end
  end
end

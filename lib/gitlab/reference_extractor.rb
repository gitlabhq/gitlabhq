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
        next references[type] if references.has_key?(type)

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
      return [] if @text.blank?
      
      klass  = "#{filter_type.to_s.camelize}ReferenceFilter"
      filter = Gitlab::Markdown.const_get(klass)

      context = {
        project: project,
        current_user: current_user,
        
        # We don't actually care about the links generated
        only_path: true,
        ignore_blockquotes: true,

        # ReferenceGathererFilter
        load_lazy_references: false,
        reference_filter:     filter
      }

      pipeline = HTML::Pipeline.new([filter, Gitlab::Markdown::ReferenceGathererFilter], context)
      result = pipeline.call(@text)

      values = result[:references][filter_type].uniq

      if @load_lazy_references
        values = Gitlab::Markdown::ReferenceFilter::LazyReference.load(values).uniq
      end

      values
    end
  end
end

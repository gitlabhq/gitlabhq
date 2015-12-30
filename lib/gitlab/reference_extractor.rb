require 'banzai'

module Gitlab
  # Extract possible GFM references from an arbitrary String for further processing.
  class ReferenceExtractor < Banzai::ReferenceExtractor
    attr_accessor :project, :current_user

    def initialize(project, current_user = nil)
      @project = project
      @current_user = current_user

      @references = {}

      super()
    end

    def analyze(text, context = {})
      super(text, context.merge(project: project))
    end

    %i(user label issue merge_request snippet commit commit_range).each do |type|
      define_method("#{type}s") do
        @references[type] ||= references(type, project: project, current_user: current_user)
      end
    end
  end
end

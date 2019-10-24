# frozen_string_literal: true

module Gitlab
  class WikiFileFinder < FileFinder
    attr_reader :repository

    def initialize(project, ref)
      @project = project
      @ref = ref
      @repository = project.wiki.repository
    end

    private

    def search_paths(query)
      safe_query = Regexp.escape(query.tr(' ', '-'))
      safe_query = Regexp.new(safe_query, Regexp::IGNORECASE)
      paths = repository.ls_files(ref)

      paths.grep(safe_query)
    end
  end
end

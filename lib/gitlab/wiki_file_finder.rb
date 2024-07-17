# frozen_string_literal: true

module Gitlab
  class WikiFileFinder < FileFinder
    extend ::Gitlab::Utils::Override

    attr_reader :repository

    def initialize(project, ref)
      @project = project
      @ref = ref
      @repository = project.wiki.repository
    end

    private

    override :search_paths
    def search_paths(query)
      safe_query = Regexp.escape(query.tr(' ', '-'))
      safe_query = Regexp.new(safe_query, Regexp::IGNORECASE)
      paths = repository.ls_files(ref)
      paths.select { |path| valid_format_wiki_file?(path) }.grep(safe_query)
    end

    override :find_by_content
    def find_by_content(query, options)
      repository.search_files_by_content(query, ref, options).filter_map do |result|
        blob = Gitlab::Search::FoundBlob.new(content_match: result, project: project, ref: ref, repository: repository)
        blob if valid_format_wiki_file?(blob.path)
      end
    end

    def valid_format_wiki_file?(path)
      Wiki::MARKUPS.values.pluck(:extension_regex).any? { |regex| regex.match?(path) } # rubocop: disable CodeReuse/ActiveRecord -- Not an ActiveRecord
    end
  end
end

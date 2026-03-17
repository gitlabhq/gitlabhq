# frozen_string_literal: true

module MergeRequests
  class KeepAroundRefsService
    include BaseServiceUtility

    def initialize(project_ids:, shas:, source:)
      @project_ids = Array(project_ids)
      @shas = Array(shas).compact
      @source = source
    end

    def execute
      return if @shas.empty?

      repositories.each do |repo|
        repo.keep_around(*@shas, source: @source)
      end
    end

    private

    def repositories
      Project.id_in(@project_ids.uniq).map(&:repository)
    end
  end
end

module Gitlab
  module GlRepository
    def self.gl_repository(project, is_wiki)
      "#{is_wiki ? 'wiki' : 'project'}-#{project.id}"
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def self.parse(gl_repository)
      match_data = /\A(project|wiki)-([1-9][0-9]*)\z/.match(gl_repository)
      unless match_data
        raise ArgumentError, "Invalid GL Repository \"#{gl_repository}\""
      end

      type, id = match_data.captures
      project = Project.find_by(id: id)
      wiki = type == 'wiki'

      [project, wiki]
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end

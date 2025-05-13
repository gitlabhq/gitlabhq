# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Models
        autoload :Base, 'gitlab/backup/cli/models/base'
        autoload :GroupWiki, 'gitlab/backup/cli/models/group_wiki'
        autoload :PersonalSnippet, 'gitlab/backup/cli/models/personal_snippet'
        autoload :ProjectDesignManagement, 'gitlab/backup/cli/models/project_design_management'
        autoload :ProjectSnippet, 'gitlab/backup/cli/models/project_snippet'
        autoload :Project, 'gitlab/backup/cli/models/project'
        autoload :ProjectWiki, 'gitlab/backup/cli/models/project_wiki'
        autoload :RepositoryStorage, 'gitlab/backup/cli/models/repository_storage'
      end
    end
  end
end

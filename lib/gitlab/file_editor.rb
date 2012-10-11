module Gitlab
  class FileEditor

    attr_accessor :user, :project

    def initialize(user, project)
      self.user = user
      self.project = project
    end

    def can_edit?(path, last_commit)
      true
    end

    def update(path, content)
      true
    end

  end
end

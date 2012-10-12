module Gitlab
  class FileEditor

    attr_accessor :user, :project, :ref

    def initialize(user, project, ref)
      self.user = user
      self.project = project
      self.ref = ref
    end

    def can_edit?(path, last_commit)
      current_last_commit = @project.commits(ref, path, 1).first.sha
      last_commit == current_last_commit
    end

    def update(path, content)
      true
    end

  end
end

module Gitlab
  # GitLab file editor
  #
  # It gives you ability to make changes to files
  # & commit this changes from GitLab UI.
  class FileEditor
    attr_accessor :user, :project, :ref

    def initialize(user, project, ref)
      self.user = user
      self.project = project
      self.ref = ref
    end

    def update(path, content, commit_message, last_commit)
      return false unless can_edit?(path, last_commit)

      Grit::Git.with_timeout(10.seconds) do
        lock_file = Rails.root.join("tmp", "#{project.path}.lock")

        File.open(lock_file, "w+") do |f|
          f.flock(File::LOCK_EX)

          unless project.satellite.exists?
            raise "Satellite doesn't exist"
          end

          project.satellite.clear

          Dir.chdir(project.satellite.path) do
            r = Grit::Repo.new('.')
            r.git.sh "git reset --hard"
            r.git.sh "git fetch origin"
            r.git.sh "git config user.name \"#{user.name}\""
            r.git.sh "git config user.email \"#{user.email}\""
            r.git.sh "git checkout -b #{ref} origin/#{ref}"
            File.open(path, 'w'){|f| f.write(content)}
            r.git.sh "git add ."
            r.git.sh "git commit -am '#{commit_message}'"
            output = r.git.sh "git push origin #{ref}"

            if output =~ /reject/
              return false
            end
          end
        end
      end
      true
    end

    protected

    def can_edit?(path, last_commit)
      current_last_commit = @project.last_commit_for(ref, path).sha
      last_commit == current_last_commit
    end
  end
end

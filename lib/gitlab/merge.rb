module Gitlab
  class Merge
    attr_accessor :project, :merge_request, :user

    def initialize(merge_request, user)
      self.user = user
      self.merge_request = merge_request
      self.project = merge_request.project
    end

    def can_be_merged?
      result = false
      process do |repo, output|
        result = !(output =~ /CONFLICT/)
      end
      result
    end

    def merge
      process do |repo, output|
        if output =~ /CONFLICT/
          false  
        else 
          !!repo.git.push({}, "origin", merge_request.target_branch)
        end
      end
    end

    def process
      Grit::Git.with_timeout(30.seconds) do
        lock_file = Rails.root.join("tmp", "merge_repo_#{project.path}.lock")

        File.open(lock_file, "w+") do |f|
          f.flock(File::LOCK_EX)

          unless project.satellite.exists?
            raise "You should run: rake gitlab:app:enable_automerge"
          end

          project.satellite.clear

          Dir.chdir(project.satellite.path) do
            merge_repo = Grit::Repo.new('.')
            merge_repo.git.sh "git reset --hard"
            merge_repo.git.sh "git fetch origin"
            merge_repo.git.sh "git config user.name \"#{user.name}\""
            merge_repo.git.sh "git config user.email \"#{user.email}\""
            merge_repo.git.sh "git checkout -b #{merge_request.target_branch} origin/#{merge_request.target_branch}"
            output = merge_repo.git.pull({}, "--no-ff", "origin", merge_request.source_branch)

            #remove source-branch
            if merge_request.should_remove_source_branch && !project.root_ref?(merge_request.source_branch)
              merge_repo.git.sh "git push origin :#{merge_request.source_branch}"
            end

            yield(merge_repo, output)
          end
        end
      end

    rescue Grit::Git::GitTimeout
      return false
    end
  end
end

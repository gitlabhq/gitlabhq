class GitlabMerge
  attr_accessor :project, :merge_request, :user

  def initialize(merge_request, user)
    self.user = user
    self.merge_request = merge_request
    self.project = merge_request.project
  end

  def can_be_merged?
    process do |repo, output|
      !(output =~ /Automatic merge failed/)
    end
  end

  def merge
    process do |repo, output|
      if output =~ /Automatic merge failed/
        false  
      else 
        repo.git.push({}, "origin", merge_request.target_branch)
        true
      end
    end
  end

  def process
    Grit::Git.with_timeout(30.seconds) do
      # Make sure tmp/merge_repo exists
      lock_path = File.join(Rails.root, "tmp", "merge_repo")
      FileUtils.mkdir_p(lock_path) unless File.exists?(File.join(Rails.root, "tmp", "merge_repo"))

      File.open(File.join(lock_path, "#{project.path}.lock"), "w+") do |f|
        f.flock(File::LOCK_EX)
        
        unless project.satellite.exists?
          raise "You should run: rake gitlab:app:enable_automerge"
        end

        project.satellite.clear

        Dir.chdir(project.satellite.path) do
          merge_repo = Grit::Repo.new('.')
          merge_repo.git.sh "git fetch origin"
          merge_repo.git.sh "git config user.name \"#{user.name}\""
          merge_repo.git.sh "git config user.email \"#{user.email}\""
          merge_repo.git.sh "git checkout -b #{merge_request.target_branch} origin/#{merge_request.target_branch}"
          output = merge_repo.git.pull({}, "--no-ff", "origin", merge_request.source_branch)
          yield(merge_repo, output)
        end
      end
    end

  rescue Grit::Git::GitTimeout
    return false
  end
end

class GitlabMerge
  attr_accessor :project, :merge_path, :merge_request, :user

  def initialize(merge_request, user)
    self.user = user
    self.merge_request = merge_request
    self.project = merge_request.project
    self.merge_path = File.join(Rails.root, "tmp", "merge_repo", project.path, merge_request.id.to_s)
    FileUtils.rm_rf(merge_path)
    FileUtils.mkdir_p merge_path
  end

  def can_be_merged?
    pull do |repo, output|
      !(output =~ /Automatic merge failed/)
    end
  end

  def merge
    pull do |repo, output|
      if output =~ /Automatic merge failed/
        false  
      else 
        repo.git.push({}, "origin", merge_request.target_branch)
        true
      end
    end
  end

  def pull
    File.open(File.join(Rails.root, "tmp", "merge_repo", "#{project.path}.lock"), "w+") do |f|
      f.flock(File::LOCK_EX)
      
      self.project.repo.git.clone({:branch => merge_request.target_branch}, project.url_to_repo, merge_path)
      unless File.exist?(self.merge_path)
        raise "Gitlab user do not have access to repo. You should run: rake gitlab_enable_automerge"
      end
      Dir.chdir(merge_path) do
        merge_repo = Grit::Repo.new('.')
        merge_repo.git.sh "git config user.name \"#{user.name}\""
        merge_repo.git.sh "git config user.email \"#{user.email}\""
        output = merge_repo.git.pull({}, "--no-ff", "origin", merge_request.source_branch)
        yield(merge_repo, output)
      end

    end
  end
end

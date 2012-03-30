class GitlabMerge
  attr_accessor :project, :merge_path, :merge_request

  def initialize(merge_request)
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
    self.project.repo.git.clone({:branch => merge_request.target_branch}, project.url_to_repo, merge_path)
    Dir.chdir(merge_path) do
      merge_repo = Grit::Repo.new('.')
      output = merge_repo.git.pull({}, "origin", merge_request.source_branch)
      yield(merge_repo, output)
    end
  end
end

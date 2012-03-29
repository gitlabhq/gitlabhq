class GitlabMerge
  attr_accessor :project, :merge_path, :merge_request

  def initialize(merge_request)
    self.merge_request = merge_request
    self.project = merge_request.project
    self.merge_path = File.join(Rails.root, "tmp", "merge_repo", project.path)
    FileUtils.rm_rf(merge_path)
    FileUtils.mkdir_p merge_path
  end

  def merge
    self.project.repo.git.clone({:branch => merge_request.target_branch}, project.url_to_repo, merge_path)
    output = ""
    Dir.chdir(merge_path) do
      merge_repo = Grit::Repo.new('.')
      output = merge_repo.git.pull({}, "origin", merge_request.source_branch)
      if output =~ /Automatic merge failed/
        return false  
      else 
        merge_repo.git.push({}, "origin", merge_request.target_branch)
        return true
      end
    end
  end
end

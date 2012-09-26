module Gitlab
  class Satellite

    PARKING_BRANCH = "__parking_branch"

    attr_accessor :project

    def initialize project
      self.project = project
    end

    def create
      `git clone #{project.url_to_repo} #{path}`
    end

    def path
      Rails.root.join("tmp", "repo_satellites", project.path)
    end

    def exists?
      File.exists? path
    end

    #will be deleted all branches except PARKING_BRANCH
    def clear
      Dir.chdir(path) do
        heads = Grit::Repo.new(".").heads.map{|head| head.name}
        if heads.include? PARKING_BRANCH
          `git checkout #{PARKING_BRANCH}`
        else
          `git checkout -b #{PARKING_BRANCH}`
        end
        heads.delete(PARKING_BRANCH)
        heads.each do |head|
          `git branch -D #{head}`
        end
      end
    end

  end
end

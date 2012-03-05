require File.join(Rails.root, "lib", "gitlabhq", "git_host")

class Repository
  attr_accessor :project

  def self.default_ref
    "master"
  end

  def self.access_options
    {}
  end
end

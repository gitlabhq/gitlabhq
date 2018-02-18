class GithubService < Service
  def title
    'GitHub'
  end

  def description
    'Sends pipeline notifications to GitHub'
  end

  def self.to_param
    'github'
  end
end

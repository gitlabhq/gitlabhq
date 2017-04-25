module Github
  Error = Class.new(StandardError)
  RepositoryFetchError = Class.new(Github::Error)
end

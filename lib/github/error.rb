module Github
  class Error < StandardError
  end

  class RepositoryFetchError < Error; end
end

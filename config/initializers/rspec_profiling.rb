module RspecProfilingConnection
  def establish_connection
    ::RspecProfiling::Collectors::PSQL::Result.establish_connection(ENV['RSPEC_PROFILING_POSTGRES_URL'])
  end
end

module RspecProfilingGitBranchCi
  def branch
    ENV['CI_BUILD_REF_NAME'] || super
  end
end

if Rails.env.test?
  RspecProfiling.configure do |config|
    if ENV['RSPEC_PROFILING_POSTGRES_URL']
      RspecProfiling::Collectors::PSQL.prepend(RspecProfilingConnection)
      config.collector = RspecProfiling::Collectors::PSQL
    end
  end

  RspecProfiling::VCS::Git.prepend(RspecProfilingGitBranchCi) if ENV.has_key?('CI')
end

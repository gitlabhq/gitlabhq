# CI setup

This document describes what services we use for testing GitLab and GitLab CI.

We currently use three CI services to test GitLab:

1. GitLab CI on [GitHost.io](https://gitlab-ce.githost.io/projects/4/) for the [GitLab.com repo](https://gitlab.com/gitlab-org/gitlab-ce)
2. GitLab CI at ci.gitlab.org to test the private GitLab B.V. repo at dev.gitlab.org
3. [Semephore](https://semaphoreapp.com/gitlabhq/gitlabhq/) for [GitHub.com repo](https://github.com/gitlabhq/gitlabhq)

| Software @ configuration being tested | GitLab CI (ci.gitlab.org) | GitLab CI (GitHost.io) | Semaphore |
|---------------------------------------|---------------------------|---------------------------------------------------------------------------|-----------|
| GitLab CE @ MySQL                     | ✓                         | ✓ [Core team can trigger builds](https://gitlab-ce.githost.io/projects/4) |           |
| GitLab CE @ PostgreSQL                |                           |                                                                           | ✓ [Core team can trigger builds](https://semaphoreapp.com/gitlabhq/gitlabhq/branches/master) |
| GitLab EE @ MySQL                     | ✓                         |                                                                           |           |
| GitLab CI @ MySQL                     | ✓                         |                                                                           |           |
| GitLab CI @ PostgreSQL                |                           |                                                                           | ✓         |
| GitLab CI Runner                      | ✓                         |                                                                           | ✓         |
| GitLab Shell                          | ✓                         |                                                                           | ✓         |
| GitLab Shell                          | ✓                         |                                                                           | ✓         |

Core team has access to trigger builds if needed for GitLab CE.

We use [these build scripts](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.gitlab-ci.yml) for testing with GitLab CI.

# Build configuration on [Semaphore](https://semaphoreapp.com/gitlabhq/gitlabhq/) for testing the [GitHub.com repo](https://github.com/gitlabhq/gitlabhq)

- Language: Ruby
- Ruby version: 2.1.8
- database.yml: pg

Build commands

```bash
sudo apt-get install cmake libicu-dev -y (Setup)
bundle install --deployment --path vendor/bundle (Setup)
cp config/gitlab.yml.example config/gitlab.yml (Setup)
bundle exec rake db:create (Setup)
bundle exec rake spinach (Thread #1)
bundle exec rake spec (thread #2)
bundle exec rake rubocop (thread #3)
bundle exec rake brakeman (thread #4)
bundle exec rake jasmine:ci (thread #5)
```

Use rubygems mirror.

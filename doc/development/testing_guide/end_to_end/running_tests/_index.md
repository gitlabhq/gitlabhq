---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Running the tests
---

## Against your GDK environment

First, follow the instructions to [install GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/index.md) as your local GitLab development environment.

Then, navigate to the QA folder, install the gems, and run the tests via RSpec:

```shell
cd gitlab-development-kit/gitlab/qa
bundle install
bundle exec rspec <path/to/spec.rb>
```

NOTE:

- If you want to run tests requiring SSH against GDK, you will need to [modify your GDK setup](https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/run_qa_against_gdk.md).
- You may be able to use the password pre-set for `root` in your GDK installation [See GDK help](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/14bd8b6eb875d72eb1b482e0ec00cbf8fc3ebf99/HELP#L62). If you have changed your `root` password from the default, export the password as `GITLAB_ADMIN_PASSWORD`.
- By default the tests will run in a headless browser. If you'd like to watch the test execution, you can export `WEBDRIVER_HEADLESS=false`.
- Tests that are tagged `:orchestrated` require special setup (e.g., custom GitLab configuration, or additional services such as LDAP). All [orchestrated tests can be run via `gitlab-qa`](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md). There are also [setup instructions](running_tests_that_require_special_setup.md) for running some of those tests against GDK or another local GitLab instance.

### Remote development

For [VSCode](https://code.visualstudio.com/) user, [.devcontainer](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/.devcontainer/devcontainer.json) defines configuration to develop E2E tests inside a Docker container which by default is attached to the same network as environments started by [`gitlab-qa`](https://gitlab.com/gitlab-org/gitlab-qa) gem. For more information on how to use `dev containers`, see [tutorial](https://code.visualstudio.com/docs/devcontainers/tutorial).

This is useful when developing E2E tests that require GitLab instance with specific omnibus configuration. Typical workflow example:

- Start `GitLab` omnibus instance with specific configuration without running tests, for example: `gitlab-qa Test::Integration::Import EE --no-tests`. For available configurations, see [docs](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md)
- Start dev container from `VSCode` environment
- Develop and run tests from within the container which will automatically execute against started GitLab instance

### Generic command for a typical GDK installation

The following is an example command you can use if you have configured GDK to run on a specific IP address and port, that aren't the defaults, and you would like the test framework to show debug logs:

```shell
QA_LOG_LEVEL=DEBUG \
QA_GITLAB_URL="http://{GDK IP ADDRESS}:{GDK PORT}" \
bundle exec rspec <path/to/spec.rb>
```

For an explanation of the variables see the [additional examples below](#overriding-gitlab-address) and the [list of supported environment variables](https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/what_tests_can_be_run.md#supported-gitlab-environment-variables).

## Against GitLab in Docker

GitLab can be [installed in Docker](../../../../install/docker/_index.md).

See the section above for situations that might require adjustment to the commands below or to the configuration of the GitLab instance. [You can find more information in the documentation](../../../../install/docker/_index.md).

### On a Unix like operating system

1. Use the following command to start an instance that you can visit at `http://127.0.0.1`:

   ```shell
   docker run \
    --hostname 127.0.0.1 \
    --publish 80:80 --publish 22:22 \
    --name gitlab \
    --shm-size 256m \
    --env GITLAB_OMNIBUS_CONFIG="gitlab_rails['initial_root_password']='5iveL\!fe';" \
    gitlab/gitlab-ee:nightly
   ```

  NOTE:
  If you are on a Mac with [Apple Silicon](https://support.apple.com/en-us/HT211814), you will also need to add: `--platform=linux/amd64`

1. Once GitLab is up and accessible on `http://127.0.0.1`, in another shell tab, navigate to the `qa` directory of the checkout of the GitLab repository on your computer and run the following commands.

   ```shell
   bundle install
   export WEBDRIVER_HEADLESS=false
   export GITLAB_ADMIN_PASSWORD=5iveL\!fe
   export QA_GITLAB_URL="http://127.0.0.1"
   ```

1. Most tests that do not require special setup could then be run with the following command. We will run `log_in_spec.rb` in this example.

   ```shell
   bundle exec rspec ./qa/specs/features/browser_ui/1_manage/login/log_in_spec.rb
   ```

### On a Windows PC

1. If you don't already have these, install:
   - [Google Chrome](https://www.google.com/chrome/)
   - [Docker Desktop](https://docs.docker.com/desktop/install/windows-install/)
   - [Git](https://git-scm.com/download/win)
   - [Ruby](https://rubyinstaller.org/downloads/). Refer to the [`.ruby-version` file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.ruby-version)
     for the exact version of Ruby to install.

   NOTE:
   Be aware that [Docker Desktop must be set to use Linux containers](https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-10-linux#run-your-first-linux-container).

1. Use the following command to start an instance that you can visit at `http://127.0.0.1`. You might need to grant admin rights if asked:

   ```shell
   docker run --hostname 127.0.0.1 --publish 80:80 --publish 22:22 --name gitlab --shm-size 256m --env GITLAB_OMNIBUS_CONFIG="gitlab_rails['initial_root_password']='5iveL\!fe';" gitlab/gitlab-ee:nightly
   ```

1. Once GitLab is up and accessible on `http://127.0.0.1`, in another command prompt window, navigate to the `qa` directory of the checkout of the GitLab repository on your computer and run the following commands.

   ```shell
   bundle install
   set WEBDRIVER_HEADLESS=false
   set GITLAB_ADMIN_PASSWORD=5iveL\!fe
   set QA_GITLAB_URL=http://127.0.0.1
   ```

1. Most tests that do not require special setup could then be run with the following command. We will run `log_in_spec.rb` in this example.

   ```shell
   bundle exec rspec .\qa\specs\features\browser_ui\1_manage\login\log_in_spec.rb
   ```

## Specific types of tests

You can supply specific tests to run as another parameter. For example, to run the repository-related specs, you can execute:

```shell
bundle exec rspec qa/specs/features/browser_ui/3_create/repository
```

### EE tests

When running EE tests you'll need to have a license available. GitLab engineers can [request a license](https://about.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee).

Once you have the license file you can export it as an environment variable and then the framework can use it. If you do so it will be installed automatically.

```shell
export QA_EE_LICENSE=$(cat /path/to/gitlab_license)
```

### Quarantined tests

Tests can be put in quarantine by assigning `:quarantine` metadata. This means they will be skipped unless run with `--tag quarantine`. This can be used for tests that are expected to fail while a fix is in progress (similar to how [`skip` or `pending`](https://relishapp.com/rspec/rspec-core/v/3-8/docs/pending-and-skipped-examples) can be used).

```shell
bundle exec rspec --tag quarantine
```

### Custom `bin/qa` test runner

`bin/qa` is an additional custom wrapper script that abstracts away some of the more complicated setups that some tests require. This option requires test scenario and test instance's GitLab address to be specified in the command. For example, to run any `Instance` scenario test, the following command can be used:

```shell
bundle exec bin/qa Test::Instance::All http://localhost:3000
```

### Feature flags

Tests can be run with a feature flag enabled or disabled by using the command-line
option `--enable-feature FEATURE_FLAG` or `--disable-feature FEATURE_FLAG`.

For example, to enable the feature flag that enforces Gitaly request limits,
you would use the command:

```shell
bundle exec bin/qa Test::Instance::All http://localhost:3000 --enable-feature gitaly_enforce_requests_limits
```

This will instruct the QA framework to enable the `gitaly_enforce_requests_limits` feature flag ([via the API](../../../../api/features.md)), run all the tests in the `Test::Instance::All` scenario, and then disable the feature flag again.

Similarly, to disable the feature flag that enforces Gitaly request limits, you would use the command:

```shell
bundle exec bin/qa Test::Instance::All http://localhost:3000 --disable-feature gitaly_enforce_requests_limits
```

This will instruct the QA framework to disable the `gitaly_enforce_requests_limits` feature flag ([via the API](../../../../api/features.md)) if not already disabled, run all the tests in the `Test::Instance::All` scenario, and then enable the feature flag again if it was enabled earlier.

NOTE:
You can also [toggle feature flags in the tests themselves](../best_practices/feature_flags.md).

Note also that the `--` separator isn't used because `--enable-feature` and `--disable-feature` are QA framework options, not `rspec` options.

## Test configuration

### Overriding GitLab address

When running tests against GDK, the default address is `http://127.0.0.1:3000`. This value can be overridden by providing environment variable `QA_GITLAB_URL`:

```shell
QA_GITLAB_URL=https://gdk.test:3000 bundle exec rspec
```

### Overriding the authenticated user

By default `root` user seeded by the GDK is used by all tests to create new unique test user for each test.

Tests will also use seeded administrator user's personal access token.

If you need to authenticate with different admin credentials, you can provide the `GITLAB_ADMIN_USERNAME`, `GITLAB_ADMIN_PASSWORD` environment variables and if administrator user has a token created, additionally `GITLAB_QA_ADMIN_ACCESS_TOKEN` can be set as well:

```shell
GITLAB_ADMIN_USERNAME=admin GITLAB_ADMIN_PASSWORD=myadminpassword GITLAB_QA_ADMIN_ACCESS_TOKEN=token bundle exec rspec
```

All [supported environment variables are here](https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/what_tests_can_be_run.md#supported-environment-variables).

### Sending additional cookies

The environment variable `QA_COOKIES` can be set to send additional cookies on every request. This is necessary on `gitlab.com` to direct traffic to the canary fleet. To do this set `QA_COOKIES="gitlab_canary=true"`.

To set multiple cookies, separate them with the `;` character, for example: `QA_COOKIES="cookie1=value;cookie2=value2"`

### Headless browser

By default tests use headless browser. To override that, `WEBDRIVER_HEADLESS` must be set to `false`:

```shell
WEBDRIVER_HEADLESS=false bundle exec rspec
```

### Log level

By default, the tests use the `info` log level. To change the test's log level, the environment variable `QA_LOG_LEVEL` can be set:

```shell
QA_LOG_LEVEL=debug bundle exec rspec
```

# GitLab QA - End-to-end tests for GitLab

This directory contains [end-to-end tests](../../../doc/development/testing_guide/end_to_end/index.md)
for GitLab. It includes the test framework and the tests themselves.

The tests can be found in `qa/specs/features` (not to be confused with the unit
tests for the test framework, which are in `spec/`).

It is part of the [GitLab QA project](https://gitlab.com/gitlab-org/gitlab-qa).

## What is it?

GitLab QA is an end-to-end tests suite for GitLab.

These are black-box and entirely click-driven end-to-end tests you can run
against any existing instance.

## How does it work?

1. When we release a new version of GitLab, we build a Docker images for it.
1. Along with GitLab Docker Images we also build and publish GitLab QA images.
1. GitLab QA project uses these images to execute end-to-end tests.

## Validating GitLab views / partials / selectors in merge requests

We recently added a new CI job that is going to be triggered for every push
event in CE and EE projects. The job is called `qa:selectors` and it will
verify coupling between page objects implemented as a part of GitLab QA
and corresponding views / partials / selectors in CE / EE.

Whenever `qa:selectors` job fails in your merge request, you are supposed to
fix [page objects](../doc/development/testing_guide/end_to_end/page_objects.md). You should also trigger end-to-end tests
using `package-and-qa` manual action, to test if everything works fine.

## How can I use it?

You can use GitLab QA to exercise tests on any live instance! If you don't
have an instance available you can follow the instructions below to use
the [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit).
This is the recommended option if you would like to contribute to the tests.

Note: GitLab QA uses [Selenium WebDriver](https://www.seleniumhq.org/) via
[Cabybara](http://teamcapybara.github.io/capybara/), and by default it targets Chrome as
the browser to use. You will need to have Chrome (or Chromium) and
[chromedriver](https://chromedriver.chromium.org/) installed / in your `$PATH`.

### Run the end-to-end tests in a local development environment

Follow the GDK instructions to [prepare](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/prepare.md)
and [install](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/set-up-gdk.md)
your local GitLab development environment.

Once you have GDK running, switch to the `qa` directory. E.g., if you setup
GDK to develop in the main `gitlab-ce` repo, the GitLab source code will be
in a `gitlab` directory and so the end-to-end test code will be in `gitlab/qa`.

From there you can run the tests. For example, the
following call would login to the GDK instance and run all specs in
`qa/specs/features`:

```
# Make sure to install the dependencies first with `bundle install`

bundle exec bin/qa Test::Instance::All http://localhost:3000
```

Note: If you want to run tests requiring SSH against GDK, you
will need to [modify your GDK setup](https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/run_qa_against_gdk.md).

### Writing tests

- [Writing tests from scratch tutorial](../doc/development/testing_guide/end_to_end/quick_start_guide.md)
    - [Best practices](../doc/development/testing_guide/best_practices.md)
    - [Using page objects](../doc/development/testing_guide/end_to_end/page_objects.md)
    - [Guidelines](../doc/development/testing_guide/index.md)

### Running specific tests

You can also supply specific tests to run as another parameter. For example, to
run the repository-related specs, you can execute:

```
bundle exec bin/qa Test::Instance::All http://localhost:3000 -- qa/specs/features/browser_ui/3_create/repository
```

Since the arguments would be passed to `rspec`, you could use all `rspec`
options there. For example, passing `--backtrace` and also line number:

```
bundle exec bin/qa Test::Instance::All http://localhost:3000 -- qa/specs/features/browser_ui/3_create/merge_request/create_merge_request_spec.rb:6 --backtrace
```

Note that the separator `--` is required; all subsequent options will be
ignored by the QA framework and passed to `rspec`.

### Overriding the authenticated user

Unless told otherwise, the QA tests will run as the default `root` user seeded
by the GDK.

If you need to authenticate as a different user, you can provide the
`GITLAB_USERNAME` and `GITLAB_PASSWORD` environment variables:

```
GITLAB_USERNAME=jsmith GITLAB_PASSWORD=password bundle exec bin/qa Test::Instance::All https://gitlab.example.com
```

Some QA tests require logging in as an admin user. By default, the QA
tests will use the the same `root` user seeded by the GDK.

If you need to authenticate with different admin credentials, you can
provide the `GITLAB_ADMIN_USERNAME` and `GITLAB_ADMIN_PASSWORD`
environment variables:

```
GITLAB_ADMIN_USERNAME=admin GITLAB_ADMIN_PASSWORD=myadminpassword GITLAB_USERNAME=jsmith GITLAB_PASSWORD=password bundle exec bin/qa Test::Instance::All https://gitlab.example.com
```

If your user doesn't have permission to default sandbox group
`gitlab-qa-sandbox`, you could also use another sandbox group by giving
`GITLAB_SANDBOX_NAME`:

```
GITLAB_USERNAME=jsmith GITLAB_PASSWORD=password GITLAB_SANDBOX_NAME=jsmith-qa-sandbox bundle exec bin/qa Test::Instance::All https://gitlab.example.com
```

All [supported environment variables are here](https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/what_tests_can_be_run.md#supported-environment-variables).

### Sending additional cookies

The environment variable `QA_COOKIES` can be set to send additional cookies
on every request. This is necessary on gitlab.com to direct traffic to the
canary fleet. To do this set `QA_COOKIES="gitlab_canary=true"`.

To set multiple cookies, separate them with the `;` character, for example: `QA_COOKIES="cookie1=value;cookie2=value2"`


### Building a Docker image to test

Once you have made changes to the CE/EE repositories, you may want to build a
Docker image to test locally instead of waiting for the `gitlab-ce-qa` or
`gitlab-ee-qa` nightly builds. To do that, you can run **from the top `gitlab`
directory** (one level up from this directory):

```sh
docker build -t gitlab/gitlab-ce-qa:nightly --file ./qa/Dockerfile ./
```

### Quarantined tests

Tests can be put in quarantine by assigning `:quarantine` metadata. This means
they will be skipped unless run with `--tag quarantine`. This can be used for
tests that are expected to fail while a fix is in progress (similar to how
[`skip` or `pending`](https://relishapp.com/rspec/rspec-core/v/3-8/docs/pending-and-skipped-examples)
 can be used).

```
bundle exec bin/qa Test::Instance::All http://localhost:3000 -- --tag quarantine
```

If `quarantine` is used with other tags, tests will only be run if they have at
least one of the tags other than `quarantine`. This is different from how RSpec
tags usually work, where all tags are inclusive.

For example, suppose one test has `:smoke` and `:quarantine` metadata, and
another test has `:ldap` and `:quarantine` metadata. If the tests are run with
`--tag smoke --tag quarantine`, only the first test will run. The test with
`:ldap` will not run even though it also has `:quarantine`.

### Running tests with a feature flag enabled

Tests can be run with with a feature flag enabled by using the command-line
option `--enable-feature FEATURE_FLAG`. For example, to enable the feature flag
that enforces Gitaly request limits, you would use the command:

```
bundle exec bin/qa Test::Instance::All http://localhost:3000 --enable-feature gitaly_enforce_requests_limits
```

This will instruct the QA framework to enable the `gitaly_enforce_requests_limits`
feature flag ([via the API](https://docs.gitlab.com/ee/api/features.html)), run
all the tests in the `Test::Instance::All` scenario, and then disable the
feature flag again.

Note: the QA framework doesn't currently allow you to easily toggle a feature
flag during a single test, [as you can in unit tests](https://docs.gitlab.com/ee/development/feature_flags.html#specs),
but [that capability is planned](https://gitlab.com/gitlab-org/quality/team-tasks/issues/77).

Note also that the `--` separator isn't used because `--enable-feature` is a QA
framework option, not an `rspec` option.

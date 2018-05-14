# GitLab QA - Integration tests for GitLab

This directory contains integration tests for GitLab.

It is part of the [GitLab QA project](https://gitlab.com/gitlab-org/gitlab-qa).

## What is it?

GitLab QA is an integration tests suite for GitLab.

These are black-box and entirely click-driven integration tests you can run
against any existing instance.

## How does it work?

1. When we release a new version of GitLab, we build a Docker images for it.
1. Along with GitLab Docker Images we also build and publish GitLab QA images.
1. GitLab QA project uses these images to execute integration tests.

## Validating GitLab views / partials / selectors in merge requests

We recently added a new CI job that is going to be triggered for every push
event in CE and EE projects. The job is called `qa:selectors` and it will
verify coupling between page objects implemented as a part of GitLab QA
and corresponding views / partials / selectors in CE / EE.

Whenever `qa:selectors` job fails in your merge request, you are supposed to
fix [page objects](qa/page/README.md). You should also trigger end-to-end tests
using `package-and-qa` manual action, to test if everything works fine.

## How can I use it?

You can use GitLab QA to exercise tests on any live instance! For example, the
following call would login to a local [GDK] instance and run all specs in
`qa/specs/features`:

```
bin/qa Test::Instance http://localhost:3000
```

### Writing tests

1. [Using page objects](qa/page/README.md)

### Running specific tests

You can also supply specific tests to run as another parameter. For example, to
run the repository-related specs, you can execute:

```
bin/qa Test::Instance http://localhost qa/specs/features/repository/
```

Since the arguments would be passed to `rspec`, you could use all `rspec`
options there. For example, passing `--backtrace` and also line number:

```
bin/qa Test::Instance http://localhost qa/specs/features/login/standard_spec.rb:3 --backtrace
```

### Overriding the authenticated user

Unless told otherwise, the QA tests will run as the default `root` user seeded
by the GDK.

If you need to authenticate as a different user, you can provide the
`GITLAB_USERNAME` and `GITLAB_PASSWORD` environment variables:

```
GITLAB_USERNAME=jsmith GITLAB_PASSWORD=password bin/qa Test::Instance https://gitlab.example.com
```

If your user doesn't have permission to default sandbox group
`gitlab-qa-sandbox`, you could also use another sandbox group by giving
`GITLAB_SANDBOX_NAME`:

```
GITLAB_USERNAME=jsmith GITLAB_PASSWORD=password GITLAB_SANDBOX_NAME=jsmith-qa-sandbox bin/qa Test::Instance https://gitlab.example.com
```

In addition, the `GITLAB_USER_TYPE` can be set to "ldap" to sign in as an LDAP user:

```
GITLAB_USER_TYPE=ldap GITLAB_USERNAME=jsmith GITLAB_PASSWORD=password GITLAB_SANDBOX_NAME=jsmith-qa-sandbox bin/qa Test::Instance https://gitlab.example.com
```

All [supported environment variables are here](https://gitlab.com/gitlab-org/gitlab-qa#supported-environment-variables).

### Building a Docker image to test

Once you have made changes to the CE/EE repositories, you may want to build a
Docker image to test locally instead of waiting for the `gitlab-ce-qa` or
`gitlab-ee-qa` nightly builds. To do that, you can run from this directory:

```sh
docker build -t gitlab/gitlab-ce-qa:nightly .
```

[GDK]: https://gitlab.com/gitlab-org/gitlab-development-kit/

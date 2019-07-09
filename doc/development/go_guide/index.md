# Go standards and style guidelines

This document describes various guidelines and best practices for GitLab
projects using the [Go language](https://golang.org).

## Overview

GitLab is built on top of [Ruby on Rails](https://rubyonrails.org/), but we're
also using Go for projects where it makes sense. Go is a very powerful
language, with many advantages, and is best suited for projects with a lot of
IO (disk/network access), HTTP requests, parallel processing, etc. Since we
have both Ruby on Rails and Go at GitLab, we should evaluate carefully which of
the two is best for the job.

This page aims to define and organize our Go guidelines, based on our various
experiences. Several projects were started with different standards and they
can still have specifics. They will be described in their respective
`README.md` or `PROCESS.md` files.

## Code Review

We follow the common principles of
[Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments).

Reviewers and maintainers should pay attention to:

- `defer` functions: ensure the presence when needed, and after `err` check.
- Inject dependencies as parameters.
- Void structs when marshaling to JSON (generates `null` instead of `[]`).

### Security

Security is our top priority at GitLab. During code reviews, we must take care
of possible security breaches in our code:

- XSS when using text/template
- CSRF Protection using Gorilla
- Use a Go version without known vulnerabilities
- Don't leak secret tokens
- SQL injections

Remember to run
[SAST](../../user/application_security/sast/index.md)
**(ULTIMATE)** on your project (or at least the [gosec
analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/gosec)),
and to follow our [Security
requirements](../code_review.md#security-requirements).

Web servers can take advantages of middlewares like [Secure](https://github.com/unrolled/secure).

### Finding a reviewer

Many of our projects are too small to have full-time maintainers. That's why we
have a shared pool of Go reviewers at GitLab. To find a reviewer, use the
[Engineering Projects](https://about.gitlab.com/handbook/engineering/projects/)
page in the handbook. "GitLab Community Edition (CE)" and "GitLab Community
Edition (EE)" both have a "Go" section with its list of reviewers.

To add yourself to this list, add the following to your profile in the
[team.yml](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/team.yml)
file and ask your manager to review and merge.

```yaml
projects:
  gitlab-ee: reviewer go
  gitlab-ce: reviewer go
```

## Code style and format

- Avoid global variables, even in packages. By doing so you will introduce side
  effects if the package is included multiple times.
- Use `go fmt` before committing ([Gofmt](https://golang.org/cmd/gofmt/) is a
  tool that automatically formats Go source code).

### Automatic linting

All Go projects should include these GitLab CI/CD jobs:

```yaml
go lint:
  image: golang:1.11
  script:
    - go get -u golang.org/x/lint/golint
    - golint -set_exit_status $(go list ./... | grep -v "vendor/")
```

Once [recursive includes](https://gitlab.com/gitlab-org/gitlab-ce/issues/56836)
become available, you will be able to share job templates like this
[analyzer](https://gitlab.com/gitlab-org/security-products/ci-templates/raw/master/includes-dev/analyzer.yml).

## Dependencies

Dependencies should be kept to the minimum. The introduction of a new
dependency should be argued in the merge request, as per our [Approval
Guidelines](../code_review.md#approval-guidelines). Both [License
Management](../../user/project/merge_requests/license_management.md)
**(ULTIMATE)** and [Dependency
Scanning](../../user/application_security/dependency_scanning/index.md)
**(ULTIMATE)** should be activated on all projects to ensure new dependencies
security status and license compatibility.

### Modules

Since Go 1.11, a standard dependency system is available behind the name [Go
Modules](https://github.com/golang/go/wiki/Modules). It provides a way to
define and lock dependencies for reproducible builds. It should be used
whenever possible.

There was a [bug on modules
checksums](https://github.com/golang/go/issues/29278) in Go < v1.11.4, so make
sure to use at least this version to avoid `checksum mismatch` errors.

### ORM

We don't use object-relational mapping libraries (ORMs) at GitLab (except
[ActiveRecord](https://guides.rubyonrails.org/active_record_basics.html) in
Ruby on Rails). Projects can be structured with services to avoid them.
[PQ](https://github.com/lib/pq) should be enough to interact with PostgreSQL
databases.

### Migrations

In the rare event of managing a hosted database, it's necessary to use a
migration system like ActiveRecord is providing. A simple library like
[Journey](https://github.com/db-journey/journey), designed to be used in
`postgres` containers, can be deployed as long-running pods. New versions will
deploy a new pod, migrating the data automatically.

## Testing

We should not use any specific library or framework for testing, as the
[standard library](https://golang.org/pkg/) provides already everything to get
started. For example, some external dependencies might be worth considering in
case we decide to use a specific library or framework:

- [Testify](https://github.com/stretchr/testify)
- [httpexpect](https://github.com/gavv/httpexpect)

Use [subtests](https://blog.golang.org/subtests) whenever possible to improve
code readability and test output.

### Benchmarks

Programs handling a lot of IO or complex operations should always include
[benchmarks](https://golang.org/pkg/testing/#hdr-Benchmarks), to ensure
performance consistency over time.

## CLIs

Every Go program is launched from the command line.
[cli](https://github.com/urfave/cli) is a convenient package to create command
line apps. It should be used whether the project is a daemon or a simple cli
tool. Flags can be mapped to [environment
variables](https://github.com/urfave/cli#values-from-the-environment) directly,
which documents and centralizes at the same time all the possible command line
interactions with the program. Don't use `os.GetEnv`, it hides variables deep
in the code.

## Daemons

### Logging

The usage of a logging library is strongly recommended for daemons. Even
though there is a `log` package in the standard library, we generally use
[Logrus](https://github.com/sirupsen/logrus). Its plugin ("hooks") system
makes it a powerful logging library, with the ability to add notifiers and
formatters at the logger level directly.

#### Structured (JSON) logging

Every binary ideally must have structured (JSON) logging in place as it helps
with searching and filtering the logs. At GitLab we use structured logging in
JSON format, as all our infrastructure assumes that. When using
[Logrus](https://github.com/sirupsen/logrus) you can turn on structured
logging simply by using the build in [JSON
formatter](https://github.com/sirupsen/logrus#formatters). This follows the
same logging type we use in our [Ruby
applications](../logging.md#use-structured-json-logging).

#### How to use Logrus

There are a few guidelines one should follow when using the
[Logrus](https://github.com/sirupsen/logrus) package:

- When printing an error use
  [WithError](https://godoc.org/github.com/sirupsen/logrus#WithError). For
  example, `logrus.WithError(err).Error("Failed to do something")`.
- Since we use [structured logging](#structured-json-logging) we can log
  fields in the context of that code path, such as the URI of the request using
  [`WithField`](https://godoc.org/github.com/sirupsen/logrus#WithField) or
  [`WithFields`](https://godoc.org/github.com/sirupsen/logrus#WithFields). For
  example, `logrus.WithField("file", "/app/go).Info("Opening dir")`. If you
  have to log multiple keys, always use `WithFields` instead of calling
  `WithField` more than once.

### Tracing and Correlation

[LabKit](https://gitlab.com/gitlab-org/labkit) is a place to keep common
libraries for Go services. Currently it's vendored into two projects:
Workhorse and Gitaly, and it exports two main (but related) pieces of
functionality:

- [`gitlab.com/gitlab-org/labkit/correlation`](https://gitlab.com/gitlab-org/labkit/tree/master/correlation):
  for propagating and extracting correlation ids between services.
- [`gitlab.com/gitlab-org/labkit/tracing`](https://gitlab.com/gitlab-org/labkit/tree/master/tracing):
  for instrumenting Go libraries for distributed tracing.

This gives us a thin abstraction over underlying implementations that is
consistent across Workhorse, Gitaly, and, in future, other Go servers. For
example, in the case of `gitlab.com/gitlab-org/labkit/tracing` we can switch
from using Opentracing directly to using Zipkin or Gokit's own tracing wrapper
without changes to the application code, while still keeping the same
consistent configuration mechanism (i.e. the `GITLAB_TRACING` environment
variable).

### Context

Since daemons are long-running applications, they should have mechanisms to
manage cancellations, and avoid unnecessary resources consumption (which could
lead to DDOS vulnerabilities). [Go
Context](https://github.com/golang/go/wiki/CodeReviewComments#contexts) should
be used in functions that can block and passed as the first parameter.

## Dockerfiles

Every project should have a `Dockerfile` at the root of their repository, to
build and run the project. Since Go program are static binaries, they should
not require any external dependency, and shells in the final image are useless.
We encourage [Multistage
builds](https://docs.docker.com/develop/develop-images/multistage-build/):

- They let the user build the project with the right Go version and
  dependencies.
- They generate a small, self-contained image, derived from `Scratch`.

Generated docker images should have the program at their `Entrypoint` to create
portable commands. That way, anyone can run the image, and without parameters
it will display its help message (if `cli` has been used).

---

[Return to Development documentation](../README.md).

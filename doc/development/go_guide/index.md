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
  gitlab: reviewer go
  gitlab-foss: reviewer go
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

Once [recursive includes](https://gitlab.com/gitlab-org/gitlab-foss/issues/56836)
become available, you will be able to share job templates like this
[analyzer](https://gitlab.com/gitlab-org/security-products/ci-templates/raw/master/includes-dev/analyzer.yml).

## Dependencies

Dependencies should be kept to the minimum. The introduction of a new
dependency should be argued in the merge request, as per our [Approval
Guidelines](../code_review.md#approval-guidelines). Both [License
Management](../../user/application_security/license_compliance/index.md)
**(ULTIMATE)** and [Dependency
Scanning](../../user/application_security/dependency_scanning/index.md)
**(ULTIMATE)** should be activated on all projects to ensure new dependencies
security status and license compatibility.

### Modules

Since Go 1.11, a standard dependency system is available behind the name [Go
Modules](https://github.com/golang/go/wiki/Modules). It provides a way to
define and lock dependencies for reproducible builds. It should be used
whenever possible.

When Go Modules are in use, there should not be a `vendor/` directory. Instead,
Go will automatically download dependencies when they are needed to build the
project. This is in line with how dependencies are handled with Bundler in Ruby
projects, and makes merge requests easier to review.

In some cases, such as building a Go project for it to act as a dependency of a
CI run for another project, removing the `vendor/` directory means the code must
be downloaded repeatedly, which can lead to intermittent problems due to rate
limiting or network failures. In these circumstances, you should cache the
downloaded code between runs with a `.gitlab-ci.yml` snippet like this:

```yaml
.go-cache:
  variables:
    GOPATH: $CI_PROJECT_DIR/.go
  before_script:
    - mkdir -p .go
  cache:
    paths:
      - .go/pkg/mod/

test:
  extends: .go-cache
  # ...
```

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

### Testing frameworks

We should not use any specific library or framework for testing, as the
[standard library](https://golang.org/pkg/) provides already everything to get
started. If there is a need for more sophisticated testing tools, the following
external dependencies might be worth considering in case we decide to use a specific
library or framework:

- [Testify](https://github.com/stretchr/testify)
- [httpexpect](https://github.com/gavv/httpexpect)

### Subtests

Use [subtests](https://blog.golang.org/subtests) whenever possible to improve
code readability and test output.

### Better output in tests

When comparing expected and actual values in tests, use
[testify/require.Equal](https://godoc.org/github.com/stretchr/testify/require#Equal),
[testify/require.EqualError](https://godoc.org/github.com/stretchr/testify/require#EqualError),
[testify/require.EqualValues](https://godoc.org/github.com/stretchr/testify/require#EqualValues),
and others to improve readability when comparing structs, errors,
large portions of text, or JSON documents:

```go
type TestData struct {
    // ...
}

func FuncUnderTest() TestData {
    // ...
}

func Test(t *testing.T) {
    t.Run("FuncUnderTest", func(t *testing.T) {
        want := TestData{}
        got := FuncUnderTest()

        require.Equal(t, want, got) // note that expected value comes first, then comes the actual one ("diff" semantics)
    })
}
```

### Table-Driven Tests

Using [Table-Driven Tests](https://github.com/golang/go/wiki/TableDrivenTests)
is generally good practice when you have multiple entries of
inputs/outputs for the same function. Below are some guidelines one can
follow when writing table-driven test. These guidelines are mostly
extracted from Go standard library source code. Keep in mind it's OK not
to follow these guidelines when it makes sense.

#### Defining test cases

Each table entry is a complete test case with inputs and expected
results, and sometimes with additional information such as a test name
to make the test output easily readable.

- [Define a slice of anonymous struct](https://github.com/golang/go/blob/50bd1c4d4eb4fac8ddeb5f063c099daccfb71b26/src/encoding/csv/reader_test.go#L16)
  inside of the test.
- [Define a slice of anonymous struct](https://github.com/golang/go/blob/55d31e16c12c38d36811bdee65ac1f7772148250/src/cmd/go/internal/module/module_test.go#L9-L66)
  outside of the test.
- [Named structs](https://github.com/golang/go/blob/2e0cd2aef5924e48e1ceb74e3d52e76c56dd34cc/src/cmd/go/internal/modfetch/coderepo_test.go#L54-L69)
  for code reuse.
- [Using `map[string]struct{}`](https://github.com/golang/go/blob/6d5caf38e37bf9aeba3291f1f0b0081f934b1187/src/cmd/trace/annotations_test.go#L180-L235).

#### Contents of the test case

- Ideally, each test case should have a field with a unique identifier
  to use for naming subtests. In the Go standard library, this is commonly the
  `name string` field.
- Use `want`/`expect`/`actual` when you are specifcing something in the
  test case that will be used for assertion.

#### Variable names

- Each table-driven test map/slice of struct can be named `tests`.
- When looping through `tests` the anonymous struct can be referred
  to as `tt` or `tc`.
- The description of the test can be referred to as
  `name`/`testName`/`tn`.

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

## Distributing Go binaries

With the exception of [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner),
which publishes its own binaries, our Go binaries are created by projects
managed by the [Distribution group](https://about.gitlab.com/handbook/product/categories/#distribution-group).

The [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab) project creates a
single, monolithic operating system package containing all the binaries, while
the [Cloud-Native GitLab (CNG)](https://gitlab.com/gitlab-org/build/CNG) project
publishes a set of Docker images and Helm charts to glue them together.

Both approaches use the same version of Go for all projects, so it's important
to ensure all our Go-using projects have at least one Go version in common in
their test matrices. You can check the version of Go currently being used by
[Omnibus](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/blob/master/docker/Dockerfile_debian_10#L59),
and the version being used for [CNG](https://gitlab.com/gitlab-org/build/cng/blob/master/ci_files/variables.yml#L12).

### Updating Go version

We should always use a [supported version](https://golang.org/doc/devel/release.html#policy)
of Go, i.e., one of the three most recent minor releases, and should always use
the most recent patch-level for that version, as it may contain security fixes.

Changing the version affects every project being compiled, so it's important to
ensure that all projects have been updated to test against the new Go version
before changing the package builders to use it. Despite [Go's compatibility promise](https://golang.org/doc/go1compat),
changes between minor versions can expose bugs or cause problems in our projects.

Once you've picked a new Go version to use, the steps to update Omnibus and CNG
are:

- [Create a merge request in the CNG project](https://gitlab.com/gitlab-org/build/CNG/edit/master/ci_files/variables.yml?branch_name=update-go-version),
   updating the `GO_VERSION` in `ci_files/variables.yml`.
- Create a merge request in the [`gitlab-omnibus-builder` project](https://gitlab.com/gitlab-org/gitlab-omnibus-builder),
   updating every file in the `docker/` directory so the `GO_VERSION` is set
   appropriately. [Here's an example](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/merge_requests/125/diffs).
- Tag a new release of `gitlab-omnibus-builder` containing the change.
- [Create a merge request in the `gitlab-omnibus` project](https://gitlab.com/gitlab-org/omnibus-gitlab/edit/master/.gitlab-ci.yml?branch_name=update-gitlab-omnibus-builder-version),
   updating the `BUILDER_IMAGE_REVISION` to match the newly-created tag.

To reduce unnecessary differences between two distribution methods, Omnibus and
CNG **should always use the same Go version**.

---

[Return to Development documentation](../README.md).

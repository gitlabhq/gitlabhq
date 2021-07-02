---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

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
can still have specifics. They are described in their respective
`README.md` or `PROCESS.md` files.

## Dependency Management

Go uses a source-based strategy for dependency management. Dependencies are
downloaded as source from their source repository. This differs from the more
common artifact-based strategy where dependencies are downloaded as artifacts
from a package repository that is separate from the dependency's source
repository.

Go did not have first-class support for version management prior to 1.11. That
version introduced Go modules and the use of semantic versioning. Go 1.12
introduced module proxies, which can serve as an intermediate between clients
and source version control systems, and checksum databases, which can be used to
verify the integrity of dependency downloads.

See [Dependency Management in Go](dependencies.md) for more details.

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
[SAST](../../user/application_security/sast/index.md) and [Dependency Scanning](../../user/application_security/dependency_scanning/index.md)
**(ULTIMATE)** on your project (or at least the
[`gosec` analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/gosec)),
and to follow our [Security requirements](../code_review.md#security-requirements).

Web servers can take advantages of middlewares like [Secure](https://github.com/unrolled/secure).

### Finding a reviewer

Many of our projects are too small to have full-time maintainers. That's why we
have a shared pool of Go reviewers at GitLab. To find a reviewer, use the
["Go" section](https://about.gitlab.com/handbook/engineering/projects/#gitlab_reviewers_go)
of the "GitLab" project on the Engineering Projects
page in the handbook.

To add yourself to this list, add the following to your profile in the
[team.yml](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/team.yml)
file and ask your manager to review and merge.

```yaml
projects:
  gitlab: reviewer go
```

## Code style and format

- Avoid global variables, even in packages. By doing so you introduce side
  effects if the package is included multiple times.
- Use `goimports` before committing.
  [`goimports`](https://pkg.go.dev/golang.org/x/tools/cmd/goimports)
  is a tool that automatically formats Go source code using
  [`Gofmt`](https://golang.org/cmd/gofmt/), in addition to formatting import lines,
  adding missing ones and removing unreferenced ones.

  Most editors/IDEs allow you to run commands before/after saving a file, you can set it
  up to run `goimports` so that it's applied to every file when saving.
- Place private methods below the first caller method in the source file.

### Automatic linting

All Go projects should include these GitLab CI/CD jobs:

```yaml
lint:
  image: registry.gitlab.com/gitlab-org/gitlab-build-images:golangci-lint-alpine
  stage: test
  script:
    # Use default .golangci.yml file from the image if one is not present in the project root.
    - '[ -e .golangci.yml ] || cp /golangci/.golangci.yml .'
    # Write the code coverage report to gl-code-quality-report.json
    # and print linting issues to stdout in the format: path/to/file:line description
    # remove `--issues-exit-code 0` or set to non-zero to fail the job if linting issues are detected
    - golangci-lint run --issues-exit-code 0 --out-format code-climate | tee gl-code-quality-report.json | jq -r '.[] | "\(.location.path):\(.location.lines.begin) \(.description)"'
  artifacts:
    reports:
      codequality: gl-code-quality-report.json
    paths:
      - gl-code-quality-report.json
```

Including a `.golangci.yml` in the root directory of the project allows for
configuration of `golangci-lint`. All options for `golangci-lint` are listed in
this [example](https://github.com/golangci/golangci-lint/blob/master/.golangci.example.yml).

Once [recursive includes](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/56836)
become available, you can share job templates like this
[analyzer](https://gitlab.com/gitlab-org/security-products/ci-templates/raw/master/includes-dev/analyzer.yml).

Go GitLab linter plugins are maintained in the [`gitlab-org/language-tools/go/linters`](https://gitlab.com/gitlab-org/language-tools/go/linters/) namespace.

## Dependencies

Dependencies should be kept to the minimum. The introduction of a new
dependency should be argued in the merge request, as per our [Approval
Guidelines](../code_review.md#approval-guidelines). Both [License
Scanning](../../user/compliance/license_compliance/index.md)
**(ULTIMATE)** and [Dependency
Scanning](../../user/application_security/dependency_scanning/index.md)
**(ULTIMATE)** should be activated on all projects to ensure new dependencies
security status and license compatibility.

### Modules

In Go 1.11 and later, a standard dependency system is available behind the name [Go
Modules](https://github.com/golang/go/wiki/Modules). It provides a way to
define and lock dependencies for reproducible builds. It should be used
whenever possible.

When Go Modules are in use, there should not be a `vendor/` directory. Instead,
Go automatically downloads dependencies when they are needed to build the
project. This is in line with how dependencies are handled with Bundler in Ruby
projects, and makes merge requests easier to review.

In some cases, such as building a Go project for it to act as a dependency of a
CI run for another project, removing the `vendor/` directory means the code must
be downloaded repeatedly, which can lead to intermittent problems due to rate
limiting or network failures. In these circumstances, you should [cache the
downloaded code between](../../ci/caching/index.md#cache-go-dependencies).

There was a
[bug on modules checksums](https://github.com/golang/go/issues/29278) in Go versions earlier than v1.11.4, so make
sure to use at least this version to avoid `checksum mismatch` errors.

### ORM

We don't use object-relational mapping libraries (ORMs) at GitLab (except
[ActiveRecord](https://guides.rubyonrails.org/active_record_basics.html) in
Ruby on Rails). Projects can be structured with services to avoid them.
[`pgx`](https://github.com/jackc/pgx) should be enough to interact with PostgreSQL
databases.

### Migrations

In the rare event of managing a hosted database, it's necessary to use a
migration system like ActiveRecord is providing. A simple library like
[Journey](https://github.com/db-journey/journey), designed to be used in
`postgres` containers, can be deployed as long-running pods. New versions
deploy a new pod, migrating the data automatically.

## Testing

### Testing frameworks

We should not use any specific library or framework for testing, as the
[standard library](https://golang.org/pkg/) provides already everything to get
started. If there is a need for more sophisticated testing tools, the following
external dependencies might be worth considering in case we decide to use a specific
library or framework:

- [Testify](https://github.com/stretchr/testify)
- [`httpexpect`](https://github.com/gavv/httpexpect)

### Subtests

Use [subtests](https://blog.golang.org/subtests) whenever possible to improve
code readability and test output.

### Better output in tests

When comparing expected and actual values in tests, use
[`testify/require.Equal`](https://pkg.go.dev/github.com/stretchr/testify/require#Equal),
[`testify/require.EqualError`](https://pkg.go.dev/github.com/stretchr/testify/require#EqualError),
[`testify/require.EqualValues`](https://pkg.go.dev/github.com/stretchr/testify/require#EqualValues),
and others to improve readability when comparing structs, errors,
large portions of text, or JSON documents:

```golang
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
- Use `want`/`expect`/`actual` when you are specifying something in the
  test case that is used for assertion.

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

## Error handling

### Adding context

Adding context before you return the error can be helpful, instead of
just returning the error. This allows developers to understand what the
program was trying to do when it entered the error state making it much
easier to debug.

For example:

```golang
// Wrap the error
return nil, fmt.Errorf("get cache %s: %w", f.Name, err)

// Just add context
return nil, fmt.Errorf("saving cache %s: %v", f.Name, err)
```

A few things to keep in mind when adding context:

- Decide if you want to expose the underlying error
  to the caller. If so, use `%w`, if not, you can use `%v`.
- Don't use words like `failed`, `error`, `didn't`. As it's an error,
  the user already knows that something failed and this might lead to
  having strings like `failed xx failed xx failed xx`. Explain _what_
  failed instead.
- Error strings should not be capitalized or end with punctuation or a
  newline. You can use `golint` to check for this.

### Naming

- When using sentinel errors they should always be named like `ErrXxx`.
- When creating a new error type they should always be named like
  `XxxError`.

### Checking Error types

- To check error equality don't use `==`. Use
  [`errors.Is`](https://pkg.go.dev/errors?tab=doc#Is) instead (for Go
  versions >= 1.13).
- To check if the error is of a certain type don't use type assertion,
  use [`errors.As`](https://pkg.go.dev/errors?tab=doc#As) instead (for
  Go versions >= 1.13).

### References for working with errors

- [Go 1.13 errors](https://blog.golang.org/go1.13-errors).
- [Programing with
  errors](https://peter.bourgon.org/blog/2019/09/11/programming-with-errors.html).
- [Don't just check errors, handle them
  gracefully](https://dave.cheney.net/2016/04/27/dont-just-check-errors-handle-them-gracefully).

## CLIs

Every Go program is launched from the command line.
[`cli`](https://github.com/urfave/cli) is a convenient package to create command
line apps. It should be used whether the project is a daemon or a simple CLI
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
  [WithError](https://pkg.go.dev/github.com/sirupsen/logrus#WithError). For
  example, `logrus.WithError(err).Error("Failed to do something")`.
- Since we use [structured logging](#structured-json-logging) we can log
  fields in the context of that code path, such as the URI of the request using
  [`WithField`](https://pkg.go.dev/github.com/sirupsen/logrus#WithField) or
  [`WithFields`](https://pkg.go.dev/github.com/sirupsen/logrus#WithFields). For
  example, `logrus.WithField("file", "/app/go").Info("Opening dir")`. If you
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
from using `Opentracing` directly to using `Zipkin` or Gokit's own tracing wrapper
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

Generated Docker images should have the program at their `Entrypoint` to create
portable commands. That way, anyone can run the image, and without parameters
it displays its help message (if `cli` has been used).

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

We should always use a [supported version](https://golang.org/doc/devel/release#policy)
of Go, i.e., one of the three most recent minor releases, and should always use
the most recent patch-level for that version, as it may contain security fixes.

Changing the version affects every project being compiled, so it's important to
ensure that all projects have been updated to test against the new Go version
before changing the package builders to use it. Despite [Go's compatibility promise](https://golang.org/doc/go1compat),
changes between minor versions can expose bugs or cause problems in our projects.

Once you've picked a new Go version to use, the steps to update Omnibus and CNG
are:

- [Create a merge request in the CNG project](https://gitlab.com/gitlab-org/build/CNG/-/edit/master/ci_files/variables.yml?branch_name=update-go-version),
  update the `GO_VERSION` in `ci_files/variables.yml`.
- [Create a merge request in the `gitlab-omnibus-builder` project](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/-/edit/master/docker/VERSIONS?branch_name=update-go-version),
  update the `GO_VERSION` in `docker/VERSIONS`.
- Tag a new release of `gitlab-omnibus-builder` containing the change.
- [Create a merge request in the `omnibus-gitlab` project](https://gitlab.com/gitlab-org/omnibus-gitlab/edit/master/.gitlab-ci.yml?branch_name=update-gitlab-omnibus-builder-version),
  update the `BUILDER_IMAGE_REVISION` to match the newly-created tag.

To reduce unnecessary differences between two distribution methods, Omnibus and
CNG **should always use the same Go version**.

### Supporting multiple Go versions

Individual Golang-projects need to support multiple Go versions for the following reasons:

1. When a new Go release is out, we should start integrating it into the CI pipelines to verify compatibility with the new compiler.
1. We must support the [Omnibus official Go version](#updating-go-version), which may be behind the latest minor release.
1. When Omnibus switches Go version, we still may need to support the old one for security backports.

These 3 requirements may easily be satisfied by keeping support for the 3 latest minor versions of Go.

It's ok to drop support for the oldest Go version and support only 2 latest releases,
if this is enough to support backports to the last 3 GitLab minor releases.

Example:

In case we want to drop support for `go 1.11` in GitLab `12.10`, we need to verify which Go versions we are using in `12.9`, `12.8`, and `12.7`.

We do not consider the active milestone, `12.10`, because a backport for `12.7` is required in case of a critical security release.

1. If both [Omnibus and CNG](#updating-go-version) were using Go `1.12` in GitLab `12.7` and later, then we safely drop support for `1.11`.
1. If Omnibus or CNG were using `1.11` in GitLab `12.7`, then we still need to keep support for Go `1.11` for easier backporting of security fixes.

## Secure Team standards and style guidelines

The following are some style guidelines that are specific to the Secure Team.

### Code style and format

Use `goimports -local gitlab.com/gitlab-org` before committing.
[`goimports`](https://pkg.go.dev/golang.org/x/tools/cmd/goimports)
is a tool that automatically formats Go source code using
[`Gofmt`](https://golang.org/cmd/gofmt/), in addition to formatting import lines,
adding missing ones and removing unreferenced ones.
By using the `-local gitlab.com/gitlab-org` option, `goimports` groups locally referenced
packages separately from external ones. See
[the imports section](https://github.com/golang/go/wiki/CodeReviewComments#imports)
of the Code Review Comments page on the Go wiki for more details.
Most editors/IDEs allow you to run commands before/after saving a file, you can set it
up to run `goimports -local gitlab.com/gitlab-org` so that it's applied to every file when saving.

### Analyzer Tests

The conventional Secure [analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/) has a [`convert` function](https://gitlab.com/gitlab-org/security-products/analyzers/command/-/blob/main/convert.go#L15-17) that converts SAST/DAST scanner reports into [GitLab Security Reports](https://gitlab.com/gitlab-org/security-products/security-report-schemas). When writing tests for the `convert` function, we should make use of [test fixtures](https://dave.cheney.net/2016/05/10/test-fixtures-in-go) using a `testdata` directory at the root of the analyzer's repository. The `testdata` directory should contain two subdirectories: `expect` and `reports`. The `reports` directory should contain sample SAST/DAST scanner reports which are passed into the `convert` function during the test setup. The `expect` directory should contain the expected GitLab Security Report that the `convert` returns. See Secret Detection for an [example](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/160424589ef1eed7b91b59484e019095bc7233bd/convert_test.go#L13-66).

If the scanner report is small, less than 35 lines, then feel free to [inline the report](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow/-/blob/8bd2428a/convert/convert_test.go#L13-77) rather than use a `testdata` directory.

---

[Return to Development documentation](../index.md).

---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Go standards and style guidelines
---

This document describes various guidelines and best practices for GitLab
projects using the [Go language](https://go.dev/).

GitLab is built on top of [Ruby on Rails](https://rubyonrails.org/), but we're
also using Go for projects where it makes sense. Go is a very powerful
language, with many advantages, and is best suited for projects with a lot of
IO (disk/network access), HTTP requests, parallel processing, and so on. Since we
have both Ruby on Rails and Go at GitLab, we should evaluate carefully which of
the two is best for the job.

This page aims to define and organize our Go guidelines, based on our various
experiences. Several projects were started with different standards and they
can still have specifics. They are described in their respective
`README.md` or `PROCESS.md` files.

## Project structure

According to the [basic layout for Go application projects](https://github.com/golang-standards/project-layout?tab=readme-ov-file#overview), there is no official Go project layout. However, there are some good suggestions
in Ben Johnson's [Standard Package Layout](https://www.gobeyond.dev/standard-package-layout/).

The following is a list of GitLab Go-based projects for inspiration:

- [Gitaly](https://gitlab.com/gitlab-org/gitaly)
- [GitLab Agent for Kubernetes](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent)
- [GitLab CLI](https://gitlab.com/gitlab-org/cli)
- [GitLab Container Registry](https://gitlab.com/gitlab-org/container-registry)
- [GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator)
- [GitLab Pages](https://gitlab.com/gitlab-org/gitlab-pages)
- [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner)
- [GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell)
- [Workhorse](https://gitlab.com/gitlab-org/gitlab/-/tree/master/workhorse)

## Go language versions

The Go upgrade documentation [provides an overview](go_upgrade.md#overview)
of how GitLab manages and ships Go binary support.

If a GitLab component requires a newer version of Go,
follow the [upgrade process](go_upgrade.md#updating-go-version) to ensure no customer, team, or component is adversely impacted.

Sometimes, individual projects must also [manage builds with multiple versions of Go](go_upgrade.md#supporting-multiple-go-versions).

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
[SAST](../../user/application_security/sast/_index.md) and [Dependency Scanning](../../user/application_security/dependency_scanning/_index.md) on your project (or at least the
[`gosec` analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/gosec)),
and to follow our [Security requirements](../code_review.md#security).

Web servers can take advantages of middlewares like [Secure](https://github.com/unrolled/secure).

### Finding a reviewer

Many of our projects are too small to have full-time maintainers. That's why we
have a shared pool of Go reviewers at GitLab. To find a reviewer, use the
["Go" section](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab_reviewers_go)
of the "GitLab" project on the Engineering Projects
page in the handbook.

To add yourself to this list, add the following to your profile in the
[`team.yml`](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/team.yml)
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
  [`Gofmt`](https://pkg.go.dev/cmd/gofmt), in addition to formatting import lines,
  adding missing ones and removing unreferenced ones.

  Most editors/IDEs allow you to run commands before/after saving a file, you can set it
  up to run `goimports` so that it's applied to every file when saving.
- Place private methods below the first caller method in the source file.

### Automatic linting

WARNING:
The use of `registry.gitlab.com/gitlab-org/gitlab-build-images:golangci-lint-alpine` has been
[deprecated as of 16.10](https://gitlab.com/gitlab-org/gitlab-build-images/-/issues/131).

Use the upstream version of [golangci-lint](https://golangci-lint.run/).
See the list of linters [enabled/disabled by default](https://golangci-lint.run/usage/linters/#enabled-by-default).

Go projects should include this GitLab CI/CD job:

```yaml
variables:
  GOLANGCI_LINT_VERSION: 'v1.56.2'
lint:
  image: golangci/golangci-lint:$GOLANGCI_LINT_VERSION
  stage: test
  script:
    # Write the code coverage report to gl-code-quality-report.json
    # and print linting issues to stdout in the format: path/to/file:line description
    # remove `--issues-exit-code 0` or set to non-zero to fail the job if linting issues are detected
    - golangci-lint run --issues-exit-code 0 --print-issued-lines=false --out-format code-climate:gl-code-quality-report.json,line-number
  artifacts:
    reports:
      codequality: gl-code-quality-report.json
    paths:
      - gl-code-quality-report.json
```

Including a `.golangci.yml` in the root directory of the project allows for
configuration of `golangci-lint`. All options for `golangci-lint` are listed in
this [example](https://github.com/golangci/golangci-lint/blob/master/.golangci.yml).

Once [recursive includes](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/56836)
become available, you can share job templates like this
[analyzer](https://gitlab.com/gitlab-org/security-products/ci-templates/raw/master/includes-dev/analyzer.yml).

Go GitLab linter plugins are maintained in the
[`gitlab-org/language-tools/go/linters`](https://gitlab.com/gitlab-org/language-tools/go/linters/) namespace.

### Help text style guide

If your Go project produces help text for users, consider following the advice given in the
[Help text style guide](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/help_text_style_guide.md) in the
`gitaly` project.

## Dependencies

Dependencies should be kept to the minimum. The introduction of a new
dependency should be argued in the merge request, as per our [Approval Guidelines](../code_review.md#approval-guidelines).
[Dependency Scanning](../../user/application_security/dependency_scanning/_index.md)
should be activated on all projects to ensure new dependencies
security status and license compatibility.

### Modules

In Go 1.11 and later, a standard dependency system is available behind the name
[Go Modules](https://github.com/golang/go/wiki/Modules). It provides a way to
define and lock dependencies for reproducible builds. It should be used
whenever possible.

When Go Modules are in use, there should not be a `vendor/` directory. Instead,
Go automatically downloads dependencies when they are needed to build the
project. This is in line with how dependencies are handled with Bundler in Ruby
projects, and makes merge requests easier to review.

In some cases, such as building a Go project for it to act as a dependency of a
CI run for another project, removing the `vendor/` directory means the code must
be downloaded repeatedly, which can lead to intermittent problems due to rate
limiting or network failures. In these circumstances, you should
[cache the downloaded code between](../../ci/caching/_index.md#cache-go-dependencies).

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
[standard library](https://pkg.go.dev/std) provides already everything to get
started. If there is a need for more sophisticated testing tools, the following
external dependencies might be worth considering in case we decide to use a specific
library or framework:

- [Testify](https://github.com/stretchr/testify)
- [`httpexpect`](https://github.com/gavv/httpexpect)

### Subtests

Use [subtests](https://go.dev/blog/subtests) whenever possible to improve
code readability and test output.

### Better output in tests

When comparing expected and actual values in tests, use
[`testify/require.Equal`](https://pkg.go.dev/github.com/stretchr/testify/require#Equal),
[`testify/require.EqualError`](https://pkg.go.dev/github.com/stretchr/testify/require#EqualError),
[`testify/require.EqualValues`](https://pkg.go.dev/github.com/stretchr/testify/require#EqualValues),
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
[benchmarks](https://pkg.go.dev/testing#hdr-Benchmarks), to ensure
performance consistency over time.

## Error handling

### Adding context

Adding context before you return the error can be helpful, instead of
just returning the error. This allows developers to understand what the
program was trying to do when it entered the error state making it much
easier to debug.

For example:

```go
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

- [Go 1.13 errors](https://go.dev/blog/go1.13-errors).
- [Programing with errors](https://peter.bourgon.org/blog/2019/09/11/programming-with-errors.html).
- [Don't just check errors, handle them gracefully](https://dave.cheney.net/2016/04/27/dont-just-check-errors-handle-them-gracefully).

## CLIs

Every Go program is launched from the command line.
[`cli`](https://github.com/urfave/cli) is a convenient package to create command
line apps. It should be used whether the project is a daemon or a simple CLI
tool. Flags can be mapped to [environment variables](https://github.com/urfave/cli#values-from-the-environment) directly,
which documents and centralizes at the same time all the possible command line
interactions with the program. Don't use `os.GetEnv`, it hides variables deep
in the code.

## Libraries

### LabKit

[LabKit](https://gitlab.com/gitlab-org/labkit) is a place to keep common
libraries for Go services. For examples using of using LabKit, see [`workhorse`](https://gitlab.com/gitlab-org/gitlab/tree/master/workhorse)
and [`gitaly`](https://gitlab.com/gitlab-org/gitaly). LabKit exports three related pieces of functionality:

- [`gitlab.com/gitlab-org/labkit/correlation`](https://gitlab.com/gitlab-org/labkit/tree/master/correlation):
  for propagating and extracting correlation ids between services.
- [`gitlab.com/gitlab-org/labkit/tracing`](https://gitlab.com/gitlab-org/labkit/tree/master/tracing):
  for instrumenting Go libraries for distributed tracing.
- [`gitlab.com/gitlab-org/labkit/log`](https://gitlab.com/gitlab-org/labkit/tree/master/log):
  for structured logging using Logrus.

This gives us a thin abstraction over underlying implementations that is
consistent across Workhorse, Gitaly, and possibly other Go servers. For
example, in the case of `gitlab.com/gitlab-org/labkit/tracing` we can switch
from using `Opentracing` directly to using `Zipkin` or the Go kit's own tracing wrapper
without changes to the application code, while still keeping the same
consistent configuration mechanism (that is, the `GITLAB_TRACING` environment
variable).

#### Structured (JSON) logging

Every binary ideally must have structured (JSON) logging in place as it helps
with searching and filtering the logs. LabKit provides an abstraction over [Logrus](https://github.com/sirupsen/logrus).
We use structured logging in JSON format, because all our infrastructure assumes that. When using
[Logrus](https://github.com/sirupsen/logrus) you can turn on structured
logging by using the built-in [JSON formatter](https://github.com/sirupsen/logrus#formatters). This follows the
same logging type we use in our [Ruby applications](../logging.md#use-structured-json-logging).

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

### Context

Since daemons are long-running applications, they should have mechanisms to
manage cancellations, and avoid unnecessary resources consumption (which could
lead to DDoS vulnerabilities). [Go Context](https://github.com/golang/go/wiki/CodeReviewComments#contexts)
should be used in functions that can block and passed as the first parameter.

## Dockerfiles

Every project should have a `Dockerfile` at the root of their repository, to
build and run the project. Since Go program are static binaries, they should
not require any external dependency, and shells in the final image are useless.
We encourage [Multistage builds](https://docs.docker.com/build/building/multi-stage/):

- They let the user build the project with the right Go version and
  dependencies.
- They generate a small, self-contained image, derived from `Scratch`.

Generated Docker images should have the program at their `Entrypoint` to create
portable commands. That way, anyone can run the image, and without parameters
it displays its help message (if `cli` has been used).

## Secure Team standards and style guidelines

The following are some style guidelines that are specific to the Secure Team.

### Code style and format

Use `goimports -local gitlab.com/gitlab-org` before committing.
[`goimports`](https://pkg.go.dev/golang.org/x/tools/cmd/goimports)
is a tool that automatically formats Go source code using
[`Gofmt`](https://pkg.go.dev/cmd/gofmt), in addition to formatting import lines,
adding missing ones and removing unreferenced ones.
By using the `-local gitlab.com/gitlab-org` option, `goimports` groups locally referenced
packages separately from external ones. See
[the imports section](https://github.com/golang/go/wiki/CodeReviewComments#imports)
of the Code Review Comments page on the Go wiki for more details.
Most editors/IDEs allow you to run commands before/after saving a file, you can set it
up to run `goimports -local gitlab.com/gitlab-org` so that it's applied to every file when saving.

### Naming branches

In addition to the GitLab [branch name rules](../../user/project/repository/branches/_index.md#name-your-branch), use only the characters `a-z`, `0-9` or `-` in branch names. This restriction is because `go get` doesn't work as expected when a branch name contains certain characters, such as a slash `/`:

```shell
$ go get -u gitlab.com/gitlab-org/security-products/analyzers/report/v3@some-user/some-feature

go get: gitlab.com/gitlab-org/security-products/analyzers/report/v3@some-user/some-feature: invalid version: version "some-user/some-feature" invalid: disallowed version string
```

If a branch name contains a slash, it forces us to refer to the commit SHA instead, which is less flexible. For example:

```shell
$ go get -u gitlab.com/gitlab-org/security-products/analyzers/report/v3@5c9a4279fa1263755718cf069d54ba8051287954

go: downloading gitlab.com/gitlab-org/security-products/analyzers/report/v3 v3.15.3-0.20221012172609-5c9a4279fa12
...
```

### Initializing slices

If initializing a slice, provide a capacity where possible to avoid extra
allocations.

**Don't:**

```go
var s2 []string
for _, val := range s1 {
    s2 = append(s2, val)
}
```

**Do:**

```go
s2 := make([]string, 0, len(s1))
for _, val := range s1 {
    s2 = append(s2, val)
}
```

If no capacity is passed to `make` when creating a new slice, `append`
will continuously resize the slice's backing array if it cannot hold
the values. Providing the capacity ensures that allocations are kept
to a minimum. It's recommended that the [`prealloc`](https://github.com/alexkohler/prealloc)
golanci-lint rule automatically check for this.

### Analyzer Tests

The conventional Secure [analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/) has a
[`convert` function](https://gitlab.com/gitlab-org/security-products/analyzers/command/-/blob/main/convert.go#L15-17)
that converts SAST/DAST scanner reports into
[GitLab Security Reports](https://gitlab.com/gitlab-org/security-products/security-report-schemas).
When writing tests for the `convert` function, we should make use of
[test fixtures](https://dave.cheney.net/2016/05/10/test-fixtures-in-go) using a `testdata`
directory at the root of the analyzer's repository. The `testdata` directory should
contain two subdirectories: `expect` and `reports`. The `reports` directory should
contain sample SAST/DAST scanner reports which are passed into the `convert` function
during the test setup. The `expect` directory should contain the expected GitLab Security Report
that the `convert` returns. See Secret Detection for an
[example](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/160424589ef1eed7b91b59484e019095bc7233bd/convert_test.go#L13-66).

If the scanner report is small, less than 35 lines, then feel free to
[inline the report](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow/-/blob/8bd2428a/convert/convert_test.go#L13-77)
rather than use a `testdata` directory.

#### Test Diffs

The [go-cmp](https://github.com/google/go-cmp) package should be used when
comparing large structs in tests. It makes it possible to output a specific diff
where the two structs differ, rather than seeing the whole of both structs
printed out in the test logs. Here is a small example:

```go
package main

import (
  "reflect"
  "testing"

  "github.com/google/go-cmp/cmp"
)

type Foo struct {
  Desc  Bar
  Point Baz
}

type Bar struct {
  A string
  B string
}

type Baz struct {
  X int
  Y int
}

func TestHelloWorld(t *testing.T) {
  want := Foo{
    Desc:  Bar{A: "a", B: "b"},
    Point: Baz{X: 1, Y: 2},
  }

  got := Foo{
    Desc:  Bar{A: "a", B: "b"},
    Point: Baz{X: 2, Y: 2},
  }

  t.Log("reflect comparison:")
  if !reflect.DeepEqual(got, want) {
    t.Errorf("Wrong result. want:\n%v\nGot:\n%v", want, got)
  }

  t.Log("cmp comparison:")
  if diff := cmp.Diff(want, got); diff != "" {
    t.Errorf("Wrong result. (-want +got):\n%s", diff)
  }
}
```

The output demonstrates why `go-cmp` is far superior when comparing large
structs. Even though you could spot the difference with this small difference,
it quickly gets unwieldy as the data grows.

```plaintext
  main_test.go:36: reflect comparison:
  main_test.go:38: Wrong result. want:
      {{a b} {1 2}}
      Got:
      {{a b} {2 2}}
  main_test.go:41: cmp comparison:
  main_test.go:43: Wrong result. (-want +got):
        main.Foo{
              Desc: {A: "a", B: "b"},
              Point: main.Baz{
      -               X: 1,
      +               X: 2,
                      Y: 2,
              },
        }
```

---

[Return to Development documentation](../_index.md).

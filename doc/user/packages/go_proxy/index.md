# GitLab Go Proxy **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27376) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.1.
> - It's deployed behind a feature flag, disabled by default.
> - It's disabled on GitLab.com.
> - It's not recommended for production use.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-the-go-proxy). **(PREMIUM)**

With the Go proxy for GitLab, every project in GitLab can be fetched with the
[Go proxy protocol](https://proxy.golang.org/).

## Prerequisites

### Enable the Go proxy

The Go proxy for GitLab is under development and not ready for production use, due to
[potential performance issues with large repositories](https://gitlab.com/gitlab-org/gitlab/-/issues/218083).

It is deployed behind a feature flag that is **disabled by default**.

[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can enable it for your instance.

To enable it:

```ruby
Feature.enable(:go_proxy) # or
```

To disable it:

```ruby
Feature.disable(:go_proxy)
```

To enable or disable it for specific projects:

```ruby
Feature.enable(:go_proxy, Project.find(1))
Feature.disable(:go_proxy, Project.find(2))
```

### Enable the Package Registry

The Package Registry is enabled for new projects by default. If you cannot find
the **{package}** **Packages > List** entry under your project's sidebar, verify
the following:

1. Your GitLab administrator has
   [enabled support for the Package Registry](../../../administration/packages/index.md). **(PREMIUM ONLY)**
1. The Package Registry is [enabled for your project](../index.md).

NOTE: **Note:**
GitLab does not currently display Go modules in the **Packages Registry** of a project.
Follow [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/213770) for details.

## Add GitLab as a Go proxy

NOTE: **Note:**
To use a Go proxy, you must be using Go 1.13 or later.

The available proxy endpoints are:

- Project - can fetch modules defined by a project - `/api/v4/projects/:id/packages/go`

To use the Go proxy for GitLab to fetch Go modules from GitLab, add the
appropriate proxy endpoint to `GOPROXY`. For details on setting Go environment
variables, see [Set environment variables](#set-environment-variables). For
details on configuring `GOPROXY`, see [Dependency Management in Go >
Proxies](../../../development/go_guide/dependencies.md#proxies).

For example, adding the project-specific endpoint to `GOPROXY` will tell Go
to initially query that endpoint and fall back to the default behavior:

```shell
go env -w GOPROXY='https://gitlab.com/api/v4/projects/1234/packages/go,https://proxy.golang.org,direct'
```

With this configuration, Go fetches dependencies as follows:

1. Attempt to fetch from the project-specific Go proxy.
1. Attempt to fetch from [proxy.golang.org](https://proxy.golang.org).
1. Fetch directly with version control system operations (such as `git clone`,
   `svn checkout`, and so on).

If `GOPROXY` is not specified, Go follows steps 2 and 3, which corresponds to
setting `GOPROXY` to `https://proxy.golang.org,direct`. If `GOPROXY` only
contains the project-specific endpoint, Go will only query that endpoint.

## Fetch modules from private projects

`go` does not support transmitting credentials over insecure connections. The
steps below work only if GitLab is configured for HTTPS.

1. Configure Go to include HTTP basic authentication credentials when fetching
   from the Go proxy for GitLab.
1. Configure Go to skip downloading of checksums for private GitLab projects
   from the public checksum database.

### Enable request authentication

Create a [personal access token](../../profile/personal_access_tokens.md) with
the `api` or `read_api` scope and add it to
[`~/.netrc`](https://ec.haxx.se/usingcurl/usingcurl-netrc):

```netrc
machine <url> login <username> password <token>
```

`<url>` should be the URL of the GitLab instance, for example `gitlab.com`.
`<username>` and `<token>` should be your username and the personal access
token, respectively.

### Disable checksum database queries

When downloading dependencies, by default Go 1.13 and later validate fetched
sources against the checksum database `sum.golang.org`. If the checksum of the
fetched sources does not match the checksum from the database, Go will not build
the dependency. This causes private modules to fail to build, as
`sum.golang.org` cannot fetch the source of private modules and thus cannot
provide a checksum. To resolve this issue, `GONOSUMDB` should be set to a
comma-separated list of private projects. For details on setting Go environment
variables, see [Set environment variables](#set-environment-variables). For more
details on disabling this feature of Go, see [Dependency Management in Go >
Checksums](../../../development/go_guide/dependencies.md#checksums).

For example, to disable checksum queries for `gitlab.com/my/project`, set `GONOSUMDB`:

```shell
go env -w GONOSUMDB='gitlab.com/my/project,<previous value>'
```

## Working with Go

If you are unfamiliar with managing dependencies in Go, or Go in general,
consider reviewing the following documentation:

- [Dependency Management in Go](../../../development/go_guide/dependencies.md)
- [Go Modules Reference](https://golang.org/ref/mod)
- [Documentation (golang.org)](https://golang.org/doc/)
- [Learn (learn.go.dev)](https://learn.go.dev/)

### Set environment variables

Go uses environment variables to control various features. These can be managed
in all the usual ways, but Go 1.14 will read and write Go environment variables
from and to a special Go environment file, `~/.go/env` by default. If `GOENV` is
set to a file, Go will read and write that file instead. If `GOENV` is not set
but `GOPATH` is set, Go will read and write `$GOPATH/env`.

Go environment variables can be read with `go env <var>` and, in Go 1.14 and
later, can be written with `go env -w <var>=<value>`. For example, `go env
GOPATH` or `go env -w GOPATH=/go`.

### Release a module

Go modules and module versions are defined by source repositories, such as Git,
SVN, Mercurial, and so on. A module is a repository containing `go.mod` and Go
files. Module versions are defined by VCS tags. To publish a module, push
`go.mod` and source files to a VCS repository. To publish a module version, push
a VCS tag. See [Dependency Management in Go >
Versioning](../../../development/go_guide/dependencies.md#versioning) for more
details on what constitutes a valid module or module version.

---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Go proxy for GitLab **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27376) in GitLab Premium 13.1.
> - It's deployed behind a feature flag, disabled by default.
> - It's disabled for GitLab.com.
> - It's not recommended for production use.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-the-go-proxy).
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Free in 13.3.

With the Go proxy for GitLab, every project in GitLab can be fetched with the
[Go proxy protocol](https://proxy.golang.org/).

For documentation of the specific API endpoints that the Go Proxy uses, see the
[Go Proxy API documentation](../../../api/packages/go_proxy.md).

## Enable the Go proxy

The Go proxy for GitLab is under development, and isn't ready for production use
due to [potential performance issues with large repositories](https://gitlab.com/gitlab-org/gitlab/-/issues/218083).

It's deployed behind a feature flag that is _disabled by default_.

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

NOTE:
Even if it's enabled, GitLab doesn't display Go modules in the **Package Registry**.
Follow [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/213770) for
details.

## Add GitLab as a Go proxy

To use GitLab as a Go proxy, you must be using Go 1.13 or later.

The available proxy endpoint is for fetching modules by project: `/api/v4/projects/:id/packages/go`

To fetch Go modules from GitLab, add the project-specific endpoint to `GOPROXY`.

Go queries the endpoint and falls back to the default behavior:

```shell
go env -w GOPROXY='https://gitlab.example.com/api/v4/projects/1234/packages/go,https://proxy.golang.org,direct'
```

With this configuration, Go fetches dependencies in this order:

1. Go attempts to fetch from the project-specific Go proxy.
1. Go attempts to fetch from [proxy.golang.org](https://proxy.golang.org).
1. Go fetches directly with version control system operations (like `git clone`,
   `svn checkout`, and so on).

If `GOPROXY` isn't specified, Go follows steps 2 and 3, which corresponds to
setting `GOPROXY` to `https://proxy.golang.org,direct`. If `GOPROXY`
contains only the project-specific endpoint, Go queries only that endpoint.

For details about how to set Go environment variables, see
[Set environment variables](#set-environment-variables).

For details about configuring `GOPROXY`, see
[Dependency Management in Go > Proxies](../../../development/go_guide/dependencies.md#proxies).

## Fetch modules from private projects

`go` doesn't support transmitting credentials over insecure connections. The
following steps work only if GitLab is configured for HTTPS:

1. Configure Go to include HTTP basic authentication credentials when fetching
   from the Go proxy for GitLab.
1. Configure Go to skip downloading of checksums for private GitLab projects
   from the public checksum database.

### Enable request authentication

Create a [personal access token](../../profile/personal_access_tokens.md) with
the scope set to `api` or `read_api`.

Open your [`~/.netrc`](https://everything.curl.dev/usingcurl/netrc) file
and add the following text. Replace the variables in `< >` with your values.

```plaintext
machine <url> login <username> password <token>
```

- `<url>`: The GitLab URL, for example `gitlab.com`.
- `<username>`: Your username.
- `<token>`: Your personal access token.

### Disable checksum database queries

When downloading dependencies with Go 1.13 and later, fetched sources are
validated against the checksum database `sum.golang.org`.

If the checksum of the fetched sources doesn't match the checksum from the
database, Go doesn't build the dependency.

Private modules fail to build because `sum.golang.org` can't fetch the source
of private modules, and so it cannot provide a checksum.

To resolve this issue, set `GONOSUMDB` to a comma-separated list of private
projects. For details about setting Go environment variables, see
[Set environment variables](#set-environment-variables). For more details about
disabling this feature of Go, see
[Dependency Management in Go > Checksums](../../../development/go_guide/dependencies.md#checksums).

For example, to disable checksum queries for `gitlab.com/my/project`, set
`GONOSUMDB`:

```shell
go env -w GONOSUMDB='gitlab.com/my/project,<previous value>'
```

## Working with Go

If you're unfamiliar with managing dependencies in Go, or Go in general, review
the following documentation:

- [Dependency Management in Go](../../../development/go_guide/dependencies.md)
- [Go Modules Reference](https://golang.org/ref/mod)
- [Documentation (`golang.org`)](https://golang.org/doc/)
- [Learn (`go.dev/learn`)](https://go.dev/learn/)

### Set environment variables

Go uses environment variables to control various features. You can manage these
variables in all the usual ways. However, Go 1.14 reads and writes Go
environment variables to and from a special Go environment file, `~/.go/env` by
default.

- If `GOENV` is set to a file, Go reads and writes to and from that file instead.
- If `GOENV` is not set but `GOPATH` is set, Go reads and writes `$GOPATH/env`.

Go environment variables can be read with `go env <var>` and, in Go 1.14 and
later, can be written with `go env -w <var>=<value>`. For example,
`go env GOPATH` or `go env -w GOPATH=/go`.

### Release a module

Go modules and module versions are defined by source repositories, such as Git,
SVN, and Mercurial. A module is a repository that contains `go.mod` and Go
files. Module versions are defined by version control system (VCS) tags.

To publish a module, push `go.mod` and source files to a VCS repository. To
publish a module version, push a VCS tag.

See [Dependency Management in Go > Versioning](../../../development/go_guide/dependencies.md#versioning)
for more details about what constitutes a valid module or module version.

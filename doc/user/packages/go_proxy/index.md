# GitLab Go Proxy **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/27376) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.1.
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

### Fetch modules from private projects

`go` does not support transmitting credentials over insecure connections. The
steps below work only if GitLab is configured for HTTPS.

1. Configure Go to include HTTP basic authentication credentials when fetching
   from the Go proxy for GitLab.
1. Configure Go to skip downloading of checksums for private GitLab projects
   from the public checksum database.

#### Enable Request Authentication

Create a [personal access token](../../profile/personal_access_tokens.md) with
the `api` or `read_api` scope and add it to
[`~/.netrc`](https://ec.haxx.se/usingcurl/usingcurl-netrc):

```netrc
machine <url> login <username> password <token>
```

`<url>` should be the URL of the GitLab instance, for example `gitlab.com`.
`<username>` and `<token>` should be your username and the personal access
token, respectively.

#### Disable checksum database queries

Go can be configured to query a checksum database for module checksums. Go 1.13
and later query `sum.golang.org` by default. This fails for modules that are not
public and thus not accessible to `sum.golang.org`. To resolve this issue, set
`GONOSUMDB` to a comma-separated list of projects or namespaces for which Go
should not query the checksum database. For example, `go env -w
GONOSUMDB=gitlab.com/my/project` persistently configures Go to skip checksum
queries for the project `gitlab.com/my/project`.

Checksum database queries can be disabled for arbitrary prefixes or disabled
entirely. However, checksum database queries are a security mechanism and as
such they should be disabled selectively and only when necessary. `GOSUMDB=off`
or `GONOSUMDB=*` disables checksum queries entirely. `GONOSUMDB=gitlab.com`
disables checksum queries for all projects hosted on GitLab.com.

## Add GitLab as a Go proxy

NOTE: **Note:**
To use a Go proxy, you must be using Go 1.13 or later.

The available proxy endpoints are:

- Project - can fetch modules defined by a project - `/api/v4/projects/:id/packages/go`

Go's use of proxies is configured with the `GOPROXY` environment variable, as a
comma separated list of URLs. Go 1.14 adds support for comma separated list of
URLs. Go 1.14 adds support for using `go env -w` to manage Go's environment
variables. For example, `go env -w GOPROXY=...` writes to `$GOPATH/env`
(which defaults to `~/.go/env`). `GOPROXY` can also be configured as a normal
environment variable, with RC files or `export GOPROXY=...`.

The default value of `$GOPROXY` is `https://proxy.golang.org,direct`, which
tells `go` to first query `proxy.golang.org` and fallback to direct VCS
operations (`git clone`, `svc checkout`, etc). Replacing
`https://proxy.golang.org` with a GitLab endpoint will direct all fetches
through GitLab. Currently GitLab's Go proxy does not support dependency
proxying, so all external dependencies will be handled directly. If GitLab's
endpoint is inserted before `https://proxy.golang.org`, then all fetches will
first go through GitLab. This can help avoid making requests for private
packages to the public proxy, but `GOPRIVATE` is a much safer way of achieving
that.

For example, with the following configuration, Go will attempt to fetch modules
from 1) GitLab project 1234's Go module proxy, 2) `proxy.golang.org`, and
finally 3) directly with Git (or another VCS, depending on where the module
source is hosted).

```shell
go env -w GOPROXY=https://gitlab.com/api/v4/projects/1234/packages/go,https://proxy.golang.org,direct
```

## Release a module

Go modules and module versions are handled entirely with Git (or SVN, Mercurial,
and so on). A module is a repository containing Go source and a `go.mod` file. A
version of a module is a Git tag (or equivalent) that is a valid [semantic
version](https://semver.org), prefixed with 'v'. For example, `v1.0.0` and
`v1.3.2-alpha` are valid module versions, but `v1` or `v1.2` are not.

Go requires that major versions after v1 involve a change in the import path of
the module. For example, version 2 of the module `gitlab.com/my/project` must be
imported and released as `gitlab.com/my/project/v2`.

For a complete understanding of Go modules and versioning, see [this series of
blog posts](https://blog.golang.org/using-go-modules) on the official Go
website.

## Valid modules and versions

The GitLab Go proxy will ignore modules and module versions that have an invalid
`module` directive in their `go.mod`. Go requires that a package imported as
`gitlab.com/my/project` can be accessed with that same URL, and that the first
line of `go.mod` is `module gitlab.com/my/project`. If `go.mod` names a
different module, compilation will fail. Additionally, Go requires, for major
versions after 1, that the name of the module have an appropriate suffix, for
example `gitlab.com/my/project/v2`. If the `module` directive does not also have
this suffix, compilation will fail.

Go supports 'pseudo-versions' that encode the timestamp and SHA of a commit.
Tags that match the pseudo-version pattern are ignored, as otherwise they could
interfere with fetching specific commits using a pseudo-version. Pseudo-versions
follow one of three formats:

- `vX.0.0-yyyymmddhhmmss-abcdefabcdef`, when no earlier tagged commit exists for X.
- `vX.Y.Z-pre.0.yyyymmddhhmmss-abcdefabcdef`, when most recent prior tag is vX.Y.Z-pre.
- `vX.Y.(Z+1)-0.yyyymmddhhmmss-abcdefabcdef`, when most recent prior tag is vX.Y.Z.

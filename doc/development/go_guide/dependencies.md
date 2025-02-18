---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Dependency Management in Go
---

Go takes an unusual approach to dependency management, in that it is
source-based instead of artifact-based. In an artifact-based dependency
management system, packages consist of artifacts generated from source code and
are stored in a separate repository system from source code. For example, many
NodeJS packages use `npmjs.org` as a package repository and `github.com` as a
source repository. On the other hand, packages in Go *are* source code and
releasing a package does not involve artifact generation or a separate
repository. Go packages must be stored in a version control repository on a VCS
server. Dependencies are fetched directly from their VCS server or via an
intermediary proxy which itself fetches them from their VCS server.

## Versioning

Go 1.11 introduced modules and first-class package versioning to the Go ecosystem.
Prior to this, Go did not have any well-defined mechanism for version management.
While 3rd party version management tools existed, the default Go experience had
no support for versioning.

Go modules use [semantic versioning](https://semver.org). The versions of a
module are defined as VCS (version control system) tags that are valid semantic
versions prefixed with `v`. For example, to release version `1.0.0` of
`gitlab.com/my/project`, the developer must create the Git tag `v1.0.0`.

For major versions other than 0 and 1, the module name must be suffixed with
`/vX` where X is the major version. For example, version `v2.0.0` of
`gitlab.com/my/project` must be named and imported as
`gitlab.com/my/project/v2`.

Go uses 'pseudo-versions', which are special semantic versions that reference a
specific VCS commit. The prerelease component of the semantic version must be or
end with a timestamp and the first 12 characters of the commit identifier:

- `vX.0.0-yyyymmddhhmmss-abcdefabcdef`, when no earlier tagged commit exists for X.
- `vX.Y.Z-pre.0.yyyymmddhhmmss-abcdefabcdef`, when most recent prior tag is vX.Y.Z-pre.
- `vX.Y.(Z+1)-0.yyyymmddhhmmss-abcdefabcdef`, when most recent prior tag is vX.Y.Z.

If a VCS tag matches one of these patterns, it is ignored.

For a complete understanding of Go modules and versioning, see
[this series of blog posts](https://go.dev/blog/using-go-modules)
on the official Go website.

## 'Module' vs 'Package'

- A package is a folder containing `*.go` files.
- A module is a folder containing a `go.mod` file.
- A module is *usually* also a package, that is a folder containing a `go.mod`
  file and `*.go` files.
- A module may have subdirectories, which may be packages.
- Modules usually come in the form of a VCS repository (Git, SVN, Hg, and so on).
- Any subdirectories of a module that themselves are modules are distinct,
  separate modules and are excluded from the containing module.
  - Given a module `repo`, if `repo/sub` contains a `go.mod` file then
    `repo/sub` and any files contained therein are a separate module and not a
    part of `repo`.

## Naming

The name of a module or package, excluding the standard library, must be of the
form `(sub.)*domain.tld(/path)*`. This is similar to a URL, but is not a URL.
The package name does not have a scheme (such as `https://`) and cannot have a
port number. `example.com:8443/my/package` is not a valid name.

## Fetching Packages

Prior to Go 1.12, the process for fetching a package was as follows:

1. Query `https://{package name}?go-get=1`.
1. Scan the response for the `go-import` meta tag.
1. Fetch the repository indicated by the meta tag using the indicated VCS.

The meta tag should have the form `<meta name="go-import" content="{prefix} {vcs} {url}">`.
For example, `gitlab.com/my/project git https://gitlab.com/my/project.git` indicates
that packages beginning with `gitlab.com/my/project` should be fetched from
`https://gitlab.com/my/project.git` using Git.

## Fetching Modules

Go 1.12 introduced checksum databases and module proxies.

### Checksums

In addition to `go.mod`, a module has a `go.sum` file. This file records a
SHA-256 checksum of the code and the `go.mod` file of every version of every
dependency that is referenced by the module or one of the module's dependencies.
Go continually updates `go.sum` as new dependencies are referenced.

When Go fetches the dependencies of a module, if those dependencies already have
an entry in `go.sum`, Go verifies the checksum of these dependencies. If the
checksum does not match what is in `go.sum`, the build fails. This ensures
that a given version of a module cannot be changed by its developers or by a
malicious party without causing build failures.

Go 1.12+ can be configured to use a checksum database. If configured to do so,
when Go fetches a dependency and there is no corresponding entry in `go.sum`, Go
queries the configured checksum databases for the checksum of the
dependency instead of calculating it from the downloaded dependency. If the
dependency cannot be found in the checksum database, the build fails. If the
downloaded dependency's checksum does not match the result from the checksum
database, the build fails. The following environment variables control this:

- `GOSUMDB` identifies the name, and optionally the public key and server URL,
  of the checksum database to query.
  - A value of `off` entirely disables checksum database queries.
  - Go 1.13+ uses `sum.golang.org` if `GOSUMDB` is not defined.
- `GONOSUMDB` is a comma-separated list of module suffixes that checksum
  database queries should be disabled for. Wildcards are supported.
- `GOPRIVATE` is a comma-separated list of module names that has the same
  function as `GONOSUMDB` in addition to disabling other features.

### Proxies

Go 1.12+ can be configured to fetch modules from a Go proxy instead of directly
from the module's VCS. If configured to do so, when Go fetches a dependency, it
attempts to fetch the dependency from the configured proxies, in order. The
following environment variables control this:

- `GOPROXY` is a comma-separated list of module proxies to query.
  - A value of `direct` entirely disables module proxy queries.
  - If the last entry in the list is `direct`, Go falls back to the process
    described [above](#fetching-packages) if none of the proxies can provide the
    dependency.
  - Go 1.13+ uses `proxy.golang.org,direct` if `GOPROXY` is not defined.
- `GONOPROXY` is a comma-separated list of module suffixes that should be
  fetched directly and not from a proxy. Wildcards are supported.
- `GOPRIVATE` is a comma-separated list of module names that has the same
  function as `GONOPROXY` in addition to disabling other features.

### Fetching

From Go 1.12 onward, the process for fetching a module or package is as follows:

1. If `GOPROXY` is a list of proxies and the module is not excluded by
   `GONOPROXY` or `GOPRIVATE`, query them in order, and stop at the first valid
   response.
1. If `GOPROXY` is `direct`, or the module is excluded, or `GOPROXY` ends with
   `,direct` and no proxy provided the module, fall back.
   1. Query `https://{module or package name}?go-get=1`.
   1. Scan the response for the `go-import` meta tag.
   1. Fetch the repository indicated by the meta tag using the indicated VCS.
   1. If the `{vcs}` field is `mod`, the URL should be treated as a module proxy instead of a VCS.
1. If the module is being fetched directly and not as a dependency, stop.
1. If `go.sum` contains an entry corresponding to the module, validate the checksum and stop.
1. If `GOSUMDB` identifies a checksum database and the module is not excluded by
   `GONOSUMDB` or `GOPRIVATE`, retrieve the module's checksum, add it to
   `go.sum`, and validate the downloaded source against it.
1. If `GOSUMDB` is `off` or the module is excluded, calculate a checksum from
   the downloaded source and add it to `go.sum`.

The downloaded source must contain a `go.mod` file. The `go.mod` file must
contain a `module` directive that specifies the name of the module. If the
module name as specified by `go.mod` does not match the name that was used to
fetch the module, the module fails to compile.

If the module is being fetched directly and no version was specified, or if the
module is being added as a dependency and no version was specified, Go uses the
most recent version of the module. If the module is fetched from a proxy, Go
queries the proxy for a list of versions and chooses the latest. If the module is
fetched directly, Go queries the repository for a list of tags and chooses the
latest that is also a valid semantic version.

## Authenticating

In versions prior to Go 1.13, support for authenticating requests made by Go was
somewhat inconsistent. Go 1.13 improved support for `.netrc` authentication. If
a request is made over HTTPS and a matching `.netrc` entry can be found, Go
adds HTTP Basic authentication credentials to the request. Go does not
authenticate requests made over HTTP. Go rejects HTTP-only entries in
`GOPROXY` that have embedded credentials.

In a future version, Go may add support for arbitrary authentication headers.
Follow [`golang/go#26232`](https://github.com/golang/go/issues/26232) for details.

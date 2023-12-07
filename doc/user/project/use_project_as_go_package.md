---
stage: Data Stores
group: Tenant Scale
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Use a project as a Go package **(FREE ALL)**

Prerequisites:

- Contact your administrator to enable the [GitLab Go Proxy](../packages/go_proxy/index.md).
- To use a private project in a subgroup as a Go package, you must [authenticate Go requests](#authenticate-go-requests-to-private-projects). Go requests that are not authenticated cause
`go get` to fail. You don't need to authenticate Go requests for projects that are not in subgroups.

To use a project as a Go package, use the `go get` and `godoc.org` discovery requests. You can use the meta tags:

- [`go-import`](https://pkg.go.dev/cmd/go#hdr-Remote_import_paths)
- [`go-source`](https://github.com/golang/gddo/wiki/Source-Code-Links)

## Authenticate Go requests to private projects

Prerequisites:

- Your GitLab instance must be accessible with HTTPS.
- You must have a [personal access token](../profile/personal_access_tokens.md) with `read_api` scope.

To authenticate Go requests, create a [`.netrc`](https://everything.curl.dev/usingcurl/netrc) file with the following information:

```plaintext
machine gitlab.example.com
login <gitlab_user_name>
password <personal_access_token>
```

On Windows, Go reads `~/_netrc` instead of `~/.netrc`.

The `go` command does not transmit credentials over insecure connections. It authenticates
HTTPS requests made by Go, but does not authenticate requests made
through Git.

## Authenticate Git requests

If Go cannot fetch a module from a proxy, it uses Git. Git uses a `.netrc` file to authenticate requests, but you can
configure other authentication methods.

Configure Git to either:

- Embed credentials in the request URL:

  ```shell
  git config --global url."https://${user}:${personal_access_token}@gitlab.example.com".insteadOf "https://gitlab.example.com"
  ```

- Use SSH instead of HTTPS:

  ```shell
  git config --global url."git@gitlab.example.com:".insteadOf "https://gitlab.example.com/"
  ```

## Disable Go module fetching for private projects

To [fetch modules or packages](../../development/go_guide/dependencies.md#fetching), Go uses
the [environment variables](../../development/go_guide/dependencies.md#proxies):

- `GOPRIVATE`
- `GONOPROXY`
- `GONOSUMDB`

To disable fetching:

1. Disable `GOPRIVATE`:
   - To disable queries for one project, disable `GOPRIVATE=gitlab.example.com/my/private/project`.
   - To disable queries for all projects on GitLab.com, disable `GOPRIVATE=gitlab.example.com`.
1. Disable proxy queries in `GONOPROXY`.
1. Disable checksum queries in `GONOSUMDB`.

- If the module name or its prefix is in `GOPRIVATE` or `GONOPROXY`, Go does not query module
  proxies.
- If the module name or its prefix is in `GONOPRIVATE` or `GONOSUMDB`, Go does not query
  Checksum databases.

## Fetch Go modules from Geo secondary sites

Use [Geo](../../administration/geo/index.md) to access Git repositories that contain Go modules
on secondary Geo servers.

You can use SSH or HTTP to access the Geo secondary server.

### Use SSH to access the Geo secondary server

To access the Geo secondary server with SSH:

1. Reconfigure Git on the client to send traffic for the primary to the secondary:

   ```shell
   git config --global url."git@gitlab-secondary.example.com".insteadOf "https://gitlab.example.com"
   git config --global url."git@gitlab-secondary.example.com".insteadOf "http://gitlab.example.com"
   ```

   - For `gitlab.example.com`, use the primary site domain name.
   - For `gitlab-secondary.example.com`, use the secondary site domain name.

1. Ensure the client is set up for SSH access to GitLab repositories. You can test this on the primary,
   and GitLab replicates the public key to the secondary.

The `go get` request generates HTTP traffic to the primary Geo server. When the module
download starts, the `insteadOf` configuration sends the traffic to the secondary Geo server.

### Use HTTP to access the Geo secondary

You must use persistent access tokens that replicate to the secondary server. You cannot use
CI/CD job tokens to fetch Go modules with HTTP.

To access the Geo secondary server with HTTP:

1. Add a Git `insteadOf` redirect on the client:

   ```shell
   git config --global url."https://gitlab-secondary.example.com".insteadOf "https://gitlab.example.com"
   ```

   - For `gitlab.example.com`, use the primary site domain name.
   - For `gitlab-secondary.example.com`, use the secondary site domain name.

1. Generate a [personal access token](../profile/personal_access_tokens.md) and
   add the credentials in the client's `~/.netrc` file:

   ```shell
   machine gitlab.example.com login USERNAME password TOKEN
   machine gitlab-secondary.example.com login USERNAME password TOKEN
   ```

The `go get` request generates HTTP traffic to the primary Geo server. When the module
download starts, the `insteadOf` configuration sends the traffic to the secondary Geo server.

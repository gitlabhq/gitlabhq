# gitlab-bitbucket

`gitlab-bitbucket` is a REST API client for [Bitbucket Cloud](https://developer.atlassian.com/cloud/bitbucket/rest/),
extracted from the GitLab monolith and used by the GitLab Bitbucket Cloud importer
(`Gitlab::BitbucketImport`). It provides the `Bitbucket::` namespace.

The gem is Rails-free: the HTTP client, OAuth credentials and logger are injected by the
caller, so it carries no GitLab/Rails runtime dependencies.

## Usage

```ruby
require 'bitbucket'

client = Bitbucket::Client.new(
  { token: oauth_token, refresh_token: refresh_token, expires_at: expires_at },
  http_client: Gitlab::HTTP
)

client.multi_workspace_repos              # Bitbucket::MultiWorkspaceCollection of Representation::Repo
client.repo('workspace/repo-slug')        # Representation::Repo
client.pull_requests('workspace', 'slug') # Bitbucket::Collection of Representation::PullRequest
```

### Connection options and authentication

The first argument is a hash of connection options; its keys select the authentication mode:

- **OAuth** — `:token`, `:refresh_token`, `:expires_at`, `:expires_in`. Uses
  `Bitbucket::OauthConnection` (the `oauth2` gem). Pass `refresh_strategy:` to refresh expired
  tokens, and `:app_id` / `:app_secret` / `:oauth_options` for the OAuth application credentials.
- **API token** — `:email`, `:api_token`. Uses `Bitbucket::ApiConnection` (HTTP basic auth
  through the injected `http_client`).

Other recognised options: `:logger` (defaults to a null logger), `:base_uri`, `:api_version`.

### Required `http_client`

`http_client:` is a mandatory keyword argument. It must respond to `.get(url, options)` and is
where the caller applies transport policy — the response parser, SSRF protections and a
response-size limit. The GitLab monolith injects `Import::Clients::HTTP` (a thin wrapper over
`Gitlab::HTTP`). The OAuth path performs its requests through the `oauth2` gem and does not use
`http_client`, but it is still required so the client API is uniform.

### Public API

`Bitbucket::Client` exposes the read operations the importer relies on:

| Method | Returns |
| ------ | ------- |
| `multi_workspace_repos(filter:, limit:, workspace_paging_info:)` | repositories across all of the user's workspaces |
| `repo(name)` | a single repository |
| `pull_requests(repo, options)`, `pull_request_comments(repo, pr)`, `pull_request_diff(repo, pr)` | pull request data |
| `issues(repo, options)`, `issue_comments(repo, issue_id)`, `issues_available?(repo)` | issue data |
| `last_pull_request(repo)`, `last_issue(repo)` | the most recent PR/issue |
| `user`, `users(workspace_key, page_number:, limit:)` | the authenticated account and workspace members |
| `each_page(method, representation_type, *args)` | streams pages without loading them all into memory |

Collections (`pull_requests`, `issues`, …) are lazy `Bitbucket::Collection`s that paginate on
demand. Records are wrapped in `Bitbucket::Representation::*` objects (e.g. `Repo#private?`,
`#full_name`, `#clone_url`, `#default_branch`). Mapping a repository's `private?` flag to a
GitLab visibility level is the caller's responsibility.

## Development

```shell
cd gems/gitlab-bitbucket
bundle install
bundle exec rspec
bundle exec rubocop
```

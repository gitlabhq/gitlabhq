# gitlab-bitbucket-server

`gitlab-bitbucket-server` is a REST API client for Bitbucket Server / Data Center,
extracted from the GitLab monolith and used by the GitLab Bitbucket Server importer.

## Usage

```ruby
require 'bitbucket_server'

client = BitbucketServer::Client.new(
  {
    base_uri: 'https://bitbucket.example.com',
    user: 'username',
    password: 'token'
  },
  http_client: Gitlab::HTTP
)

client.repos(page_offset: 0, limit: 25)
client.pull_requests('PROJECT_KEY', 'repo-slug')
```

A `http_client:` is required: it must respond to `.get/.post/.delete(url, options)` and
return an HTTParty-like response (`#code`, `#parsed_response`). The GitLab monolith injects
`Import::Clients::HTTP`, which wraps `Gitlab::HTTP` with SSRF protections and a response-size
limit.

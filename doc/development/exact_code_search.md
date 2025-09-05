---
stage: AI-powered
group: Global Search
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Exact code search development guidelines
---

This page includes information about developing and working with exact code search, which is powered by Zoekt.

For how to enable exact code search and perform the initial indexing, see the
[integration documentation](../integration/zoekt/_index.md#enable-exact-code-search).

## Set up your development environment

To set up your development environment:

1. [Enable and configure Zoekt in the GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/zoekt.md).
1. Ensure two `gitlab-zoekt-indexer` and two `gitlab-zoekt-webserver` processes are running in the GDK:

   ```shell
   gdk status
   ```

1. To tail the logs for Zoekt, run this command:

   ```shell
   tail -f log/zoekt.log
   ```

## Rake tasks

- `gitlab:zoekt:info`: outputs information about exact code search, Zoekt nodes, indexing status,
  and feature flag status. Use this task to debug issues with nodes or indexing.
- `bin/rake "gitlab:zoekt:info[10]"`: runs the task in watch mode. Use this task during initial indexing to monitor
  progress.

## Debugging and troubleshooting

### Debug Zoekt queries

The `ZOEKT_CLIENT_DEBUG` environment variable enables
the [debug option for the Zoekt client](https://gitlab.com/gitlab-org/gitlab/-/blob/b9ec9fd2d035feb667fd14055b03972c828dcf3a/ee/lib/gitlab/search/zoekt/client.rb#L207)
in development or test environments.
The requests are logged in the `log/zoekt.log` file.
To debug HTTP queries generated from code or tests for the Zoekt webserver
before running specs or starting the Rails console:

```console
ZOEKT_CLIENT_DEBUG=1 bundle exec rspec ee/spec/services/ee/search/group_service_blob_and_commit_visibility_spec.rb

export ZOEKT_CLIENT_DEBUG=1
rails console
```

### Send requests directly to the Zoekt webserver

In development, two indexer (ports `6080` and `6081`) and two webserver (ports `6090` and `6091`) processes are started.
You can send search requests directly to any webserver (including the test webserver) by using either port:

1. Open the Rails console and generate a JWT that does not expire
   (this should never be done in a production or test environment):

```shell
::Search::Zoekt::JwtAuth::ZOEKT_JWT_SKIP_EXPIRY=true; ::Search::Zoekt::JwtAuth.authorization_header
=> "Bearer YOUR_JWT"
```

1. Use the JWT to send the request to one of the Zoekt webservers.
   The JSON request contains the following fields:

- `version` - The webserver uses this value to make decisions about how to process the request
- `timeout` - How long before the search request times out
- `num_context_lines` - Maps to [`NumContextLines` in Zoekt API](https://github.com/sourcegraph/zoekt/blob/87bb21ae49ead6e0cd19ee57425fd3bc72b11743/api.go#L994)
- `max_file_match_window` - Early termination limit for file matches during result aggregation (post-processing only). When combining results from multiple search nodes, cancels search early when total file count reaches this threshold.
- `max_file_match_results` - Post-processing limit on the final number of file results returned. After all searches complete and results are combined, truncates the file results to this maximum number.
- `max_line_match_window` - Early termination limit for line matches during search collection. When the total number of line matches across all search nodes reaches this threshold, the search is cancelled immediately. Maps to [`TotalMaxMatchCount` in Zoekt API](https://github.com/sourcegraph/zoekt/blob/87bb21ae49ead6e0cd19ee57425fd3bc72b11743/api.go#L966). `max_line_match_window` should be higher than `max_line_match_results` to ensure we get consistent results.
- `max_line_match_results` - Post-processing limit on the total number of line matches returned across all files. After search completion, limits the total number of line matches returned, respecting max_line_match_results_per_file per individual file.
- `max_line_match_results_per_file` - Max line match results per file. Maps to `chunkCount` in [`blobSearch` GraphQL API](../api/graphql/reference/_index.md#queryblobsearch).
- `query` - Search query containing the search term, authorization, and filters
- `endpoint` - Zoekt webserver that responds to the request

```shell
curl --request POST \
  --url "http://127.0.0.1:6090/webserver/api/v2/search" \
  --header 'Content-Type: application/json' \
  --header 'Gitlab-Zoekt-Api-Request: Bearer YOUR_JWT' \
  --data '{
    "version": 2,
    "timeout": "120s",
    "num_context_lines": 1,
    "max_file_match_window": 1000,
    "max_file_match_results": 5000,
    "max_line_match_window": 500,
    "max_line_match_results": 5000,
    "max_line_match_results_per_file": 3,
    "forward_to": [
      {
        "query": {
          "and": {
            "children": [
              {
                "query_string": {
                  "query": "\\.gitmodules"
                }
              },
              {
                "or": {
                  "children": [
                    {
                      "or": {
                        "children": [
                          {
                            "meta": {
                              "key": "repository_access_level",
                              "value": "10"
                            }
                          },
                          {
                            "meta": {
                              "key": "repository_access_level",
                              "value": "20"
                            }
                          }
                        ]
                      },
                      "_context": {
                        "name": "admin_branch"
                      }
                    }
                  ]
                }
              },
              {
                "meta": {
                  "key": "archived",
                  "value": "f"
                }
              },
              {
                "meta": {
                  "key": "traversal_ids",
                  "value": "^259-"
                },
                "_context": {
                  "name": "traversal_ids_for_group"
                }
              }
            ]
          }
        },
        "endpoint": "http://127.0.0.1:6070"
      }
    ]
  }'
```

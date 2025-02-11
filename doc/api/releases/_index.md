---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Releases API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use this API to manipulate [release entries](../../user/project/releases/_index.md).

To manipulate links as a release asset, see [Release Links API](links.md).

## Authentication

For authentication, the Releases API accepts either:

- A [personal access token](../../user/profile/personal_access_tokens.md) using the
  `PRIVATE-TOKEN` header.
- The [GitLab CI/CD job token](../../ci/jobs/ci_job_token.md) `$CI_JOB_TOKEN` using
  the `JOB-TOKEN` header.

## List Releases

Returns a paginated list of releases, sorted by `released_at`.

```plaintext
GET /projects/:id/releases
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](../rest/_index.md#namespaced-paths). |
| `order_by`    | string         | no       | The field to use as order. Either `released_at` (default) or `created_at`. |
| `sort`        | string         | no       | The direction of the order. Either `desc` (default) for descending order or `asc` for ascending order. |
| `include_html_description` | boolean        | no       | If `true`, a response includes HTML rendered Markdown of the release description.   |

If successful, returns [`200 OK`](../rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                             | Type   | Description                                      |
|:--------------------------------------|:-------|:-------------------------------------------------|
| `[]._links`                           | object | Links of the release.                            |
| `[]._links.closed_issues_url`         | string | HTTP URL of the release's closed issues.         |
| `[]._links.closed_merge_requests_url` | string | HTTP URL of the release's closed merge requests. |
| `[]._links.edit_url`                  | string | HTTP URL of the release's edit page.             |
| `[]._links.merged_merge_requests_url` | string | HTTP URL of the release's merged merge requests. |
| `[]._links.opened_issues_url`         | string | HTTP URL of the release's open issues.           |
| `[]._links.opened_merge_requests_url` | string | HTTP URL of the release's open merge requests.   |
| `[]._links.self`                      | string | HTTP URL of the release.                         |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases"
```

Example response:

```json
[
   {
      "tag_name":"v0.2",
      "description":"## CHANGELOG\r\n\r\n- Escape label and milestone titles to prevent XSS in GLFM autocomplete. !2740\r\n- Prevent private snippets from being embeddable.\r\n- Add subresources removal to member destroy service.",
      "name":"Awesome app v0.2 beta",
      "created_at":"2019-01-03T01:56:19.539Z",
      "released_at":"2019-01-03T01:56:19.539Z",
      "author":{
         "id":1,
         "name":"Administrator",
         "username":"root",
         "state":"active",
         "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
         "web_url":"https://gitlab.example.com/root"
      },
      "commit":{
         "id":"079e90101242458910cccd35eab0e211dfc359c0",
         "short_id":"079e9010",
         "title":"Update README.md",
         "created_at":"2019-01-03T01:55:38.000Z",
         "parent_ids":[
            "f8d3d94cbd347e924aa7b715845e439d00e80ca4"
         ],
         "message":"Update README.md",
         "author_name":"Administrator",
         "author_email":"admin@example.com",
         "authored_date":"2019-01-03T01:55:38.000Z",
         "committer_name":"Administrator",
         "committer_email":"admin@example.com",
         "committed_date":"2019-01-03T01:55:38.000Z"
      },
      "milestones": [
         {
            "id":51,
            "iid":1,
            "project_id":24,
            "title":"v1.0-rc",
            "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
            "state":"closed",
            "created_at":"2019-07-12T19:45:44.256Z",
            "updated_at":"2019-07-12T19:45:44.256Z",
            "due_date":"2019-08-16",
            "start_date":"2019-07-30",
            "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/1",
            "issue_stats": {
               "total": 98,
               "closed": 76
            }
         },
         {
            "id":52,
            "iid":2,
            "project_id":24,
            "title":"v1.0",
            "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
            "state":"closed",
            "created_at":"2019-07-16T14:00:12.256Z",
            "updated_at":"2019-07-16T14:00:12.256Z",
            "due_date":"2019-08-16",
            "start_date":"2019-07-30",
            "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/2",
            "issue_stats": {
               "total": 24,
               "closed": 21
            }
         }
      ],
      "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
      "tag_path":"/root/awesome-app/-/tags/v0.11.1",
      "assets":{
         "count":6,
         "sources":[
            {
               "format":"zip",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.zip"
            },
            {
               "format":"tar.gz",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.tar.gz"
            },
            {
               "format":"tar.bz2",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.tar.bz2"
            },
            {
               "format":"tar",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.2/awesome-app-v0.2.tar"
            }
         ],
         "links":[
            {
               "id":2,
               "name":"awesome-v0.2.msi",
               "url":"http://192.168.10.15:3000/msi",
               "link_type":"other"
            },
            {
               "id":1,
               "name":"awesome-v0.2.dmg",
               "url":"http://192.168.10.15:3000",
               "link_type":"other"
            }
         ],
         "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.2/evidence.json"
      },
      "evidences":[
        {
          "sha": "760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
          "filepath": "https://gitlab.example.com/root/awesome-app/-/releases/v0.2/evidence.json",
          "collected_at": "2019-01-03T01:56:19.539Z"
        }
     ]
   },
   {
      "tag_name":"v0.1",
      "description":"## CHANGELOG\r\n\r\n-Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
      "name":"Awesome app v0.1 alpha",
      "created_at":"2019-01-03T01:55:18.203Z",
      "released_at":"2019-01-03T01:55:18.203Z",
      "author":{
         "id":1,
         "name":"Administrator",
         "username":"root",
         "state":"active",
         "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
         "web_url":"https://gitlab.example.com/root"
      },
      "commit":{
         "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
         "short_id":"f8d3d94c",
         "title":"Initial commit",
         "created_at":"2019-01-03T01:53:28.000Z",
         "parent_ids":[

         ],
         "message":"Initial commit",
         "author_name":"Administrator",
         "author_email":"admin@example.com",
         "authored_date":"2019-01-03T01:53:28.000Z",
         "committer_name":"Administrator",
         "committer_email":"admin@example.com",
         "committed_date":"2019-01-03T01:53:28.000Z"
      },
      "assets":{
         "count":4,
         "sources":[
            {
               "format":"zip",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
            },
            {
               "format":"tar.gz",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
            },
            {
               "format":"tar.bz2",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
            },
            {
               "format":"tar",
               "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
            }
         ],
         "links":[

         ],
         "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json"
      },
      "evidences":[
        {
          "sha": "c3ffedec13af470e760d6cdfb08790f71cf52c6cde4d",
          "filepath": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json",
          "collected_at": "2019-01-03T01:55:18.203Z"
        }
      ],
      "_links": {
         "closed_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=closed",
         "closed_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=closed",
         "edit_url": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/edit",
         "merged_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=merged",
         "opened_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=opened",
         "opened_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=opened",
         "self": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1"
      }
   }
]
```

## Get a Release by a tag name

Gets a release for the given tag.

```plaintext
GET /projects/:id/releases/:tag_name
```

| Attribute                  | Type           | Required | Description                                                                         |
|----------------------------| -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`                       | integer/string | yes      | The ID or [URL-encoded path of the project](../rest/_index.md#namespaced-paths).  |
| `tag_name`                 | string         | yes      | The Git tag the release is associated with.                                         |
| `include_html_description` | boolean        | no       | If `true`, a response includes HTML rendered Markdown of the release description.   |

If successful, returns [`200 OK`](../rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                             | Type   | Description                                      |
|:--------------------------------------|:-------|:-------------------------------------------------|
| `[]._links`                           | object | Links of the release.                            |
| `[]._links.closed_issues_url`         | string | HTTP URL of the release's closed issues.         |
| `[]._links.closed_merge_requests_url` | string | HTTP URL of the release's closed merge requests. |
| `[]._links.edit_url`                  | string | HTTP URL of the release's edit page.             |
| `[]._links.merged_merge_requests_url` | string | HTTP URL of the release's merged merge requests. |
| `[]._links.opened_issues_url`         | string | HTTP URL of the release's open issues.           |
| `[]._links.opened_merge_requests_url` | string | HTTP URL of the release's open merge requests.   |
| `[]._links.self`                      | string | HTTP URL of the release.                         |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1"
```

Example response:

```json
{
   "tag_name":"v0.1",
   "description":"## CHANGELOG\r\n\r\n- Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
   "name":"Awesome app v0.1 alpha",
   "created_at":"2019-01-03T01:55:18.203Z",
   "released_at":"2019-01-03T01:55:18.203Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
      "short_id":"f8d3d94c",
      "title":"Initial commit",
      "created_at":"2019-01-03T01:53:28.000Z",
      "parent_ids":[

      ],
      "message":"Initial commit",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:53:28.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:53:28.000Z"
   },
   "milestones": [
       {
         "id":51,
         "iid":1,
         "project_id":24,
         "title":"v1.0-rc",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-12T19:45:44.256Z",
         "updated_at":"2019-07-12T19:45:44.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/1",
         "issue_stats": {
            "total": 98,
            "closed": 76
         }
       },
       {
         "id":52,
         "iid":2,
         "project_id":24,
         "title":"v1.0",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-16T14:00:12.256Z",
         "updated_at":"2019-07-16T14:00:12.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/2",
         "issue_stats": {
            "total": 24,
            "closed": 21
         }
       }
   ],
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "assets":{
      "count":5,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
         }
      ],
      "links":[
         {
            "id":3,
            "name":"hoge",
            "url":"https://gitlab.example.com/root/awesome-app/-/tags/v0.11.1/binaries/linux-amd64",
            "link_type":"other"
         }
      ]
   },
   "evidences":[
     {
       "sha": "760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
       "filepath": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json",
       "collected_at": "2019-07-16T14:00:12.256Z"
     },
   "_links": {
      "closed_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=closed",
      "closed_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=closed",
      "edit_url": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/edit",
      "merged_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=merged",
      "opened_issues_url": "https://gitlab.example.com/root/awesome-app/-/issues?release_tag=v0.1&scope=all&state=opened",
      "opened_merge_requests_url": "https://gitlab.example.com/root/awesome-app/-/merge_requests?release_tag=v0.1&scope=all&state=opened",
      "self": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1"
    }
  ]
}
```

## Download a release asset

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/358188) in GitLab 15.4.

Download a release asset file by making a request with the following format:

```plaintext
GET /projects/:id/releases/:tag_name/downloads/:direct_asset_path
```

| Attribute                  | Type           | Required | Description                                                                         |
|----------------------------| -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`                       | integer/string | yes      | The ID or [URL-encoded path of the project](../rest/_index.md#namespaced-paths).  |
| `tag_name`                 | string         | yes      | The Git tag the release is associated with.                                         |
| `direct_asset_path`        | string         | yes      | Path to the release asset file as specified when [creating](links.md#create-a-release-link) or [updating](links.md#update-a-release-link) its link. |

Example request:

```shell
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/downloads/bin/asset.exe"
```

### Get the latest release

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/358188) in GitLab 15.4.

Latest release information is accessible through a permanent API URL.

The format of the URL is:

```plaintext
GET /projects/:id/releases/permalink/latest
```

To call any other GET API that requires a release tag, append a suffix to the `permalink/latest` API path.

For example, to get latest [release evidence](#collect-release-evidence) you can use:

```plaintext
GET /projects/:id/releases/permalink/latest/evidence
```

Another example is [downloading an asset](#download-a-release-asset) of the latest release, for which you can use:

```plaintext
GET /projects/:id/releases/permalink/latest/downloads/bin/asset.exe
```

#### Sorting preferences

By default, GitLab fetches the release using `released_at` time. The use of the query parameter
`?order_by=released_at` is optional, and support for `?order_by=semver` is tracked [in issue 352945](https://gitlab.com/gitlab-org/gitlab/-/issues/352945).

## Create a release

Creates a release. Developer level access to the project is required to create a release.

```plaintext
POST /projects/:id/releases
```

| Attribute          | Type            | Required                    | Description                                                                                                                      |
| -------------------| --------------- | --------                    | -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | integer/string  | yes                         | The ID or [URL-encoded path of the project](../rest/_index.md#namespaced-paths).                                              |
| `name`             | string          | no                          | The release name.                                                                                                                |
| `tag_name`         | string          | yes                         | The tag where the release is created from.                                                                                  |
| `tag_message`      | string          | no                          | Message to use if creating a new annotated tag.                                                                                  |
| `description`      | string          | no                          | The description of the release. You can use [Markdown](../../user/markdown.md).                                                  |
| `ref`              | string          | yes, if `tag_name` doesn't exist | If a tag specified in `tag_name` doesn't exist, the release is created from `ref` and tagged with `tag_name`. It can be a commit SHA, another tag name, or a branch name. |
| `milestones`       | array of string | no                          | The title of each milestone the release is associated with. [GitLab Premium](https://about.gitlab.com/pricing/) customers can specify group milestones.                                                                      |
| `assets:links`     | array of hash   | no                          | An array of assets links.                                                                                                        |
| `assets:links:name`| string          | required by: `assets:links` | The name of the link. Link names must be unique within the release.                                                              |
| `assets:links:url` | string          | required by: `assets:links` | The URL of the link. Link URLs must be unique within the release.                                                                |
| `assets:links:direct_asset_path` | string     | no | Optional path for a [direct asset link](../../user/project/releases/release_fields.md#permanent-links-to-release-assets). |
| `assets:links:link_type` | string     | no | The type of the link: `other`, `runbook`, `image`, `package`. Defaults to `other`. |
| `released_at`      | datetime        | no                          | Date and time for the release. Defaults to the current time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). Only provide this field if creating an [upcoming](../../user/project/releases/_index.md#upcoming-releases) or [historical](../../user/project/releases/_index.md#historical-releases) release.  |

Example request:

```shell
curl --header 'Content-Type: application/json' --header "PRIVATE-TOKEN: <your_access_token>" \
     --data '{ "name": "New release", "tag_name": "v0.3", "description": "Super nice release", "milestones": ["v1.0", "v1.0-rc"], "assets": { "links": [{ "name": "hoge", "url": "https://google.com", "direct_asset_path": "/binaries/linux-amd64", "link_type":"other" }] } }' \
     --request POST "https://gitlab.example.com/api/v4/projects/24/releases"
```

Example response:

```json
{
   "tag_name":"v0.3",
   "description":"Super nice release",
   "name":"New release",
   "created_at":"2019-01-03T02:22:45.118Z",
   "released_at":"2019-01-03T02:22:45.118Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"079e90101242458910cccd35eab0e211dfc359c0",
      "short_id":"079e9010",
      "title":"Update README.md",
      "created_at":"2019-01-03T01:55:38.000Z",
      "parent_ids":[
         "f8d3d94cbd347e924aa7b715845e439d00e80ca4"
      ],
      "message":"Update README.md",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:55:38.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:55:38.000Z"
   },
   "milestones": [
       {
         "id":51,
         "iid":1,
         "project_id":24,
         "title":"v1.0-rc",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-12T19:45:44.256Z",
         "updated_at":"2019-07-12T19:45:44.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/1",
         "issue_stats": {
            "total": 99,
            "closed": 76
         }
       },
       {
         "id":52,
         "iid":2,
         "project_id":24,
         "title":"v1.0",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"closed",
         "created_at":"2019-07-16T14:00:12.256Z",
         "updated_at":"2019-07-16T14:00:12.256Z",
         "due_date":"2019-08-16",
         "start_date":"2019-07-30",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/2",
         "issue_stats": {
            "total": 24,
            "closed": 21
         }
       }
   ],
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "evidence_sha":"760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
   "assets":{
      "count":5,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.3/awesome-app-v0.3.tar"
         }
      ],
      "links":[
         {
            "id":3,
            "name":"hoge",
            "url":"https://gitlab.example.com/root/awesome-app/-/tags/v0.11.1/binaries/linux-amd64",
            "link_type":"other"
         }
      ],
      "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.3/evidence.json"
   }
}
```

### Group milestones

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Group milestones associated with the project may be specified in the `milestones`
array for [Create a release](#create-a-release) and [Update a release](#update-a-release)
API calls. Only milestones associated with the project's group may be specified, and
adding milestones for ancestor groups raises an error.

## Collect release evidence

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Creates an evidence for an existing release.

```plaintext
POST /projects/:id/releases/:tag_name/evidence
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](../rest/_index.md#namespaced-paths). |
| `tag_name`    | string         | yes      | The Git tag the release is associated with.                                         |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/evidence"
```

Example response:

```json
200
```

## Update a release

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72448) to allow for `JOB-TOKEN` in GitLab 14.5.

Updates a release. Developer level access to the project is required to update a release.

```plaintext
PUT /projects/:id/releases/:tag_name
```

| Attribute     | Type            | Required | Description                                                                                                 |
| ------------- | --------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `id`          | integer/string  | yes      | The ID or [URL-encoded path of the project](../rest/_index.md#namespaced-paths).                         |
| `tag_name`    | string          | yes      | The Git tag the release is associated with.                                                                 |
| `name`        | string          | no       | The release name.                                                                                           |
| `description` | string          | no       | The description of the release. You can use [Markdown](../../user/markdown.md).                             |
| `milestones`  | array of string | no       | The title of each milestone to associate with the release. [GitLab Premium](https://about.gitlab.com/pricing/) customers can specify group milestones. To remove all milestones from the release, specify `[]`. |
| `released_at` | datetime        | no       | The date when the release is/was ready. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`).          |

Example request:

```shell
curl --header 'Content-Type: application/json' --request PUT --data '{"name": "new name", "milestones": ["v1.2"]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1"
```

Example response:

```json
{
   "tag_name":"v0.1",
   "description":"## CHANGELOG\r\n\r\n- Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
   "name":"new name",
   "created_at":"2019-01-03T01:55:18.203Z",
   "released_at":"2019-01-03T01:55:18.203Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
      "short_id":"f8d3d94c",
      "title":"Initial commit",
      "created_at":"2019-01-03T01:53:28.000Z",
      "parent_ids":[

      ],
      "message":"Initial commit",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:53:28.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:53:28.000Z"
   },
   "milestones": [
      {
         "id":53,
         "iid":3,
         "project_id":24,
         "title":"v1.2",
         "description":"Voluptate fugiat possimus quis quod aliquam expedita.",
         "state":"active",
         "created_at":"2019-09-01T13:00:00.256Z",
         "updated_at":"2019-09-01T13:00:00.256Z",
         "due_date":"2019-09-20",
         "start_date":"2019-09-05",
         "web_url":"https://gitlab.example.com/root/awesome-app/-/milestones/3",
         "issue_stats": {
            "opened": 11,
            "closed": 78
         }
      }
   ],
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "evidence_sha":"760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
   "assets":{
      "count":4,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
         }
      ],
      "links":[

      ],
      "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json"
   }
}
```

## Delete a Release

Deletes a release. Deleting a release doesn't delete the associated tag. Maintainer level access to the project is required to delete a release.

```plaintext
DELETE /projects/:id/releases/:tag_name
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](../rest/_index.md#namespaced-paths). |
| `tag_name`    | string         | yes      | The Git tag the release is associated with.                                         |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1"
```

Example response:

```json
{
   "tag_name":"v0.1",
   "description":"## CHANGELOG\r\n\r\n- Remove limit of 100 when searching repository code. !8671\r\n- Show error message when attempting to reopen an MR and there is an open MR for the same branch. !16447 (Akos Gyimesi)\r\n- Fix a bug where internal email pattern wasn't respected. !22516",
   "name":"new name",
   "created_at":"2019-01-03T01:55:18.203Z",
   "released_at":"2019-01-03T01:55:18.203Z",
   "author":{
      "id":1,
      "name":"Administrator",
      "username":"root",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/root"
   },
   "commit":{
      "id":"f8d3d94cbd347e924aa7b715845e439d00e80ca4",
      "short_id":"f8d3d94c",
      "title":"Initial commit",
      "created_at":"2019-01-03T01:53:28.000Z",
      "parent_ids":[

      ],
      "message":"Initial commit",
      "author_name":"Administrator",
      "author_email":"admin@example.com",
      "authored_date":"2019-01-03T01:53:28.000Z",
      "committer_name":"Administrator",
      "committer_email":"admin@example.com",
      "committed_date":"2019-01-03T01:53:28.000Z"
   },
   "commit_path":"/root/awesome-app/commit/588440f66559714280628a4f9799f0c4eb880a4a",
   "tag_path":"/root/awesome-app/-/tags/v0.11.1",
   "evidence_sha":"760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
   "assets":{
      "count":4,
      "sources":[
         {
            "format":"zip",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.zip"
         },
         {
            "format":"tar.gz",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.gz"
         },
         {
            "format":"tar.bz2",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar.bz2"
         },
         {
            "format":"tar",
            "url":"https://gitlab.example.com/root/awesome-app/-/archive/v0.1/awesome-app-v0.1.tar"
         }
      ],
      "links":[

      ],
      "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json"
   }
}
```

## Upcoming Releases

A release with a `released_at` attribute set to a future date is labeled
as an **Upcoming Release** [in the UI](../../user/project/releases/_index.md#upcoming-releases).

Additionally, if a [release is requested from the API](#list-releases), for each release with a `release_at` attribute set to a future date, an additional attribute `upcoming_release` (set to true) is returned as part of the response.

## Historical releases

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/199429) in GitLab 15.2.

A release with a `released_at` attribute set to a past date is labeled
as an **Historical release** [in the UI](../../user/project/releases/_index.md#historical-releases).

Additionally, if a [release is requested from the API](#list-releases), for each
release with a `release_at` attribute set to a past date, an additional
attribute `historical_release` (set to true) is returned as part of the response.

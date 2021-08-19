---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Releases API

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41766) in GitLab 11.7.
> - Using this API you can manipulate GitLab [Release](../../user/project/releases/index.md) entries.
> - For manipulating links as a release asset, see [Release Links API](links.md).
> - Release Evidences were [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/26019) in GitLab 12.5.
> - `description_html` became an opt-in field [with GitLab 13.12 for performance reasons](https://gitlab.com/gitlab-org/gitlab/-/issues/299447).
    Please pass the `include_html_description` query string parameter if you need it.
> - [The permission model for create, update and delete actions was fixed](https://gitlab.com/gitlab-org/gitlab/-/issues/327505) in GitLab 14.1.
    See [Release permissions](../../user/project/releases/index.md#release-permissions) for more information.

## Authentication

For authentication, the Releases API accepts either:

- A [Personal Access Token](../../user/profile/personal_access_tokens.md) using the
  `PRIVATE-TOKEN` header.
- The [GitLab CI/CD job token](../index.md#gitlab-cicd-job-token) `$CI_JOB_TOKEN` using
  the `JOB-TOKEN` header.

## List Releases

Paginated list of Releases, sorted by `released_at`.

```plaintext
GET /projects/:id/releases
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](../index.md#namespaced-path-encoding). |
| `order_by`    | string         | no       | The field to use as order. Either `released_at` (default) or `created_at`. |
| `sort`        | string         | no       | The direction of the order. Either `desc` (default) for descending order or `asc` for ascending order. |
| `include_html_description` | boolean        | no       | If `true`, a response includes HTML rendered Markdown of the release description.   |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases"
```

Example response:

```json
[
   {
      "tag_name":"v0.2",
      "description":"## CHANGELOG\r\n\r\n- Escape label and milestone titles to prevent XSS in GFM autocomplete. !2740\r\n- Prevent private snippets from being embeddable.\r\n- Add subresources removal to member destroy service.",
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
            "due_date":"2019-08-16T11:00:00.256Z",
            "start_date":"2019-07-30T12:00:00.256Z",
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
            "due_date":"2019-08-16T11:00:00.256Z",
            "start_date":"2019-07-30T12:00:00.256Z",
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
               "external":true,
               "link_type":"other"
            },
            {
               "id":1,
               "name":"awesome-v0.2.dmg",
               "url":"http://192.168.10.15:3000",
               "external":true,
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
     ]
   }
]
```

## Get a Release by a tag name

Get a Release for the given tag.

```plaintext
GET /projects/:id/releases/:tag_name
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](../index.md#namespaced-path-encoding). |
| `tag_name`    | string         | yes      | The Git tag the release is associated with.                                         |
| `include_html_description` | boolean        | no       | If `true`, a response includes HTML rendered Markdown of the release description.   |

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
         "due_date":"2019-08-16T11:00:00.256Z",
         "start_date":"2019-07-30T12:00:00.256Z",
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
         "due_date":"2019-08-16T11:00:00.256Z",
         "start_date":"2019-07-30T12:00:00.256Z",
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
            "external":true,
            "link_type":"other"
         }
      ]
   },
   "evidences":[
     {
       "sha": "760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d",
       "filepath": "https://gitlab.example.com/root/awesome-app/-/releases/v0.1/evidence.json",
       "collected_at": "2019-07-16T14:00:12.256Z"
     }
  ]
}
```

## Create a release

Create a release. Developer level access to the project is required to create a release.

```plaintext
POST /projects/:id/releases
```

| Attribute          | Type            | Required                    | Description                                                                                                                      |
| -------------------| --------------- | --------                    | -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | integer/string  | yes                         | The ID or [URL-encoded path of the project](../index.md#namespaced-path-encoding).                                              |
| `name`             | string          | no                          | The release name.                                                                                                                |
| `tag_name`         | string          | yes                         | The tag where the release is created from.                                                                                  |
| `description`      | string          | no                          | The description of the release. You can use [Markdown](../../user/markdown.md).                                                  |
| `ref`              | string          | yes, if `tag_name` doesn't exist | If a tag specified in `tag_name` doesn't exist, the release is created from `ref` and tagged with `tag_name`. It can be a commit SHA, another tag name, or a branch name. |
| `milestones`       | array of string | no                          | The title of each milestone the release is associated with. [GitLab Premium](https://about.gitlab.com/pricing/) customers can specify group milestones.                                                                      |
| `assets:links`     | array of hash   | no                          | An array of assets links.                                                                                                        |
| `assets:links:name`| string          | required by: `assets:links` | The name of the link. Link names must be unique within the release.                                                              |
| `assets:links:url` | string          | required by: `assets:links` | The URL of the link. Link URLs must be unique within the release.                                                                |
| `assets:links:filepath` | string     | no | Optional path for a [Direct Asset link](../../user/project/releases/index.md#permanent-links-to-release-assets).
| `assets:links:link_type` | string     | no | The type of the link: `other`, `runbook`, `image`, `package`. Defaults to `other`.
| `released_at`      | datetime        | no                          | The date when the release is/was ready. Defaults to the current time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |

Example request:

```shell
curl --header 'Content-Type: application/json' --header "PRIVATE-TOKEN: <your_access_token>" \
     --data '{ "name": "New release", "tag_name": "v0.3", "description": "Super nice release", "milestones": ["v1.0", "v1.0-rc"], "assets": { "links": [{ "name": "hoge", "url": "https://google.com", "filepath": "/binaries/linux-amd64", "link_type":"other" }] } }' \
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
         "due_date":"2019-08-16T11:00:00.256Z",
         "start_date":"2019-07-30T12:00:00.256Z",
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
         "due_date":"2019-08-16T11:00:00.256Z",
         "start_date":"2019-07-30T12:00:00.256Z",
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
            "external":true,
            "link_type":"other"
         }
      ],
      "evidence_file_path":"https://gitlab.example.com/root/awesome-app/-/releases/v0.3/evidence.json"
   }
}
```

### Group milestones **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/235391) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.5.

Group milestones associated with the project may be specified in the `milestones`
array for [Create a release](#create-a-release) and [Update a release](#update-a-release)
API calls. Only milestones associated with the project's group may be specified, and
adding milestones for ancestor groups raises an error.

## Collect release evidence **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/199065) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.10.

Create Evidence for an existing Release.

```plaintext
POST /projects/:id/releases/:tag_name/evidence
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](../index.md#namespaced-path-encoding). |
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

Update a release. Developer level access to the project is required to update a release.

```plaintext
PUT /projects/:id/releases/:tag_name
```

| Attribute     | Type            | Required | Description                                                                                                 |
| ------------- | --------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `id`          | integer/string  | yes      | The ID or [URL-encoded path of the project](../index.md#namespaced-path-encoding).                         |
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
         "due_date":"2019-09-20T13:00:00.256Z",
         "start_date":"2019-09-05T12:00:00.256Z",
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

Delete a release. Deleting a release doesn't delete the associated tag. Maintainer level access to the project is required to delete a release.

```plaintext
DELETE /projects/:id/releases/:tag_name
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](../index.md#namespaced-path-encoding). |
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

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/38105) in GitLab 12.1.

A release with a `released_at` attribute set to a future date is labeled
as an **Upcoming Release** [in the UI](../../user/project/releases/index.md#upcoming-releases).

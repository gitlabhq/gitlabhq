---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Repository submodules API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## Update existing submodule reference in repository

In some workflows, especially automated ones, you can update a
submodule's reference to keep up to date other projects that use it.
This endpoint allows you to update a [Git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) reference in a
specific branch.

```plaintext
PUT /projects/:id/repository/submodules/:submodule
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `submodule` | string | yes | URL-encoded full path to the submodule. For example, `lib%2Fclass%2Erb` |
| `branch` | string | yes | Name of the branch to commit into |
| `commit_sha` | string | yes | Full commit SHA to update the submodule to |
| `commit_message` | string | no | Commit message. If no message is provided, a default is set |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/repository/submodules/lib%2Fmodules%2Fexample" \
--data "branch=main&commit_sha=3ddec28ea23acc5caa5d8331a6ecb2a65fc03e88&commit_message=Update submodule reference"
```

Example response:

```json
{
  "id": "ed899a2f4b50b4370feeea94676502b42383c746",
  "short_id": "ed899a2f4b5",
  "title": "Updated submodule example_submodule with oid 3ddec28ea23acc5caa5d8331a6ecb2a65fc03e88",
  "author_name": "Dmitriy Zaporozhets",
  "author_email": "dzaporozhets@sphereconsultinginc.com",
  "committer_name": "Dmitriy Zaporozhets",
  "committer_email": "dzaporozhets@sphereconsultinginc.com",
  "created_at": "2018-09-20T09:26:24.000-07:00",
  "message": "Updated submodule example_submodule with oid 3ddec28ea23acc5caa5d8331a6ecb2a65fc03e88",
  "parent_ids": [
    "ae1d9fb46aa2b07ee9836d49862ec4e2c46fbbba"
  ],
  "committed_date": "2018-09-20T09:26:24.000-07:00",
  "authored_date": "2018-09-20T09:26:24.000-07:00",
  "status": null
}
```

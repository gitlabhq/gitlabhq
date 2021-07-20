---
stage: Verify
group: Testing
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, api
---

# Visual Review discussions API **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18710) in GitLab 12.5.
> - [Moved](https://about.gitlab.com/blog/2021/01/26/new-gitlab-product-subscription-model/) to GitLab Premium in 13.9.

Visual Review discussions are notes on Merge Requests sent as
feedback from [Visual Reviews](../ci/review_apps/index.md#visual-reviews).

## Create new merge request thread

Creates a new thread to a single project merge request. This is similar to creating
a note but other comments (replies) can be added to it later.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/visual_review_discussions
```

Parameters:

| Attribute                 | Type           | Required | Description |
| ------------------------- | -------------- | -------- | ----------- |
| `id`                      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `merge_request_iid`       | integer        | yes      | The IID of a merge request |
| `body`                    | string         | yes      | The content of the thread |
| `position`                | hash           | no       | Position when creating a diff note |
| `position[base_sha]`      | string         | yes      | Base commit SHA in the source branch |
| `position[start_sha]`     | string         | yes      | SHA referencing commit in target branch |
| `position[head_sha]`      | string         | yes      | SHA referencing HEAD of this merge request |
| `position[position_type]` | string         | yes      | Type of the position reference. Either `text` or `image`. |
| `position[new_path]`      | string         | no       | File path after change |
| `position[new_line]`      | integer        | no       | Line number after change (Only stored for `text` diff notes) |
| `position[old_path]`      | string         | no       | File path before change |
| `position[old_line]`      | integer        | no       | Line number before change (Only stored for `text` diff notes) |
| `position[width]`         | integer        | no       | Width of the image (Only stored for `image` diff notes) |
| `position[height]`        | integer        | no       | Height of the image (Only stored for `image` diff notes) |
| `position[x]`             | integer        | no       | X coordinate (Only stored for `image` diff notes) |
| `position[y]`             | integer        | no       | Y coordinate (Only stored for `image` diff notes) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/visual_review_discussions?body=comment"
```

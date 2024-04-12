---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

<!--- start_remove The following content will be removed on remove_date: '2024-05-22' -->
# Visual Review discussions API (deprecated)

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/387751) in GitLab 15.8
and is planned for removal in 17.0. This change is a breaking change.

Visual Review discussions are notes on merge requests sent as
feedback from [Visual Reviews](../ci/review_apps/index.md#visual-reviews-deprecated).

## Create new merge request thread

Creates a new thread to a single project merge request. This is similar to creating
a note but other comments (replies) can be added to it later.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/visual_review_discussions
```

Parameters:

| Attribute                 | Type           | Required | Description |
|---------------------------|----------------|----------|-------------|
| `id`                      | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |
| `merge_request_iid`       | integer        | Yes      | The IID of a merge request |
| `body`                    | string         | Yes      | The content of the thread |
| `position`                | hash           | No       | Position when creating a diff note |
| `position[base_sha]`      | string         | Yes      | Base commit SHA in the source branch |
| `position[start_sha]`     | string         | Yes      | SHA referencing commit in target branch |
| `position[head_sha]`      | string         | Yes      | SHA referencing HEAD of this merge request |
| `position[position_type]` | string         | Yes      | Type of the position reference. Either `text` or `image`. |
| `position[new_path]`      | string         | No       | File path after change |
| `position[new_line]`      | integer        | No       | Line number after change (Only stored for `text` diff notes) |
| `position[old_path]`      | string         | No       | File path before change |
| `position[old_line]`      | integer        | No       | Line number before change (Only stored for `text` diff notes) |
| `position[width]`         | integer        | No       | Width of the image (Only stored for `image` diff notes) |
| `position[height]`        | integer        | No       | Height of the image (Only stored for `image` diff notes) |
| `position[x]`             | integer        | No       | X coordinate (Only stored for `image` diff notes) |
| `position[y]`             | integer        | No       | Y coordinate (Only stored for `image` diff notes) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/merge_requests/11/visual_review_discussions?body=comment"
```
<!--- end_remove -->

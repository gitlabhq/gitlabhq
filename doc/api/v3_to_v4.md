# API V3 to API V4

Since GitLab 9.0, API V4 is the preferred version to be used.

API V3 will be unsupported from GitLab 9.5, to be released on August
22, 2017. It will be removed in GitLab 9.5 or later. In the meantime, we advise
you to make any necessary changes to applications that use V3. The V3 API
documentation is still
[available](https://gitlab.com/gitlab-org/gitlab-ce/blob/8-16-stable/doc/api/README.md).

Below are the changes made between V3 and V4.

### 8.17

- Removed `GET /projects/:search` (use: `GET /projects?search=x`) [!8877](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8877)
- `iid` filter has been removed from `GET /projects/:id/issues` [!8967](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8967)
- `GET /projects/:id/merge_requests?iid[]=x&iid[]=y` array filter has been renamed to `iids` [!8793](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8793)
- Endpoints under `GET /projects/merge_request/:id` have been removed (use: `GET /projects/merge_requests/:id`) [!8793](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8793)
- Project snippets do not return deprecated field `expires_at` [!8723](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8723)
- Endpoints under `GET /projects/:id/keys` have been removed (use `GET /projects/:id/deploy_keys`) [!8716](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8716)

### 9.0

- Status 409 returned for `POST /projects/:id/members` when a member already exists [!9093](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9093)
- Moved `DELETE /projects/:id/star` to `POST /projects/:id/unstar` [!9328](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9328)
- Removed the following deprecated Templates endpoints (these are still accessible with `/templates` prefix) [!8853](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8853)
  - `/licences`
  - `/licences/:key`
  - `/gitignores`
  - `/gitlab_ci_ymls`
  - `/dockerfiles`
  - `/gitignores/:key`
  - `/gitlab_ci_ymls/:key`
  - `/dockerfiles/:key`
- Moved `POST /projects/fork/:id` to `POST /projects/:id/fork` [!8940](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8940)
- Moved `DELETE /todos` to `POST /todos/mark_as_done` and `DELETE /todos/:todo_id` to `POST /todos/:todo_id/mark_as_done` [!9410](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9410)
- Project filters are no longer available as `GET /projects/foo`, but as `GET /projects?foo=true` instead [!8962](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8962)
  - `GET /projects/visible` & `GET /projects/all` are consolidated into `GET /projects` and can be used with or without authorization
  - `GET /projects/owned` moved to `GET /projects?owned=true`
  - `GET /projects/starred` moved to `GET /projects?starred=true`
- `GET /projects` returns all projects visible to current user, even if the user is not a member [!9674](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9674)
  - To get projects the user is a member of, use `GET /projects?membership=true`
- Return pagination headers for all endpoints that return an array [!8606](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8606)
- Added `POST /environments/:environment_id/stop` to stop an environment [!8808](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8808)
- Removed `DELETE /projects/:id/deploy_keys/:key_id/disable`. Use `DELETE /projects/:id/deploy_keys/:key_id` instead [!9366](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9366)
- Moved `PUT /users/:id/(block|unblock)` to `POST /users/:id/(block|unblock)` [!9371](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9371)
- Make subscription API more RESTful. Use `POST /projects/:id/:subscribable_type/:subscribable_id/subscribe` to subscribe and `POST /projects/:id/:subscribable_type/:subscribable_id/unsubscribe` to unsubscribe from a resource. [!9325](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9325)
- Labels filter on `GET /projects/:id/issues` and `GET /issues` now matches only issues containing all labels (i.e.: Logical AND, not OR) [!8849](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8849)
- Renamed param `branch_name` to `branch` on the following endpoints [!8936](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8936)
  - `POST /projects/:id/repository/branches`
  - `POST /projects/:id/repository/commits`
  - `POST/PUT/DELETE :id/repository/files`
- Renamed the `merge_when_build_succeeds` parameter to `merge_when_pipeline_succeeds` on the following endpoints: [!9335](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/)
  - `PUT /projects/:id/merge_requests/:merge_request_id/merge`
  - `POST /projects/:id/merge_requests/:merge_request_id/cancel_merge_when_pipeline_succeeds`
  - `POST /projects`
  - `POST /projects/user/:user_id`
  - `PUT /projects/:id`
- Renamed `branch_name` to `branch` on `DELETE /projects/:id/repository/branches/:branch` response [!8936](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8936)
- Remove `public` param from create and edit actions of projects [!8736](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8736)
- Remove `subscribed` field from responses returning list of issues or merge
  requests. Fetch individual issues or merge requests to obtain the value
  of `subscribed`
  [!9661](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9661)
- Use `visibility` as string parameter everywhere [!9337](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9337)
- Notes do not return deprecated field `upvote` and `downvote` [!9384](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9384)
- Return HTTP status code `400` for all validation errors when creating or updating a member instead of sometimes `422` error. [!9523](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9523)
- Remove `GET /groups/owned`. Use `GET /groups?owned=true` instead [!9505](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9505)
- Return 202 with JSON body on async removals on V4 API (`DELETE /projects/:id/repository/merged_branches` and `DELETE /projects/:id`) [!9449](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9449)
- `GET /projects/:id/milestones?iid[]=x&iid[]=y` array filter has been renamed to `iids` [!9096](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9096)
- Return basic info about pipeline in `GET /projects/:id/pipelines` [!8875](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8875)
- Renamed all `build` references to `job` [!9463](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9463)
- Drop `GET /projects/:id/repository/commits/:sha/jobs` [!9463](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9463)
- Rename Build Triggers to be Pipeline Triggers API [!9713](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9713)
  - `POST /projects/:id/trigger/builds` to `POST /projects/:id/trigger/pipeline`
  - Require description when creating a new trigger `POST /projects/:id/triggers`
- Simplify project payload exposed on Environment endpoints [!9675](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9675)
- API uses merge request `IID`s (internal ID, as in the web UI) rather than `ID`s. This affects the merge requests, award emoji, todos, and time tracking APIs. [!9530](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9530)
- API uses issue `IID`s (internal ID, as in the web UI) rather than `ID`s. This affects the issues, award emoji, todos, and time tracking APIs. [!9530](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9530)
- Change initial page from `0` to `1` on `GET /projects/:id/repository/commits` (like on the rest of the API) [!9679] (https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9679)
- Return correct `Link` header data for `GET /projects/:id/repository/commits` [!9679] (https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9679)
- Update endpoints for repository files [!9637](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9637)
  - Moved `GET /projects/:id/repository/files?file_path=:file_path` to `GET /projects/:id/repository/files/:file_path` (`:file_path` should be URL-encoded)
  - `GET /projects/:id/repository/blobs/:sha` now returns JSON attributes for the blob identified by `:sha`, instead of finding the commit identified by `:sha` and returning the raw content of the blob in that commit identified by the required `?filepath=:filepath`
  - Moved `GET /projects/:id/repository/commits/:sha/blob?file_path=:file_path`  and `GET /projects/:id/repository/blobs/:sha?file_path=:file_path` to `GET /projects/:id/repository/files/:file_path/raw?ref=:sha`
  - `GET /projects/:id/repository/tree` parameter `ref_name` has been renamed to `ref` for consistency
- `confirm` parameter for `POST /users` has been deprecated in favor of `skip_confirmation` parameter

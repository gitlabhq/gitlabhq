# V3 to V4 version

Our V4 API version is currently available as *Beta*! It means that V3
will still be supported and remain unchanged for now, but be aware that the following
changes are in V4:

### 8.17

- Removed `/projects/:search` (use: `/projects?search=x`) [!8877](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8877)
- `iid` filter has been removed from `projects/:id/issues` [!8967](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8967)
- `projects/:id/merge_requests?iid[]=x&iid[]=y` array filter has been renamed to `iids` [!8793](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8793)
- Endpoints under `projects/merge_request/:id` have been removed (use: `projects/merge_requests/:id`) [!8793](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8793)
- Project snippets do not return deprecated field `expires_at` [!8723](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8723)
- Endpoints under `projects/:id/keys` have been removed (use `projects/:id/deploy_keys`) [!8716](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8716)

### 9.0

- Status 409 returned for POST `project/:id/members` when a member already exists [!9093](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9093)
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
- Moved `/projects/fork/:id` to `/projects/:id/fork` [!8940](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8940)
- Moved `DELETE /todos` to `POST /todos/mark_as_done` and `DELETE /todos/:todo_id` to `POST /todos/:todo_id/mark_as_done` [!9410](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9410)
- Endpoints `/projects/owned`, `/projects/visible`, `/projects/starred` & `/projects/all` are consolidated into `/projects` using query parameters [!8962](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8962)
- Return pagination headers for all endpoints that return an array [!8606](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8606)
- Removed `DELETE projects/:id/deploy_keys/:key_id/disable`. Use `DELETE projects/:id/deploy_keys/:key_id` instead [!9366](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9366)
- Moved `PUT /users/:id/(block|unblock)` to `POST /users/:id/(block|unblock)` [!9371](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9371)
- Make subscription API more RESTful. Use `post ":project_id/:subscribable_type/:subscribable_id/subscribe"` to subscribe and `post ":project_id/:subscribable_type/:subscribable_id/unsubscribe"` to unsubscribe from a resource. [!9325](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9325)
- Labels filter on `projects/:id/issues` and `/issues` now matches only issues containing all labels (i.e.: Logical AND, not OR) [!8849](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8849)
- Renamed param `branch_name` to `branch` on the following endpoints [!8936](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8936)
  - POST `:id/repository/branches`
  - POST `:id/repository/commits`
  - POST/PUT/DELETE `:id/repository/files`
- Renamed `branch_name` to `branch` on DELETE `id/repository/branches/:branch` response [!8936](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8936)
- Remove `public` param from create and edit actions of projects [!8736](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8736)
- Notes do not return deprecated field `upvote` and `downvote` [!9384](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9384)

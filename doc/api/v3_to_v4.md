# V3 to V4 version

Our V4 API version is currently available as *Beta*! It means that V3
will still be supported and remain unchanged for now, but be aware that the following
changes are in V4:

### Changes

- Removed `/projects/:search` (use: `/projects?search=x`)
- `iid` filter has been removed from `projects/:id/issues`
- `projects/:id/merge_requests?iid[]=x&iid[]=y` array filter has been renamed to `iids`
- Endpoints under `projects/merge_request/:id` have been removed (use: `projects/merge_requests/:id`)
- Project snippets do not return deprecated field `expires_at`
- Endpoints under `projects/:id/keys` have been removed (use `projects/:id/deploy_keys`)
- Status 409 returned for POST `project/:id/members` when a member already exists
- Moved `DELETE /projects/:id/star` to `POST /projects/:id/unstar`
- Removed the following deprecated Templates endpoints (these are still accessible with `/templates` prefix)
  - `/licences`
  - `/licences/:key`
  - `/gitignores`
  - `/gitlab_ci_ymls`
  - `/dockerfiles`
  - `/gitignores/:key`
  - `/gitlab_ci_ymls/:key`
  - `/dockerfiles/:key`
- Moved `/projects/fork/:id` to `/projects/:id/fork`
- Moved `DELETE /todos` to `POST /todos/mark_as_done` and `DELETE /todos/:todo_id` to `POST /todos/:todo_id/mark_as_done`
- Endpoints `/projects/owned`, `/projects/visible`, `/projects/starred` & `/projects/all` are consolidated into `/projects` using query parameters
- Return pagination headers for all endpoints that return an array
- Removed `DELETE projects/:id/deploy_keys/:key_id/disable`. Use `DELETE projects/:id/deploy_keys/:key_id` instead
- Moved `PUT /users/:id/(block|unblock)` to `POST /users/:id/(block|unblock)`
- Labels filter on `projects/:id/issues` and `/issues` now matches only issues containing all labels (i.e.: Logical AND, not OR)
- Renamed param `branch_name` to `branch` on the following endpoints
  - POST `:id/repository/branches`
  - POST `:id/repository/commits`
  - POST/PUT/DELETE `:id/repository/files`
- Renamed `branch_name` to `branch` on DELETE `id/repository/branches/:branch` response


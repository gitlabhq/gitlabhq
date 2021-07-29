---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Internal workings of GitLab Maintenance Mode **(PREMIUM SELF)**

## Where is Maintenance Mode enforced?

GitLab Maintenance Mode **only** blocks writes from HTTP and SSH requests at the application level in a few key places within the rails application.
[Search the codebase for `maintenance_mode?`.](https://gitlab.com/search?search=maintenance_mode%3F&group_id=9970&project_id=278964&scope=blobs&search_code=false&snippets=false&repository_ref=)

- [the read-only database method](https://gitlab.com/gitlab-org/gitlab/-/blob/2425e9de50c678413ceaad6ee3bf66f42b7e228c/ee/lib/ee/gitlab/database.rb#L13), which toggles special behavior when we are not allowed to write to the database. [Search the codebase for `Gitlab::Database.main.read_only?`.](https://gitlab.com/search?search=Gitlab%3A%3ADatabase.read_only%3F&group_id=9970&project_id=278964&scope=blobs&search_code=false&snippets=false&repository_ref=)
- [the read-only middleware](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/gitlab/middleware/read_only/controller.rb), where HTTP requests that cause database writes are blocked, unless explicitly allowed.
- [Git push access via SSH is denied](https://gitlab.com/gitlab-org/gitlab/-/blob/2425e9de50c678413ceaad6ee3bf66f42b7e228c/ee/lib/ee/gitlab/git_access.rb#L13) by returning 401 when `gitlab-shell` POSTs to [`/internal/allowed`](internal_api.md) to [check if access is allowed](internal_api.md#git-authentication).
- [Container registry authentication service](https://gitlab.com/gitlab-org/gitlab/-/blob/2425e9de50c678413ceaad6ee3bf66f42b7e228c/ee/app/services/ee/auth/container_registry_authentication_service.rb#L12), where updates to the container registry are blocked.

The database itself is not in read-only mode (except in a Geo secondary site) and can be written by sources other than the ones blocked.

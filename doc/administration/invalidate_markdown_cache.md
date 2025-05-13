---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Markdown cache
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

For performance reasons, GitLab caches the HTML version of Markdown text in fields such as:

- Comments.
- Issue descriptions.
- Merge request descriptions.

These cached versions can become outdated, such as when the `external_url` configuration option is changed. Links
in the cached text would still refer to the old URL.

## Invalidate the cache

You can invalidate the Markdown cache by using either the API or the Rails console.

### Use the API

Prerequisites:

- You must have administrator access.

To invalidate the existing cache using the API:

1. Increase the `local_markdown_version` setting in application settings by sending a PUT request:

   ```shell
   curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/application/settings?local_markdown_version=<increased_number>"
   ```

For more information about this API endpoint, see [update application settings](../api/settings.md#update-application-settings).

### Use the Rails console

Prerequisites:

- You must have [Rails console](operations/rails_console.md) access.

#### For a group

To invalidate the cache for a group:

1. Start a Rails console:

   ```shell
   sudo gitlab-rails console
   ```

1. Find the group to update:

   ```ruby
   group = Group.find(<group_id>)
   ```

1. Invalidate the cache for all projects in the group:

   ```ruby
   group.all_projects.each_slice(10) do |projects|
     projects.each do |project|
       # Invalidate issues
       project.issues.update_all(
         description_html: nil,
         title_html: nil
       )

       # Invalidate merge requests
       project.merge_requests.update_all(
         description_html: nil,
         title_html: nil
       )

       # Invalidate notes/comments
       project.notes.update_all(note_html: nil)
     end

     # Pause for one second after updating 10 projects
     sleep 1
   end
   ```

#### For a project

To invalidate the cache for a single project:

1. Start a Rails console:

   ```shell
   sudo gitlab-rails console
   ```

1. Find the project to update:

   ```ruby
   project = Project.find(<project_id>)
   ```

1. Invalidate issues:

   ```ruby
   project.issues.update_all(
     description_html: nil,
     title_html: nil
   )
   ```

1. Invalidate merge requests:

   ```ruby
   project.merge_requests.update_all(
     description_html: nil,
     title_html: nil
   )
   ```

1. Invalidate notes and comments:

   ```ruby
   project.notes.update_all(note_html: nil)
   ```

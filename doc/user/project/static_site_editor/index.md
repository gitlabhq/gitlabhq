---
stage: Create
group: Editor
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
remove_date: '2022-08-03'
redirect_to: '../web_ide/index.md'
---

# Static Site Editor (removed) **(FREE)**

This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77246) in GitLab 14.7
and [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/352505) in 15.0.
Use the [Web Editor](../repository/web_editor.md) or [Web IDE](../web_ide/index.md) instead.

## Remove the Static Site Editor

The Static Site Editor itself isn't part of your project. To remove the Static Site Editor
from an existing project, remove links that point back to the editor:

1. Remove any links that use `edit_page_url` in your project. If you used the
   **Middleman - Static Site Editor** project template, the only instance of this
   helper is located in `/source/layouts/layout.erb`. Remove this line entirely:

   ```ruby
   <%= link_to('Edit this page', edit_page_url(data.config.repository, current_page.file_descriptor.relative_path), id: 'edit-page-link') %>
   ```

1. In `/data/config.yml`, delete the `repository` key / value pair:

   ```yaml
   repository: https://gitlab.com/<username>/<myproject>
   ```

   - If `repository` is the only value stored in `/data/config.yml`, you can delete the entire file.
1. In `/helpers/custom_helpers.rb`, delete `edit_page_url()` and `endcode_path()`:

   ```ruby
   def edit_page_url(base_url, relative_path)
     "#{base_url}/-/sse/#{encode_path(relative_path)}/"
   end

   def encode_path(relative_path)
     ERB::Util.url_encode("master/source/#{relative_path}")
   end
   ```

   - If `edit_page_url()` and `encode_path()` are the only helpers, you may delete
     `/helpers/custom_helpers.rb` entirely.
1. Clean up any extraneous configuration files.
1. Commit and push your changes.

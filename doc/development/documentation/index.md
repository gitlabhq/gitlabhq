---
stage: none
group: Documentation Guidelines
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Learn how to contribute to GitLab Documentation.
---

# Contribute to the GitLab documentation

The GitLab documentation is [intended as the single source of truth (SSOT)](https://about.gitlab.com/handbook/documentation/) for information about how to configure, use, and troubleshoot GitLab. The documentation contains use cases and usage instructions for every GitLab feature, organized by product area and subject. This includes topics and workflows that span multiple GitLab features and the use of GitLab with other applications.

In addition to this page, the following resources can help you craft and contribute to documentation:

- [Style Guide](styleguide/index.md) - What belongs in the docs, language guidelines, Markdown standards to follow, links, and more.
- [Topic types](topic_types/index.md) - Learn about the different types of topics.
- [Documentation process](workflow.md).
- [Markdown Guide](../../user/markdown.md) - A reference for all Markdown syntax supported by GitLab.
- [Site architecture](site_architecture/index.md) - How <https://docs.gitlab.com> is built.
- [Documentation for feature flags](feature_flags.md) - How to write and update documentation for GitLab features deployed behind feature flags.

## Source files and rendered web locations

Documentation for GitLab, GitLab Runner, GitLab Operator, Omnibus GitLab, and Charts is published to <https://docs.gitlab.com>. Documentation for GitLab is also published within the application at `/help` on the domain of the GitLab instance.
At `/help`, only help for your current edition and version is included. Help for other versions is available at <https://docs.gitlab.com/archives/>.

The source of the documentation exists within the codebase of each GitLab application in the following repository locations:

| Project | Path |
| --- | --- |
| [GitLab](https://gitlab.com/gitlab-org/gitlab/) | [`/doc`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc) |
| [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/) | [`/docs`](https://gitlab.com/gitlab-org/gitlab-runner/-/tree/main/docs) |
| [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab/) | [`/doc`](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/doc) |
| [Charts](https://gitlab.com/gitlab-org/charts/gitlab) | [`/doc`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/doc) |
| [GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator) | [`/doc`](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/tree/master/doc) |

Documentation issues and merge requests are part of their respective repositories and all have the label `Documentation`.

### Branch naming

The [CI pipeline for the main GitLab project](../pipelines/index.md) is configured to automatically
run only the jobs that match the type of contribution. If your contribution contains
**only** documentation changes, then only documentation-related jobs run, and
the pipeline completes much faster than a code contribution.

If you are submitting documentation-only changes to Omnibus, Charts, or Operator,
the fast pipeline is not determined automatically. Instead, create branches for
docs-only merge requests using the following guide:

| Branch name           | Valid example                |
|:----------------------|:-----------------------------|
| Starting with `docs/` | `docs/update-api-issues`     |
| Starting with `docs-` | `docs-update-api-issues`     |
| Ending in `-docs`     | `123-update-api-issues-docs` |

## Contributing to docs

[Contributions to GitLab docs](workflow.md) are welcome from the entire GitLab community.

To ensure that the GitLab docs are current, there are special processes and responsibilities for all [feature changes](workflow.md), that is development work that impacts the appearance, usage, or administration of a feature.

However, anyone can contribute [documentation improvements](workflow.md) that are not associated with a feature change. For example, adding a new document on how to accomplish a use case that's already possible with GitLab or with third-party tools and GitLab.

## Markdown and styles

[GitLab docs](https://gitlab.com/gitlab-org/gitlab-docs) uses [GitLab Kramdown](https://gitlab.com/gitlab-org/gitlab_kramdown)
as its Markdown rendering engine. See the [GitLab Markdown Guide](https://about.gitlab.com/handbook/markdown-guide/) for a complete Kramdown reference.

Adhere to the [Documentation Style Guide](styleguide/index.md). If a style standard is missing, you are welcome to suggest one via a merge request.

## Folder structure and files

See the [Folder structure](site_architecture/folder_structure.md) page.

## Metadata

To provide additional directives or useful information, we add metadata in YAML
format to the beginning of each product documentation page (YAML front matter).
All values are treated as strings and are only used for the
[docs website](site_architecture/index.md).

### Stage and group metadata

Each page should ideally have metadata related to the stage and group it
belongs to, as well as an information block as described below:

- `stage`: The [Stage](https://about.gitlab.com/handbook/product/categories/#devops-stages)
  to which the majority of the page's content belongs.
- `group`: The [Group](https://about.gitlab.com/company/team/structure/#product-groups)
  to which the majority of the page's content belongs.
- `info`: The following line, which provides direction to contributors regarding
  how to contact the Technical Writer associated with the page's stage and
  group:

  ```plaintext
  To determine the technical writer assigned to the Stage/Group
  associated with this page, see
  https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
  ```

For example:

```yaml
---
stage: Example Stage
group: Example Group
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---
```

### Redirection metadata

The following metadata should be added when a page is moved to another location:

- `redirect_to`: The relative path and filename (with an `.md` extension) of the
  location to which visitors should be redirected for a moved page.
  [Learn more](redirects.md).

### Additional page metadata

Each page can have additional, optional metadata (set in the
[default.html](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/fc3577921343173d589dfa43d837b4307e4e620f/layouts/default.html#L30-52)
Nanoc layout), which is displayed at the top of the page if defined.

### Deprecated metadata

The `type` metadata parameter is deprecated but still exists in documentation
pages. You can safely remove the `type` metadata parameter and its values.

### Batch updates for TW metadata

The [`CODEOWNERS`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/CODEOWNERS)
file contains a list of files and the associated technical writers.

When a merge request contains documentation, the information in the `CODEOWNERS` file determines:

- The list of users in the **Approvers** section.
- The technical writer that the GitLab Bot pings for community contributions.

You can use a Rake task to update the `CODEOWNERS` file.

#### Update the `CODEOWNERS` file

When groups or [TW assignments](https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments)
change, you must update the `CODEOWNERS` file:

1. Update the [stage and group metadata](#stage-and-group-metadata) for any affected doc pages, if necessary. If there are many changes, you can do this step in a separate MR.
1. Update the [`codeowners.rake`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/tasks/gitlab/tw/codeowners.rake) file with the changes.
1. Go to the root of the `gitlab` repository.
1. Run the Rake task with this command: `bundle exec rake tw:codeowners`
1. Review the changes in the `CODEOWNERS` file.
1. Add and commit all your changes and push your branch up to `origin`.
1. Create a merge request and assign it to a technical writing manager for review.

When updating the `codeowners.rake` file:

- To specify multiple writers for a single group, use a space between writer names:

  ```plaintext
  CodeOwnerRule.new('Group Name', '@writer1 @writer2'),
  ```

- For a group that does not have an assigned writer, include the group name in the file and comment out the line:

  ```plaintext
  # CodeOwnerRule.new('Group Name', ''),
  ```

## Move, rename, or delete a page

See [redirects](redirects.md).

## Merge requests for GitLab documentation

Before getting started, make sure you read the introductory section
"[contributing to docs](#contributing-to-docs)" above and the
[documentation workflow](workflow.md).

- Use the current [merge request description template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/merge_request_templates/Documentation.md)
- Label the MR `Documentation` (can only be done by people with `developer` access, for example, GitLab team members)
- Assign the correct milestone per note below (can only be done by people with `developer` access, for example, GitLab team members)

Documentation is merged if it is an improvement on existing content,
represents a good-faith effort to follow the template and style standards,
and is believed to be accurate.

Further needs for what would make the doc even better should be immediately addressed
in a follow-up merge request or issue.

If the release version you want to add the documentation to has already been
released, follow the [patch release runbook](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/patch/engineers.md)
to get it merged into the current version.

## GitLab `/help`

Every GitLab instance includes documentation at `/help` (`https://gitlab.example.com/help`)
that matches the version of the instance. For example, <https://gitlab.com/help>.

The documentation available online at <https://docs.gitlab.com> is deployed every
hour from the default branch of [GitLab, Omnibus, Runner, and Charts](#source-files-and-rendered-web-locations).
After a merge request that updates documentation is merged, it is available online
in an hour or less.

However, it's only available at `/help` on self-managed instances in the next released
version. The date an update is merged can impact which self-managed release the update
is present in.

For example:

1. A merge request in `gitlab` updates documentation. It has a milestone of 14.4,
   with an expected release date of 2021-10-22.
1. It is merged on 2021-10-19 and available online the same day at <https://docs.gitlab.com>.
1. GitLab 14.4 is released on 2021-10-22, based on the `gitlab` codebase from 2021-10-18
   (one day *before* the update was merged).
1. The change shows up in the 14.5 self-managed release, due to missing the release cutoff
   for 14.4.

The exact cutoff date for each release is flexible, and can be sooner or later
than expected due to holidays, weekends or other events. In general, MRs merged
by the 17th should be present in the release on the 22nd, though it is not guaranteed.
If it is important that a documentation update is present in that month's release,
merge it as early as possible.

### Linking to `/help`

When you're building a new feature, you may need to link to the documentation
from the GitLab application. This is normally done in files inside the
`app/views/` directory, with the help of the `help_page_path` helper method.

The `help_page_path` contains the path to the document you want to link to,
with the following conventions:

- It's relative to the `doc/` directory in the GitLab repository.
- It omits the `.md` extension.
- It doesn't end with a forward slash (`/`).

The help text follows the [Pajamas guidelines](https://design.gitlab.com/usability/contextual-help#formatting-help-content).

#### Linking to `/help` in HAML

Use the following special cases depending on the context, ensuring all link text
is inside `_()` so it can be translated:

- Linking to a doc page. In its most basic form, the HAML code to generate a
  link to the `/help` page is:

  ```haml
  = link_to _('Learn more.'), help_page_path('user/permissions'), target: '_blank', rel: 'noopener noreferrer'
  ```

- Linking to an anchor link. Use `anchor` as part of the `help_page_path`
  method:

  ```haml
  = link_to _('Learn more.'), help_page_path('user/permissions', anchor: 'anchor-link'), target: '_blank', rel: 'noopener noreferrer'
  ```

- Using links inline of some text. First, define the link, and then use it. In
  this example, `link_start` is the name of the variable that contains the
  link:

  ```haml
  - link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: help_page_path('user/permissions') }
  %p= _("This is a text describing the option/feature in a sentence. %{link_start}Learn more.%{link_end}").html_safe % { link_start: link_start, link_end: '</a>'.html_safe }
  ```

- Using a button link. Useful in places where text would be out of context with
  the rest of the page layout:

  ```haml
  = link_to _('Learn more.'), help_page_path('user/permissions'),  class: 'btn btn-info', target: '_blank', rel: 'noopener noreferrer'
  ```

#### Linking to `/help` in JavaScript

To link to the documentation from a JavaScript or a Vue component, use the `helpPagePath` function from [`help_page_helper.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/helpers/help_page_helper.js):

```javascript
import { helpPagePath } from '~/helpers/help_page_helper';

helpPagePath('user/permissions', { anchor: 'anchor-link' })
// evaluates to '/help/user/permissions#anchor-link' for GitLab.com
```

This is preferred over static paths, as the helper also works on instances installed under a [relative URL](../../install/relative_url.md).

#### Linking to `/help` in Ruby

To link to the documentation from within Ruby code, use the following code block as a guide, ensuring all link text is inside `_()` so it can
be translated:

```ruby
docs_link = link_to _('Learn more.'), help_page_url('user/permissions', anchor: 'anchor-link'), target: '_blank', rel: 'noopener noreferrer'
_('This is a text describing the option/feature in a sentence. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
```

In cases where you need to generate a link from outside of views/helpers, where the `link_to` and `help_page_url` methods are not available, use the following code block
as a guide where the methods are fully qualified:

```ruby
docs_link = ActionController::Base.helpers.link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('user/permissions', anchor: 'anchor-link'), target: '_blank', rel: 'noopener noreferrer'
_('This is a text describing the option/feature in a sentence. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
```

Do not use `include ActionView::Helpers::UrlHelper` just to make the `link_to` method available as you might see in some existing code. Read more in
[issue 340567](https://gitlab.com/gitlab-org/gitlab/-/issues/340567).

### GitLab `/help` tests

Several [RSpec tests](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/features/help_pages_spec.rb)
are run to ensure GitLab documentation renders and works correctly. In particular, that [main docs landing page](../../index.md) works correctly from `/help`.
For example, [GitLab.com's `/help`](https://gitlab.com/help).

## Docs site architecture

For information on how we build and deploy <https://docs.gitlab.com>, see [Docs site architecture](site_architecture/index.md).

### Global navigation

See the [Global navigation](site_architecture/global_nav.md) doc for information
on how the left-side navigation menu is built and updated.

## Previewing the changes live

See how you can use review apps to [preview your changes live](review_apps.md).

## Testing

For more information about documentation testing, see the [Documentation testing](testing.md)
guide.

## Danger Bot

GitLab uses [Danger](https://github.com/danger/danger) for some elements in
code review. For docs changes in merge requests, whenever a change to files under `/doc`
is made, Danger Bot leaves a comment with further instructions about the documentation
process. This is configured in the `Dangerfile` in the GitLab repository under
[/danger/documentation/](https://gitlab.com/gitlab-org/gitlab/-/tree/master/danger/documentation).

## Help and feedback section

This section ([introduced](https://gitlab.com/gitlab-org/gitlab-docs/-/merge_requests/319) in GitLab 11.4)
is displayed at the end of each document and can be omitted by adding a key into
the front matter:

```yaml
---
feedback: false
---
```

The default is to leave it there. If you want to omit it from a document, you
must check with a technical writer before doing so.

The click events in the feedback section are tracked with Google Tag Manager.
The conversions can be viewed on Google Analytics by navigating to
**Behavior > Events > Top events > docs**.

## Automatic screenshot generator

You can now set up an automatic screenshot generator to take and compress screenshots with the
help of a configuration file known as **screenshot generator**.

### Use the tool

To run the tool on an existing screenshot generator, take the following steps:

1. Set up the [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/gitlab_docs.md).
1. Navigate to the subdirectory with your cloned GitLab repository, typically `gdk/gitlab`.
1. Make sure that your GDK database is fully migrated: `bin/rake db:migrate RAILS_ENV=development`.
1. Install `pngquant`, see the tool website for more information: [`pngquant`](https://pngquant.org/)
1. Run `scripts/docs_screenshots.rb spec/docs_screenshots/<name_of_screenshot_generator>.rb <milestone-version>`.
1. Identify the location of the screenshots, based on the `gitlab/doc` location defined by the `it` parameter in your script.
1. Commit the newly created screenshots.

### Extending the tool

To add an additional **screenshot generator**, take the following steps:

- Locate the `spec/docs_screenshots` directory.
- Add a new file with a `_docs.rb` extension.
- Be sure to include the following bits in the file:

```ruby
require 'spec_helper'

RSpec.describe '<What I am taking screenshots of>', :js do
  include DocsScreenshotHelpers # Helper that enables the screenshots taking mechanism

  before do
    page.driver.browser.manage.window.resize_to(1366, 1024) # length and width of the page
  end
```

- In addition, every `it` block must include the path where the screenshot is saved

```ruby
 it 'user/packages/container_registry/img/project_image_repositories_list'
```

#### Full page screenshots

To take a full page screenshot, `visit the page` and perform any expectation on real content (to have capybara wait till the page is ready and not take a white screenshot).

#### Element screenshot

To have the screenshot focuses few more steps are needed:

- **find the area**: `screenshot_area = find('#js-registry-policies')`
- **scroll the area in focus**: `scroll_to screenshot_area`
- **wait for the content**: `expect(screenshot_area).to have_content 'Expiration interval'`
- **set the crop area**: `set_crop_data(screenshot_area, 20)`

In particular, `set_crop_data` accepts as arguments: a `DOM` element and a
padding. The padding is added around the element, enlarging the screenshot area.

#### Live example

Please use `spec/docs_screenshots/container_registry_docs.rb` as a guide and as an example to create your own scripts.

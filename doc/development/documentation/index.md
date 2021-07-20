---
stage: none
group: Documentation Guidelines
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: Learn how to contribute to GitLab Documentation.
---

# GitLab Documentation guidelines

The GitLab documentation is [intended as the single source of truth (SSOT)](https://about.gitlab.com/handbook/documentation/) for information about how to configure, use, and troubleshoot GitLab. The documentation contains use cases and usage instructions for every GitLab feature, organized by product area and subject. This includes topics and workflows that span multiple GitLab features, and the use of GitLab with other applications.

In addition to this page, the following resources can help you craft and contribute to documentation:

- [Style Guide](styleguide/index.md) - What belongs in the docs, language guidelines, Markdown standards to follow, links, and more.
- [Topic type template](structure.md) - Learn about the different types of topics.
- [Documentation process](workflow.md).
- [Markdown Guide](../../user/markdown.md) - A reference for all Markdown syntax supported by GitLab.
- [Site architecture](site_architecture/index.md) - How <https://docs.gitlab.com> is built.
- [Documentation for feature flags](feature_flags.md) - How to write and update documentation for GitLab features deployed behind feature flags.

## Source files and rendered web locations

Documentation for GitLab, GitLab Runner, Omnibus GitLab, and Charts is published to <https://docs.gitlab.com>. Documentation for GitLab is also published within the application at `/help` on the domain of the GitLab instance.
At `/help`, only help for your current edition and version is included. Help for other versions is available at <https://docs.gitlab.com/archives/>.

The source of the documentation exists within the codebase of each GitLab application in the following repository locations:

| Project | Path |
| --- | --- |
| [GitLab](https://gitlab.com/gitlab-org/gitlab/) | [`/doc`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc) |
| [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/) | [`/docs`](https://gitlab.com/gitlab-org/gitlab-runner/-/tree/main/docs) |
| [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab/) | [`/doc`](https://gitlab.com/gitlab-org/omnibus-gitlab/tree/master/doc) |
| [Charts](https://gitlab.com/gitlab-org/charts/gitlab) | [`/doc`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/doc) |

Documentation issues and merge requests are part of their respective repositories and all have the label `Documentation`.

### Branch naming

The [CI pipeline for the main GitLab project](../pipelines.md) is configured to automatically
run only the jobs that match the type of contribution. If your contribution contains
**only** documentation changes, then only documentation-related jobs run, and
the pipeline completes much faster than a code contribution.

If you are submitting documentation-only changes to Runner, Omnibus, or Charts,
the fast pipeline is not determined automatically. Instead, create branches for
docs-only merge requests using the following guide:

| Branch name           | Valid example                |
|:----------------------|:-----------------------------|
| Starting with `docs/` | `docs/update-api-issues`     |
| Starting with `docs-` | `docs-update-api-issues`     |
| Ending in `-docs`     | `123-update-api-issues-docs` |

## Contributing to docs

[Contributions to GitLab docs](workflow.md) are welcome from the entire GitLab community.

To ensure that GitLab docs are current, there are special processes and responsibilities for all [feature changes](workflow.md), that is development work that impacts the appearance, usage, or administration of a feature.

However, anyone can contribute [documentation improvements](workflow.md) that are not associated with a feature change. For example, adding a new doc on how to accomplish a use case that's already possible with GitLab or with third-party tools and GitLab.

## Markdown and styles

[GitLab docs](https://gitlab.com/gitlab-org/gitlab-docs) uses [GitLab Kramdown](https://gitlab.com/gitlab-org/gitlab_kramdown)
as its Markdown rendering engine. See the [GitLab Markdown Guide](https://about.gitlab.com/handbook/markdown-guide/) for a complete Kramdown reference.

Adhere to the [Documentation Style Guide](styleguide/index.md). If a style standard is missing, you are welcome to suggest one via a merge request.

## Folder structure and files

See the [Structure](styleguide/index.md#structure) section of the [Documentation Style Guide](styleguide/index.md).

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
  how to contact the Technical Writer associated with the page's Stage and
  Group:

  ```plaintext
  To determine the technical writer assigned to the Stage/Group
  associated with this page, see
  https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
  ```

For example:

```yaml
---
stage: Example Stage
group: Example Group
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---
```

If you need help determining the correct stage, read [Ask for help](workflow.md#ask-for-help).

### Document type metadata

Originally discussed in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/1280),
each page should have a metadata tag called `type`. It can be one or more of the
following:

- `index`: It consists mostly of a list of links to other pages.
  [Example page](../../index.md).
- `concepts`: The background or context of a subject.
  [Example page](../../topics/autodevops/index.md).
- `howto`: Specific use case instructions.
  [Example page](../../ssh/index.md).
- `tutorial`: Learn a process/concept by doing.
  [Example page](../../gitlab-basics/start-using-git.md).
- `reference`: A collection of information used as a reference to use a feature
  or a functionality. [Example page](../../ci/yaml/index.md).

### Redirection metadata

The following metadata should be added when a page is moved to another location:

- `redirect_to`: The relative path and filename (with an `.md` extension) of the
  location to which visitors should be redirected for a moved page.
  [Learn more](#move-or-rename-a-page).
- `disqus_identifier`: Identifier for Disqus commenting system. Used to keep
  comments with a page that's been moved to a new URL.
  [Learn more](#redirections-for-pages-with-disqus-comments).

### Comments metadata

The [docs website](site_architecture/index.md) has comments (provided by Disqus)
enabled by default. In case you want to disable them (for example in index pages),
set it to `false`:

```yaml
---
comments: false
---
```

### Additional page metadata

Each page can have additional, optional metadata (set in the
[default.html](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/fc3577921343173d589dfa43d837b4307e4e620f/layouts/default.html#L30-52)
Nanoc layout), which is displayed at the top of the page if defined:

- `reading_time`: If you want to add an indication of the approximate reading
  time of a page, you can set `reading_time` to `true`. This uses a simple
  [algorithm](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/lib/helpers/reading_time.rb)
  to calculate the reading time based on the number of words.

## Move or rename a page

Moving or renaming a document is the same as changing its location. Be sure to
assign a technical writer to any merge request that renames or moves a page.
Technical Writers can help with any questions and can review your change.

When moving or renaming a page, you must redirect browsers to the new page.
This ensures users find the new page, and have the opportunity to update their
bookmarks.

There are two types of redirects:

- Redirect codes added into the documentation files themselves, for users who
  view the docs in `/help` on self-managed instances. For example,
  [`/help` on GitLab.com](https://gitlab.com/help).
- [GitLab Pages redirects](../../user/project/pages/redirects.md),
  for users who view the docs on [`docs.gitlab.com`](https://docs.gitlab.com).

The Technical Writing team manages the [process](https://gitlab.com/gitlab-org/technical-writing/-/blob/main/.gitlab/issue_templates/tw-monthly-tasks.md)
to regularly update the [`redirects.yaml`](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/content/_data/redirects.yaml)
file.

To add a redirect:

1. In the repository (`gitlab`, `gitlab-runner`, `omnibus-gitlab`, or `charts`),
   create a new documentation file. Don't delete the old one. The easiest
   way is to copy it. For example:

   ```shell
   cp doc/user/search/old_file.md doc/api/new_file.md
   ```

1. Add the redirect code to the old documentation file by running the
   following Rake task. The first argument is the path of the old file,
   and the second argument is the path of the new file:

   - To redirect to a page in the same project, use relative paths and
     the `.md` extension. Both old and new paths start from the same location.
     In the following example, both paths are relative to `doc/`:

     ```shell
     bundle exec rake "gitlab:docs:redirect[doc/user/search/old_file.md, doc/api/new_file.md]"
     ```

   - To redirect to a page in a different project or site, use the full URL (with `https://`) :

     ```shell
     bundle exec rake "gitlab:docs:redirect[doc/user/search/old_file.md, https://example.com]"
     ```

   Alternatively, you can omit the arguments, and you'll be asked to enter
   their values:

   ```shell
   bundle exec rake gitlab:docs:redirect
   ```

   If you don't want to use the Rake task, you can use the following template.
   However, the file paths must be relative to the `doc` or `docs` directory.

   Replace the value of `redirect_to` with the new file path and `YYYY-MM-DD`
   with the date the file should be removed.

   Redirect files that link to docs in internal documentation projects
   are removed after three months. Redirect files that link to external sites are
   removed after one year:

   ```markdown
   ---
   redirect_to: '../newpath/to/file/index.md'
   remove_date: 'YYYY-MM-DD'
   ---

   This document was moved to [another location](../path/to/file/index.md).

   <!-- This redirect file can be deleted after <YYYY-MM-DD>. -->
   <!-- Before deletion, see: https://docs.gitlab.com/ee/development/documentation/#move-or-rename-a-page -->
   ```

1. If the documentation page being moved has any Disqus comments, follow the steps
   described in [Redirections for pages with Disqus comments](#redirections-for-pages-with-disqus-comments).
1. Open a merge request with your changes. If a documentation page
   you're removing includes images that aren't used
   with any other documentation pages, be sure to use your merge request to delete
   those images from the repository.
1. Assign the merge request to a technical writer for review and merge.
1. Search for links to the old documentation file. You must find and update all
   links that point to the old documentation file:

   - In <https://gitlab.com/gitlab-com/www-gitlab-com>, search for full URLs:
     `grep -r "docs.gitlab.com/ee/path/to/file.html" .`
   - In <https://gitlab.com/gitlab-org/gitlab-docs/-/tree/master/content/_data>,
     search the navigation bar configuration files for the path with `.html`:
     `grep -r "path/to/file.html" .`
   - In any of the four internal projects, search for links in the docs
     and codebase. Search for all variations, including full URL and just the path.
     For example, go to the root directory of the `gitlab` project and run:

     ```shell
     grep -r "docs.gitlab.com/ee/path/to/file.html" .
     grep -r "path/to/file.html" .
     grep -r "path/to/file.md" .
     grep -r "path/to/file" .
     ```

     You may need to try variations of relative links, such as `../path/to/file` or
     `../file` to find every case.

### Redirections for pages with Disqus comments

If the documentation page being relocated already has Disqus comments,
we need to preserve the Disqus thread.

Disqus uses an identifier per page, and for <https://docs.gitlab.com>, the page identifier
is configured to be the page URL. Therefore, when we change the document location,
we need to preserve the old URL as the same Disqus identifier.

To do that, add to the front matter the variable `disqus_identifier`,
using the old URL as value. For example, let's say we moved the document
available under `https://docs.gitlab.com/my-old-location/README.html` to a new location,
`https://docs.gitlab.com/my-new-location/index.html`.

Into the **new document** front matter, we add the following information. You must
include the filename in the `disqus_identifier` URL, even if it's `index.html` or `README.html`.

```yaml
---
disqus_identifier: 'https://docs.gitlab.com/my-old-location/README.html'
---
```

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
frozen or released, use the label `~"Pick into X.Y"` to get it merged into
the correct release. Avoid picking into a past release as much as you can, as
it increases the work of the release managers.

## GitLab `/help`

Every GitLab instance includes the documentation, which is available at `/help`
(`https://gitlab.example.com/help`). For example, <https://gitlab.com/help>.

The documentation available online on <https://docs.gitlab.com> is deployed every
four hours from the `main` branch of GitLab, Omnibus, and Runner. Therefore,
after a merge request gets merged, it is available online on the same day.
However, it's shipped (and available on `/help`) within the milestone assigned
to the MR.

For example, let's say your merge request has a milestone set to 11.3, which
a release date of 2018-09-22. If it gets merged on 2018-09-15, it is
available online on 2018-09-15, but, as the feature freeze date has passed, if
the MR does not have a `~"Pick into 11.3"` label, the milestone has to be changed
to 11.4 and it ships with all GitLab packages only on 2018-10-22,
with GitLab 11.4. Meaning, it's available only with `/help` from GitLab
11.4 onward, but available on <https://docs.gitlab.com/> on the same day it was merged.

### Linking to `/help`

When you're building a new feature, you may need to link to the documentation
from the GitLab application. This is normally done in files inside the
`app/views/` directory, with the help of the `help_page_path` helper method.

The `help_page_path` contains the path to the document you want to link to,
with the following conventions:

- It's relative to the `doc/` directory in the GitLab repository.
- It omits the `.md` extension.
- It doesn't end with a slash (`/`).

The help text follows the [Pajamas guidelines](https://design.gitlab.com/usability/helping-users/#formatting-help-content).

Use the following special cases depending on the context, ensuring all links
are inside `_()` so they can be translated:

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

### GitLab `/help` tests

Several [RSpec tests](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/features/help_pages_spec.rb)
are run to ensure GitLab documentation renders and works correctly. In particular, that [main docs landing page](../../index.md) works correctly from `/help`.
For example, [GitLab.com's `/help`](https://gitlab.com/help).

## Docs site architecture

See the [Docs site architecture](site_architecture/index.md) page to learn
how we build and deploy the site at <https://docs.gitlab.com> and
to review all the assets and libraries in use.

### Global navigation

See the [Global navigation](site_architecture/global_nav.md) doc for information
on how the left-side navigation menu is built and updated.

## Previewing the changes live

NOTE:
To preview your changes to documentation locally, follow this
[development guide](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/README.md#development-when-contributing-to-gitlab-documentation) or [these instructions for GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/gitlab_docs.md).

The live preview is currently enabled for the following projects:

- [`gitlab`](https://gitlab.com/gitlab-org/gitlab)
- [`omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab)
- [`gitlab-runner`](https://gitlab.com/gitlab-org/gitlab-runner)

If your merge request has docs changes, you can use the manual `review-docs-deploy` job
to deploy the docs review app for your merge request.

![Manual trigger a docs build](img/manual_build_docs.png)

You must push a branch to those repositories, as it doesn't work for forks.

The `review-docs-deploy*` job:

1. Triggers a cross project pipeline and build the docs site with your changes.

In case the review app URL returns 404, this means that either the site is not
yet deployed, or something went wrong with the remote pipeline. Give it a few
minutes and it should appear online, otherwise you can check the status of the
remote pipeline from the link in the merge request's job output.
If the pipeline failed or got stuck, drop a line in the `#docs` chat channel.

NOTE:
Someone with no merge rights to the GitLab projects (think of forks from
contributors) cannot run the manual job. In that case, you can
ask someone from the GitLab team who has the permissions to do that for you.

### Troubleshooting review apps

In case the review app URL returns 404, follow these steps to debug:

1. **Did you follow the URL from the merge request widget?** If yes, then check if
   the link is the same as the one in the job output.
1. **Did you follow the URL from the job output?** If yes, then it means that
   either the site is not yet deployed or something went wrong with the remote
   pipeline. Give it a few minutes and it should appear online, otherwise you
   can check the status of the remote pipeline from the link in the job output.
   If the pipeline failed or got stuck, drop a line in the `#docs` chat channel.

### Technical aspects

If you want to know the in-depth details, here's what's really happening:

1. You manually run the `review-docs-deploy` job in a merge request.
1. The job runs the [`scripts/trigger-build`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/trigger-build)
   script with the `docs deploy` flag, which triggers the "Triggered from `gitlab-org/gitlab` 'review-docs-deploy' job"
   pipeline trigger in the `gitlab-org/gitlab-docs` project for the `$DOCS_BRANCH` (defaults to `main`).
1. The preview URL is shown both at the job output and in the merge request
   widget. You also get the link to the remote pipeline.
1. In the `gitlab-org/gitlab-docs` project, the pipeline is created and it
   [skips the test jobs](https://gitlab.com/gitlab-org/gitlab-docs/blob/8d5d5c750c602a835614b02f9db42ead1c4b2f5e/.gitlab-ci.yml#L50-55)
   to lower the build time.
1. Once the docs site is built, the HTML files are uploaded as artifacts.
1. A specific runner tied only to the docs project, runs the Review App job
   that downloads the artifacts and uses `rsync` to transfer the files over
   to a location where NGINX serves them.

The following GitLab features are used among others:

- [Manual actions](../../ci/yaml/index.md#whenmanual)
- [Multi project pipelines](../../ci/pipelines/multi_project_pipelines.md)
- [Review Apps](../../ci/review_apps/index.md)
- [Artifacts](../../ci/yaml/index.md#artifacts)
- [Specific runner](../../ci/runners/runners_scope.md#prevent-a-specific-runner-from-being-enabled-for-other-projects)
- [Pipelines for merge requests](../../ci/pipelines/merge_request_pipelines.md)

## Testing

For more information about documentation testing, see the [Documentation testing](testing.md)
guide.

## Danger Bot

GitLab uses [Danger](https://github.com/danger/danger) for some elements in
code review. For docs changes in merge requests, whenever a change to files under `/doc`
is made, Danger Bot leaves a comment with further instructions about the documentation
process. This is configured in the `Dangerfile` in the GitLab repository under
[/danger/documentation/](https://gitlab.com/gitlab-org/gitlab/-/tree/master/danger/documentation).

## Automatic screenshot generator

You can now set up an automatic screenshot generator to take and compress screenshots, with the
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

To take a full page screenshot simply `visit the page` and perform any expectation on real content (to have capybara wait till the page is ready and not take a white screenshot).

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

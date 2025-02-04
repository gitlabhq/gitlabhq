---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: GitLab /help
---

Every GitLab instance includes documentation at `/help` (`https://gitlab.example.com/help`)
that matches the version of the instance. For example, <https://gitlab.com/help>.

The documentation available online at <https://docs.gitlab.com> is deployed every
hour from the default branch of GitLab, Omnibus, Runner, Charts, and Operator.
After a merge request that updates documentation is merged, it is available online
in an hour or less.

However, it's only available at `/help` on GitLab Self-Managed instances in the next released
version. The date an update is merged can impact which GitLab Self-Managed release the update
is present in.

For example:

1. A merge request in `gitlab` updates documentation. It has a milestone of 14.4,
   with an expected release date of 2021-10-22.
1. It is merged on 2021-10-19 and available online the same day at <https://docs.gitlab.com>.
1. GitLab 14.4 is released on 2021-10-22, based on the `gitlab` codebase from 2021-10-18
   (one day *before* the update was merged).
1. The change shows up in the 14.5 GitLab Self-Managed release, due to missing the release cutoff
   for 14.4.

If it is important that a documentation update is present in that month's release,
merge it as early as possible.

## Page mapping

Requests to `/help` can be [redirected](../../administration/settings/help_page.md#redirect-help-pages). If redirection
is turned off, `/help` maps requests for help pages to specific files in the `doc`
directory. For example:

- Requested URLs: `<gdk_instance>/help/topics/plan_and_track.md`, `<gdk_instance>/help/topics/plan_and_track.html`
  and `<gdk_instance>/help/topics/plan_and_track`.
- Mapping: `doc/topics/plan_and_track.md`.

### `_index.md` files

> - Support for `_index.md` files [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144419) in GitLab 16.10.

The Hugo static site generator makes use of `_index.md` files. To allow for index pages to be
named either `index.md` or `_index.md` in `/help`, GitLab maps requests for `index.md`, `index.html`, or `index`:

- To `index.md` if the file exists at the requested location.
- Otherwise, to `_index.md`.

For example:

- Requested URLs: `<gdk_instance>/help/user/index.md`, `<gdk_instance>/help/user/index.html`, and
  `<gdk_instance>/help/user/index`.
- Mapping:
  - `doc/user/index.md` if it exists.
  - Otherwise, to `doc/user/_index.md`.

## Source files

`/help` can render Markdown files with the level 1 heading either:

- Specified in YAML front matter using `title`. For example, `title: My Markdown file`.
  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145627) in GitLab 16.10.
- Specified in the Markdown itself. For example, `# My Markdown file`.

You should not specify the level 1 heading for a page using both methods at the same time, otherwise the level 1 heading
is repeated.

## Linking to `/help`

When you're building a new feature, you may need to link to the documentation
from the GitLab application. This is usually done in files inside the
`app/views/` directory, with the help of the `help_page_path` helper method.

The `help_page_path` contains the path to the document you want to link to,
with the following conventions:

- It's relative to the `doc/` directory in the GitLab repository.
- For clarity, it should end with the `.md` file extension.

The help text follows the [Pajamas guidelines](https://design.gitlab.com/usability/contextual-help#formatting-help-content).

### Linking to `/help` in HAML

Use the following special cases depending on the context, ensuring all link text
is inside `_()` so it can be translated:

- Linking to a doc page. In its most basic form, the HAML code to generate a
  link to the `/help` page is:

  ```haml
  = link_to _('Learn more.'), help_page_path('user/permissions.md'), target: '_blank', rel: 'noopener noreferrer'
  ```

- Linking to an anchor link. Use `anchor` as part of the `help_page_path`
  method:

  ```haml
  = link_to _('Learn more.'), help_page_path('user/permissions.md', anchor: 'anchor-link'), target: '_blank', rel: 'noopener noreferrer'
  ```

- Using links inline of some text. First, define the link, and then use it. In
  this example, `link_start` is the name of the variable that contains the
  link:

  ```haml
  - link = link_to('', help_page_path('user/permissions.md'), target: '_blank', rel: 'noopener noreferrer')
  %p= safe_format(_("This is a text describing the option/feature in a sentence. %{link_start}Learn more.%{link_end}"), tag_pair(link, :link_start, :link_end))
  ```

- Using a button link. Useful in places where text would be out of context with
  the rest of the page layout:

  ```haml
  = render Pajamas::ButtonComponent.new(href: help_page_path('user/group/import/index.md'), target: '_blank') do
      = _('Learn more')
  ```

### Linking to `/help` in JavaScript

To link to the documentation from a JavaScript or a Vue component, use the `helpPagePath` function from [`help_page_helper.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/helpers/help_page_helper.js):

```javascript
import { helpPagePath } from '~/helpers/help_page_helper';

helpPagePath('user/permissions.md', { anchor: 'anchor-link' })
// evaluates to '/help/user/permissions#anchor-link' for GitLab.com
```

This is preferred over static paths, as the helper also works on instances installed under a [relative URL](../../install/relative_url.md).

### Linking to `/help` in Ruby

To link to the documentation from within Ruby code, use the following code block as a guide, ensuring all link text is inside `_()` so it can
be translated:

```ruby
docs_link = link_to _('Learn more.'), help_page_url('user/permissions.md', anchor: 'anchor-link'), target: '_blank', rel: 'noopener noreferrer'
safe_format(_('This is a text describing the option/feature in a sentence. %{docs_link}'), docs_link: docs_link)
```

In cases where you need to generate a link from outside of views/helpers, where the `link_to` and `help_page_url` methods are not available, use the following code block
as a guide where the methods are fully qualified:

```ruby
docs_link = ActionController::Base.helpers.link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('user/permissions.md', anchor: 'anchor-link'), target: '_blank', rel: 'noopener noreferrer'
safe_format(_('This is a text describing the option/feature in a sentence. %{docs_link}'), docs_link: docs_link)
```

Do not use `include ActionView::Helpers::UrlHelper` just to make the `link_to` method available as you might see in some existing code. Read more in
[issue 340567](https://gitlab.com/gitlab-org/gitlab/-/issues/340567).

## `/help` tests

Several [RSpec tests](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/features/help_pages_spec.rb)
are run to ensure GitLab documentation renders and works correctly. In particular, that [main docs landing page](../../index.md) works correctly from `/help`.
For example, [GitLab.com's `/help`](https://gitlab.com/help).

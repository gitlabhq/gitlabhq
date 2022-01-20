---
stage: none
group: Documentation Guidelines
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: Learn how to contribute to GitLab Documentation.
---

<!---
  The clean_redirects Rake task in the gitlab-docs repository manually
  excludes this file. If the line containing remove_date is moved to a new
  document, update the Rake task with the new location.

  https://gitlab.com/gitlab-org/gitlab-docs/-/blob/1979f985708d64558bb487fbe9ed5273729c01b7/Rakefile#L306
--->

# Redirects in GitLab documentation

When you move, rename, or delete a page, you must add a redirect. Redirects reduce
how often users get 404s when visiting the documentation site from out-of-date links, like:

- Bookmarks
- Links from external sites
- Links from old blog posts
- Links in the documentation site global navigation

Add a redirect to ensure:

- Users see the new page and can update or delete their bookmark.
- External sites can update their links, especially sites that have automation that
  check for redirecting links.
- The documentation site global navigation does not link to a missing page.

  The links in the global navigation are already tested in the `gitlab-docs` project.
  If the redirect is missing, the `gitlab-docs` project's `main` branch might break.

Be sure to assign a technical writer to any merge request that moves, renames, or deletes a page.
Technical Writers can help with any questions and can review your change.

There are two types of redirects:

- Redirect added into the documentation files themselves, for users who
  view the docs in `/help` on self-managed instances. For example,
  [`/help` on GitLab.com](https://gitlab.com/help).
- [GitLab Pages redirects](../../user/project/pages/redirects.md),
  for users who view the docs on [`docs.gitlab.com`](https://docs.gitlab.com).

  The Technical Writing team manages the [process](https://gitlab.com/gitlab-org/technical-writing/-/blob/main/.gitlab/issue_templates/tw-monthly-tasks.md)
  to regularly update and [clean up the redirects](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/raketasks.md#clean-up-redirects).
  If you're a contributor, you may add a new redirect, but you don't need to delete
  the old ones. This process is automatic and handled by the Technical
  Writing team.

NOTE:
If the old page you're renaming doesn't exist in a stable branch, skip the
following steps and ask a Technical Writer to add the redirect in
[`redirects.yaml`](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/content/_data/redirects.yaml).
For example, if you add a new page on the 3rd of the month and then rename it before it gets
added in the stable branch on the 18th, the old page will never be part of the internal `/help`.
In that case, you can jump straight to the
[Pages redirect](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/doc/maintenance.md#pages-redirects).

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

   Alternatively, you can omit the arguments and be asked to enter their values:

   ```shell
   bundle exec rake gitlab:docs:redirect
   ```

   If you don't want to use the Rake task, you can use the following template.

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

## Redirections for pages with Disqus comments

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

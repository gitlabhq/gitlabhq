---
stage: none
group: unassigned
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: Metadata
---

Each documentation Markdown page contains YAML front matter.
All values in the metadata are treated as strings and are used for the
documentation website only.

## Stage and group metadata

Each page should have metadata related to the stage and group it
belongs to, an information block, and the page title. For example:

```yaml
---
stage: Example Stage
group: Example Group
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Example page title
---
```

To populate the metadata, include this information:

- `stage`: The [Stage](https://handbook.gitlab.com/handbook/product/categories/#devops-stages)
  that the majority of the page's content belongs to.
- `group`: The [Group](https://handbook.gitlab.com/handbook/company/structure/#product-groups)
  that the majority of the page's content belongs to.
- `info`: How to find the Technical Writer associated with the page's stage and
  group.
- `title`: The page title that appears as the H1 (level one heading) at the top of the page.

### Exceptions

Documents in the `/development` directory get this metadata:

```yaml
---
stage: Example Stage
group: Example Group
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Example page title
---
```

Documents in the `/solutions` directory get this metadata:

```yaml
---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: Example page title
---
```

## Title metadata

The `title` metadata:

- Generates the H1 (level one heading) at the top of the rendered page.
- Can be used to generate automated page listings.
- Replaces Markdown H1 headings (like `# Page title`).

## Description metadata

The `description` tag:

- Is used to populate text on the documentation home page.
- Is shown in social media previews.
- Can be used in search result snippets.
- Is shown when the page is included in a [`cards` shortcode](styleguide/_index.md#cards).

For the top-level pages, like **Use GitLab** and one level underneath,
the descriptions are lists of nouns. For example, for **Set up your organization**,
the description is `Users, groups, namespaces, SSH keys.`

For other pages, descriptions are not actively maintained. However, if you want to add one,
use a short description of what the page is about.
See the Google [Best practices for creating quality meta descriptions](https://developers.google.com/search/docs/appearance/snippet#meta-descriptions) for tips.

## Avoid pages being added to global navigation

If a specific page shouldn't be added to the global navigation (have an entry added to
[`navigation.yaml`](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/data/en-us/navigation.yaml), add
the following to the page's metadata:

```yaml
ignore_in_report: true
```

When this metadata is set on a page:

- The [`pages_not_in_nav.cjs`](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/scripts/pages_not_in_nav.cjs)
  script ignores the page when processing the documentation.
- Technical writers doing the Technical Writing team's monthly tasks aren't prompted to add the page to the global
  navigation.

## Indicate GitLab Dedicated support

The `gitlab_dedicated` metadata indicates whether a documentation page applies to GitLab Dedicated.

Add this field to documentation pages when GitLab Dedicated availability status has been confirmed with the product team. This metadata should complement, not replace, the information from the **Offering** details.

For example, usually pages that apply to GitLab Self-Managed apply to GitLab Dedicated.
Use this metadata when they don't:

```yaml
gitlab_dedicated: no
```

When a page applies to GitLab Dedicated, use:

```yaml
gitlab_dedicated: yes
```

For pages with partial availability on GitLab Dedicated, use `gitlab_dedicated: yes`
and update the [product availability details](styleguide/availability_details.md)
for any topics that don't apply to GitLab Dedicated.

## Indicate lack of product availability details

On pages that purposely do not have availability details, add this metadata to the
top of the page:

```yaml
availability_details: no
```

## Additional metadata

The following metadata is optional and is not actively maintained.

- `feedback`: Set to `false` to not include the "Help & Feedback" footer.
- `noindex`: Set to `true` to prevent the page from being indexed by search engines.
- `redirect_to`: Used to control redirects. For more information, see [Redirects in GitLab documentation](redirects.md).
- `searchbar`: Set to `false` to not include the search bar in the page header.
- `toc`: Set to `false` to not include the "On this page" navigation.

## Batch updates for TW metadata

The [`CODEOWNERS`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/CODEOWNERS)
file contains a list of files and the associated technical writers.

When a merge request contains documentation, the information in the `CODEOWNERS` file determines:

- The list of users in the **Approvers** section.
- The technical writer that the GitLab Bot pings for community contributions.

You can use a Rake task to [update the `CODEOWNERS` file](#update-the-codeowners-file).

### Update the `CODEOWNERS` file

When groups or [TW assignments](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments)
change, you must update the `CODEOWNERS` file. To do this, you run the `codeowners.rake` Rake task.
This task checks all files in the `doc` directory, reads the metadata, and uses the information in
the `codeowners.rake` file to populate the `CODEOWNERS` file.

To update the `CODEOWNERS` file:

1. Update the [stage and group metadata](#stage-and-group-metadata) for any affected doc pages, if necessary. If there are many changes, you can do this step in a separate MR.
1. Update the [`codeowners.rake`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/tasks/gitlab/tw/codeowners.rake) file with the changes.
1. Go to the root of the `gitlab` repository.
1. Run the Rake task with this command: `bundle exec rake tw:codeowners`
1. Review the changes in the `CODEOWNERS` file.
1. Add and commit all your changes and push your branch up to `origin`.
1. Create a merge request and assign it to a technical writing manager for review.

When you update the `codeowners.rake` file:

- To specify multiple writers for a single group, use a space between writer names. Files are assigned to both writers.

  ```ruby
  CodeOwnerRule.new('Group Name', '@writer1 @writer2'),
  ```

  - To assign different writers in a group to documentation in different directories, use the `path` parameter to specify a directory:

    ```ruby
    CodeOwnerRule.new('Group Name', ->(path) { path.start_with?('/doc/user') ? '@writer1' : '@writer2' }),
    ```

    In this example, `writer1` is a code owner for files related to this group that are in `/doc/user`.
    For everything else, `writer2` is made code owner. For an example, see [MR 127903](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127903).

- For a group that does not have an assigned writer, include the group name in the file and comment out the line:

  ```ruby
  # CodeOwnerRule.new('Group Name', ''),
  ```

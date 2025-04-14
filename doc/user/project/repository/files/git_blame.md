---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Documentation on Git file blame.
title: Git file blame
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Git blame](https://git-scm.com/docs/git-blame) provides more information
about every line in a file, including the last modified time, author, and
commit hash.

## View blame for a file

{{< history >}}

- Viewing blame directly in the file view [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/430950) in GitLab 16.7 [with flag](../../../../administration/feature_flags.md) named `inline_blame`. Disabled by default.

{{< /history >}}

Prerequisites:

- The file type must be text-based. The GitLab UI does not display
  `git blame` results for binary files.

To view the blame for a file:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Repository**.
1. Select the file you want to review.
1. Either:
   - To change the view of the current file, in the file header, select **Blame**.
   - To open the full blame page, in the upper-right corner, select **Blame**.
1. Go to the line you want to see.

When you select **Blame**, this information is displayed:

![Git blame output](img/file_blame_output_v16_6.png "Blame button output")

To see the precise date and time of the commit, hover over the date. The vertical bar
to the left of the user avatar shows the general age of the commit. The newest
commits have a dark blue bar. As the age of the commit increases, the bar color
changes to light gray.

### Blame previous commit

To see earlier revisions of a specific line:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Repository**.
1. Select the file you want to review.
1. In the upper-right corner, select **Blame**, and go to the line you want to see.
1. Select **View blame prior to this change** ({{< icon name="doc-versions" >}})
   until you've found the changes you're interested in viewing.

### Ignore specific revisions

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/514684) in GitLab 17.10 [with a flag](../../../../administration/feature_flags.md) named `blame_ignore_revs`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/514325) in GitLab 17.10.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/525095) in GitLab 17.11. Feature flag `blame_ignore_revs` removed.
{{< /history >}}

To configure Git blame to ignore specific revisions:

1. In the root of your repository, create a `.git-blame-ignore-revs` file.
1. Add the commit hashes you want to ignore, one per line.
   For example:

   ```plaintext
   a24cb33c0e1390b0719e9d9a4a4fc0e4a3a069cc
   676c1c7e8b9e2c9c93e4d5266c6f3a50ad602a4c
   ```

1. Open a file in the blame view.
1. Select the **Blame preferences** dropdown list.
1. Select **Ignore specific revisions**.

The blame view refreshes and skips the revisions specified in the `.git-blame-ignore-revs` file,
showing the previous meaningful changes instead.

## Related topics

- [Git file blame REST API](../../../../api/repository_files.md#get-file-blame-from-repository)
- [Common Git commands](../../../../topics/git/commands.md)
- [File management with Git](../../../../topics/git/file_management.md)

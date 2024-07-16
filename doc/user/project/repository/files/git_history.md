---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "How to view a file's Git history in GitLab."
---

# Git file history

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Git file history provides information about the commit history associated
with a file:

![A list of 3 commits for a single file, with the newest commit marked as 'Verified'.](img/file_history_output_v17_2.png)

Each commit shows:

- The date of the commit. GitLab groups together all commits made on the same day.
- The user's avatar.
- The user's name. Hover over the name to see the user's job title, location, local time, and current status message.
- The date of the commit, in time-ago format. To see the precise date and time of
  the commit, hover over the date.
- If the [commit is signed](../signed_commits/index.md), a **Verified** badge.
- The commit SHA. GitLab shows the first 8 characters. Select **Copy commit SHA** (**{copy-to-clipboard}**) to copy the entire SHA.
- A link to **browse** (**{folder-open}**) the file as it appeared at the time of this commit.

GitLab retrieves the user name and email information from the
[Git configuration](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)
of the contributor when the user creates a commit.

## View a file's Git history in the UI

To see a file's Git history in the UI:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Repository**.
1. Go to your desired file in the repository.
1. In the upper-right corner, select **History**.

## In the CLI

To see the history of a file from the command line, use the `git log <filename>` command.
For example, to see `history` information about the `CONTRIBUTING.md` file in the root
of the `gitlab` repository, run this command:

```shell
$ git log CONTRIBUTING.md

commit b350bf041666964c27834885e4590d90ad0bfe90
Author: Nick Malcolm <nmalcolm@gitlab.com>
Date:   Fri Dec 8 13:43:07 2023 +1300

    Update security contact and vulnerability disclosure info

commit 8e4c7f26317ff4689610bf9d031b4931aef54086
Author: Brett Walker <bwalker@gitlab.com>
Date:   Fri Oct 20 17:53:25 2023 +0000

    Fix link to Code of Conduct

    and condense some of the verbiage
```

## Related topics

- [Git blame](git_blame.md) for line-by-line information about a file

## Troubleshooting

## Limit history range of results

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423108) in GitLab 16.9.

When reviewing history for old files, or files with many commits, you can
limit the search results by date. Limiting the dates for commits helps fix
[commit history requests timeouts](https://gitlab.com/gitlab-org/gitaly/-/issues/5426)
in very large repositories.

In the GitLab UI, edit the URL. Include these parameters in `YYYY-MM-DD` format:

- `committed_before`
- `committed_after`

Separate each key-value pair in the query string with an ampersand (`&`), like this:

```plaintext
?ref_type=heads&committed_after=2023-05-15&committed_before=2023-11-22
```

The full URL to the range of commits looks like this:

For example:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/commits/master/CONTRIBUTING.md?ref_type=heads&committed_after=2023-05-15&committed_before=2023-11-22
```

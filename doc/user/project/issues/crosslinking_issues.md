---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Crosslinking issues
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Crosslinking creates relationships between issues in GitLab.
Crosslinking:

- Connects related issues for better tracking and visibility.
- Links issues to their related commits and merge requests.
- Creates references through commit messages, branch names, and descriptions.
- Works across projects and groups.
- Shows relationships in each issue's **Linked items** section.

You can create crosslinks through:

- [Commit messages](#from-commit-messages)
- [Linked issues](#from-linked-issues)
- [Merge requests](#from-merge-requests)
- [Branch names](#from-branch-names)

## From commit messages

Every time you mention an issue in your commit message, you're creating
a relationship between the two stages of the development workflow: the
issue itself and the first commit related to that issue.

If the issue and the code you're committing are both in the same project,
add `#xxx` to the commit message, where `xxx` is the issue number.

```shell
git commit -m "this is my commit message. Ref #xxx"
```

Commit messages cannot usually begin with a `#` character, so you may use
the alternative `GL-xxx` notation as well:

```shell
git commit -m "GL-xxx: this is my commit message"
```

If they are in different projects, but in the same group,
add `projectname#xxx` to the commit message.

```shell
git commit -m "this is my commit message. Ref projectname#xxx"
```

If they are not in the same group, you can add the full URL to the issue
(`https://gitlab.com/<username>/<projectname>/-/issues/<xxx>`).

```shell
git commit -m "this is my commit message. Related to https://gitlab.com/<username>/<projectname>/-/issues/<xxx>"
```

Of course, you can replace `gitlab.com` with the URL of your own GitLab instance.

Linking your first commit to your issue is relevant
for tracking your process with [GitLab Value Stream Analytics](https://about.gitlab.com/solutions/value-stream-management/).
It measures the time taken for planning the implementation of that issue,
which is the time between creating an issue and making the first commit.

## From linked issues

Mentioning linked issues in merge requests and other issues helps your team members and
collaborators know that there are opened issues regarding the same topic.

When mentioning issue `#111` in issue `#222`, issue `#111` also displays a notification
in its **Activity** feed. That is, you only need to mention the relationship once for it to
display in both issues. The same is valid when mentioning issues in [merge requests](#from-merge-requests).

When the activity feed for an issue is filtered to **Show history only** or **Show all activity**,
crosslinks are shown as `(Username) mentioned in issue #(number) (time ago)`.

## From merge requests

Mentioning issues in merge request comments works exactly the same way as
they do for [linked issues](#from-linked-issues).

When you mention an issue in a merge request description, it
[links the issue and merge request together](#from-linked-issues). Additionally,
you can also [set an issue to close automatically](managing_issues.md#closing-issues-automatically)
as soon as the merge request is merged.

When the activity feed for an issue is filtered to **Show history only** or **Show all activity**,
crosslinks are shown as `(Username) mentioned in merge request !(number) (time ago)`.

## From branch names

When you create a branch in the same project as an issue and start the branch name with the issue
number, followed by a hyphen, the issue and MR you create are linked.
For more information, see
[Prefix branch names with issue numbers](../repository/branches/_index.md#prefix-branch-names-with-a-number).

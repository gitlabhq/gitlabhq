---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Crosslinking Issues

Please read through the [GitLab Issue Documentation](index.md) for an overview on GitLab Issues.

## From Commit Messages

Every time you mention an issue in your commit message, you're creating
a relationship between the two stages of the development workflow: the
issue itself and the first commit related to that issue.

If the issue and the code you're committing are both in the same project,
you simply add `#xxx` to the commit message, where `xxx` is the issue number.
If they are not in the same project, you can add the full URL to the issue
(`https://gitlab.com/<username>/<projectname>/issues/<xxx>`).

```shell
git commit -m "this is my commit message. Ref #xxx"
```

or

```shell
git commit -m "this is my commit message. Related to https://gitlab.com/<username>/<projectname>/issues/<xxx>"
```

Of course, you can replace `gitlab.com` with the URL of your own GitLab instance.

NOTE: **Note:** Linking your first commit to your issue is going to be relevant
for tracking your process with [GitLab Cycle Analytics](https://about.gitlab.com/stages-devops-lifecycle/value-stream-analytics/).
It will measure the time taken for planning the implementation of that issue,
which is the time between creating an issue and making the first commit.

## From Related Issues

Mentioning related issues in merge requests and other issues is useful
for your team members and collaborators to know that there are opened
issues regarding the same topic.

You do that as explained above, when [mentioning an issue from a commit message](#from-commit-messages).

When mentioning issue `#111` in issue `#222`, issue `#111` will also display a notification
in its tracker. That is, you only need to mention the relationship once for it to
display in both issues. The same is valid when mentioning issues in [merge requests](#from-merge-requests).

![issue mentioned in issue](img/mention_in_issue.png)

## From Merge Requests

Mentioning issues in merge request comments works exactly the same way as
they do for [related issues](#from-related-issues).

When you mention an issue in a merge request description, it will simply
[link the issue and merge request together](#from-related-issues). Additionally,
you can also [set an issue to close automatically](managing_issues.md#closing-issues-automatically)
as soon as the merge request is merged.

![issue mentioned in MR](img/mention_in_merge_request.png)

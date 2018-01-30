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

**Note:** Linking your first commit to your issue is going to be relevant
for tracking your process far ahead with
[GitLab Cycle Analytics](https://about.gitlab.com/features/cycle-analytics/)).
It will measure the time taken for planning the implementation of that issue,
which is the time between creating an issue and making the first commit.

## From Related Issues

Mentioning related issues in merge requests and other issues is useful
for your team members and collaborators to know that there are opened
issues around that same idea.

You do that as explained above, when
[mentioning an issue from a commit message](#from-commit-messages).

When mentioning the issue "A" in issue "B", the issue "A" will also
display a notification in its tracker. The same is valid for mentioning
issues in merge requests.

![issue mentioned in issue](img/mention_in_issue.png)

## From Merge Requests

Mentioning issues in merge request comments work exactly the same way
they do for [related issues](#from-related-issues). 

When you mention an issue in a merge request description, you can either
[close the issue as soon as the merge request is merged](closing_issues.md#via-merge-request),
or simply link both issue and merge request as described in the
[closing issues documentation](closing_issues.md#from-related-issues).

![issue mentioned in MR](img/mention_in_merge_request.png)

### Close an issue by merging a merge request

To [close an issue when a merge request is merged](closing_issues.md#via-merge-request), use the [automatic issue closing patern](automatic_issue_closing.md).

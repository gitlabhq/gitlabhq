# Closing Issues

Please read through the [GitLab Issue Documentation](index.md) for an overview on GitLab Issues.

## Directly

Whenever you decide that's no longer need for that issue,
close the issue using the close button:

![close issue - button](img/button_close_issue.png)

## Via Merge Request

When a merge request resolves the discussion over an issue, you can
make it close that issue(s) when merged.

All you need is to use a [keyword](automatic_issue_closing.md)
accompanying the issue number, add to the description of that MR.

In this example, the keyword "closes" prefixing the issue number will create a relationship
in such a way that the merge request will close the issue when merged. 

Mentioning various issues in the same line also works for this purpose:

```md
Closes #333, #444, #555 and #666
```

If the issue is in a different repository rather then the MR's,
add the full URL for that issue(s):

```md
Closes #333, #444, and https://gitlab.com/<username>/<projectname>/issues/<xxx>
```

All the following keywords will produce the same behaviour:

- Close, Closes, Closed, Closing, close, closes, closed, closing
- Fix, Fixes, Fixed, Fixing, fix, fixes, fixed, fixing
- Resolve, Resolves, Resolved, Resolving, resolve, resolves, resolved, resolving

![merge request closing issue when merged](img/merge_request_closes_issue.png)

If you use any other word before the issue number, the issue and the MR will
link to each other, but the MR will NOT close the issue(s) when merged.

![mention issues in MRs - closing and related](img/closing_and_related_issues.png)

## From the Issue Board

You can close an issue from [Issue Boards](../issue_board.md) by dragging an issue card
from its list and dropping into **Closed**.

![close issue from the Issue Board](img/close_issue_from_board.gif)

## Customizing the issue closing pattern

Alternatively, a GitLab **administrator** can
[customize the issue closing pattern](../../../administration/issue_closing_pattern.md).

# Issue closing pattern

When a commit or merge request resolves one or more issues, it is possible to
automatically have these issues closed when the commit or merge request lands
in the project's default branch.

If a commit message or merge request description contains a sentence matching
a certain regular expression, all issues referenced from the matched text will
be closed. This happens when the commit is pushed to a project's **default**
branch, or when a commit or merge request is merged into it.

## Default closing pattern value

When not specified, the default issue closing pattern as shown below will be
used:

```bash
((?:[Cc]los(?:e[sd]?|ing)|[Ff]ix(?:e[sd]|ing)?|[Rr]esolv(?:e[sd]?|ing))(:?) +(?:(?:issues? +)?%{issue_ref}(?:(?:, *| +and +)?)|([A-Z][A-Z0-9_]+-\d+))+)
```

Note that `%{issue_ref}` is a complex regular expression defined inside GitLab's
source code that can match a reference to 1) a local issue (`#123`),
2) a cross-project issue (`group/project#123`) or 3) a link to an issue
(`https://gitlab.example.com/group/project/issues/123`).

---

This translates to the following keywords:

- Close, Closes, Closed, Closing, close, closes, closed, closing
- Fix, Fixes, Fixed, Fixing, fix, fixes, fixed, fixing
- Resolve, Resolves, Resolved, Resolving, resolve, resolves, resolved, resolving

---

For example the following commit message:

```
Awesome commit message

Fix #20, Fixes #21 and Closes group/otherproject#22.
This commit is also related to #17 and fixes #18, #19
and https://gitlab.example.com/group/otherproject/issues/23.
```

will close `#18`, `#19`, `#20`, and `#21` in the project this commit is pushed
to, as well as `#22` and `#23` in group/otherproject. `#17` won't be closed as
it does not match the pattern. It works with multiline commit messages as well
as one-liners when used with `git commit -m`.

## Change the issue closing pattern

In order to change the pattern you need to have access to the server that GitLab
is installed on.

> **Tip:**
You are advised to use http://rubular.com to test the issue closing pattern.
Because Rubular doesn't understand `%{issue_ref}`, you can replace this by
`#\d+` when testing your patterns, which matches only local issue references
like `#123`.

**For Omnibus installations**

1. Open `/etc/gitlab/gitlab.rb` with your editor.
1. Change the value of `gitlab_rails['issue_closing_pattern']` to a regular
   expression of your liking:

    ```ruby
    gitlab_rails['issue_closing_pattern'] = "((?:[Cc]los(?:e[sd]|ing)|[Ff]ix(?:e[sd]|ing)?) +(?:(?:issues? +)?%{issue_ref}(?:(?:, *| +and +)?))+)"
    ```
1. [Reconfigure] GitLab for the changes to take effect.

**For installations from source**

1. Open [gitlab.yml][0] with your editor.
1. Change the value of `issue_closing_pattern`:

    ```yaml
    issue_closing_pattern: "((?:[Cc]los(?:e[sd]|ing)|[Ff]ix(?:e[sd]|ing)?) +(?:(?:issues? +)?%{issue_ref}(?:(?:, *| +and +)?))+)"
    ```

1. [Restart] GitLab for the changes to take effect.

[0]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/gitlab.yml.example
[1]: http://rubular.com/r/Xmbexed1OJ
[reconfigure]: restart_gitlab.md#omnibus-gitlab-reconfigure
[restart]: restart_gitlab.md#installations-from-source

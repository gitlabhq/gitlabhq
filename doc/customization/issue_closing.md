# Issue closing pattern

Here's how to close multiple issues in one commit message:

If a commit message matches the regular expression below, all issues referenced from
the matched text will be closed. This happens when the commit is pushed or merged
into the default branch of a project.

When not specified, the default issue_closing_pattern as shown below will be used:

```bash
((?:[Cc]los(?:e[sd]?|ing)|[Ff]ix(?:e[sd]|ing)?) +(?:(?:issues? +)?#\d+(?:(?:, *| +and +)?))+)
```

For example:

```
git commit -m "Awesome commit message (Fix #20, Fixes #21 and Closes #22). This commit is also related to #17 and fixes #18, #19 and #23."
```

will close `#20`, `#21`, `#22`, `#18`, `#19` and `#23`, but `#17` won't be closed
as it does not match the pattern. It also works with multiline commit messages.

Tip: you can test this closing pattern at [http://rubular.com][1]. Use this site
to test your own patterns.

## Change the pattern

For Omnibus installs you can change the default pattern in `/etc/gitlab/gitlab.rb`:

```
issue_closing_pattern: '((?:[Cc]los(?:e[sd]|ing)|[Ff]ix(?:e[sd]|ing)?) +(?:(?:issues? +)?#\d+(?:(?:, *| +and +)?))+)'
```

For manual installs you can customize the pattern in [gitlab.yml][0].

[0]: https://gitlab.com/gitlab-org/gitlab-ce/blob/40c3675372320febf5264061c9bcd63db2dfd13c/config/gitlab.yml.example#L65
[1]: http://rubular.com/r/Xmbexed1OJ
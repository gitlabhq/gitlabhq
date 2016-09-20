# Issue closing pattern

When a commit or merge request resolves one or more issues, it is possible to
automatically have these issues closed when the commit or merge request lands
in the project's default branch.

If a commit message or merge request description contains a sentence matching
the regular expression below, all issues referenced from the matched text will
be closed. This happens when the commit is pushed to a project's default branch,
or when a commit or merge request is merged into there.

When not specified, the default `issue_closing_pattern` as shown below will be
used:

```bash
((?:[Cc]los(?:e[sd]?|ing)|[Ff]ix(?:e[sd]|ing)?|[Rr]esolv(?:e[sd]?|ing))(:?) +(?:(?:issues? +)?%{issue_ref}(?:(?:, *| +and +)?)|([A-Z][A-Z0-9_]+-\d+))+)
```

Here, `%{issue_ref}` is a complex regular expression defined inside GitLab, that matches a reference to a local issue (`#123`), cross-project issue (`group/project#123`) or a link to an issue (`https://gitlab.example.com/group/project/issues/123`).

For example:

```
git commit -m "Awesome commit message (Fix #20, Fixes #21 and Closes group/otherproject#22). This commit is also related to #17 and fixes #18, #19 and https://gitlab.example.com/group/otherproject/issues/23."
```

will close `#18`, `#19`, `#20`, and `#21` in the project this commit is pushed to, as well as `#22` and `#23` in group/otherproject. `#17` won't be closed as it does not match the pattern. It also works with multiline commit messages.

Tip: you can test this closing pattern at [http://rubular.com][1]. Use this site
to test your own patterns.
Because Rubular doesn't understand `%{issue_ref}`, you can replace this by `#\d+` in testing, which matches only local issue references like `#123`.

## Change the pattern

For Omnibus installs you can change the default pattern in `/etc/gitlab/gitlab.rb`:

```
issue_closing_pattern: '((?:[Cc]los(?:e[sd]|ing)|[Ff]ix(?:e[sd]|ing)?) +(?:(?:issues? +)?%{issue_ref}(?:(?:, *| +and +)?))+)'
```

For manual installs you can customize the pattern in [gitlab.yml][0] using the `issue_closing_pattern` key.

[0]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/gitlab.yml.example
[1]: http://rubular.com/r/Xmbexed1OJ

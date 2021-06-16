---
stage: Create
group: Code Review
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Issue closing pattern **(FREE SELF)**

NOTE:
This is the administration documentation. There is a separate [user documentation](../user/project/issues/managing_issues.md#closing-issues-automatically)
on issue closing pattern.

When a commit or merge request resolves one or more issues, it is possible to
automatically close these issues when the commit or merge request lands
in the project's default branch.

## Change the issue closing pattern

In order to change the pattern you need to have access to the server that GitLab
is installed on.

The default pattern can be located in [`gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)
under the "Automatic issue closing" section.

NOTE:
You are advised to use <https://rubular.com> to test the issue closing pattern.
Because Rubular doesn't understand `%{issue_ref}`, you can replace this by
`#\d+` when testing your patterns, which matches only local issue references like `#123`.

**For Omnibus installations**

1. Open `/etc/gitlab/gitlab.rb` with your editor.
1. Change the value of `gitlab_rails['gitlab_issue_closing_pattern']` to a regular
   expression of your liking:

   ```ruby
   gitlab_rails['gitlab_issue_closing_pattern'] = /\b((?:[Cc]los(?:e[sd]?|ing)|\b[Ff]ix(?:e[sd]|ing)?|\b[Rr]esolv(?:e[sd]?|ing)|\b[Ii]mplement(?:s|ed|ing)?)(:?) +(?:(?:issues? +)?%{issue_ref}(?:(?: *,? +and +| *,? *)?)|([A-Z][A-Z0-9_]+-\d+))+)/.source
   ```

1. [Reconfigure](restart_gitlab.md#omnibus-gitlab-reconfigure) GitLab for the changes to take effect.

**For installations from source**

1. Open `gitlab.yml` with your editor.
1. Change the value of `issue_closing_pattern`:

   ```yaml
   issue_closing_pattern: "\b((?:[Cc]los(?:e[sd]?|ing)|\b[Ff]ix(?:e[sd]|ing)?|\b[Rr]esolv(?:e[sd]?|ing)|\b[Ii]mplement(?:s|ed|ing)?)(:?) +(?:(?:issues? +)?%{issue_ref}(?:(?: *,? +and +| *,? *)?)|([A-Z][A-Z0-9_]+-\d+))+)"
   ```

1. [Restart](restart_gitlab.md#installations-from-source) GitLab for the changes to take effect.

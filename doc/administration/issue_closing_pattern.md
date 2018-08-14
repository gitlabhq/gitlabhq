# Issue closing pattern

>**Note:**
This is the administration documentation.
There is a separate [user documentation] on issue closing pattern.

When a commit or merge request resolves one or more issues, it is possible to
automatically have these issues closed when the commit or merge request lands
in the project's default branch.

## Change the issue closing pattern

In order to change the pattern you need to have access to the server that GitLab
is installed on.

The default pattern can be located in [gitlab.yml.example] under the
"Automatic issue closing" section.

> **Tip:**
You are advised to use http://rubular.com to test the issue closing pattern.
Because Rubular doesn't understand `%{issue_ref}`, you can replace this by
`#\d+` when testing your patterns, which matches only local issue references like `#123`.

**For Omnibus installations**

1. Open `/etc/gitlab/gitlab.rb` with your editor.
1. Change the value of `gitlab_rails['gitlab_issue_closing_pattern']` to a regular
   expression of your liking:

    ```ruby
    gitlab_rails['gitlab_issue_closing_pattern'] = "((?:[Cc]los(?:e[sd]|ing)|[Ff]ix(?:e[sd]|ing)?) +(?:(?:issues? +)?%{issue_ref}(?:(?:, *| +and +)?))+)"
    ```
1. [Reconfigure] GitLab for the changes to take effect.

**For installations from source**

1. Open `gitlab.yml` with your editor.
1. Change the value of `issue_closing_pattern`:

    ```yaml
    issue_closing_pattern: "((?:[Cc]los(?:e[sd]|ing)|[Ff]ix(?:e[sd]|ing)?) +(?:(?:issues? +)?%{issue_ref}(?:(?:, *| +and +)?))+)"
    ```

1. [Restart] GitLab for the changes to take effect.

[gitlab.yml.example]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/gitlab.yml.example
[reconfigure]: restart_gitlab.md#omnibus-gitlab-reconfigure
[restart]: restart_gitlab.md#installations-from-source
[user documentation]: ../user/project/issues/automatic_issue_closing.md

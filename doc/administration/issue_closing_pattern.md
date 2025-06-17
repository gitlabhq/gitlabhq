---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Instance administrators can configure a custom issue closing pattern for their GitLab instance.
title: Issue closing pattern
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

For user documentation about issue closing patterns, see
[Closing issues automatically](../user/project/issues/managing_issues.md#closing-issues-automatically).

{{< /alert >}}

When a commit or merge request resolves one or more issues, GitLab can close those issues when the
commit or merge request lands in the project's default branch. The
[default issue closing pattern](../user/project/issues/managing_issues.md#default-closing-pattern)
covers a wide range of words, and administrators can configure the word list as needed.

## Change the issue closing pattern

To change the default issue closing pattern to suit your needs:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb` and change the `gitlab_rails['gitlab_issue_closing_pattern']`
   value:

   ```ruby
   gitlab_rails['gitlab_issue_closing_pattern'] = /<regular_expression>/.source
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml` and change the `issueClosingPattern` value:

   ```yaml
   global:
     appConfig:
       issueClosingPattern: "<regular_expression>"
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Edit `docker-compose.yml` and change the `gitlab_rails['gitlab_issue_closing_pattern']`
   value:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['gitlab_issue_closing_pattern'] = /<regular_expression>/.source
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Edit `/home/git/gitlab/config/gitlab.yml` and change the `issue_closing_pattern` value:

   ```yaml
   production: &base
     gitlab:
       issue_closing_pattern: "<regular_expression>"
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

To test the issue closing pattern, use [Rubular](https://rubular.com).
Rubular does not understand `%{issue_ref}`. When you test your patterns,
replace this string with `#\d+`, which matches only local issue references like `#123`.

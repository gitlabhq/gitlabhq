---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting conversion from CE to EE
---

When converting a Linux package installation from GitLab Community Edition
to GitLab Enterprise Edition, you might encounter the following issues.

## RPM 'package is already installed' error

If you are using RPM, you might get an error similar to:

```shell
package gitlab-7.5.2_omnibus.5.2.1.ci-1.el7.x86_64 (which is newer than gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64) is already installed
```

You can override this version check with the `--oldpackage` option:

```shell
sudo rpm -Uvh --oldpackage gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm
```

## Package obsoleted by installed package

Community Edition (CE) and Enterprise Edition (EE) packages are marked as obsoleting each other so that both aren't
installed at the same time.

If you are using local RPM files to switch from CE to EE or vice versa, use `rpm` for installing the package rather than
`yum`. If you try to use yum, then you may get an error like this:

```plaintext
Cannot install package gitlab-ee-11.8.3-ee.0.el6.x86_64. It is obsoleted by installed package gitlab-ce-11.8.3-ce.0.el6.x86_64
```

To avoid this issue, either:

- Use the same instructions provided in
  [Upgrade with a downloaded package](../package/_index.md#upgrade-with-a-downloaded-package) section.
- Temporarily disable this checking in yum by adding `--setopt=obsoletes=0` to the options given to the command.

## 500 error when accessing project repository settings

This error occurs when GitLab is converted from Community Edition (CE) to Enterprise Edition (EE), and then to
CE and then back to EE.

When viewing a project's repository settings, you can see this error in the logs:

```shell
Processing by Projects::Settings::RepositoryController#show as HTML
  Parameters: {"namespace_id"=>"<namespace_id>", "project_id"=>"<project_id>"}
Completed 500 Internal Server Error in 62ms (ActiveRecord: 4.7ms | Elasticsearch: 0.0ms | Allocations: 14583)

NoMethodError (undefined method `commit_message_negative_regex' for #<PushRule:0x00007fbddf4229b8>
Did you mean?  commit_message_regex_change):
```

This error is caused by an EE feature being added to a CE instance on the initial move to EE.
After the instance is moved back to CE and then is upgraded to EE again, the
`push_rules` table already exists in the database. Therefore, a migration is
unable to add the `commit_message_regex_change` column.

This results in the [backport migration of EE tables](https://gitlab.com/gitlab-org/gitlab/-/blob/cf00e431024018ddd82158f8a9210f113d0f4dbc/db/migrate/20190402150158_backport_enterprise_schema.rb#L1619)
not working correctly. The backport migration assumes that certain tables in the database do not exist when running CE.

To fix this issue:

1. Start a database console:

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

1. Manually add the missing `commit_message_negative_regex` column:

   ```sql
   ALTER TABLE push_rules ADD COLUMN commit_message_negative_regex VARCHAR;

   # Exit psql
   \q
   ```

1. Restart GitLab:

   ```shell
   sudo gitlab-ctl restart
   ```

---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting Geo failover
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

## Fixing errors during a failover or when promoting a secondary to a primary site

The following are possible error messages that might be encountered during failover or
when promoting a secondary to a primary site with strategies to resolve them.

### Message: `ActiveRecord::RecordInvalid: Validation failed: Name has already been taken`

When [promoting a **secondary** site](_index.md#step-3-promoting-a-secondary-site),
you might encounter the following error message:

```plaintext
Running gitlab-rake geo:set_secondary_as_primary...

rake aborted!
ActiveRecord::RecordInvalid: Validation failed: Name has already been taken
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:236:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:221:in `block (2 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Tasks: TOP => geo:set_secondary_as_primary
(See full trace by running task with --trace)

You successfully promoted this node!
```

If you encounter this message when running `gitlab-rake geo:set_secondary_as_primary`
or `gitlab-ctl promote-to-primary-node`, enter a Rails console and run:

  ```ruby
  Rails.application.load_tasks; nil
  Gitlab::Geo.expire_cache!
  Rake::Task['geo:set_secondary_as_primary'].invoke
  ```

### Message: ``NoMethodError: undefined method `secondary?' for nil:NilClass``

When [promoting a **secondary** site](_index.md#step-3-promoting-a-secondary-site),
you might encounter the following error message:

```plaintext
sudo gitlab-rake geo:set_secondary_as_primary

rake aborted!
NoMethodError: undefined method `secondary?' for nil:NilClass
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:232:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:221:in `block (2 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Tasks: TOP => geo:set_secondary_as_primary
(See full trace by running task with --trace)
```

This command is intended to be executed on a secondary site only, and this error message
is displayed if you attempt to run this command on a primary site.

### Expired artifacts

If you notice for some reason there are more artifacts on the Geo
**secondary** site than on the Geo **primary** site, you can use the Rake task
to [cleanup orphan artifact files](../../../raketasks/cleanup.md#remove-orphan-artifact-files)

On a Geo **secondary** site, this command also cleans up all Geo
registry record related to the orphan files on disk.

### Fixing sign in errors

#### Message: The redirect URI included is not valid

If you are able to sign in to the web interface for the **primary** site, but you receive this error message
when attempting to sign in to a **secondary** web interface, you should verify the Geo
site's URL matches its external URL.

On the **primary** site:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Geo > Sites**.
1. Find the affected **secondary** site and select **Edit**.
1. Ensure the **URL** field matches the value found in `/etc/gitlab/gitlab.rb`
   in `external_url "https://gitlab.example.com"` on the **Rails nodes of the secondary** site.

#### Authenticating with SAML on the secondary site always lands on the primary site

This [problem is usually encountered when upgrading to GitLab 15.1](../../../update/versions/gitlab_15_changes.md#1510). To fix this problem, see [configuring instance-wide SAML in Geo with Single Sign-On](../replication/single_sign_on.md#configuring-instance-wide-saml).

## Recovering from a partial failover

The partial failover to a secondary Geo *site* may be the result of a temporary/transient issue. Therefore, first attempt to run the promote command again.

1. SSH into every Sidekiq, PostgreSQL, Gitaly, and Rails node in the **secondary** site and run one of the following commands:

   - To promote the secondary site to primary:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - To promote the secondary site to primary **without any further confirmation**:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. Verify you can connect to the newly-promoted **primary** site using the URL used previously for the **secondary** site.
1. If **successful**, the **secondary** site is now promoted to the **primary** site.

If the above steps are **not successful**, proceed through the next steps:

1. SSH to every Sidekiq, PostgreSQL, Gitaly and Rails node in the **secondary** site and perform the following operations:

   - Create a `/etc/gitlab/gitlab-cluster.json` file with the following content:

     ```shell
     {
       "primary": true,
       "secondary": false
     }
     ```

   - Reconfigure GitLab for the changes to take effect:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

1. Verify you can connect to the newly-promoted **primary** site using the URL used previously for the **secondary** site.
1. If successful, the **secondary** site is now promoted to the **primary** site.

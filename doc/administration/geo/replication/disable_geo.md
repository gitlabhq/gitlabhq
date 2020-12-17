---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Disabling Geo **(PREMIUM ONLY)**

If you want to revert to a regular Omnibus setup after a test, or you have encountered a Disaster Recovery
situation and you want to disable Geo momentarily, you can use these instructions to disable your
Geo setup.

There should be no functional difference between disabling Geo and having an active Geo setup with
no secondary Geo nodes if you remove them correctly.

To disable Geo, follow these steps:

1. [Remove all secondary Geo nodes](#remove-all-secondary-geo-nodes).
1. [Remove the primary node from the UI](#remove-the-primary-node-from-the-ui).
1. [Remove secondary replication slots](#remove-secondary-replication-slots).
1. [Remove Geo-related configuration](#remove-geo-related-configuration).
1. [(Optional) Revert PostgreSQL settings to use a password and listen on an IP](#optional-revert-postgresql-settings-to-use-a-password-and-listen-on-an-ip).

## Remove all secondary Geo nodes

To disable Geo, you need to first remove all your secondary Geo nodes, which means replication will not happen
anymore on these nodes. You can follow our docs to [remove your secondary Geo nodes](remove_geo_node.md).

If the current node that you want to keep using is a secondary node, you need to first promote it to primary.
You can use our steps on [how to promote a secondary node](../disaster_recovery/#step-3-promoting-a-secondary-node)
to do that.

## Remove the primary node from the UI

1. Go to **Admin Area > Geo** (`/admin/geo/nodes`).
1. Click the **Remove** button for the **primary** node.
1. Confirm by clicking **Remove** when the prompt appears.

## Remove secondary replication slots

To remove secondary replication slots, run one of the following queries on your primary
Geo node in a PostgreSQL console (`sudo gitlab-psql`):

- If you already have a PostgreSQL cluster, drop individual replication slots by name to prevent
  removing your secondary databases from the same cluster. You can use the following to get
  all names and then drop each individual slot:

  ```sql
  SELECT slot_name, slot_type, active FROM pg_replication_slots; -- view present replication slots
  SELECT pg_drop_replication_slot('slot_name'); -- where slot_name is the one expected from above
  ```

- To remove all secondary replication slots:

  ```sql
  SELECT pg_drop_replication_slot(slot_name) FROM pg_replication_slots;
  ```

## Remove Geo-related configuration

1. SSH into your primary Geo node and log in as root:

   ```shell
   sudo -i
   ```

1. Edit `/etc/gitlab/gitlab.rb` and remove the Geo related configuration by
   removing any lines that enabled `geo_primary_role`:

   ```ruby
   ## In pre-11.5 documentation, the role was enabled as follows. Remove this line.
   geo_primary_role['enable'] = true

   ## In 11.5+ documentation, the role was enabled as follows. Remove this line.
   roles ['geo_primary_role']
   ```

1. After making these changes, [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

## (Optional) Revert PostgreSQL settings to use a password and listen on an IP

If you want to remove the PostgreSQL-specific settings and revert
to the defaults (using a socket instead), you can safely remove the following
lines from the `/etc/gitlab/gitlab.rb` file:

```ruby
postgresql['sql_user_password'] = '...'
gitlab_rails['db_password'] = '...'
postgresql['listen_address'] = '...'
postgresql['md5_auth_cidr_addresses'] =  ['...', '...']
```

---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Removing secondary Geo sites
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

**Secondary** sites can be removed from the Geo cluster using the Geo administration page of the **primary** site. To remove a **secondary** site:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Geo > Nodes**.
1. For the **secondary** site you want to remove, select **Remove**.
1. Confirm by selecting **Remove** when the prompt appears.

After the **secondary** site is removed from the Geo administration page, you must
stop and uninstall this site. For each node on your secondary Geo site:

1. Stop GitLab:

   ```shell
   sudo gitlab-ctl stop
   ```

1. Uninstall GitLab:

   NOTE:
   If GitLab data has to be cleaned from the instance as well, see how to [uninstall the Linux package and all its data](https://docs.gitlab.com/omnibus/installation/#uninstall-the-linux-package-omnibus).

   ```shell
   # Stop gitlab and remove its supervision process
   sudo gitlab-ctl uninstall

   # Debian/Ubuntu
   sudo dpkg --remove gitlab-ee

   # Redhat/Centos
   sudo rpm --erase gitlab-ee
   ```

When GitLab has been uninstalled from each node on the **secondary** site, the replication slot must be dropped from the **primary** site's database as follows:

1. On the **primary** site's database node, start a PostgreSQL console session:

   ```shell
   sudo gitlab-psql
   ```

   NOTE:
   Using `gitlab-rails dbconsole` does not work, because managing replication slots requires superuser permissions.

1. Find the name of the relevant replication slot. This is the slot that is specified with `--slot-name` when running the replicate command: `gitlab-ctl replicate-geo-database`.

   ```sql
   SELECT * FROM pg_replication_slots;
   ```

1. Remove the replication slot for the **secondary** site:

   ```sql
   SELECT pg_drop_replication_slot('<name_of_slot>');
   ```

---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Updating the Geo nodes **(PREMIUM SELF)**

WARNING:
Read these sections carefully before updating your Geo nodes. Not following
version-specific update steps may result in unexpected downtime. If you have
any specific questions, [contact Support](https://about.gitlab.com/support/#contact-support).

Updating Geo nodes involves performing:

1. [Version-specific update steps](version_specific_updates.md), depending on the
   version being updated to or from.
1. [General update steps](#general-update-steps), for all updates.

## General update steps

NOTE:
These general update steps are not intended for [high-availability deployments](https://docs.gitlab.com/omnibus/update/README.html#multi-node--ha-deployment), and will cause downtime. If you want to avoid downtime, consider using [zero downtime updates](https://docs.gitlab.com/omnibus/update/README.html#zero-downtime-updates).

To update the Geo nodes when a new GitLab version is released, update **primary**
and all **secondary** nodes:

1. **Optional:** [Pause replication on each **secondary** node.](../index.md#pausing-and-resuming-replication)
1. Log into the **primary** node.
1. [Update GitLab on the **primary** node using Omnibus](https://docs.gitlab.com/omnibus/update/#update-using-the-official-repositories).
1. Log into each **secondary** node.
1. [Update GitLab on each **secondary** node using Omnibus](https://docs.gitlab.com/omnibus/update/#update-using-the-official-repositories).
1. If you paused replication in step 1, [resume replication on each **secondary**](../index.md#pausing-and-resuming-replication)
1. [Test](#check-status-after-updating) **primary** and **secondary** nodes, and check version in each.

### Check status after updating

Now that the update process is complete, you may want to check whether
everything is working correctly:

1. Run the Geo Rake task on all nodes, everything should be green:

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

1. Check the **primary** node's Geo dashboard for any errors.
1. Test the data replication by pushing code to the **primary** node and see if it
   is received by **secondary** nodes.

If you encounter any issues, see the [Geo troubleshooting guide](troubleshooting.md).

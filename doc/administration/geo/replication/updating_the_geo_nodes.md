# Updating the Geo nodes **(PREMIUM ONLY)**

Updating Geo nodes involves performing:

1. [Version-specific update steps](#version-specific-update-steps), depending on the
   version being updated to or from.
1. [General update steps](#general-update-steps), for all updates.

## Version specific update steps

Depending on which version of Geo you are updating to/from, there may be
different steps.

- [Updating to GitLab 12.1](version_specific_updates.md#updating-to-gitlab-121)
- [Updating to GitLab 10.8](version_specific_updates.md#updating-to-gitlab-108)
- [Updating to GitLab 10.6](version_specific_updates.md#updating-to-gitlab-106)
- [Updating to GitLab 10.5](version_specific_updates.md#updating-to-gitlab-105)
- [Updating to GitLab 10.3](version_specific_updates.md#updating-to-gitlab-103)
- [Updating to GitLab 10.2](version_specific_updates.md#updating-to-gitlab-102)
- [Updating to GitLab 10.1](version_specific_updates.md#updating-to-gitlab-101)
- [Updating to GitLab 10.0](version_specific_updates.md#updating-to-gitlab-100)
- [Updating from GitLab 9.3 or older](version_specific_updates.md#updating-from-gitlab-93-or-older)
- [Updating to GitLab 9.0](version_specific_updates.md#updating-to-gitlab-90)

## General update steps

NOTE: **Note:** These general update steps are not intended for [high-availability deployments](https://docs.gitlab.com/omnibus/update/README.html#multi-node--ha-deployment), and will cause downtime. If you want to avoid downtime, consider using [zero downtime updates](https://docs.gitlab.com/omnibus/update/README.html#zero-downtime-updates).

To update the Geo nodes when a new GitLab version is released, update **primary**
and all **secondary** nodes:

1. Log into the **primary** node.
1. [Update GitLab on the **primary** node using Omnibus](https://docs.gitlab.com/omnibus/update/README.html).
1. Log into each **secondary** node.
1. [Update GitLab on each **secondary** node using Omnibus](https://docs.gitlab.com/omnibus/update/README.html).
1. [Test](#check-status-after-updating) **primary** and **secondary** nodes, and check version in each.

### Check status after updating

Now that the update process is complete, you may want to check whether
everything is working correctly:

1. Run the Geo raketask on all nodes, everything should be green:

   ```sh
   sudo gitlab-rake gitlab:geo:check
   ```

1. Check the **primary** node's Geo dashboard for any errors.
1. Test the data replication by pushing code to the **primary** node and see if it
   is received by **secondary** nodes.

If you encounter any issues, please consult the [Geo troubleshooting guide](troubleshooting.md).

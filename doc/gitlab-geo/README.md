## GitLab Geo (EE)

GitLab Geo allows you to replicate your GitLab instance to other
geographical locations as a read-only fully operational version.

When Geo is enabled, we reffer to your original instance as a **primary**
node and the replicated read-only ones as **secondaries**.

GitLab Geo requires some additional work installing and configuring your
instance, than a normal setup.

### Primary Node

To make your day-use instance a primary Geo node, you access your
administration screen and go to Gitlab Geo `/admin/geo_nodes`.

You must add your instance address the same way it is configured on
your `gitlab.yml`, select **this is a primary node** and save.

### Secondary Node

To install a secondary node, you must follow your normal install
instructions with some extra requirements:
 
 * You must replicate your database to this instance.
 * Primary node must be able to access this instance by HTTP/HTTPS

### Current limitations

 * You cannot push code to secondary nodes
 * Git LFS is not supported yet
 * Git Annex is not supported yet

### Frequently Asked Questions

 * Can I use Geo in a disaster recovery situation?
 
Gitlab Geo was not made with that in mind. There are limitations to what
we replicate (see Current limitations). In an extreme data-loss situation
you can make a secondary Geo into your primary, but this is not officially
supported.

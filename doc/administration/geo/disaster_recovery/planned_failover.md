# Disaster recovery for planned failover

A planned failover is similar to a disaster recovery scenario, except you are able
to notify users of the maintenance window, and allow data to finish replicating to
secondaries.

Please read this entire document as well as [Disaster Recovery][disaster-recovery]
before proceeding.

## Notify users of scheduled maintenance

On the primary, navigate to **Admin Area > Messages**, add a broadcast message.
You can check under **Admin Area > Geo Nodes** to estimate how long it will
take to finish syncing. An example message would be:

> A scheduled maintenance will take place at XX:XX UTC. We expect it to take
  less than 1 hour.

On the secondary, you may need to clear the cache for the broadcast message
to show up.

## Block primary traffic

At the scheduled time, using your cloud provider or your node's firewall, block
HTTP and SSH traffic to/from the primary except for your IP and the secondary's
IP.

## Allow replication to finish as much as possible

1. On the secondary, navigate to **Admin Area > Geo Nodes** and wait until all
   replication progress is 100% on the secondary "Current node".
1. Navigate to **Admin Area > Monitoring > Background Jobs > Queues** and wait
   until the "geo" queues drop ideally to 0.

## Promote the secondary

Finally, follow the [Disaster Recovery docs][disaster-recovery] to promote the secondary
to a primary.

[disaster-recovery]: index.md

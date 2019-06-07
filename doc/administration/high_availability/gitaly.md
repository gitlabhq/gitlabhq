# Configuring Gitaly for Scaled and High Availability

Gitaly does not yet support full high availability. However, Gitaly is quite
stable and is in use on GitLab.com. Scaled and highly available GitLab environments
should consider using Gitaly on a separate node. 

See the [Gitaly HA Epic](https://gitlab.com/groups/gitlab-org/-/epics/289) to 
track plans and progress toward high availability support. 

This document is relevant for [Scaled Architecture](README.md#scalable-architecture-examples)
environments and [High Availability Architecture](README.md#high-availability-architecture-examples). 

## Running Gitaly on its own server

See [Running Gitaly on its own server](../gitaly/index.md#running-gitaly-on-its-own-server)
in Gitaly documentation.

Continue configuration of other components by going back to:

- [Scaled Architectures](README.md#scalable-architecture-examples)
- [High Availability Architectures](README.md#high-availability-architecture-examples)

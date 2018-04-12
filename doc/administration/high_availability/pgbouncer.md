# Working with the bundle Pgbouncer service

## Overview

As part of its High Availability stack, GitLab Premium includes a bundled version of [Pgbouncer](https://pgbouncer.github.io/) that can be managed through `/etc/gitlab/gitlab.rb`.

In a High Availability setup, Pgbounce is used to seamlessly migrate database connections between servers in a failover scenario.

Additionally, it can be used in a non-HA setup to pool connections, speeding up response time while reducing resource usage.

It is recommended to run pgbouncer alongside the `gitlab-rails` service, or on its own dedicated node in a cluster.

## Operations

### Running Pgbouncer as part of an HA GitLab installation
See our [HA documentation for PostgreSQL](database.md) for information on running pgbouncer as part of a HA setup

### Running Pgbouncer as part of a non-HA GitLab installation

### Interacting with pgbouncer

## Troubleshooting

### Debugging connection issues


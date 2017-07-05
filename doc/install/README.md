# Installation

GitLab can be installed via various ways. Check the [installation methods][methods]
for an overview.

## Requirements

Before installing GitLab, make sure to check the [requirements documentation](requirements.md)
which includes useful information on the supported Operating Systems as well as
the hardware requirements.

## Installation methods

- [Installation using the Omnibus packages](https://about.gitlab.com/downloads/) -
  Install GitLab using our official deb/rpm repositories. This is the
  recommended way.
- [Installation from source](installation.md) - Install GitLab from source.
  Useful for unsupported systems like *BSD. For an overview of the directory
  structure, read the [structure documentation](structure.md).
- [Docker](https://docs.gitlab.com/omnibus/docker/) - Install GitLab using Docker.
- [Installing in Kubernetes](kubernetes/index.md) - Install GitLab into a Kubernetes
  Cluster using our official Helm Chart Repository.
- Testing only! [DigitalOcean and Docker Machine](digitaloceandocker.md) -
  Quickly test any version of GitLab on DigitalOcean using Docker Machine.
- [GitLab Pivotal Tile](pivotal/index.md) - Install and configure GitLab
  Enterprise Edition Premium on Pivotal Cloud Foundry.

## Database

While the recommended database is PostgreSQL, we provide information to install
GitLab using MySQL. Check the [MySQL documentation](database_mysql.md) for more
information.

[methods]: https://about.gitlab.com/installation/

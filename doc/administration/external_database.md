# Configure GitLab using an external PostgreSQL service

If you're hosting GitLab on a cloud provider, you can optionally use a
managed service for PostgreSQL. For example, AWS offers a managed Relational
Database Service (RDS) that runs PostgreSQL.

Alternatively, you may opt to manage your own PostgreSQL instance or cluster
separate from the GitLab Omnibus package.

If you use a cloud-managed service, or provide your own PostgreSQL instance:

1. Setup PostgreSQL according to the
   [database requirements document](../install/requirements.md#database).
1. Set up a `gitlab` username with a password of your choice. The `gitlab` user
   needs privileges to create the `gitlabhq_production` database.
1. Configure the GitLab application servers with the appropriate details.
   This step is covered in [Configuring GitLab for HA](high_availability/gitlab.md).

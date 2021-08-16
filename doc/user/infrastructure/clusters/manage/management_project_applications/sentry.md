---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Install Sentry with a cluster management project

> [Introduced](https://gitlab.com/gitlab-org/project-templates/cluster-management/-/merge_requests/5) in GitLab 14.0.

The Sentry Helm chart [recommends](https://github.com/helm/charts/blob/f6e5784f265dd459c5a77430185d0302ed372665/stable/sentry/values.yaml#L284-L285)
at least 3 GB of available RAM for database migrations.

Assuming you already have a [Cluster management project](../../../../../user/clusters/management_project.md) created from a
[management project template](../../../../../user/clusters/management_project_template.md), to install Sentry you should
uncomment this line from your `helmfile.yaml`:

```yaml
  - path: applications/sentry/helmfile.yaml
```

Sentry is installed by default into the `gitlab-managed-apps` namespace
of your cluster.

You can customize the installation of Sentry by defining
`applications/sentry/values.yaml` file in your cluster
management project. Refer to the
[chart](https://github.com/helm/charts/tree/master/stable/sentry)
for the available configuration options.

We recommend you pay close attention to the following configuration options:

- `email`. Needed to invite users to your Sentry instance and to send error emails.
- `user`. Where you can set the login credentials for the default administrator user.
- `postgresql`. For a PostgreSQL password that can be used when running future updates.

When upgrading, it's important to provide the existing PostgreSQL password (given
using the `postgresql.postgresqlPassword` key) to avoid authentication errors.
Read the [PostgreSQL chart documentation](https://github.com/helm/charts/tree/master/stable/postgresql#upgrade)
for more information.

Here is an example configuration for Sentry:

```yaml
# Admin user to create
user:
  # Indicated to create the admin user or not,
  # Default is true as the initial installation.
  create: true
  email: "<your email>"
  password: "<your password>"

email:
  from_address: "<your from email>"
  host: smtp
  port: 25
  use_tls: false
  user: "<your email username>"
  password: "<your email password>"
  enable_replies: false

ingress:
  enabled: true
  hostname: "<sentry.example.com>"

# Needs to be here between runs.
# See https://github.com/helm/charts/tree/master/stable/postgresql#upgrade for more info
postgresql:
  postgresqlPassword: example-postgresql-password
```

Support for installing the Sentry managed application is provided by the
GitLab Health group. If you run into unknown issues,
[open a new issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new), and ping at
least 2 people from the
[Health group](https://about.gitlab.com/handbook/product/categories/#health-group).

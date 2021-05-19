---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Steps after installing GitLab

Here are a few resources you might want to check out after completing the
installation.

## License

- [Upload a license](../user/admin_area/license.md) or [start a free trial](https://about.gitlab.com/free-trial/):
  Activate all GitLab Enterprise Edition functionality with a license.
- [Pricing](https://about.gitlab.com/pricing/): Pricing for the different tiers.

## Security

- [Secure GitLab](../security/README.md#securing-your-gitlab-installation):
  Recommended practices to secure your GitLab instance.

## Authentication

- [LDAP](../administration/auth/ldap/index.md): Configure LDAP to be used as
  an authentication mechanism for GitLab.

## Email and notifications

- [SMTP](https://docs.gitlab.com/omnibus/settings/smtp.html): Configure SMTP
  for proper email notifications support.

## Backup and upgrade

- [Back up and restore GitLab](../raketasks/backup_restore.md): Learn the different
  ways you can back up or restore GitLab.
- [Upgrade GitLab](../update/index.md): Every 22nd of the month, a new feature-rich GitLab version
  is released. Learn how to upgrade to it, or to an interim release that contains a security fix.
- [Release and maintenance policy](../policy/maintenance.md): Learn about GitLab
  policies governing version naming, as well as release pace for major, minor, patch,
  and security releases.

## CI/CD

- [Set up runners](https://docs.gitlab.com/runner/): Set up one or more GitLab
  Runners, the agents that are responsible for all of the GitLab CI/CD features.
- [GitLab Pages](../administration/pages/index.md): Configure GitLab Pages to
  allow hosting of static sites.
- [GitLab Registry](../administration/packages/container_registry.md): With the
  GitLab Container Registry, every project can have its own space to store Docker
  images.

## Scaling and replication

- [Scaling GitLab](../administration/reference_architectures/index.md):
  GitLab supports several different types of clustering.
- [Geo replication](../administration/geo/index.md):
  Geo is the solution for widely distributed development teams.

## Search

- [Advanced Search](../integration/elasticsearch.md): Leverage Elasticsearch for
  faster, more advanced code search across your entire GitLab instance.

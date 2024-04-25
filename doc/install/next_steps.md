---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Steps after installing GitLab

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

Here are a few resources you might want to check out after completing the
installation.

## Email and notifications

- [SMTP](https://docs.gitlab.com/omnibus/settings/smtp.html): Configure SMTP
  for proper email notifications support.

## CI/CD

- [Set up runners](https://docs.gitlab.com/runner/): Set up one or more
  runners, the agents that are responsible for running CI/CD jobs.
- [GitLab Pages](../administration/pages/index.md): Configure GitLab Pages to
  allow hosting of static sites.
- [GitLab Registry](../administration/packages/container_registry.md): Set up the
  GitLab container registry so every project can have its own space to store Docker
  images.
- [GitLab Dependency Proxy](../administration/packages/dependency_proxy.md): Set up the dependency
  proxy so you can cache container images from Docker Hub for faster, more reliable builds.

## Security

- [Secure GitLab](../security/index.md):
  Recommended practices to secure your GitLab instance.
- Sign up for the GitLab [Security Newsletter](https://about.gitlab.com/company/preference-center/) to get notified for security updates upon release.

## Authentication

- [LDAP](../administration/auth/ldap/index.md): Configure LDAP to be used as
  an authentication mechanism for GitLab.
- [SAML and OAuth](../integration/omniauth.md): Authenticate via online services like Okta, Google, Azure AD, and more.

## Backup and upgrade

- [Back up and restore GitLab](../administration/backup_restore/index.md): Learn the different
  ways you can back up or restore GitLab.
- [Upgrade GitLab](../update/index.md): Every month, a new feature-rich GitLab version
  is released. Learn how to upgrade to it, or to an interim release that contains a security fix.
- [Release and maintenance policy](../policy/maintenance.md): Learn about GitLab
  policies governing version naming, as well as release pace for major, minor and patch releases.

## License

- [Add a license](../administration/license.md) or [start a free trial](https://about.gitlab.com/free-trial/):
  Activate all GitLab Enterprise Edition functionality with a license.
- [Pricing](https://about.gitlab.com/pricing/): Pricing for the different tiers.

## Cross-repository Code Search

- [Advanced search](../integration/advanced_search/elasticsearch.md): Leverage [Elasticsearch](https://www.elastic.co/) or [OpenSearch](https://opensearch.org/) for
  faster, more advanced code search across your entire GitLab instance.

## Scaling and replication

- [Scaling GitLab](../administration/reference_architectures/index.md):
  GitLab supports several different types of clustering.
- [Geo replication](../administration/geo/index.md):
  Geo is the solution for widely distributed development teams.

## Install the product documentation

This is an optional step. If you want to host the documentation on your own
server, see how to [self-host the product documentation](../administration/docs_self_host.md).

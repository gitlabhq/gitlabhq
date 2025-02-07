---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting a GitLab installation
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

This page documents a collection of resources to help you troubleshoot a GitLab
installation.

This list is not necessarily comprehensive. If you don't find what you're looking
for in this list, you should search the documentation.

## Troubleshooting guides

- [SSL](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting.html)
- [Geo](../geo/replication/troubleshooting/_index.md)
- [SAML](../../user/group/saml_sso/troubleshooting.md)
- [Kubernetes cheat sheet](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet.html)
- [Linux cheat sheet](linux_cheat_sheet.md)
- [Parsing GitLab logs with `jq`](../logs/log_parsing.md)
- [Diagnostics tools](diagnostics_tools.md)

Some feature documentation pages also have a troubleshooting section at the end
that you can check for feature-specific help, including helpful Rails commands.

If you need a testing environment to troubleshoot, see the
[apps for a testing environment](test_environments.md).

## Support team troubleshooting info

The GitLab Support Team has collected a lot of information about troubleshooting GitLab.
The following documents are used by the Support Team or by customers
with direct guidance from a Support Team member. GitLab administrators may find the
information useful for troubleshooting. However, if you are experiencing trouble with your
GitLab instance, you should check your [support options](https://about.gitlab.com/support/)
before referring to these documents.

WARNING:
The commands in the following documentation might result in data loss or
other damage to a GitLab instance. They should be used only by experienced administrators
who are aware of the risks.

- [Diagnostics tools](diagnostics_tools.md)
- [Linux commands](linux_cheat_sheet.md)
- [Troubleshooting Kubernetes](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet.html)
- [Troubleshooting PostgreSQL](postgresql.md)
- [Guide to test environments](test_environments.md) (for Support Engineers)
- [Troubleshooting SSL](https://docs.gitlab.com/omnibus/settings/ssl/ssl_troubleshooting.html)
- Related links:
  - [Repairing and recovering broken Git repositories](https://git.seveas.net/repairing-and-recovering-broken-git-repositories.html)
  - [Testing with OpenSSL](https://www.feistyduck.com/library/openssl-cookbook/online/testing-with-openssl/index.html)
  - [`strace` zine](https://wizardzines.com/zines/strace/)

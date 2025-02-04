---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: X.509 signatures Rake task
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

When [signing commits with X.509](../user/project/repository/signed_commits/x509.md),
the trust anchor might change and the signatures stored in the database must be updated.

## Update all X.509 signatures

This task:

- Iterates through all X.509-signed commits.
- Updates their verification status based on the current certificate store.
- Modifies only the database entries for the signatures.
- Leaves the commits unchanged.

To update all X.509 signatures, run:

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-rake gitlab:x509:update_signatures
```

:::TabTitle Self-compiled (source)

```shell
sudo -u git -H bundle exec rake gitlab:x509:update_signatures RAILS_ENV=production
```

::EndTabs

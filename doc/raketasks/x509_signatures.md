---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# X.509 signatures **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/122159) in GitLab 12.10.

When [signing commits with X.509](../user/project/repository/x509_signed_commits/index.md),
the trust anchor might change and the signatures stored within the database must be updated.

## Update all X.509 signatures

This task loops through all X.509 signed commits and updates their verification based on current
certificate store.

To update all X.509 signatures, run:

**Omnibus Installations:**

```shell
sudo gitlab-rake gitlab:x509:update_signatures
```

**Source Installations:**

```shell
sudo -u git -H bundle exec rake gitlab:x509:update_signatures RAILS_ENV=production
```

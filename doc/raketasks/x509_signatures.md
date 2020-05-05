# X.509 signatures **(CORE ONLY)**

When [signing commits with X.509](../user/project/repository/x509_signed_commits/index.md),
the trust anchor might change and the signatures stored within the database must be updated.

## Update all X.509 signatures

This task loops through all X.509 signed commits and updates their verification based on current
certificate store.

To update all X.509 signatures, run:

**Omnibus Installation**

```shell
sudo gitlab-rake gitlab:x509:update_signatures
```

**Source Installation**

```shell
sudo -u git -H bundle exec rake gitlab:x509:update_signatures RAILS_ENV=production
```

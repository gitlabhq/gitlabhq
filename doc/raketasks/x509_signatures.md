# X509 signatures

When [signing commits with x509](../user/project/repository/x509_signed_commits/index.md)
the trust anchor might change and the signatures stored within the database have
to be updated.

## Update all x509 signatures

This task loops through all X509 signed commits and updates their verification
based on current certificate store.

**Omnibus Installation**

```shell
sudo gitlab-rake gitlab:x509:update_signatures
```

**Source Installation**

```shell
sudo -u git -H bundle exec rake gitlab:x509:update_signatures RAILS_ENV=production
```

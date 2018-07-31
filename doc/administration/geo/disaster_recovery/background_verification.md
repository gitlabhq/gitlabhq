# Automatic background verification **[PREMIUM ONLY]**

NOTE: **Note:**
Automatic background verification of repositories and wikis was added in
GitLab EE 10.6 but is enabled by default only on Gitlab EE 11.1. You can
disable or enable this feature manually by following
[these instructions][feature-flag].

Automatic backgorund verification ensures that the transferred data matches a
calculated checksum, proving that the content on the **secondary** matches that
on the **primary**. Following a planned failover, any corrupted data may be
**lost**, depending on the extent of the corruption.

If verification fails on the **primary**, this indicates that Geo is
successfully replicating a corrupted object; restore it from backup or remove it
it from the primary to resolve the issue.

If verification succeeds on the **primary** but fails on the **secondary**,
this indicates that the object was corrupted during the replication process.
Until [issue #5195][ee-5195] is implemented, Geo won't automatically resolve
verification failures of this kind, so you should follow
[these instructions][reset-verification]

If verification is lagging significantly behind replication, consider giving
the node more time before scheduling a planned failover.

### Disabling or enabling the automatic background verification

The following commands are to be issues in a Rails console on
the **primary**:

```sh
# Omnibus GitLab
gitlab-rails console

# Installation from source
cd /home/git/gitlab
sudo -u git -H bin/rails console RAILS_ENV=production
```

**To check if automatic background verification is enabled:**

```ruby
Feature.enabled?('geo_repository_verification')
```

**To disable automatic background verification:**

```ruby
Feature.disable('geo_repository_verification')
```

**To enable automatic background verification:**

```ruby
Feature.enable('geo_repository_verification')
```

NOTE: **Note:**
Until [issue #5699][ee-5699] is completed, we need to reset the cache for this
feature flag on each **secondary**, to do this run
`sudo gitlab-rails runner 'Rails.cache.expire('flipper/v1/feature/geo_repository_verification', 0)'`.

# Repository verification

Visit the **Admin Area ➔ Geo nodes** dashboard on the **primary** and expand
the **Verification information** tab for that node to view automatic checksumming
status for repositories and wikis. Successes are shown in green, pending work
in grey, and failures in red.

![Verification status](img/verification-status-primary.png)

Visit the **Admin Area ➔ Geo nodes** dashboard on the **secondary** and expand
the **Verification information** tab for that node to view automatic verifcation
status for repositories and wikis. As with checksumming, successes are shown in
green, pending work in grey, and failures in red.

![Verification status](img/verification-status-secondary.png)

# Using checksums to compare Geo nodes

To check the health of Geo secondary nodes, we use a checksum over the list of
Git references and theirs values. Right now the checksum only includes `heads`
and `tags`. We should include all references ([issue #5196][ee-5196]), including
GitLab-specific references to ensure true consistency. If two nodes have the
same checksum, then they definitely hold the same data. We compute the checksum
for every node after every update to make sure that they are all in sync.

# Reset verification for projects where verification has failed

Until [issue #5195][ee-5195] is implemented, Geo won't automatically resolve
verification failures, so you should reset them manually. This rake task marks
projects where verification has failed or the checksum mismatch to be resynced:

#### For repositories:

**Omnibus Installation**

```
sudo gitlab-rake geo:verification:repository:reset
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake geo:verification:repository:reset RAILS_ENV=production
```

#### For wikis:

**Omnibus Installation**

```
sudo gitlab-rake geo:verification:wiki:reset
```

**Source Installation**

```bash
sudo -u git -H bundle exec rake geo:verification:wiki:reset RAILS_ENV=production
```

# Current limitations

Until [issue #5064][ee-5064] is completed, background verification doesn't cover
CI job artifacts and traces, LFS objects, or user uploads in file storage.
Verify their integrity manually by following [these instructions][foreground-verification]
on both nodes, and comparing the output between them.

Data in object storage is **not verified**, as the object store is responsible
for ensuring the integrity of the data.

[disaster-recovery]: index.md
[feature-flag]: background_verification.md#enabling-or-disabling-the-automatic-background-verification
[reset-verification]: background_verification.md#reset-verification-for-projects-where-verification-has-failed
[foreground-verification]: ../../raketasks/check.md
[ee-5064]: https://gitlab.com/gitlab-org/gitlab-ee/issues/5064
[ee-5699]: https://gitlab.com/gitlab-org/gitlab-ee/issues/5699
[ee-5195]: https://gitlab.com/gitlab-org/gitlab-ee/issues/5195
[ee-5196]: https://gitlab.com/gitlab-org/gitlab-ee/issues/5196

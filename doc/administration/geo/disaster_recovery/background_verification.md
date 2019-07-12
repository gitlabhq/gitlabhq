# Automatic background verification **(PREMIUM ONLY)**

NOTE: **Note:**
Automatic background verification of repositories and wikis was added in
GitLab EE 10.6 but is enabled by default only on GitLab EE 11.1. You can
disable or enable this feature manually by following
[these instructions](#disabling-or-enabling-the-automatic-background-verification).

Automatic background verification ensures that the transferred data matches a
calculated checksum. If the checksum of the data on the **primary** node matches checksum of the
data on the **secondary** node, the data transferred successfully. Following a planned failover,
any corrupted data may be **lost**, depending on the extent of the corruption.

If verification fails on the **primary** node, this indicates that Geo is
successfully replicating a corrupted object; restore it from backup or remove it
it from the **primary** node to resolve the issue.

If verification succeeds on the **primary** node but fails on the **secondary** node,
this indicates that the object was corrupted during the replication process.
Geo actively try to correct verification failures marking the repository to
be resynced with a backoff period. If you want to reset the verification for
these failures, so you should follow [these instructions][reset-verification].

If verification is lagging significantly behind replication, consider giving
the node more time before scheduling a planned failover.

## Disabling or enabling the automatic background verification

Run the following commands in a Rails console on the **primary** node:

```sh
gitlab-rails console
```

To check if automatic background verification is enabled:

```ruby
Gitlab::Geo.repository_verification_enabled?
```

To disable automatic background verification:

```ruby
Feature.disable('geo_repository_verification')
```

To enable automatic background verification:

```ruby
Feature.enable('geo_repository_verification')
```

## Repository verification

Navigate to the **Admin Area > Geo** dashboard on the **primary** node and expand
the **Verification information** tab for that node to view automatic checksumming
status for repositories and wikis. Successes are shown in green, pending work
in grey, and failures in red.

![Verification status](img/verification-status-primary.png)

Navigate to the **Admin Area > Geo** dashboard on the **secondary** node and expand
the **Verification information** tab for that node to view automatic verification
status for repositories and wikis. As with checksumming, successes are shown in
green, pending work in grey, and failures in red.

![Verification status](img/verification-status-secondary.png)

## Using checksums to compare Geo nodes

To check the health of Geo **secondary** nodes, we use a checksum over the list of
Git references and their values. The checksum includes `HEAD`, `heads`, `tags`,
`notes`, and GitLab-specific references to ensure true consistency. If two nodes
have the same checksum, then they definitely hold the same references. We compute
the checksum for every node after every update to make sure that they are all
in sync.

## Repository re-verification

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/8550) in GitLab Enterprise Edition 11.6. Available in [GitLab Premium](https://about.gitlab.com/pricing/).

Due to bugs or transient infrastructure failures, it is possible for Git
repositories to change unexpectedly without being marked for verification.
Geo constantly reverifies the repositories to ensure the integrity of the
data. The default and recommended re-verification interval is 7 days, though
an interval as short as 1 day can be set. Shorter intervals reduce risk but
increase load and vice versa.

Navigate to the **Admin Area > Geo** dashboard on the **primary** node, and
click the **Edit** button for the **primary** node to customize the minimum
re-verification interval:

![Re-verification interval](img/reverification-interval.png)

The automatic background re-verification is enabled by default, but you can
disable if you need. Run the following commands in a Rails console on the
**primary** node:

```sh
gitlab-rails console
```

To disable automatic background re-verification:

```ruby
Feature.disable('geo_repository_reverification')
```

To enable automatic background re-verification:

```ruby
Feature.enable('geo_repository_reverification')
```

## Reset verification for projects where verification has failed

Geo actively try to correct verification failures marking the repository to
be resynced with a backoff period. If you want to reset them manually, this
rake task marks projects where verification has failed or the checksum mismatch
to be resynced without the backoff period:

For repositories:

```sh
sudo gitlab-rake geo:verification:repository:reset
```

For wikis:

```sh
sudo gitlab-rake geo:verification:wiki:reset
```

## Reconcile differences with checksum mismatches

If the **primary** and **secondary** nodes have a checksum verification mismatch, the cause may not be apparent. To find the cause of a checksum mismatch:

1. Navigate to the **Admin Area > Projects** dashboard on the **primary** node, find the
   project that you want to check the checksum differences and click on the
   **Edit** button:
   ![Projects dashboard](img/checksum-differences-admin-projects.png)

1. On the project admin page get the **Gitaly storage name**, and **Gitaly relative path**:
   ![Project admin page](img/checksum-differences-admin-project-page.png)

1. Navigate to the project's repository directory on both **primary** and **secondary** nodes
   (the path is usually `/var/opt/gitlab/git-data/repositories`). Note that if `git_data_dirs`
   is customized, check the directory layout on your server to be sure.

   ```sh
   cd /var/opt/gitlab/git-data/repositories
   ```

1. Run the following command on the **primary** node, redirecting the output to a file:

   ```sh
   git show-ref --head | grep -E "HEAD|(refs/(heads|tags|keep-around|merge-requests|environments|notes)/)" > primary-node-refs
   ```

1. Run the following command on the **secondary** node, redirecting the output to a file:

   ```sh
   git show-ref --head | grep -E "HEAD|(refs/(heads|tags|keep-around|merge-requests|environments|notes)/)" > secondary-node-refs
   ```

1. Copy the files from the previous steps on the same system, and do a diff between the contents:

   ```sh
   diff primary-node-refs secondary-node-refs
   ```

## Current limitations

Until [issue #5064][ee-5064] is completed, background verification doesn't cover
CI job artifacts and traces, LFS objects, or user uploads in file storage.
Verify their integrity manually by following [these instructions][foreground-verification]
on both nodes, and comparing the output between them.

Data in object storage is **not verified**, as the object store is responsible
for ensuring the integrity of the data.

[reset-verification]: background_verification.md#reset-verification-for-projects-where-verification-has-failed
[foreground-verification]: ../../raketasks/check.md
[ee-5064]: https://gitlab.com/gitlab-org/gitlab-ee/issues/5064

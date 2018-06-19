# Pseudonymizer

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/5532) in [GitLab Enterprise Edition][ee] 11.1

## Export GitLab's data for safe analytics

As the GitLab's database host sensitive informations, using it unfiltered for analytics implies high security requirements. To help alleviate this constraint, the Pseudonymizer service shall export GitLab's data, in a pseudonymized way.

### Pseudonymization

> **Note:**
> This process is not impervious: if the source data is available, it is possible for an user to correlate data to the pseudonymized version.

The Pseudonymizer currently uses `HMAC(SHA256)` to mutate fields that should not textually exported. This should ensure that:

  - End-user of the data source cannot infer/revert the pseudonymized fields
  - Referencial integrity is maintained

### Manifest

The manifest is a file that describe which fields should be included or pseudonymized.

You may find this manifest at `lib/pseudonymizer/manifest.yml`. 

### Usage

> **Note:**
> You can configure the pseudonymizer using the following environment variables:
>
>   - PSEUDONYMIZER_OUTPUT_DIR: where to store the output CSV files (default: `/tmp`)
>   - PSEUDONYMIZER_BATCH: the batch size when querying the DB (default: `100 000`)

> **Note:**
> Object store is required for the pseudonymizer to work properly.

```
bundle exec rake gitlab:db:pseudonymizer
```

### Output

> **Note:**
> The output CSV files might be very large. Make sure the `PSEUDONYMIZER_OUTPUT_DIR` has sufficient space. As a rule of thumb, at least 10% of the database size is recommended.

After the pseudonymizer has run, the output CSV files should be uploaded to the configured object store.

### Configuration

See [administration].

[ee]: https://about.gitlab.com/products/
[administration]: administration/pseudonymizer.md

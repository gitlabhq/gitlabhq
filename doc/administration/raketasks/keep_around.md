---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Keep-around orphaned reference Rake task
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Improvements to Rake task [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/475246) in GitLab 18.4.

{{< /history >}}

`gitlab:keep_around:orphaned` generates a CSV report of every keep-around reference in the project repository and every database reference to a Git commit.

The CSV report has three columns:

- The type of reference. Either `keep` for a keep-around reference or `usage` for a database reference.
- The Git commit ID.
- The source of the reference if known. For example, `Pipeline`.

## Run orphaned reference report

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:keep_around:orphaned PROJECT_PATH=project/path FILENAME=/tmp/report.csv
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
bundle exec rake gitlab:keep_around:orphaned RAILS_ENV=production PROJECT_PATH=project/path FILENAME=/tmp/report.csv
```

{{< /tab >}}

{{< /tabs >}}

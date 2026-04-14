---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Release evidence
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Each time a release is created, GitLab takes a snapshot of data that's related to it.
This data is saved in a JSON file and called *release evidence*. The feature
includes test artifacts, linked milestones, and matching packages to facilitate
internal processes, like external audits.

To access the release evidence, on the Releases page, select the link to the JSON file that's listed
under the **Evidence collection** heading.

You can also [use the API](../../../api/releases/_index.md#collect-release-evidence) to
generate release evidence for an existing release. Because of this, each release
can have multiple release evidence snapshots. You can view the release evidence and
its details on the Releases page.

When the issue tracker is disabled, release evidence [can't be downloaded](https://gitlab.com/gitlab-org/gitlab/-/issues/208397).

Here is an example of a release evidence object:

```json
{
  "release": {
    "id": 5,
    "tag_name": "v4.0",
    "name": "New release",
    "project": {
      "id": 20,
      "name": "Project name",
      "created_at": "2019-04-14T11:12:13.940Z",
      "description": "Project description"
    },
    "created_at": "2019-06-28 13:23:40 UTC",
    "description": "Release description",
    "milestones": [
      {
        "id": 11,
        "title": "v4.0-rc1",
        "state": "closed",
        "due_date": "2019-05-12 12:00:00 UTC",
        "created_at": "2019-04-17 15:45:12 UTC",
        "description": "milestone description",
      },
      {
        "id": 12,
        "title": "v4.0-rc2",
        "state": "closed",
        "due_date": "2019-05-30 18:30:00 UTC",
        "created_at": "2019-04-17 15:45:12 UTC",
        "description": "milestone description",
      }
    ],
    "packages": [
      {
        "id": 1,
        "name": "my-package",
        "version": "4.0",
        "package_type": "generic",
        "created_at": "2019-06-20 10:00:00 UTC"
      }
    ],
    "report_artifacts": [
      {
        "url":"https://gitlab.example.com/root/project-name/-/jobs/111/artifacts/download"
      }
    ]
  }
}
```

## Include packages as release evidence

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/283995) in GitLab 18.11.

{{< /history >}}

When a release is created, GitLab automatically queries the project's
[package registry](../../packages/package_registry/_index.md) for packages
whose version matches the release tag. Matching packages are included in the
release evidence JSON under the `packages` key.

Version matching works as follows:

- If the release tag has a `v` or `V` prefix (for example, `v1.0.0`), the prefix
  is stripped before matching. A tag `v1.0.0` matches packages with version `1.0.0`.
- If the release tag has no prefix (for example, `1.0.0`), it is matched directly.
- Only [displayable packages](../../packages/package_registry/_index.md) are included.
  Packages that are pending destruction or in an error state are excluded.
- Multiple packages can match a single release. For example, if a project
  publishes both a generic package and an npm package with version `1.0.0`,
  both are included in the evidence.

Each package entry in the evidence contains the following fields:

| Field          | Description                                                    |
|----------------|----------------------------------------------------------------|
| `id`           | The unique ID of the package.                                  |
| `name`         | The name of the package.                                       |
| `version`      | The version string of the package.                             |
| `package_type` | The type of the package (for example, `generic`, `npm`, `maven`). |
| `created_at`   | The timestamp when the package was created.                    |

No additional configuration is required. As long as packages exist in the
project's package registry with a version that matches the release tag,
they are automatically included when evidence is collected.

## Collect release evidence

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When a release is created, release evidence is automatically collected. To initiate evidence collection any other time, use an [API call](../../../api/releases/_index.md#collect-release-evidence). You can collect release evidence multiple times for one release.

Evidence collection snapshots are visible on the Releases page, along with the timestamp the evidence was collected.

## Include report artifacts as release evidence

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When you create a release, if [job artifacts](../../../ci/yaml/_index.md#artifactsreports) are included in the last pipeline that ran, they are automatically included in the release as release evidence.

Although job artifacts usually expire, artifacts included in release evidence do not expire.

To enable job artifact collection you must specify both:

1. [`artifacts:paths`](../../../ci/yaml/_index.md#artifactspaths)
1. [`artifacts:reports`](../../../ci/yaml/_index.md#artifactsreports)

```yaml
ruby:
  script:
    - gem install bundler
    - bundle install
    - bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml
  artifacts:
    paths:
      - rspec.xml
    reports:
      junit: rspec.xml
```

If the pipeline ran successfully, when you create your release, the `rspec.xml` file is saved as
release evidence.

If you [schedule release evidence collection](#schedule-release-evidence-collection),
some artifacts may already be expired by the time of evidence collection. To avoid this you can use
the [`artifacts:expire_in`](../../../ci/yaml/_index.md#artifactsexpire_in)
keyword. For more information, see [issue 222351](https://gitlab.com/gitlab-org/gitlab/-/issues/222351).

## Schedule release evidence collection

In the API:

- If you specify a future `released_at` date, the release becomes an **Upcoming release**
  and the evidence is collected on the date of the release. You cannot collect
  release evidence before then.
- If you specify a past `released_at` date, the release becomes an **Historical
  release** and no evidence is collected.
- If you do not specify a `released_at` date, release evidence is collected on the
  date the release is created.

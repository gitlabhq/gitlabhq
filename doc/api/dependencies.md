---
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Dependencies API

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

WARNING:
This API is in an [Experiment](../policy/experiment-beta-support.md#experiment) and considered unstable.
The response payload may be subject to change or breakage
across GitLab releases.

> - Introduced in GitLab 12.1.
> - Pagination introduced in 14.4.

Every call to this endpoint requires authentication. To perform this call, user should be authorized to read repository.
To see vulnerabilities in response, user should be authorized to read
[Project Security Dashboard](../user/application_security/security_dashboard/index.md).

## List project dependencies

Get a list of project dependencies. This API partially mirroring
[Dependency List](../user/application_security/dependency_list/index.md) feature.
This list can be generated only for [languages and package managers](../user/application_security/dependency_scanning/index.md#supported-languages-and-package-managers)
supported by Gemnasium.

```plaintext
GET /projects/:id/dependencies
GET /projects/:id/dependencies?package_manager=maven
GET /projects/:id/dependencies?package_manager=yarn,bundler
```

| Attribute     | Type           | Required | Description                                                                                                                                                                 |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding).                                                            |
| `package_manager` | string array   | no       | Returns dependencies belonging to specified package manager. Valid values: `bundler`, `composer`, `conan`, `go`, `gradle`, `maven`, `npm`, `nuget`, `pip`, `pipenv`, `pnpm`, `yarn`, `sbt`, or `setuptools`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/4/dependencies"
```

Example response:

```json
[
  {
    "name": "rails",
    "version": "5.0.1",
    "package_manager": "bundler",
    "dependency_file_path": "Gemfile.lock",
    "vulnerabilities": [
      {
        "name": "DDoS",
        "severity": "unknown",
        "id": 144827,
        "url": "https://gitlab.example.com/group/project/-/security/vulnerabilities/144827"
      }
    ],
    "licenses": [
      {
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT"
      }
    ]
  },
  {
    "name": "hanami",
    "version": "1.3.1",
    "package_manager": "bundler",
    "dependency_file_path": "Gemfile.lock",
    "vulnerabilities": [],
    "licenses": [
      {
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT"
      }
    ]
  }
]
```

## Dependencies pagination

By default, `GET` requests return 20 results at a time because the API results
are paginated.

Read more on [pagination](rest/index.md#pagination).

---
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Dependencies API **(ULTIMATE)**

WARNING:
This API is in an alpha stage and considered unstable.
The response payload may be subject to change or breakage
across GitLab releases.

Every call to this endpoint requires authentication. To perform this call, user should be authorized to read repository.
To see vulnerabilities in response, user should be authorized to read
[Project Security Dashboard](../user/application_security/security_dashboard/index.md#project-security-dashboard).

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
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding).                                                            |
| `package_manager` | string array   | no       | Returns dependencies belonging to specified package manager. Valid values: `bundler`, `composer`, `maven`, `npm`, `pip` or `yarn`.                                   |

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
    "vulnerabilities": [{
      "name": "DDoS",
      "severity": "unknown"
    }]
  },
  {
      "name": "hanami",
      "version": "1.3.1",
      "package_manager": "bundler",
      "dependency_file_path": "Gemfile.lock",
      "vulnerabilities": []
    }
]
```

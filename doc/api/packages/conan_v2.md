---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Conan v2 API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

For Conan v1 operations, see [Conan v1 API](conan_v1.md).

{{< /alert >}}

Use this API to interact with the Conan v2 package manager. For more information, see [Conan packages in the package registry](../../user/packages/conan_repository/_index.md).

Generally, these endpoints are used by the [Conan 2 package manager client](https://docs.conan.io/2/index.html)
and are not meant for manual consumption.

For instructions on how to upload and install Conan packages from the GitLab
package registry, see the [Conan package registry documentation](../../user/packages/conan_repository/_index.md) and [Conan 2 package manager client](https://docs.conan.io/2/index.html).

{{< alert type="note" >}}

These endpoints do not adhere to the standard API authentication methods.
See each route for details on how credentials are expected to be passed. Undocumented authentication methods might be removed in the future.

{{< /alert >}}

{{< alert type="note" >}}

The Conan registry is not FIPS compliant and is disabled when [FIPS mode](../../development/fips_gitlab.md) is enabled.
These endpoints will all return 404 Not Found.
{{< /alert >}}

## Route prefix

The project-level prefix is used to make requests in a single project's scope. The examples in this document all use the project-level prefix.

```plaintext
/projects/:id/packages/conan
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | yes | The project ID or full project path. |

## Get latest recipe revision

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/519741) in GitLab 17.11 [with a flag](../../administration/feature_flags.md) named `conan_package_revisions_support`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag. For more information, see the history.

{{< /alert >}}

Get the revision hash and creation date of the latest package recipe.

```plaintext
GET <route_prefix>/v2/conans/:package_name/:package_version/:package_username/:package_channel/latest
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `package_name`      | string | yes | Name of a package. |
| `package_version`   | string | yes | Version of a package. |
| `package_username`  | string | yes | Conan username of a package. This attribute is the `+`-separated full path of your project. |
| `package_channel`   | string | yes | Channel of a package. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/latest"
```

Example response:

```json
{
  "revision" : "75151329520e7685dcf5da49ded2fec0",
  "time" : "2024-12-17T09:16:40.334+0000"
}
```

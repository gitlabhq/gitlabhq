# GitLab private Maven repository administration

> **Notes:**
- [Introduced][ee-5811] in GitLab 11.3.
- This document is about the admin guide. Learn how to use GitLab Maven 
  repository from [user documentation](../user/project/maven_packages.md).

When enabled, every project in GitLab will have its own space to store Maven packages.

## Enable the Maven repository

**Omnibus GitLab installations**

# TODO: Update this section once https://gitlab.com/gitlab-org/gitlab-ee/issues/7253 is resolved

**Installations from source**

If you have installed GitLab from source:

1. After the installation is complete, you will have to configure the `packages` 
   section in `gitlab.yml` in order to enable it.

The contents of `gitlab.yml` are:

```
packages:
  enabled: true
```

where:

| Parameter | Description |
| --------- | ----------- |
| `enabled` | `true` or `false`. Enables the packages repository in GitLab. By default this is `false`. |

[ee-5811]: https://gitlab.com/gitlab-org/gitlab-ee/issues/5811

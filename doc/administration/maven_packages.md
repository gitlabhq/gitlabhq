# GitLab private Maven repository administration

> **Notes:**
> - [Introduced][ee-5811] in GitLab 11.3.
> - This document is about the admin guide. Learn how to use GitLab Maven 
>   repository from [user documentation](../user/project/maven_packages.md).

When enabled, every project in GitLab will have its own space to store Maven packages.

## Enable the Maven repository

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

    ```ruby
    gitlab_rails['packages_enabled'] = true
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

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

[reconfigure gitlab]: restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab"
[ee-5811]: https://gitlab.com/gitlab-org/gitlab-ee/issues/5811

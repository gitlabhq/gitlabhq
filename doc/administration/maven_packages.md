# GitLab private Maven repository administration

> **Notes:**
- [Introduced][ee-5811] in GitLab 11.3.
- This document is about the admin guide. Learn how to use GitLab Maven
  repository from [user documentation](../user/project/maven_packages.md).

When enabled, every project in GitLab will have its own space to store
[Maven](https://maven.apache.org/) packages.

## Enabling the Maven repository

NOTE: **Note:**
Once enabled, newly created projects will have the Packages feature enabled by
default. Existing projects will need to
[explicitly enabled it](../user/project/maven_packages.md#enabling-the-packages-repository).

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

    ```ruby
    gitlab_rails['packages_enabled'] = true
    ```

1. Save the file and [reconfigure GitLab][] for the changes to take effect.

**Installations from source**

If you have installed GitLab from source:

1. After the installation is complete, you will have to configure the `packages`
   section in `config/gitlab.yml`. Set to `true` to enable it:

      ```yaml
      packages:
        enabled: true
      ```
1. [Restart GitLab] for the changes to take effect.

[reconfigure gitlab]: restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab"
[restart gitlab]: restart_gitlab.md#omnibus-gitlab-reconfigure "How to reconfigure Omnibus GitLab"
[ee-5811]: https://gitlab.com/gitlab-org/gitlab-ee/issues/5811

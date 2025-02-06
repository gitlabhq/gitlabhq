---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Example configuration files
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Gitaly and Gitaly Cluster are configured by using configuration files. The default location of the configuration files
depends on the type of installation you have:

- For Linux package installations, the default location for Gitaly and Gitaly Cluster configuration is in the
  `/etc/gitlab/gitlab.rb` Ruby file.
- For self-compiled, the default location for Gitaly and Gitaly Cluster configuration is in the
  `/home/git/gitaly/config.toml` and `/home/git/gitaly/config.prafect.toml` TOML files.

You can find example TOML configuration files in the `gitaly` project for:

- Gitaly: <https://gitlab.com/gitlab-org/gitaly/-/blob/master/config.toml.example>
- Gitaly Cluster: <https://gitlab.com/gitlab-org/gitaly/-/blob/master/config.praefect.toml.example>

If you are configuring a Linux package installation, you must convert the examples into Ruby to use them.

For more information on:

- Configuring Gitaly, see [Configure Gitaly](configure_gitaly.md).
- Configuring Gitaly Cluster, see [Configure Gitaly Cluster](praefect.md).

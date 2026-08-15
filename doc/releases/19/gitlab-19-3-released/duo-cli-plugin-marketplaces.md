---
title: GitLab Duo CLI plugins and marketplaces (Experiment)
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli/customize/#plugins"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22497
categories: [ Duo CLI ]
level: secondary
weight: 50
---

GitLab Duo CLI now supports plugins and plugin marketplaces as an experiment, introduced in
GitLab Duo CLI 9.10.0. A plugin bundles Agent Skills, custom
slash commands, and Model Context Protocol (MCP) servers into a single directory. A marketplace is a catalog of
available plugins, hosted in a Git repository or a local directory.

GitLab Duo CLI automatically registers the official `gitlab-duo-plugins` marketplace the first
time you use plugins. 

The marketplace includes three skills for common GitLab workflows:

- `mr-review`: Reviews a merge request and posts comments.
- `stack-changes`: Splits a large local
  change into a stacked merge request chain.
- `create-issue`: Drafts a GitLab issue from a
  natural-language description. 

To install one of the skills, run `glab duo cli plugin install <plugin>@gitlab-duo-plugins` or `duo plugin install <plugin>@gitlab-duo-plugins`, based on your setup.

For compatibility with the existing community plugin ecosystem, GitLab Duo CLI also reads
`.claude-plugin/marketplace.json` files, so existing Claude Code plugin marketplaces work with
GitLab Duo CLI without modification.

---
title: "Configure GitLab Duo CLI with settings files"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli/settings/"
work_item: https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2126
categories: [ Duo CLI ]
level: secondary
weight: 50
---

You can now configure GitLab Duo CLI with settings files, for yourself or for your whole organization.

The settings file stores the choices you make in the `/settings` panel.
You can also edit the file directly, or create it in advance, for example in a container image.

System administrators can deploy a managed settings file to each machine with a mobile device
management tool or group policy.
Settings in the managed file take precedence over the settings file, command-line options, and
environment variables, and users can't change them.
Settings not in the managed file remain under user control.

The settings file requires GitLab Duo CLI 9.26.0 or later, and the managed settings file requires
GitLab Duo CLI 9.27.0 or later.

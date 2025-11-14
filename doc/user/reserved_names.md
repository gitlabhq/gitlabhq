---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Reserved project and group names
description: Naming conventions, restrictions, and reserved names.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

To not conflict with existing routes used by GitLab, some words cannot be used as project or group names.
These words are listed in the
[`path_regex.rb` file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/path_regex.rb),
where:

- `TOP_LEVEL_ROUTES` are names reserved as usernames or top-level groups.
- `PROJECT_WILDCARD_ROUTES` are names reserved for subgroups or projects.
- `GROUP_ROUTES` are names reserved for all groups or projects.

## Rules for usernames, project and group names, and slugs

Usernames must start and end with a letter (`a-zA-Z`) or a digit (`0-9`).
For example, the following usernames satisfy these criteria:

- `A_Garcia`
- `a_garcia_1`

Additionally, usernames and group names must contain only letters (`a-zA-Z`), digits (`0-9`), emoji, underscores (`_`), dots (`.`), parentheses (`()`), dashes (`-`), or spaces. For example:

- Valid username: `sidney.jones` or `sidney ⭐ jones`
- Valid group name: `Web Development Team (Frontend)`

Project names must contain only letters (`a-zA-Z`), digits (`0-9`), emoji, underscores (`_`), dots (`.`), pluses (`+`), dashes (`-`), or spaces. For example:

- `web-app-v2+features`
- `web-analytics-dashboard`
- `Backend API Service 🚀`

Usernames and project or group slugs:

- Must start and end with a letter (`a-zA-Z`) or digit (`0-9`).
- Must not contain consecutive special characters.
- Cannot end in `.git` or `.atom`.
- Must contain only letters (`a-zA-Z`), digits (`0-9`), underscores (`_`), dots (`.`), or dashes (`-`).

Valid username slug examples:

- `dev_user_1`
- `zhang.wei-2024`
- `maria.lopez`

Valid project slug examples:

- `api.service.v2`
- `user_management_portal`
- `docs_site_v3`

Valid group slug examples:

- `marketing-team-2024`
- `backend.services`
- `mobile-dev-team`

## Reserved project names

You cannot create projects with the following names:

- `\-`
- `badges`
- `blame`
- `blob`
- `builds`
- `commits`
- `create`
- `create_dir`
- `edit`
- `environments/folders`
- `files`
- `find_file`
- `gitlab-lfs/objects`
- `info/lfs/objects`
- `new`
- `preview`
- `raw`
- `refs`
- `tree`
- `update`
- `wikis`

## Reserved group names

You cannot create groups with the following names, because they are reserved for top-level groups:

- `\-`
- `.well-known`
- `404.html`
- `422.html`
- `500.html`
- `502.html`
- `503.html`
- `admin`
- `api`
- `apple-touch-icon.png`
- `assets`
- `dashboard`
- `deploy.html`
- `explore`
- `favicon.ico`
- `favicon.png`
- `files`
- `groups`
- `health_check`
- `help`
- `import`
- `jwt`
- `login`
- `oauth`
- `profile`
- `projects`
- `public`
- `robots.txt`
- `s`
- `search`
- `sitemap`
- `sitemap.xml`
- `sitemap.xml.gz`
- `slash-command-logo.png`
- `snippets`
- `unsubscribes`
- `uploads`
- `users`
- `v2`

You cannot create subgroups with the following names:

- `\-`

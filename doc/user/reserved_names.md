---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Reserved project and group names
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

To not conflict with existing routes used by GitLab, some words cannot be used as project or group names.
These words are listed in the
[`path_regex.rb` file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/path_regex.rb),
where:

- `TOP_LEVEL_ROUTES` are names reserved as usernames or top-level groups.
- `PROJECT_WILDCARD_ROUTES` are names reserved for subgroups or projects.
- `GROUP_ROUTES` are names reserved for all groups or projects.

## Rules for usernames, project and group names, and slugs

- Usernames must start and end with a letter (`a-zA-Z`) or a digit (`0-9`). Additionally:
  - Usernames and group names can contain only letters (`a-zA-Z`), digits (`0-9`), emoji, underscores (`_`), dots (`.`), parentheses (`()`), dashes (`-`), or spaces.
  - Project names can contain only letters (`a-zA-Z`), digits (`0-9`), emoji, underscores (`_`), dots (`.`), pluses (`+`), dashes (`-`), or spaces.
- Usernames and project or group slugs:
  - Must start and end with a letter (`a-zA-Z`) or digit (`0-9`).
  - Must not contain consecutive special characters.
  - Cannot end in `.git` or `.atom`.
  - Can contain only letters (`a-zA-Z`), digits (`0-9`), underscores (`_`), dots (`.`), or dashes (`-`).

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

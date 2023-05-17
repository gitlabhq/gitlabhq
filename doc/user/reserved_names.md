---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Reserved project and group names **(FREE)**

Not all project & group names are allowed because they would conflict with
existing routes used by GitLab.

For a list of words that are not allowed to be used as group or project names, see the
[`path_regex.rb` file](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/path_regex.rb)
under the `TOP_LEVEL_ROUTES`, `PROJECT_WILDCARD_ROUTES` and `GROUP_ROUTES` lists:

- `TOP_LEVEL_ROUTES`: are names that are reserved as usernames or top level groups
- `PROJECT_WILDCARD_ROUTES`: are names that are reserved for child groups or projects.
- `GROUP_ROUTES`: are names that are reserved for all groups or projects.

## Limitations on project and group names

- Project or group names must start with a letter, digit, emoji, or "_".
- Project or group names can only contain letters, digits, emojis, "_", ".", "+", dashes, or spaces.
- Project or group slugs must start with a letter or digit.
- Project or group slugs can only contain letters, digits, '_', '.', '+', or dashes.
- Project or group slugs must not contain consecutive special characters.
- Project or group slugs cannot end with a special character.
- Project or group slugs cannot end in `.git` or `.atom`.

## Reserved project names

It is not possible to create a project with the following names:

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

The following names are reserved as top level groups:

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

These group names are unavailable as subgroup names:

- `\-`

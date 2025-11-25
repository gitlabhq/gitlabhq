---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 予約済みのプロジェクト名とグループ名
description: 命名規則、制限、および予約済みの名前。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabが使用する既存のルートと競合しないように、一部の単語はプロジェクト名またはグループ名として使用できません。これらの単語は、[`path_regex.rb`ファイル](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/path_regex.rb)にリストされています。以下に詳細を示します:

- `TOP_LEVEL_ROUTES`は、ユーザー名またはトップレベルグループとして予約されている名前です。
- `PROJECT_WILDCARD_ROUTES`は、サブグループまたはプロジェクト用に予約されている名前です。
- `GROUP_ROUTES`は、すべてのグループまたはプロジェクト用に予約されている名前です。

## ユーザー名、プロジェクト名、グループ名、およびslugのルール {#rules-for-usernames-project-and-group-names-and-slugs}

ユーザー名は、文字（`a-zA-Z`）または数字（`0-9`）で始まり、終わる必要があります。たとえば、次のユーザー名は、これらの基準を満たしています:

- `A_Garcia`
- `a_garcia_1`

さらに、ユーザー名とグループ名には、文字（`a-zA-Z`）、数字（`0-9`）、絵文字、アンダースコア（`_`）、ドット（`.`）、括弧（`()`）、ダッシュ（`-`）、またはスペースのみを含める必要があります。例: 

- 有効なユーザー名: `sidney.jones`または`sidney ⭐ jones`
- 有効なグループ名: `Web Development Team (Frontend)`

プロジェクト名には、文字（`a-zA-Z`）、数字（`0-9`）、絵文字、アンダースコア（`_`）、ドット（`.`）、プラス（`+`）、ダッシュ（`-`）、またはスペースのみを含める必要があります。例: 

- `web-app-v2+features`
- `web-analytics-dashboard`
- `Backend API Service 🚀`

ユーザー名とプロジェクトまたはグループのslug:

- 文字（`a-zA-Z`）または数字（`0-9`）で始まり、終わる必要があります。
- 連続する特殊文字を含めることはできません。
- `.git`または`.atom`で終わることはできません。
- 文字（`a-zA-Z`）、数字（`0-9`）、アンダースコア（`_`）、ドット（`.`）、またはダッシュ（`-`）のみを含める必要があります。

有効なユーザー名slugの例:

- `dev_user_1`
- `zhang.wei-2024`
- `maria.lopez`

有効なプロジェクトslugの例:

- `api.service.v2`
- `user_management_portal`
- `docs_site_v3`

有効なグループslugの例:

- `marketing-team-2024`
- `backend.services`
- `mobile-dev-team`

## 予約済みのプロジェクト名 {#reserved-project-names}

次の名前でプロジェクトを作成することはできません:

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

## 予約済みのグループ名 {#reserved-group-names}

次の名前でグループを作成することはできません。これらはトップレベルグループ用に予約されているためです:

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

次の名前でサブグループを作成することはできません:

- `\-`

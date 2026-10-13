---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 예약된 프로젝트 및 그룹 이름
description: "명명 규칙, 제한 사항 및 예약된 이름."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab에서 사용하는 기존 경로와 충돌하지 않도록 일부 단어는 프로젝트 또는 그룹 이름으로 사용할 수 없습니다. 이러한 단어는 [`path_regex.rb` 파일](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/path_regex.rb)에 나열되어 있습니다:

- `TOP_LEVEL_ROUTES`는 사용자 이름 또는 최상위 그룹으로 예약된 이름입니다.
- `PROJECT_WILDCARD_ROUTES`는 하위 그룹 또는 프로젝트에 예약된 이름입니다.
- `GROUP_ROUTES`는 모든 그룹 또는 프로젝트에 예약된 이름입니다.

## 사용자 이름, 프로젝트 및 그룹 이름, 그리고 슬러그 규칙 {#rules-for-usernames-project-and-group-names-and-slugs}

사용자 이름은 문자(`a-zA-Z`) 또는 숫자(`0-9`)로 시작하고 끝나야 합니다. 예를 들어 다음 사용자 이름은 이러한 조건을 만족합니다:

- `A_Garcia`
- `a_garcia_1`

또한 사용자 이름과 그룹 이름은 문자(`a-zA-Z`), 숫자(`0-9`), 이모지, 밑줄(`_`), 점(`.`), 괄호(`()`), 대시(`-`) 또는 공백만 포함해야 합니다. 예를 들어:

- 유효한 사용자 이름: `sidney.jones` 또는 `sidney ⭐ jones`
- 유효한 그룹 이름: `Web Development Team (Frontend)`

프로젝트 이름은 문자(`a-zA-Z`), 숫자(`0-9`), 이모지, 밑줄(`_`), 점(`.`), 더하기 기호(`+`), 대시(`-`) 또는 공백만 포함해야 합니다. 예를 들어:

- `web-app-v2+features`
- `web-analytics-dashboard`
- `Backend API Service 🚀`

사용자 이름과 프로젝트 또는 그룹 슬러그:

- 문자(`a-zA-Z`) 또는 숫자(`0-9`)로 시작하고 끝나야 합니다.
- 연속된 특수 문자를 포함할 수 없습니다.
- `.git` 또는 `.atom`로 끝날 수 없습니다.
- 문자(`a-zA-Z`), 숫자(`0-9`), 밑줄(`_`), 점(`.`) 또는 대시(`-`)만 포함해야 합니다.

유효한 사용자 이름 슬러그 예시:

- `dev_user_1`
- `zhang.wei-2024`
- `maria.lopez`

유효한 프로젝트 슬러그 예시:

- `api.service.v2`
- `user_management_portal`
- `docs_site_v3`

유효한 그룹 슬러그 예시:

- `marketing-team-2024`
- `backend.services`
- `mobile-dev-team`

## 예약된 프로젝트 이름 {#reserved-project-names}

다음 이름으로는 프로젝트를 만들 수 없습니다:

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

## 예약된 그룹 이름 {#reserved-group-names}

최상위 그룹으로 예약되어 있기 때문에 다음 이름으로는 그룹을 만들 수 없습니다:

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

다음 이름으로는 하위 그룹을 만들 수 없습니다:

- `\-`

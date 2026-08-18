---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab CI/CD를 사용하여 GitLab 프로젝트를 Heroku에 배포합니다.
title: GitLab CI/CD를 사용하여 Heroku에 배포
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab CI/CD를 사용하여 애플리케이션을 Heroku에 배포할 수 있습니다.

## 전제 조건 {#prerequisites}

- [Heroku](https://id.heroku.com/login) 계정 기존 Heroku 계정으로 로그인하거나 새로운 계정을 생성합니다.

## Heroku에 배포 {#deploy-to-heroku}

1. Heroku에서:
   1. 애플리케이션을 생성하고 애플리케이션 이름을 복사합니다.
   1. **Account Settings**로 이동하여 API 키를 복사합니다.
1. GitLab 프로젝트에서 두 개의 [variables](../variables/_index.md)을(를) 생성합니다:
   - `HEROKU_APP_NAME` 애플리케이션 이름
   - `HEROKU_PRODUCTION_KEY` API 키
1. `.gitlab-ci.yml` 파일을 편집하여 Heroku 배포 명령을 추가합니다. 이 예제에서는 Ruby용 `dpl` gem을 사용합니다:

   ```yaml
   heroku_deploy:
     stage: production
     script:
       - gem install dpl
       - dpl --provider=heroku --app=$HEROKU_APP_NAME --api-key=$HEROKU_PRODUCTION_KEY
   ```

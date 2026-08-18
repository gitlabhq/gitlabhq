---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 배포 도구로 Dpl 사용
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Dpl](https://github.com/travis-ci/dpl)은(는) (D-P-L 문자처럼 발음) Travis CI에서 개발하고 사용하는 지속적 배포를 위한 배포 도구이지만 GitLab CI/CD와도 함께 사용할 수 있습니다.

Dpl은(는) [지원되는 공급자](https://github.com/travis-ci/dpl#supported-providers) 중 어느 곳에든 배포할 수 있습니다.

## 필수 조건 {#prerequisite}

Dpl을(를) 사용하려면 최소한 Ruby 1.9.3이 필요하며 gem을 설치할 수 있어야 합니다.

## 기본 사용법 {#basic-usage}

Dpl을(를) 다음 명령으로 모든 머신에 설치할 수 있습니다:

```shell
gem install dpl
```

이를 통해 CI 서버에서 테스트해야 하는 대신 로컬 터미널에서 모든 명령을 테스트할 수 있습니다.

Ruby가 설치되어 있지 않으면 Debian 호환 Linux에서 다음을 수행할 수 있습니다:

```shell
apt-get update
apt-get install ruby-dev
```

Dpl은(는) 다음을 포함한 다양한 서비스를 지원합니다: Heroku, Cloud Foundry, AWS/S3 등 이를 사용하려면 공급자 및 공급자가 필요로 하는 추가 매개변수를 정의합니다.

예를 들어 애플리케이션을 Heroku에 배포하려면 `heroku`을(를) 공급자로 지정하고 `api_key` 및 `app`을(를) 지정해야 합니다. 사용 가능한 모든 매개변수는 [Heroku API 섹션](https://github.com/travis-ci/dpl#heroku-api)에서 찾을 수 있습니다.

```yaml
staging:
  stage: deploy
  script:
    - gem install dpl
    - dpl heroku api --app=my-app-staging --api_key=$HEROKU_STAGING_API_KEY
  environment: staging
```

이전 예제는 Dpl을(를) 사용하여 `my-app-staging`을(를) Heroku 서버에 배포했으며 API 키는 `HEROKU_STAGING_API_KEY` 보안 변수에 저장되었습니다.

다른 공급자를 사용하려면 [지원되는 공급자](https://github.com/travis-ci/dpl#supported-providers)의 긴 목록을 확인하세요.

## Docker를 사용하여 Dpl 사용 {#using-dpl-with-docker}

대부분의 경우 [GitLab 러너](https://docs.gitlab.com/runner/)를 구성하여 서버의 셸 명령을 사용하도록 했습니다. 이는 모든 명령이 로컬 사용자의 컨텍스트에서 실행됨을 의미합니다(예: `gitlab_runner` 또는 `gitlab_ci_multi_runner`). 이는 또한 Docker 컨테이너에 Ruby 런타임이 설치되어 있지 않을 가능성이 높음을 의미합니다. 이를 설치해야 합니다:

```yaml
staging:
  stage: deploy
  script:
    - apt-get update -yq
    - apt-get install -y ruby-dev
    - gem install dpl
    - dpl heroku api --app=my-app-staging --api_key=$HEROKU_STAGING_API_KEY
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: staging
```

첫 번째 줄 `apt-get update -yq`은(는) 사용 가능한 패키지 목록을 업데이트하고, 두 번째 `apt-get install -y ruby-dev`은(는) 시스템에 Ruby 런타임을 설치합니다. 이전 예제는 모든 Debian 호환 시스템에 유효합니다.

## 스테이징 및 프로덕션에서 사용 {#usage-in-staging-and-production}

개발 워크플로우에서 스테이징(개발) 및 프로덕션 환경을 갖는 것은 매우 일반적입니다.

다음 예제를 고려합니다: `main` 브랜치를 `staging`에 배포하고 모든 태그를 `production` 환경에 배포하려고 합니다. 해당 설정의 최종 `.gitlab-ci.yml`은(는) 다음과 같이 표시됩니다:

```yaml
staging:
  stage: deploy
  script:
    - gem install dpl
    - dpl heroku api --app=my-app-staging --api_key=$HEROKU_STAGING_API_KEY
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: staging

production:
  stage: deploy
  script:
    - gem install dpl
    - dpl heroku api --app=my-app-production --api_key=$HEROKU_PRODUCTION_API_KEY
  rules:
    - if: $CI_COMMIT_TAG
  environment: production
```

다른 이벤트에서 실행되는 두 개의 배포 작업을(를) 생성했습니다:

- `staging`: `main` 브랜치로 푸시된 모든 커밋에 대해 실행됨
- `production`: 푸시된 모든 태그에 대해 실행됨

이 작업은(는) 두 개의 보안 변수도 사용합니다:

- `HEROKU_STAGING_API_KEY`: 스테이징 앱을 배포하는 데 사용되는 Heroku API 키
- `HEROKU_PRODUCTION_API_KEY`: 프로덕션 앱을 배포하는 데 사용되는 Heroku API 키

## API 키 저장 {#storing-api-keys}

API 키를 보안 변수로 저장하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **변수**를 펼칩니다.

프로젝트 설정에서 정의된 변수는 빌드 스크립트와 함께 러너로 전송됩니다. 보안 변수는 리포지토리 외부에 저장됩니다. 프로젝트의 `.gitlab-ci.yml` 파일에 절대 비밀을 저장하지 마세요. 또한 비밀의 값이 작업 로그에 숨겨지는 것이 중요합니다.

추가된 변수에 `$`(비-Windows 러너의 경우) 또는 `%`(Windows Batch 러너의 경우) 접두사를 붙여 액세스합니다:

- `$VARIABLE`: 비-Windows 러너에 사용
- `%VARIABLE%`: Windows Batch 러너에 사용

[CI/CD 변수](../../variables/_index.md)에 대해 더 알아보세요.

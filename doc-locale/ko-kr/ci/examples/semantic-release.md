---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: semantic-release를 사용하여 npm 패키지를 GitLab 패키지 레지스트리에 게시합니다
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 가이드에서는 [GitLab 패키지 레지스트리](../../user/packages/npm_registry/_index.md)에 npm 패키지를 자동으로 게시하는 방법을 [semantic-release](https://github.com/semantic-release/semantic-release)를 사용하여 설명합니다.

완전한 [예제 소스](https://gitlab.com/gitlab-examples/semantic-release-npm)를 보거나 포크할 수도 있습니다.

## 모듈 초기화 {#initialize-the-module}

1. 터미널을 열고 프로젝트의 리포지토리로 이동합니다.
1. `npm init`을 실행합니다. 모듈 이름을 [패키지 레지스트리의 명명 규칙](../../user/packages/npm_registry/_index.md#naming-convention)에 따라 정합니다. 예를 들어 프로젝트의 경로가 `gitlab-examples/semantic-release-npm`인 경우 모듈 이름을 `@gitlab-examples/semantic-release-npm`로 정합니다.
1. 다음 npm 패키지를 설치합니다:

   ```shell
   npm install semantic-release @semantic-release/git @semantic-release/gitlab @semantic-release/npm --save-dev
   ```

1. 모듈의 `package.json`에 다음 속성을 추가합니다:

   ```json
   {
     "scripts": {
       "semantic-release": "semantic-release"
     },
     "publishConfig": {
       "access": "public"
     },
     "files": [ <path(s) to files here> ]
   }
   ```

1. `files` 키를 게시된 모듈에 포함되어야 하는 모든 파일을 선택하는 glob 패턴으로 업데이트합니다. `files`에 대한 자세한 정보는 [npm 문서](https://docs.npmjs.com/cli/v6/configuring-npm/package-json/#files)에서 찾을 수 있습니다.
1. `.gitignore` 파일을 프로젝트에 추가하여 `node_modules` 커밋을 피합니다:

   ```plaintext
   node_modules
   ```

## 파이프라인 구성 {#configure-the-pipeline}

`.gitlab-ci.yml`을 다음 콘텐츠로 생성합니다:

```yaml
default:
  image: node:latest
  before_script:
    - npm ci --cache .npm --prefer-offline
    - |
      {
        echo "@${CI_PROJECT_ROOT_NAMESPACE}:registry=${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/"
        echo "${CI_API_V4_URL#https?}/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=\${CI_JOB_TOKEN}"
      } | tee -a .npmrc
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - .npm/

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH

variables:
  NPM_TOKEN: ${CI_JOB_TOKEN}

stages:
  - release

publish:
  stage: release
  script:
    - npm run semantic-release
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

이 예제에서는 `publish`이라는 단일 작업으로 파이프라인을 구성하며, 이 작업은 `semantic-release`을 실행합니다. semantic-release 라이브러리는 npm 패키지의 새 버전을 게시하고 필요한 경우 새 GitLab 릴리스를 생성합니다.

기본 `before_script`은 `publish` 작업 중에 패키지 레지스트리에 인증하는 데 사용되는 임시 `.npmrc`를 생성합니다.

## CI/CD 변수 설정 {#set-up-cicd-variables}

패키지 게시의 일부로 semantic-release는 `package.json`의 버전 번호를 증가시킵니다. semantic-release가 이 변경 사항을 커밋하고 GitLab으로 다시 푸시하도록 하려면 파이프라인에 `GITLAB_TOKEN`라는 사용자 지정 CI/CD 변수가 필요합니다. 이 CI/CD 변수를 생성하려면:

1. 왼쪽 사이드바를 엽니다.
1. **설정** > **액세스 토큰**을 선택합니다.
1. 프로젝트에서 **새 토큰 추가**를 선택합니다.
1. **토큰 이름** 상자에 토큰 이름을 입력합니다.
   <!-- markdownlint-disable MD044 -->
1. **범위 선택** 아래에서 **API** 확인란을 선택합니다.
   <!-- markdownlint-enable MD044 -->
1. **Create project access token**을 선택합니다.
1. 토큰 값을 복사합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **변수**를 펼칩니다.
1. **변수 추가**를 선택합니다.
1. **공개범위** 아래에서 **마스킹됨**을 선택합니다.
1. **키** 상자에 `GITLAB_TOKEN`를 입력합니다.
1. **값** 상자에 토큰 값을 입력합니다.
1. **변수 추가**를 선택합니다.

## semantic-release 구성 {#configure-semantic-release}

semantic-release는 프로젝트의 `.releaserc.json` 파일에서 구성 정보를 가져옵니다. `.releaserc.json`를 리포지토리의 루트에 생성합니다:

```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/gitlab",
    "@semantic-release/npm",
    [
      "@semantic-release/git",
      {
        "assets": ["package.json"],
        "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
      }
    ]
  ]
}
```

이전 semantic-release 구성 예제에서 브랜치 이름을 프로젝트의 기본 브랜치로 변경할 수 있습니다.

## 릴리스 게시 시작 {#begin-publishing-releases}

다음과 같은 메시지가 있는 커밋을 생성하여 파이프라인을 테스트합니다:

```plaintext
fix: testing patch releases
```

기본 브랜치에 커밋을 푸시합니다. 파이프라인은 프로젝트의 **릴리스** 페이지에서 새 릴리스(`v1.0.0`)를 생성하고 프로젝트의 **패키지 레지스트리** 페이지에 패키지의 새 버전을 게시합니다.

마이너 릴리스를 생성하려면 다음과 같은 커밋 메시지를 사용합니다:

```plaintext
feat: testing minor releases
```

또는 커밋 변경의 경우:

```plaintext
feat: testing major releases

BREAKING CHANGE: This is a breaking change.
```

커밋 메시지가 릴리스에 매핑되는 방법에 대한 자세한 정보는 [semantic-releases의 문서](https://github.com/semantic-release/semantic-release#how-does-it-work)에서 찾을 수 있습니다.

## 프로젝트에서 모듈 사용 {#use-the-module-in-a-project}

게시된 모듈을 사용하려면 모듈에 종속된 프로젝트에 `.npmrc` 파일을 추가합니다. 예를 들어 [예제 프로젝트](https://gitlab.com/gitlab-examples/semantic-release-npm)의 모듈을 사용하려면:

```plaintext
@gitlab-examples:registry=https://gitlab.com/api/v4/packages/npm/
```

그런 다음 모듈을 설치합니다:

```shell
npm install --save @gitlab-examples/semantic-release-npm
```

## 문제 해결 {#troubleshooting}

### 삭제된 Git 태그 다시 나타남 {#deleted-git-tags-reappear}

리포지토리에서 삭제된 [Git 태그](../../user/project/repository/tags/_index.md)는 GitLab 러너가 리포지토리의 캐시된 버전을 사용할 때 `semantic-release`에 의해 때때로 다시 생성될 수 있습니다. 작업이 태그가 여전히 있는 캐시된 리포지토리가 있는 러너에서 실행되는 경우 `semantic-release`은 주 리포지토리에서 태그를 다시 생성합니다.

이 동작을 피하려면 다음 중 하나를 수행할 수 있습니다:

- 러너를 [`GIT_STRATEGY: clone`](../runners/configure_runners.md#git-strategy)로 구성합니다.
- CI/CD 변수 스크립트에 [`git fetch --prune-tags` 명령](https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---prune-tags)을 포함합니다.

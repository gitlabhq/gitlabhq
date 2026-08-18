---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: '튜토리얼: 복잡한 파이프라인 생성'
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 튜토리얼은 작은 반복적인 단계를 통해 점진적으로 더 복잡한 CI/CD 파이프라인을 구성하는 방법을 설명합니다. 파이프라인은 항상 완전히 작동하지만 각 단계마다 더 많은 기능을 얻습니다. 목표는 설명서 사이트를 빌드, 테스트 및 배포하는 것입니다.

이 튜토리얼을 완료하면 GitLab.com에 새 프로젝트가 생기고 [Docusaurus](https://docusaurus.io/)를 사용하는 작동하는 설명서 사이트를 갖게 됩니다.

이 튜토리얼을 완료하려면 다음을 수행합니다:

1. Docusaurus 파일을 보관할 프로젝트 생성
1. 초기 파이프라인 구성 파일 생성
1. 사이트를 빌드하는 작업 추가
1. 사이트를 배포하는 작업 추가
1. 작업 테스트 추가
1. 머지 리퀘스트 파이프라인 사용 시작
1. 중복된 구성 감소

## 전제 조건 {#prerequisites}

- GitLab.com에 계정이 필요합니다.
- Git에 익숙해야 합니다.
- 로컬 머신에 Node.js를 설치해야 합니다. 예를 들어 macOS에서는 [install node](https://formulae.brew.sh/formula/node)를 `brew install node`로 설치할 수 있습니다.

## Docusaurus 파일을 보관할 프로젝트 생성 {#create-a-project-to-hold-the-docusaurus-files}

파이프라인 구성을 추가하기 전에 먼저 GitLab.com에서 Docusaurus 프로젝트를 설정해야 합니다:

1. 사용자 이름 아래에 새 프로젝트를 생성합니다(그룹이 아님):
   1. 오른쪽 상단 모서리에서 **새로 만들기** ({{< icon name="plus" >}}) 및 **새 프로젝트/리포지토리**를 선택합니다.
   1. **빈 프로젝트 생성**을 선택합니다.
   1. 프로젝트 세부 정보를 입력합니다:
      - **프로젝트 이름** 필드에 프로젝트의 이름(예: `My Pipeline Tutorial Project`)을 입력합니다.
      - **README 파일을 포함하여 리포지토리 초기화**를 선택합니다.
   1. **프로젝트 생성**을 선택합니다.
1. 프로젝트의 개요 페이지의 오른쪽 위 모서리에서 **코드**를 선택하여 프로젝트의 클론 경로를 찾습니다. SSH 또는 HTTP 경로를 복사하고 경로를 사용하여 프로젝트를 로컬로 클론합니다.

   예를 들어 SSH로 컴퓨터의 `pipeline-tutorial` 디렉터리로 클론하려면:

   ```shell
   git clone git@gitlab.com:my-username/my-pipeline-tutorial-project.git pipeline-tutorial
   ```

1. 프로젝트의 디렉터리로 변경한 다음 새 Docusaurus 사이트를 생성합니다:

   ```shell
   cd pipeline-tutorial
   npm init docusaurus
   ```

   Docusaurus 초기화 마법사는 사이트에 대한 질문을 입력하라는 메시지를 표시합니다. 모든 기본 옵션을 사용합니다.

1. 초기화 마법사는 `website/`에 사이트를 설정하지만 사이트는 프로젝트의 루트에 있어야 합니다. 파일을 루트로 이동하고 이전 디렉터리를 삭제합니다:

   ```shell
   mv website/* .
   rm -r website
   ```

1. GitLab 프로젝트의 세부 정보로 Docusaurus 구성 파일을 업데이트합니다. `docusaurus.config.js`에서:

   - `url:`를 이 형식의 경로로 설정합니다: `https://<my-username>.gitlab.io/`.
   - `baseUrl:`를 프로젝트 이름(예: `/my-pipeline-tutorial-project/`)으로 설정합니다.

1. 변경 사항을 커밋하고 GitLab으로 푸시합니다:

   ```shell
   git add .
   git commit -m "Add simple generated Docusaurus site"
   git push origin
   ```

## 초기 CI/CD 구성 파일 생성 {#create-the-initial-cicd-configuration-file}

CI/CD가 프로젝트에서 활성화되고 러너가 작업을 실행할 수 있도록 가장 간단한 가능한 파이프라인 구성 파일로 시작합니다.

이 단계에서는 다음을 소개합니다:

- [작업](../jobs/_index.md): 이는 명령을 실행하는 파이프라인의 자체 포함된 부분입니다. 작업은 [러너](../runners/_index.md)에서 실행되고 GitLab 인스턴스와 분리됩니다.
- [`script`](../yaml/_index.md#script): 이는 작업 구성의 이 섹션으로 작업을 위한 명령을 정의하는 위치입니다. 여러 명령이 있는 경우(배열에서) 순서대로 실행됩니다. 각 명령은 CLI 명령으로 실행된 것처럼 실행됩니다. 기본적으로 명령이 실패하거나 오류를 반환하면 작업이 실패로 표시되고 더 이상 명령이 실행되지 않습니다.

이 단계에서 프로젝트의 루트에 `.gitlab-ci.yml` 파일을 생성하고 다음 구성을 사용합니다:

```yaml
test-job:
  script:
    - echo "This is my first job!"
    - date
```

이 변경 사항을 커밋하고 GitLab으로 푸시한 다음:

1. **빌드** > **파이프라인**으로 이동하고 GitLab에서 이 단일 작업으로 파이프라인이 실행되는지 확인합니다.
1. 파이프라인을 선택한 다음 작업을 선택하여 작업 로그를 보고 `This is my first job!` 메시지 뒤에 날짜를 확인합니다.

프로젝트에 `.gitlab-ci.yml` 파일이 있으면 [파이프라인 편집기](../pipeline_editor/_index.md)를 사용하여 파이프라인 구성을 모두 변경할 수 있습니다.

## 사이트를 빌드하는 작업 추가 {#add-a-job-to-build-the-site}

CI/CD 파이프라인의 일반적인 작업은 프로젝트의 코드를 빌드한 다음 배포하는 것입니다. 사이트를 빌드하는 작업을 추가하여 시작합니다.

이 단계에서는 다음을 소개합니다:

- [`image`](../yaml/_index.md#image): 러너에 작업을 실행하는 데 사용할 Docker 컨테이너를 알려줍니다. 러너:
  1. 컨테이너 이미지를 다운로드하고 시작합니다.
  1. 실행 중인 컨테이너에 GitLab 프로젝트를 클론합니다.
  1. `script` 명령을 한 번에 하나씩 실행합니다.
- [`artifacts`](../yaml/_index.md#artifacts): 작업은 자체 포함되어 있으며 서로 리소스를 공유하지 않습니다. 한 작업에서 생성된 파일을 다른 작업에서 사용하려면 먼저 아티팩트로 저장해야 합니다. 나중에 작업은 아티팩트를 검색하고 생성된 파일을 사용할 수 있습니다.

이 단계에서 `test-job`를 `build-job`로 바꿉니다:

- `image`를 사용하여 최신 `node` 이미지로 작업을 실행하도록 구성합니다. Docusaurus는 Node.js 프로젝트이고 `node` 이미지에는 필요한 `npm` 명령이 내장되어 있습니다.
- `npm install`를 실행하여 실행 중인 `node` 컨테이너에 Docusaurus를 설치한 다음 `npm run build`를 실행하여 사이트를 빌드합니다.
- Docusaurus는 빌드된 사이트를 `build/`에 저장하므로 이 파일을 `artifacts`로 저장합니다.

```yaml
build-job:
  image: node
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"
```

파이프라인 편집기를 사용하여 이 파이프라인 구성을 기본 브랜치에 커밋하고 작업 로그를 확인합니다. 다음을 수행할 수 있습니다.

- `npm` 명령이 실행되고 사이트가 빌드되는 것을 확인합니다.
- 아티팩트가 끝에 저장되는지 확인합니다.
- 작업이 완료된 후 작업 로그의 오른쪽에 있는 **탐색**을 선택하여 아티팩트 파일의 내용을 찹니다.

## 사이트를 배포하는 작업 추가 {#add-a-job-to-deploy-the-site}

Docusaurus 사이트가 `build-job`에서 빌드되는지 확인한 후 배포하는 작업을 추가할 수 있습니다.

이 단계에서는 다음을 소개합니다:

- [`stage`](../yaml/_index.md#stage) 및 [`stages`](../yaml/_index.md#stage): 가장 일반적인 파이프라인 구성은 작업을 스테이지로 그룹화합니다. 같은 스테이지의 작업은 병렬로 실행할 수 있지만 이후 스테이지의 작업은 이전 스테이지의 작업이 완료될 때까지 기다립니다. 작업이 실패하면 전체 스테이지가 실패한 것으로 간주되고 이후 스테이지의 작업은 실행되지 않습니다.
- [GitLab Pages](../../user/project/pages/_index.md): 정적 사이트를 호스팅하려면 GitLab Pages를 사용합니다.

이 단계에서:

- 빌드된 사이트를 가져와서 배포하는 작업을 추가합니다. GitLab Pages를 사용할 때 작업의 이름은 항상 `pages`입니다. `build-job`의 아티팩트가 자동으로 가져와져 작업으로 추출됩니다. Pages는 사이트를 `public/` 디렉터리에서 찾지만 `script` 명령을 추가하여 사이트를 해당 디렉터리로 이동합니다.
- `stages` 섹션을 추가하고 각 작업에 대한 스테이지를 정의합니다. `build-job`는 `build` 스테이지에서 먼저 실행되고 `pages`는 나중에 `deploy` 스테이지에서 실행됩니다.

```yaml
stages:          # List of stages for jobs and their order of execution
  - build
  - deploy

build-job:
  stage: build   # Set this job to run in the `build` stage
  image: node
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"

pages:
  stage: deploy  # Set this new job to run in the `deploy` stage
  script:
    - mv build/ public/
  artifacts:
    paths:
      - "public/"
```

파이프라인 편집기를 사용하여 이 파이프라인 구성을 기본 브랜치에 커밋하고 **파이프라인** 목록에서 파이프라인 세부 정보를 봅니다. 다음을 확인합니다:

- 두 작업이 다른 스테이지인 `build` 및 `deploy`에서 실행됩니다.
- `pages` 작업이 완료되면 `pages:deploy` 작업이 나타나고 이는 Pages 사이트를 배포하는 GitLab 프로세스입니다. 그 작업이 완료되면 새 Docusaurus 사이트를 방문할 수 있습니다.

사이트를 보려면:

- 왼쪽 사이드바에서 **배포** > **Pages**를 선택합니다.
- **고유 도메인 사용**이 꺼져 있는지 확인합니다.
- **Pages 액세스** 아래에서 링크를 선택합니다. URL 형식은 다음과 유사해야 합니다: `https://<my-username>.gitlab.io/<project-name>`. 자세한 내용은 [GitLab Pages 기본 도메인 이름](../../user/project/pages/getting_started_part_one.md#gitlab-pages-default-domain-names)을 참조하세요.

> [!note]
> [고유 도메인](../../user/project/pages/_index.md#unique-domains)을 사용해야 하는 경우 `docusaurus.config.js`에서 `baseUrl`를 `/`로 설정합니다.

## 작업 테스트 추가 {#add-test-jobs}

사이트가 예상대로 빌드되고 배포되면 이제 테스트와 린팅을 추가할 수 있습니다. 예를 들어 Ruby 프로젝트는 RSpec 작업 테스트를 실행할 수 있습니다. Docusaurus는 Markdown 및 생성된 HTML을 사용하는 정적 사이트이므로 이 튜토리얼은 Markdown 및 HTML을 테스트하는 작업을 추가합니다.

이 단계에서는 다음을 소개합니다:

- [`allow_failure`](../yaml/_index.md#allow_failure): 간헐적으로 실패하거나 실패할 것으로 예상되는 작업은 생산성을 저하시키거나 문제를 해결하기 어려울 수 있습니다. `allow_failure`를 사용하여 파이프라인 실행을 중단하지 않고 작업이 실패하도록 합니다.
- [`dependencies`](../yaml/_index.md#dependencies): `dependencies`를 사용하여 어떤 작업에서 아티팩트를 가져올지 나열하여 개별 작업의 아티팩트 다운로드를 제어합니다.

이 단계에서:

- `test` 스테이지를 추가합니다. 이는 `build` 및 `deploy` 사이에서 실행됩니다. 이 세 스테이지는 `stages`가 구성에서 정의되지 않을 때 기본 스테이지입니다.
- `lint-markdown` 작업을 추가하여 [markdownlint](https://github.com/DavidAnson/markdownlint)를 실행하고 프로젝트의 Markdown을 확인합니다. markdownlint는 Markdown 파일이 형식 표준을 따르는지 확인하는 정적 분석 도구입니다.
  - Docusaurus가 생성하는 샘플 Markdown 파일은 `blog/` 및 `docs/`에 있습니다.
  - 이 도구는 원본 Markdown 파일만 스캔하며 `build-job` 아티팩트에 저장된 생성된 HTML이 필요하지 않습니다. `dependencies: []`를 사용하여 작업의 속도를 높여 아티팩트를 가져오지 않도록 합니다.
  - 몇 가지 샘플 Markdown 파일이 기본 markdownlint 규칙을 위반하므로 `allow_failure: true`를 추가하여 규칙 위반에도 불구하고 파이프라인을 계속하도록 합니다.
- `test-html` 작업을 추가하여 [HTMLHint](https://htmlhint.com/)를 실행하고 생성된 HTML을 확인합니다. HTMLHint는 생성된 HTML에서 알려진 이슈를 스캔하는 정적 분석 도구입니다.
- `test-html` 및 `pages` 모두 `build-job` 아티팩트에서 찾은 생성된 HTML이 필요합니다. 작업은 기본적으로 이전 스테이지의 모든 작업에서 아티팩트를 가져오지만 `dependencies:`를 추가하여 향후 파이프라인 변경 후 작업이 실수로 다른 아티팩트를 다운로드하지 않도록 합니다.

```yaml
stages:
  - build
  - test               # Add a `test` stage for the test jobs
  - deploy

build-job:
  stage: build
  image: node
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"

lint-markdown:
  stage: test
  image: node
  dependencies: []     # Don't fetch any artifacts
  script:
    - npm install markdownlint-cli2 --global           # Install markdownlint into the container
    - markdownlint-cli2 -v                             # Verify the version, useful for troubleshooting
    - markdownlint-cli2 "blog/**/*.md" "docs/**/*.md"  # Lint all markdown files in blog/ and docs/
  allow_failure: true  # This job fails right now, but don't let it stop the pipeline.

test-html:
  stage: test
  image: node
  dependencies:
    - build-job        # Only fetch artifacts from `build-job`
  script:
    - npm install --save-dev htmlhint                  # Install HTMLHint into the container
    - npx htmlhint --version                           # Verify the version, useful for troubleshooting
    - npx htmlhint build/                              # Lint all markdown files in blog/ and docs/

pages:
  stage: deploy
  dependencies:
    - build-job        # Only fetch artifacts from `build-job`
  script:
    - mv build/ public/
  artifacts:
    paths:
      - "public/"
```

이 파이프라인 구성을 기본 브랜치에 커밋하고 파이프라인 세부 정보를 봅니다.

- `lint-markdown` 작업이 샘플 Markdown이 기본 markdownlint 규칙을 위반하여 실패하지만 실패가 허용됩니다. 다음을 수행할 수 있습니다.
  - 지금은 위반을 무시하세요. 튜토리얼의 일부로 수정할 필요가 없습니다.
  - Markdown 파일 위반을 수정합니다. 그런 다음 `allow_failure`를 `false`로 변경하거나 `allow_failure`를 완전히 제거할 수 있습니다. 왜냐하면 `allow_failure: false`는 정의되지 않을 때 기본 동작이기 때문입니다.
  - markdownlint 구성 파일을 추가하여 경고할 규칙 위반을 제한합니다.
- Markdown 파일 콘텐츠를 변경하고 다음 배포 후 사이트에서 변경 사항을 볼 수도 있습니다.

## 머지 리퀘스트 파이프라인 사용 시작 {#start-using-merge-request-pipelines}

이전 파이프라인 구성에서는 파이프라인이 성공적으로 완료될 때마다 사이트가 배포되지만 이는 이상적인 개발 워크플로가 아닙니다. 기능 브랜치 및 머지 리퀘스트에서 작업하고 변경 사항이 기본 브랜치로 병합될 때만 사이트를 배포하는 것이 좋습니다.

이 단계에서는 다음을 소개합니다:

- [`rules`](../yaml/_index.md#rules): 각 작업에 규칙을 추가하여 실행되는 파이프라인을 구성합니다. 작업을 [머지 리퀘스트 파이프라인](../pipelines/merge_request_pipelines.md), [예약된 파이프라인](../pipelines/schedules.md) 또는 기타 특정 상황에서 실행하도록 구성할 수 있습니다. 규칙은 위에서 아래로 평가되며 규칙이 일치하면 작업이 파이프라인에 추가됩니다.
- [CI/CD 변수](../variables/_index.md): 이 환경 변수를 사용하여 구성 파일 및 스크립트 명령에서 작업 동작을 구성합니다. [미리 정의된 CI/CD 변수](../variables/predefined_variables.md)는 수동으로 정의할 필요가 없는 변수입니다. 이 변수들은 파이프라인에 자동으로 주입되므로 파이프라인을 구성하는 데 사용할 수 있습니다. 변수는 일반적으로 `$VARIABLE_NAME`로 형식화되고 미리 정의된 변수는 일반적으로 `$CI_`로 접두사됩니다.

이 단계에서:

- 새 기능 브랜치를 만들고 기본 브랜치 대신 브랜치에서 변경 사항을 만듭니다.
- 각 작업에 `rules`를 추가합니다:
  - 사이트는 기본 브랜치에 대한 변경 사항에만 배포되어야 합니다.
  - 다른 작업은 머지 리퀘스트 또는 기본 브랜치의 모든 변경 사항에 대해 실행되어야 합니다.
- 이 파이프라인 구성을 사용하면 리소스를 절약하는 기능 브랜치에서 작업을 실행하지 않고도 작업할 수 있습니다. 변경 사항을 검증할 준비가 되면 머지 리퀘스트를 만들고 머지 리퀘스트에서 실행하도록 구성된 작업으로 파이프라인이 실행됩니다.
- 머지 리퀘스트가 수락되고 변경 사항이 기본 브랜치로 병합되면 `pages` 배포 작업도 포함된 새 파이프라인이 실행됩니다. 작업이 실패하지 않으면 사이트가 배포됩니다.

```yaml
stages:
  - build
  - test
  - deploy

build-job:
  stage: build
  image: node
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'  # Run for all changes to a merge request's source branch
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH       # Run for all changes to the default branch

lint-markdown:
  stage: test
  image: node
  dependencies: []
  script:
    - npm install markdownlint-cli2 --global
    - markdownlint-cli2 -v
    - markdownlint-cli2 "blog/**/*.md" "docs/**/*.md"
  allow_failure: true
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'  # Run for all changes to a merge request's source branch
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH       # Run for all changes to the default branch

test-html:
  stage: test
  image: node
  dependencies:
    - build-job
  script:
    - npm install --save-dev htmlhint
    - npx htmlhint --version
    - npx htmlhint build/
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'  # Run for all changes to a merge request's source branch
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH       # Run for all changes to the default branch

pages:
  stage: deploy
  dependencies:
    - build-job
  script:
    - mv build/ public/
  artifacts:
    paths:
      - "public/"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH      # Run for all changes to the default branch only
```

머지 리퀘스트의 변경 사항을 병합합니다. 이 작업은 기본 브랜치를 업데이트합니다. 새 파이프라인이 사이트를 배포하는 `pages` 작업을 포함하는지 확인합니다.

모든 향후 파이프라인 구성 변경에 기능 브랜치 및 머지 리퀘스트를 사용하세요. Git 태그를 생성하거나 파이프라인 일정을 추가하는 것과 같은 다른 프로젝트 변경은 이러한 경우에 대한 규칙도 추가하지 않으면 파이프라인을 트리거하지 않습니다.

## 중복된 구성 감소 {#reduce-duplicated-configuration}

파이프라인에는 이제 동일한 `rules` 및 `image` 구성이 모두 있는 세 작업이 포함되어 있습니다. 이 규칙을 반복하는 대신 `extends` 및 `default`를 사용하여 단일 정보 소스를 만듭니다.

이 단계에서는 다음을 소개합니다:

- [숨겨진 작업](../jobs/_index.md#hide-a-job): `.`로 시작하는 작업은 파이프라인에 추가되지 않습니다. 이를 사용하여 재사용하려는 구성을 보관합니다.
- [`extends`](../yaml/_index.md#extends): 확장을 사용하여 여러 위치(종종 숨겨진 작업에서)의 구성을 반복합니다. 숨겨진 작업의 구성을 업데이트하면 숨겨진 작업을 확장하는 모든 작업이 업데이트된 구성을 사용합니다.
- [`default`](../yaml/_index.md#default): 정의되지 않을 때 모든 작업에 적용되는 키워드 기본값을 설정합니다.
- YAML 재정의: `extends` 또는 `default`를 사용하여 구성을 재사용할 때 작업의 키워드를 명시적으로 정의하여 `extends` 또는 `default` 구성을 재정의할 수 있습니다.

이 단계에서:

- `.standard-rules` 숨겨진 작업을 추가하여 `build-job`, `lint-markdown` 및 `test-html`에서 반복되는 규칙을 보관합니다.
- `extends`를 사용하여 세 작업에서 `.standard-rules` 구성을 재사용합니다.
- `default` 섹션을 추가하여 `image` 기본값을 `node`로 정의합니다.
- `pages` 배포 작업은 기본 `node` 이미지가 필요하지 않으므로 명시적으로 [`busybox`](https://hub.docker.com/_/busybox)를 사용합니다. 이는 매우 작고 빠른 이미지입니다.

```yaml
stages:
  - build
  - test
  - deploy

default:               # Add a default section to define the `image` keyword's default value
  image: node

.standard-rules:       # Make a hidden job to hold the common rules
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

build-job:
  extends:
    - .standard-rules  # Reuse the configuration in `.standard-rules` here
  stage: build
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"

lint-markdown:
  stage: test
  extends:
    - .standard-rules  # Reuse the configuration in `.standard-rules` here
  dependencies: []
  script:
    - npm install markdownlint-cli2 --global
    - markdownlint-cli2 -v
    - markdownlint-cli2 "blog/**/*.md" "docs/**/*.md"
  allow_failure: true

test-html:
  stage: test
  extends:
    - .standard-rules  # Reuse the configuration in `.standard-rules` here
  dependencies:
    - build-job
  script:
    - npm install --save-dev htmlhint
    - npx htmlhint --version
    - npx htmlhint build/

pages:
  stage: deploy
  image: busybox       # Override the default `image` value with `busybox`
  dependencies:
    - build-job
  script:
    - mv build/ public/
  artifacts:
    paths:
      - "public/"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

머지 리퀘스트를 사용하여 이 파이프라인 구성을 기본 브랜치에 커밋합니다. 파일이 더 간단하지만 이전 단계와 동일한 동작을 가져야 합니다.

전체 파이프라인을 만들고 더 효율적으로 만들었습니다. 잘했습니다! 이제 이 지식을 가지고 `.gitlab-ci.yml` 키워드의 나머지를 배우고 [CI/CD YAML 구문 참조](../yaml/_index.md)에서 고유한 파이프라인을 빌드할 수 있습니다.

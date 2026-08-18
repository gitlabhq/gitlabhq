---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab CI/CD에서 작업 아티팩트를 만들고, 다운로드하고, 탐색하고, 관리합니다."
title: 작업 아티팩트
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

작업은 파일과 디렉터리의 아카이브를 출력할 수 있습니다. 이 출력은 작업 아티팩트로 알려져 있습니다. 아티팩트에는 빌드 출력 또는 보고서 파일이 포함될 수 있습니다. 기본적으로, 이후 작업은 이전 스테이지의 작업에서 모든 아티팩트의 복사본을 가져옵니다.

예를 들어, 초기 작업은 프로젝트를 빌드하고 출력을 아티팩트로 저장할 수 있습니다. 그러면 이후 작업은 아티팩트를 가져오고 저장된 빌드 출력에서 테스트를 실행합니다.

`artifacts` 키워드에 대한 전체 지원 구성 목록은 [GitLab CI/CD YAML 구문 참조](../yaml/_index.md#artifacts)를 참조하세요.

관련 항목:

- [작업 아티팩트 API](../../api/job_artifacts.md)
- [작업 아티팩트 관리](../../administration/cicd/job_artifacts.md)

## 작업 아티팩트 만들기 {#create-job-artifacts}

작업 아티팩트를 만들려면 `artifacts` 키워드를 `.gitlab-ci.yml` 파일에서 사용하세요:

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
      - mycv.pdf
```

이 예에서 `pdf`라는 작업은 `xelatex` 명령을 호출하여 LaTeX 소스 파일 `mycv.tex`에서 PDF 파일을 빌드합니다.

`paths` 키워드는 작업 아티팩트에 추가할 파일을 결정합니다. 파일 및 디렉터리에 대한 모든 경로는 작업이 생성된 리포지토리에 상대적입니다.

### 와일드카드 사용 {#with-wildcards}

경로 및 디렉터리에 와일드카드를 사용할 수 있습니다. 예를 들어, `xyz`로 끝나는 디렉터리 내의 모든 파일이 포함된 아티팩트를 만들려면:

```yaml
job:
  script: echo "build xyz project"
  artifacts:
    paths:
      - path/*xyz/*
```

### 만료 시간 지정 {#with-an-expiry}

`expire_in` 키워드는 GitLab이 `artifacts:paths`에 정의된 아티팩트를 유지하는 기간을 결정합니다. 예를 들어:

```yaml
pdf:
  script: xelatex mycv.tex
  artifacts:
    paths:
      - mycv.pdf
    expire_in: 1 week
```

`expire_in`이 정의되지 않으면 [**기본 아티팩트 만료**](../../administration/settings/continuous_integration.md#set-default-artifacts-expiration) 인스턴스 설정이 사용됩니다.

아티팩트가 만료되는 것을 방지하려면 작업 세부 정보 페이지에서 **유지**를 선택할 수 있습니다. 아티팩트가 만료 시간 집합이 없을 때는 이 옵션을 사용할 수 없습니다.

기본적으로 각 ref의 가장 최근에 성공한 파이프라인에 대해 아티팩트가 항상 유지됩니다.

### 명시적으로 정의된 아티팩트 이름 {#with-an-explicitly-defined-artifact-name}

`artifacts:name` 구성을 사용하여 아티팩트 이름을 명시적으로 사용자 지정할 수 있습니다:

```yaml
job:
  artifacts:
    name: "job1-artifacts-file"
    paths:
      - binaries/
```

### 제외된 파일 없음 {#without-excluded-files}

`artifacts:exclude`를 사용하여 파일이 아티팩트 아카이브에 추가되는 것을 방지합니다.

예를 들어 `binaries/`의 모든 파일을 저장하되 `binaries/`의 하위 디렉터리에 위치한 `*.o` 파일은 저장하지 않으려면:

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/**/*.o
```

`artifacts:paths`와 달리 `exclude` 경로는 재귀적이지 않습니다. 디렉터리의 모든 내용을 제외하려면 디렉터리 자체를 일치시키는 대신 명시적으로 일치시키세요.

예를 들어 `binaries/`의 모든 파일을 저장하되 `temp/` 하위 디렉터리에 위치한 내용은 저장하지 않으려면:

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/temp/**/*
```

### 추적되지 않은 파일 포함 {#with-untracked-files}

`artifacts:untracked`를 사용하여 모든 Git 추적되지 않은 파일을 `artifacts:paths`에 정의된 경로와 함께 아티팩트로 추가합니다. 추적되지 않은 파일은 리포지토리에 추가되지 않았지만 리포지토리 체크아웃에 존재하는 파일입니다.

예를 들어 모든 Git 추적되지 않은 파일 및 `binaries`의 파일을 저장하려면:

```yaml
artifacts:
  untracked: true
  paths:
    - binaries/
```

예를 들어 모든 추적되지 않은 파일을 저장하되 `*.txt` 파일은 제외하려면:

```yaml
artifacts:
  untracked: true
  exclude:
    - "*.txt"
```

### 변수 확장 포함 {#with-variable-expansion}

변수 확장은 `artifacts:name`, `artifacts:paths`, `artifacts:exclude`에 대해 지원됩니다.

셸 사용 대신 GitLab 러너는 내부 변수 확장 메커니즘을 사용합니다. 이 컨텍스트에서는 CI/CD 변수만 지원됩니다.

예를 들어 현재 브랜치 또는 태그 이름을 사용하고 현재 프로젝트의 이름을 딴 디렉터리에서만 파일을 포함하는 아카이브를 만들려면:

```yaml
job:
  artifacts:
    name: "$CI_COMMIT_REF_NAME"
    paths:
      - binaries/${CI_PROJECT_NAME}/
```

브랜치 이름에 슬래시가 포함되어 있으면(예: `feature/my-feature`) 적절한 아티팩트 이름을 지정하려면 `$CI_COMMIT_REF_NAME` 대신 `$CI_COMMIT_REF_SLUG`를 사용하세요.

변수는 glob보다 먼저 확장됩니다.

## 아티팩트 가져오기 {#fetching-artifacts}

기본적으로 작업은 이전 스테이지에 정의된 작업에서 모든 아티팩트를 가져옵니다. 이러한 아티팩트는 작업의 작업 디렉터리로 다운로드됩니다.

`dependencies` 또는 `needs:artifacts` 키워드를 사용하여 다운로드할 아티팩트를 제어할 수 있습니다.

이러한 키워드를 사용하면 기본 동작이 변경되고 아티팩트는 지정한 작업에서만 가져옵니다.

### 작업이 아티팩트를 가져오는 것을 방지합니다 {#prevent-a-job-from-fetching-artifacts}

작업이 아티팩트를 다운로드하지 않도록 하려면 `dependencies`을 빈 배열(`[]`)로 설정하세요:

```yaml
job:
  stage: test
  script: make build
  dependencies: []
```

## 프로젝트의 모든 작업 아티팩트 보기 {#view-all-job-artifacts-in-a-project}

프로젝트에 저장된 모든 아티팩트는 **빌드** > **아티팩트** 페이지에서 볼 수 있습니다. 이 목록은 모든 작업과 관련 아티팩트를 표시합니다. 항목을 확장하여 작업과 관련된 모든 아티팩트에 액세스합니다:

- `artifacts:` 키워드로 만든 아티팩트.
- 보고서 아티팩트.
- 작업 로그 및 메타데이터는 별도의 아티팩트로 내부적으로 저장됩니다.

이 목록에서 개별 아티팩트를 다운로드하거나 삭제할 수 있습니다.

## 작업 아티팩트 다운로드 {#download-job-artifacts}

GitLab UI 또는 API를 사용하여 작업 아티팩트를 다운로드할 수 있습니다.

GitLab UI에서 다음 위치에서 작업 아티팩트를 다운로드할 수 있습니다:

- 모든 **파이프라인** 목록. 파이프라인 오른쪽에서 **아티팩트 다운로드**({{< icon name="download" >}})를 선택합니다.
- 모든 **작업** 목록. 작업 오른쪽에서 **아티팩트 다운로드**({{< icon name="download" >}})를 선택합니다.
- 작업 세부 정보 페이지. 페이지 오른쪽에서 **다운로드**를 선택합니다.
- 머지 리퀘스트 **개요** 페이지. 최신 파이프라인 오른쪽에서 **아티팩트**({{< icon name="download" >}})를 선택합니다.
- **아티팩트** 페이지. 작업 오른쪽에서 **다운로드**({{< icon name="download" >}})를 선택합니다.
- 아티팩트 브라우저. 페이지 상단에서 **아티팩트 아카이브 다운로드**({{< icon name="download" >}})를 선택합니다.

[보고서 아티팩트](../yaml/artifacts_reports.md)는 **파이프라인** 목록 또는 **아티팩트** 페이지에서만 다운로드할 수 있습니다.

### URL에서 {#from-a-url}

공개적으로 액세스 가능한 URL을 사용하여 특정 작업에 대한 아티팩트 아카이브를 다운로드할 수 있습니다.

예를 들어 GitLab.com의 프로젝트에서 `main` 브랜치에서 `build`이라는 작업의 최신 아티팩트를 다운로드하려면:

```plaintext
https://gitlab.com/api/v4/projects/<project-id>/jobs/artifacts/main/download?job=build
```

아티팩트에서 특정 파일을 다운로드하려면:

```plaintext
https://gitlab.com/api/v4/projects/<project-id>/jobs/artifacts/main/raw/review/index.html?job=build
```

이 끝점에서 반환된 파일은 항상 `plain/text` 콘텐츠 유형을 갖습니다.

두 예에서 모두 `<project-id>`을 유효한 프로젝트 ID로 바꾸세요. [프로젝트 개요 페이지](../../user/project/working_with_projects.md#find-the-project-id)에서 프로젝트 ID를 찾을 수 있습니다.

상위 및 하위 파이프라인의 아티팩트는 상위에서 하위로의 계층 순서로 검색됩니다. 예를 들어 상위 및 하위 파이프라인이 모두 동일한 이름의 작업을 가지고 있으면 상위 파이프라인에서 아티팩트가 반환됩니다.

### CI/CD 작업 토큰 사용 {#with-a-cicd-job-token}

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD 작업 토큰을 사용하여 작업 아티팩트 API 끝점으로 인증하고 다른 파이프라인에서 아티팩트를 가져올 수 있습니다. 예를 들어 어떤 작업에서 아티팩트를 검색할 지 지정해야 합니다:

```yaml
build_submodule:
  stage: test
  script:
    - apt update && apt install -y unzip
    - |
      curl --location --output artifacts.zip \
        --url "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test&job_token=$CI_JOB_TOKEN"
    - unzip artifacts.zip
```

동일한 파이프라인의 작업에서 아티팩트를 가져오려면 `needs:artifacts` 키워드를 사용합니다.

### 작업 아티팩트를 다운로드할 수 있는 사용자 제어 {#control-who-can-download-artifacts}

작업 아티팩트 다운로드 권한을 가진 사용자를 제한하려면 `artifacts:access` 키워드를 `.gitlab-ci.yml` 파일에서 사용합니다. 예를 들어:

```yaml
job:
  artifacts:
    access: maintainer
    paths:
      - build/
```

## 아티팩트 아카이브의 내용 탐색 {#browse-the-contents-of-the-artifacts-archive}

아티팩트 아카이브를 로컬로 다운로드하지 않고 UI에서 아티팩트의 내용을 탐색할 수 있습니다:

- 모든 **작업** 목록. 작업 오른쪽에서 **탐색**({{< icon name="folder-open" >}})을 선택합니다.
- 작업 세부 정보 페이지. 페이지 오른쪽에서 **탐색**을 선택합니다.
- **아티팩트** 페이지. 작업 오른쪽에서 **탐색**({{< icon name="folder-open" >}})을 선택합니다.

GitLab Pages가 전역적으로 활성화되면 프로젝트 설정에서 비활성화된 경우에도 브라우저에서 일부 아티팩트 파일 확장명을 직접 미리 볼 수 있습니다. 프로젝트가 내부 또는 비공개인 경우 미리 보기를 활성화하려면 GitLab Pages 액세스 제어를 활성화해야 합니다.

다음 확장명이 지원됩니다:

| 파일 확장명 | GitLab.com  | 기본 제공 NGINX가 포함된 Linux 패키지 |
|----------------|-------------|-----------------------------------|
| `.html`        | {{< yes >}} | {{< yes >}}                       |
| `.json`        | {{< yes >}} | {{< yes >}}                       |
| `.xml`         | {{< yes >}} | {{< yes >}}                       |
| `.txt`         | {{< no >}}  | {{< yes >}}                       |
| `.log`         | {{< no >}}  | {{< yes >}}                       |

### URL에서 {#from-a-url-1}

특정 작업의 최신 성공 파이프라인에 대한 작업 아티팩트를 공개적으로 액세스 가능한 URL로 탐색할 수 있습니다.

예를 들어 GitLab.com의 프로젝트에서 `main` 브랜치에서 `build`이라는 작업의 최신 아티팩트를 탐색하려면:

```plaintext
https://gitlab.com/<full-project-path>/-/jobs/artifacts/main/browse?job=build
```

`<full-project-path>`을 유효한 프로젝트 경로로 바꾸세요. 프로젝트의 URL에서 찾을 수 있습니다.

## 최대 아티팩트 크기 설정 {#set-the-maximum-artifacts-size}

작업 아티팩트에 대한 크기 제한을 설정하여 스토리지 사용량을 제어합니다. 작업의 각 아티팩트 파일의 기본 최대 크기는 100MB입니다.

> [!note]
> 이 설정은 최종 아카이브 파일의 크기에 적용되며 작업의 개별 파일이 아닙니다.

다음에 대한 아티팩트 크기 제한을 구성할 수 있습니다:

- [인스턴스](../../administration/cicd/limits.md#maximum-artifacts-size): 모든 프로젝트 및 그룹에 적용되는 기본 설정입니다.
- 그룹: 그룹의 모든 프로젝트에 대한 인스턴스 설정을 재정의합니다.
- 프로젝트: 특정 프로젝트에 대해 인스턴스 및 그룹 설정을 모두 재정의합니다.

그룹 또는 프로젝트의 최대 아티팩트 크기를 변경하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **일반 파이프라인**을 확장합니다.
1. **최대 아티팩트 크기**의 값을 변경합니다(MB).
1. **변경사항 저장**을 선택합니다.

## 작업 로그 및 아티팩트 삭제 {#delete-job-log-and-artifacts}

> [!warning]
> 작업 로그 및 아티팩트 삭제는 복구할 수 없는 파괴적 작업입니다. 주의하여 사용하세요. 보고서 아티팩트, 작업 로그, 메타데이터 파일을 포함한 특정 파일을 삭제하면 이러한 파일을 데이터 소스로 사용하는 GitLab 기능에 영향을 미칩니다.

작업의 아티팩트 및 로그를 삭제할 수 있습니다.

전제 조건:

- 작업의 소유자이거나 프로젝트에 대한 유지 보수자 또는 소유자 역할을 가진 사용자여야 합니다.

작업을 삭제하려면:

1. 작업 세부 정보 페이지로 이동합니다.
1. 작업 로그의 오른쪽 상단 모서리에서 **작업 로그 및 아티팩트 삭제**({{< icon name="remove" >}})를 선택합니다.

**아티팩트** 페이지에서 개별 아티팩트를 삭제할 수도 있습니다.

### 아티팩트 일괄 삭제 {#bulk-delete-artifacts}

동시에 여러 아티팩트를 삭제할 수 있습니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **아티팩트**를 선택합니다.
1. 삭제할 아티팩트 옆의 확인란을 선택합니다. 최대 100개의 아티팩트를 선택할 수 있습니다.
1. **선택 항목 삭제**를 선택합니다.

## 머지 리퀘스트 UI에서 작업 아티팩트에 연결 {#link-to-job-artifacts-in-the-merge-request-ui}

`artifacts:expose_as` 키워드를 사용하여 머지 리퀘스트 UI에서 아티팩트에 직접 액세스할 수 있습니다.

예를 들어 단일 파일이 있는 아티팩트의 경우:

```yaml
test:
  script: ["echo 'test' > file.txt"]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['file.txt']
```

이 구성을 사용하면 **노출된 아티팩트 보기** 섹션에 `file.txt`에 대한 링크가 **artifact 1** 레이블과 함께 표시됩니다.

![노출된 아티팩트에 연결하는 머지 리퀘스트 위젯.](img/mr_artifact_expose_v18_4.png)

## 가장 최근에 성공한 작업에서 아티팩트 유지 {#keep-artifacts-from-most-recent-successful-jobs}

기본적으로 각 ref의 가장 최근에 성공한 파이프라인에 대해 아티팩트가 항상 유지됩니다. `expire_in` 구성은 가장 최근의 아티팩트에 적용되지 않습니다.

동일한 ref의 새 파이프라인이 성공적으로 완료되면 이전 파이프라인의 아티팩트는 `expire_in` 구성에 따라 삭제됩니다. 새 파이프라인의 아티팩트는 자동으로 유지됩니다.

파이프라인의 아티팩트는 `expire_in` 구성에 따라 새 파이프라인이 동일한 ref를 위해 실행되는 경우에만 삭제됩니다:

- 성공합니다.
- 수동 작업에 의해 차단되어 실행을 중지합니다.

최신 아티팩트 유지는 많은 작업 또는 큰 아티팩트가 있는 프로젝트에서 많은 스토리지 공간을 사용할 수 있습니다. 프로젝트에서 최신 아티팩트가 필요하지 않으면 이 동작을 비활성화하여 공간을 절약할 수 있습니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **아티팩트**를 확장합니다.
1. **가장 최근에 성공한 작업의 아티팩트 유지** 확인란을 선택 해제합니다.

이 설정을 비활성화한 후 모든 새로운 아티팩트는 `expire_in` 구성에 따라 만료됩니다. 이전 파이프라인의 아티팩트는 동일한 ref를 위해 새 파이프라인이 실행될 때까지 유지됩니다. 그 후 해당 ref에 대한 이전 파이프라인의 아티팩트도 만료되도록 허용됩니다.

GitLab Self-Managed의 모든 프로젝트에 대해 [**Keep artifacts from latest successful pipelines**](../../administration/settings/continuous_integration.md#keep-artifacts-from-latest-successful-pipelines) 인스턴스 설정으로 이 동작을 비활성화할 수 있습니다.

GitLab Self-Managed의 모든 프로젝트에 대해 [인스턴스의 CI/CD 설정](../../administration/settings/continuous_integration.md#keep-artifacts-from-latest-successful-pipelines)에서 이 동작을 비활성화할 수 있습니다.

## 관련 항목 {#related-topics}

- [dotenv 보고서 아티팩트로 작업 간 환경 변수 전달](../variables/dotenv_variables.md)

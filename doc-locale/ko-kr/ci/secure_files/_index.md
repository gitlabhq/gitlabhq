---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 수준의 보안 파일
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [일반 공개 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/350748) 및 기능 플래그 `ci_secure_files`가 GitLab 15.7에서 제거되었습니다.

{{< /history >}}

이 기능은 [Mobile DevOps](../mobile_devops/_index.md)의 일부입니다. 이 기능은 아직 개발 중이지만 다음을 수행할 수 있습니다:

- [기능 요청](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?description_template=feature_request)을 제출합니다.
- [버그를 보고](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?description_template=report_bug)합니다.
- [피드백을 공유](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?description_template=general_feedback)합니다.

CI/CD 파이프라인에서 사용하기 위해 최대 100개의 파일을 안전하게 저장할 수 있습니다. 이러한 파일은 프로젝트의 리포지토리 외부에 안전하게 저장되며 버전 관리되지 않습니다. 이러한 파일에 민감한 정보를 저장하는 것은 안전합니다. 보안 파일은 일반 텍스트와 이진 파일 형식을 모두 지원하지만 5MB 이하여야 합니다.

프로젝트 설정에서 또는 [보안 파일 API](../../api/secure_files.md)를 사용하여 보안 파일을 관리할 수 있습니다.

보안 파일은 [CI/CD 작업에 의해 다운로드되고 사용](#use-secure-files-in-cicd-jobs)될 수 있으며 [`glab securefile`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/securefile) 명령을 사용하여 수행할 수 있습니다.

## 프로젝트에 보안 파일 추가 {#add-a-secure-file-to-a-project}

프로젝트에 보안 파일을 추가하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **Secure Files** 섹션을 확장합니다.
1. **파일 업로드**를 선택합니다.
1. 업로드할 파일을 찾아 **열기**를 선택하면 파일 업로드가 즉시 시작됩니다. 업로드가 완료되면 파일이 목록에 표시됩니다.

## CI/CD 작업에서 보안 파일 사용 {#use-secure-files-in-cicd-jobs}

> [!warning]
> 보안 파일의 내용은 작업 로그 출력에서 [마스킹](../variables/_index.md#mask-a-cicd-variable)되지 않습니다. 특히 민감한 정보를 포함할 수 있는 로깅 출력을 할 때는 작업 로그에 보안 파일 내용을 출력하지 않도록 주의합니다.

### `glab` 도구 {#with-the-glab-tool}

[`glab`](https://gitlab.com/gitlab-org/cli/)를 사용하여 하나 이상의 보안 파일을 다운로드하려면 CI/CD 작업에서 `cli` Docker 이미지를 사용할 수 있습니다.

#### 프로젝트의 모든 파일 다운로드 {#download-all-the-files-in-a-project}

프로젝트의 모든 보안 파일을 다운로드하려면:

```yaml
test:
  image: registry.gitlab.com/gitlab-org/cli:latest
  script:
    - glab auth login --job-token $CI_JOB_TOKEN --hostname $CI_SERVER_FQDN --api-protocol $CI_SERVER_PROTOCOL
    - glab -R $CI_PROJECT_PATH securefile download --all --output-dir="where/to/save"
```

이 예제에서 모든 변수는 자동으로 사용 가능한 [미리 정의된 변수](../variables/predefined_variables.md)입니다.

#### 프로젝트의 단일 파일 다운로드 {#download-a-single-file-in-a-project}

```yaml
test:
  image: registry.gitlab.com/gitlab-org/cli:latest
  script:
    - glab auth login --job-token $CI_JOB_TOKEN --hostname $CI_SERVER_FQDN --api-protocol $CI_SERVER_PROTOCOL
    - glab -R $CI_PROJECT_PATH securefile download $SECURE_FILE_ID --path="where/to/save/file.txt"
```

`SECURE_FILE_ID` CI/CD 변수는 명시적으로 작업에 전달되어야 합니다. 예를 들어 [CI/CD 설정](../variables/_index.md#define-a-cicd-variable-in-the-ui)에서 또는 [파이프라인을 수동으로 실행](../pipelines/_index.md#run-a-pipeline-manually)할 때입니다. 다른 모든 변수는 자동으로 사용 가능한 [미리 정의된 변수](../variables/predefined_variables.md)입니다.

또는 Docker 이미지를 사용하는 대신 [바이너리를 다운로드](https://gitlab.com/gitlab-org/cli/-/releases)할 수 있습니다. 그리고 CI/CD 작업에서 사용합니다.

### `download-secure-files` 도구(더 이상 사용되지 않음) {#with-the-download-secure-files-tool-deprecated}

{{< history >}}

- GitLab 18.6에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/issues/45).

{{< /history >}}

> [!warning]
> 이 방법은 더 이상 사용되지 않습니다.

CI/CD 작업에서 보안 파일을 사용하려면 [`download-secure-files`](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files) 도구를 사용하여 작업에서 파일을 다운로드할 수 있습니다. 다운로드 후 다른 스크립트 명령과 함께 사용할 수 있습니다.

작업의 `script` 섹션에 명령을 추가하여 `download-secure-files` 도구를 다운로드하고 실행합니다. 파일은 프로젝트의 루트에 있는 `.secure_files` 디렉토리로 다운로드됩니다. 보안 파일의 다운로드 위치를 변경하려면 `SECURE_FILES_DOWNLOAD_PATH` [CI/CD 변수](../variables/_index.md)에서 경로를 설정합니다.

예를 들어:

```yaml
test:
  variables:
    SECURE_FILES_DOWNLOAD_PATH: './where/files/should/go/'
  script:
    - curl --silent "https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/download-secure-files/-/raw/main/installer" | bash
```

## 보안 세부 정보 {#security-details}

프로젝트 수준의 보안 파일은 [Lockbox](https://github.com/ankane/lockbox) Ruby gem을 사용하여 업로드 시 암호화되며 [`Ci::SecureFileUploader`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/uploaders/ci/secure_file_uploader.rb) 인터페이스를 사용합니다. 이 인터페이스는 업로드 중에 소스 파일의 SHA256 체크섬을 생성하고 데이터베이스의 레코드와 함께 저장되므로 다운로드 시 파일의 내용을 확인하는 데 사용할 수 있습니다.

[고유한 암호화 키](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/secure_file.rb#L27)는 파일이 생성될 때 각 파일에 대해 생성되고 데이터베이스에 저장됩니다. 암호화된 업로드 파일은 [GitLab 인스턴스 구성](../../administration/cicd/secure_files.md)에 따라 로컬 저장소 또는 객체 저장소에 저장됩니다.

개별 파일은 [보안 파일 다운로드 API](../../api/secure_files.md#download-a-secure-file)로 검색할 수 있습니다. 메타데이터는 [목록](../../api/secure_files.md#list-all-secure-files-for-a-project) 또는 [표시](../../api/secure_files.md#retrieve-details-of-a-secure-file) API 엔드포인트로 검색할 수 있습니다. 파일은 또한 [`glab securefile`](https://gitlab.com/gitlab-org/cli/-/tree/main/docs/source/securefile) 명령으로도 검색할 수 있습니다. 이 명령은 다운로드할 때 각 파일의 체크섬을 자동으로 확인합니다.

Developer, Maintainer 또는 Owner 역할을 가진 모든 프로젝트 구성원은 프로젝트 수준의 보안 파일에 액세스할 수 있습니다. 프로젝트 수준의 보안 파일과의 상호작용은 감사 이벤트에 포함되지 않지만 [이슈 117](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/readme/-/issues/117)에서는 이 기능을 추가할 것을 제안합니다.

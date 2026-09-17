---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 컨테이너 스캐닝 문제 해결
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

컨테이너 스캐닝을 사용할 때 다음과 같은 문제가 발생할 수 있습니다.

## 상세 로깅 활성화 {#enable-verbose-logging}

컨테이너 스캐닝 작업이 정확히 무엇을 수행하는지 자세히 보려면 상세 출력을 활성화합니다. 자세한 내용은 [디버그 수준 로깅](../troubleshooting_application_security.md#turn-on-debug-level-logging)을 참조하세요.

## `docker: Error response from daemon: failed to copy xattrs` {#docker-error-response-from-daemon-failed-to-copy-xattrs}

러너가 `docker` 실행기를 사용하고 NFS가 사용되는 경우(예: `/var/lib/docker`가 NFS 마운트에 있음) 컨테이너 스캐닝이 다음과 같은 오류로 실패할 수 있습니다:

```plaintext
docker: Error response from daemon: failed to copy xattrs: failed to set xattr "security.selinux" on /path/to/file: operation not supported.
```

이 오류는 현재 [수정된](https://github.com/containerd/continuity/pull/138 "fs: add WithAllowXAttrErrors CopyOpt") Docker의 버그로 인한 것입니다. 오류를 방지하려면 러너가 사용하는 Docker 버전이 `18.09.03` 이상인지 확인합니다. 자세한 내용은 [이슈 #10241](https://gitlab.com/gitlab-org/gitlab/-/issues/10241 "NFS 마운트에서 컨테이너 스캐닝이 작동하지 않는 이유 조사")를 참조합니다.

## 오류: `gl-container-scanning-report.json: no matching files` {#error-gl-container-scanning-reportjson-no-matching-files}

자세한 내용은 [일반 애플리케이션 보안 문제 해결 섹션](../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload)을 참조합니다.

## 오류: `unexpected status code 401 Unauthorized: Not Authorized` {#error-unexpected-status-code-401-unauthorized-not-authorized}

이 오류는 AWS ECR에서 이미지를 스캔하고 AWS 영역이 구성되지 않은 경우에 발생할 수 있습니다. 스캐너가 인증 토큰을 검색할 수 없습니다. `SECURE_LOG_LEVEL`을 `debug`로 설정하면 다음과 같은 로그 메시지가 표시됩니다:

```shell
[35mDEBUG[0m failed to get authorization token: MissingRegion: could not find region configuration
```

이를 해결하려면 `AWS_DEFAULT_REGION`을 CI/CD 변수에 추가합니다:

```yaml
variables:
  AWS_DEFAULT_REGION: <AWS_REGION_FOR_ECR>
```

## 오류: `unable to open a file: open /home/gitlab/.cache/trivy/ee/db/metadata.json` {#error-unable-to-open-a-file-open-homegitlabcachetrivyeedbmetadatajson}

압축된 Trivy 데이터베이스는 컨테이너의 `/tmp` 폴더에 저장되며 런타임에 `/home/gitlab/.cache/trivy/{ee|ce}/db`로 추출됩니다. 러너 구성에서 `/tmp` 디렉토리에 대한 볼륨 마운트가 있으면 이 오류가 발생할 수 있습니다.

이 문제를 해결하려면 `/tmp` 폴더를 바인딩하는 대신 `/tmp`의 특정 파일 또는 폴더를 바인딩합니다(예: `/tmp/myfile.txt`).

## 오류: `context deadline exceeded` {#error-context-deadline-exceeded}

이 오류는 시간 초과가 발생했음을 의미합니다. 이를 해결하려면 `TRIVY_TIMEOUT` 환경 변수를 충분히 긴 기간으로 `container_scanning` 작업에 추가합니다.

## 이전 이미지를 기반으로 한 이미지에서 감지된 취약성 없음 {#no-vulnerabilities-detected-on-images-based-on-an-old-image}

Trivy는 더 이상 업데이트를 받지 않는 운영 체제 이미지를 스캔하지 않습니다.

UI에서 이를 표시하는 것은 [이슈 433325](https://gitlab.com/gitlab-org/gitlab/-/issues/433325)에 제안되어 있습니다.

## 예상된 취약성이 감지되지 않음 {#expected-vulnerabilities-not-detected}

Trivy는 기본적으로 [언어별 발견 사항](_index.md#report-language-specific-findings)을 보고하지 않으며, 이미지에 취약한 운영 체제 종속성이 없을 때 빈 보고서가 나타날 수 있습니다. 언어별 발견 사항을 활성화하려면 연결된 설명서의 단계를 따르고 스캔을 다시 실행합니다.

## 경고: `vulnerability database was built X days ago (max allowed age is Y days)` {#warning-vulnerability-database-was-built-x-days-ago-max-allowed-age-is-y-days}

다음과 같은 오류 메시지가 표시될 수 있습니다:

```plaintext
1 error occurred: * the vulnerability database was built 6 days ago (max allowed age is 5 days)
```

컨테이너 스캐닝 이미지가 5일보다 오래된 경우 컨테이너 스캐닝이 실패합니다. GitLab은 이미지를 매일 업데이트하지만, 예를 들어 오프라인 환경에서 이미지 사본을 사용하면 이미지가 오래될 수 있습니다. 최신 이미지는 Trivy 데이터베이스(이미지에 저장됨)가 최신 상태인지 확인합니다.

이 문제를 해결하려면 컨테이너 스캐닝 이미지를 업데이트합니다. 자세한 내용은 [로컬 컨테이너 이미지 업데이트](_index.md#update-local-container-image)를 참조합니다.

## 오류: `Unknown scheme in CS_IMAGE. Allowed schemes: docker, archive` {#error-unknown-scheme-in-cs_image-allowed-schemes-docker-archive}

`CS_IMAGE` 환경 변수가 유효하지 않거나 누락된 URI 스키마로 설정된 경우 이 오류가 발생할 수 있습니다.

이 문제는 이미지 참조가 지원되는 스키마 중 하나를 사용하지 않을 때 발생합니다. 스키마는 레지스트리의 컨테이너 이미지에 대한 `docker://` 스키마이거나 로컬 tar 아카이브 파일에 대한 `archive://` 스키마여야 합니다.

표준 컨테이너 이미지를 스캔하는 경우 스키마를 생략하고 이미지 이름만 사용할 수 있습니다(예: `myapp:latest` 또는 `registry.example.com/myapp:latest`). 분석기가 Docker 스키마로 기본 설정되기 때문입니다.

`CS_IMAGE` 변수가 올바르게 설정되었고 오타나 지원되지 않는 접두사가 포함되지 않았는지 확인합니다.

---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 코드 품질 문제 해결
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

코드 품질을 사용할 때 다음과 같은 이슈가 발생할 수 있습니다.

## 코드를 찾을 수 없고 파이프라인이 항상 기본 구성으로 실행됩니다 {#the-code-cannot-be-found-and-the-pipeline-runs-always-with-default-configuration}

Docker-in-Docker 소켓 바인딩 구성을 사용하는 프라이빗 러너를 사용 중일 수 있습니다. 코드 품질 검사를 워커에서 실행하도록 구성해야 하며, 자세한 내용은 [프라이빗 러너 사용](code_quality_codeclimate_scanning.md#use-private-runners)에서 확인할 수 있습니다.

## 기본 구성 변경이 효과가 없습니다 {#changing-the-default-configuration-has-no-effect}

`Code Quality` (GitLab 전용) 및 `Code Climate` (GitLab에서 사용하는 엔진)이라는 용어가 매우 유사하다는 점이 일반적인 이슈입니다. **`.codeclimate.yml`** 파일을 추가하여 기본 구성을 변경해야 하며, `.codequality.yml` 파일이 아닙니다. 잘못된 파일명을 사용하면 [기본 `.codeclimate.yml`](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml.template)이 여전히 사용됩니다.

## 머지 리퀘스트에 코드 품질 보고서가 표시되지 않습니다 {#no-code-quality-report-is-displayed-in-a-merge-request}

소스 브랜치 또는 대상 브랜치의 코드 품질 보고서가 머지 리퀘스트의 비교를 위해 누락될 수 있으므로 정보를 표시할 수 없습니다.

소스 브랜치에서 누락된 보고서는 다음으로 인해 발생할 수 있습니다:

1. [`REPORT_STDOUT` 환경 변수](https://gitlab.com/gitlab-org/ci-cd/codequality#environment-variables) 사용으로 인해 보고서 파일이 생성되지 않으며 머지 리퀘스트에 아무것도 표시되지 않습니다.

대상 브랜치에서 누락된 보고서는 다음으로 인해 발생할 수 있습니다:

- `.gitlab-ci.yml`에서 새로 추가된 코드 품질 작업입니다.
- 대상 브랜치에서 코드 품질 작업을 실행하도록 파이프라인이 설정되지 않았습니다.
- 코드 품질 작업을 실행하지 않는 기본 브랜치에 커밋이 수행됩니다.
- [`artifacts:expire_in`](../yaml/_index.md#artifactsexpire_in) CI/CD 설정으로 인해 코드 품질 아티팩트가 예상보다 빠르게 만료될 수 있습니다.

[머지 리퀘스트 API](../../api/merge_requests.md#retrieve-a-merge-request)를 사용하여 `base_sha`을(를) 가져오고 [파이프라인 API와 `sha` 속성](../../api/pipelines.md#list-project-pipelines)을 사용하여 파이프라인이 실행되었는지 확인하여 기본 커밋에서 보고서의 존재를 확인합니다.

## 변경 보기에서 코드 품질 기호 없음 {#no-code-quality-symbol-in-the-changes-view}

[변경 보기](code_quality.md#merge-request-changes-view)에 기호가 표시되지 않으면 코드 품질 보고서의 `location.path`이(가) 다음을 확인하세요:

- 코드 품질 위반을 포함하는 파일에 대한 상대 경로를 사용합니다.
- `./`로 시작하지 않습니다. 예를 들어 `path`는 `somedir/file1.rb` 대신 `./somedir/file1.rb`여야 합니다.

## 단일 코드 품질 보고서만 표시되지만 더 많은 보고서가 정의됩니다 {#only-a-single-code-quality-report-is-displayed-but-more-are-defined}

코드 품질은 자동으로 [여러 보고서를 결합합니다](code_quality.md#scan-code-for-quality-violations).

## RuboCop 오류 {#rubocop-errors}

Ruby 프로젝트에서 코드 품질 작업을 사용할 때 RuboCop 실행 문제가 발생할 수 있습니다. 예를 들어 매우 최신 또는 매우 오래된 Ruby 버전을 사용할 때 다음 오류가 나타날 수 있습니다:

```plaintext
/usr/local/bundle/gems/rubocop-0.52.1/lib/rubocop/config.rb:510:in `check_target_ruby':
Unknown Ruby version 2.7 found in `.ruby-version`. (RuboCop::ValidationError)
Supported versions: 2.1, 2.2, 2.3, 2.4, 2.5
```

이는 사용 중인 Ruby 버전을 지원하지 않는 체크 엔진에서 사용되는 RuboCop의 기본 버전으로 인해 발생합니다.

[프로젝트에서 사용하는 Ruby 버전을 지원하는](https://docs.rubocop.org/rubocop/compatibility.html#support-matrix) RuboCop의 사용자 지정 버전을 사용하려면 [`.codeclimate.yml` 파일을 통해 구성을 재정의할 수 있습니다](https://docs.codeclimate.com/docs/rubocop#using-rubocops-newer-versions). 이 파일은 리포지토리에 생성됩니다.

예를 들어 RuboCop 릴리스 **0.67**을(를) 사용하도록 지정하려면:

```yaml
version: "2"
plugins:
  rubocop:
    enabled: true
    channel: rubocop-0-67
```

## 사용자 지정 도구를 사용할 때 머지 리퀘스트에서 코드 품질이 나타나지 않습니다 {#no-code-quality-appears-on-merge-requests-when-using-custom-tool}

사용자 지정 도구를 사용할 때 머지 리퀘스트에 코드 품질 변경 사항이 표시되지 않으면 JSON의 *모든* 라인 속성이 `integer`인지 확인합니다.

## 오류: `Could not analyze code quality` {#error-could-not-analyze-code-quality}

다음 오류가 표시될 수 있습니다:

```shell
error: (CC::CLI::Analyze::EngineFailure) engine pmd ran for 900 seconds and was killed
Could not analyze code quality for the repository at /code
```

코드 클라이밋 플러그인을 활성화하고 코드 품질 CI/CD 작업이 이 오류 메시지로 실패하면 작업이 900초의 기본 제한 시간보다 더 오래 걸릴 가능성이 있습니다:

이 문제를 해결하려면 `TIMEOUT_SECONDS`을(를) `.gitlab-ci.yml` 파일에서 더 높은 값으로 설정합니다.

예를 들어:

```yaml
code_quality:
  variables:
    TIMEOUT_SECONDS: 3600
```

## Kubernetes 또는 OpenShift 러너에서 코드 품질 사용 {#using-code-quality-with-a-kubernetes-or-openshift-runner}

CodeClimate 기반 스캔에는 특수한 요구 사항이 있습니다. 스캔이 제대로 작동하기 전에 [CodeClimate 기반 스캔용 Kubernetes 또는 OpenShift 러너 구성](code_quality_codeclimate_scanning.md#configure-kubernetes-or-openshift-runners)이 필요할 수 있습니다.

## 오류: `x509: certificate signed by unknown authority` {#error-x509-certificate-signed-by-unknown-authority}

`CODE_QUALITY_IMAGE`을(를) 자체 서명 인증서 같은 신뢰할 수 없는 TLS 인증서를 사용하는 Docker 레지스트리에서 호스팅되는 이미지로 설정하면 다음 오류가 표시될 수 있습니다:

```shell
$ docker pull --quiet "$CODE_QUALITY_IMAGE"
Error response from daemon: Get https://gitlab.example.com/v2/: x509: certificate signed by unknown authority
```

이를 해결하려면 [인증서 신뢰](https://distribution.github.io/distribution/about/insecure/#use-self-signed-certificates)하도록 Docker 데몬을 구성하고 `/etc/docker/certs.d` 디렉터리 내에 인증서를 입력합니다.

이 Docker 데몬은 [GitLab 코드 품질 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/v13.8.3-ee/lib/gitlab/ci/templates/Jobs/Code-Quality.gitlab-ci.yml#L41)에서 후속 코드 품질 Docker 컨테이너에 노출되며 인증서 구성을 적용할 다른 모든 컨테이너에도 노출되어야 합니다.

### Docker {#docker}

러너 구성에 액세스할 수 있으면 [볼륨 마운트](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section)로 디렉터리를 추가합니다.

`gitlab.example.com`을(를) 레지스트리의 실제 도메인으로 바꿉니다.

예:

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    volumes = ["/cache", "/etc/gitlab-runner/certs/gitlab.example.com.crt:/etc/docker/certs.d/gitlab.example.com/ca.crt:ro"]
```

### Kubernetes {#kubernetes}

러너 구성과 Kubernetes 클러스터에 액세스할 수 있으면 [ConfigMap 마운트](https://docs.gitlab.com/runner/executors/kubernetes/#configmap-volume)할 수 있습니다.

`gitlab.example.com`을(를) 레지스트리의 실제 도메인으로 바꿉니다.

1. 인증서를 사용하여 ConfigMap을 생성합니다:

   ```shell
   kubectl create configmap registry-crt --namespace gitlab-runner --from-file /etc/gitlab-runner/certs/gitlab.example.com.crt
   ```

1. 러너 `config.toml`을(를) 업데이트하여 ConfigMap을 지정합니다:

   ```toml
   [[runners]]
     ...
     executor = "kubernetes"
     [runners.kubernetes]
       image = "alpine:3.12"
       privileged = true
       [[runners.kubernetes.volumes.config_map]]
         name = "registry-crt"
         mount_path = "/etc/docker/certs.d/gitlab.example.com/ca.crt"
         sub_path = "gitlab.example.com.crt"
   ```

## 코드 품질 보고서 로드 실패 {#failed-to-load-code-quality-report}

아티팩트 파일에서 데이터를 구문 분석할 때 이슈가 있으면 코드 품질 보고서가 로드되지 않을 수 있습니다. 오류에 대한 인사이트를 얻으려면 다음 단계를 사용하여 GraphQL 쿼리를 실행할 수 있습니다:

1. 파이프라인 세부 정보 페이지로 이동합니다.
1. URL에 `.json`을(를) 추가합니다.
1. 파이프라인의 `iid`을(를) 복사합니다.
1. [대화형 GraphQL 탐색기](../../api/graphql/_index.md#interactive-graphql-explorer)로 이동합니다.
1. 다음 쿼리를 실행합니다:

   ```graphql
   {
     project(fullPath: "<fullpath-to-your-project>") {
       pipeline(iid: "<iid>") {
         codeQualityReports {
           count
           nodes {
             line
             description
             path
             fingerprint
             severity
           }
           pageInfo {
             hasNextPage
             hasPreviousPage
             startCursor
             endCursor
           }
         }
       }
     }
   }
   ```

## 보고서 아티팩트가 생성되지 않음 {#no-report-artifact-is-created}

특정 러너 구성에서 코드 품질 스캔 작업이 소스 코드에 액세스하지 못할 수 있습니다. 이 경우 `gl-code-quality-report.json` 아티팩트가 생성되지 않습니다.

이 이슈를 해결하려면 다음 중 하나를 수행합니다:

- [Docker-in-Docker에 대해 문서화된 러너 구성](../docker/using_docker_build.md#use-docker-in-docker)을 사용합니다. 이는 Docker 소켓 바인딩 대신 권한 있는 모드를 사용합니다.
- Docker 소켓 바인딩을 계속 사용하려면 [이슈 32027의 커뮤니티 해결 방법](https://gitlab.com/gitlab-org/gitlab/-/issues/32027#note_1318822628)을 적용합니다.

자세한 내용은 [러너 구성 변경](code_quality_codeclimate_scanning.md#change-runner-configuration)을 참조하세요.

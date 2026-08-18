---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sigstore를 사용한 서명 없는 키 서명 및 검증
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

[Sigstore](https://www.sigstore.dev/) 프로젝트는 [Cosign](https://docs.sigstore.dev/quickstart/quickstart-cosign/)이라는 CLI를 제공하며, 이를 GitLab CI/CD로 구축한 컨테이너 이미지의 서명 없는 키 서명에 사용할 수 있습니다. 서명 없는 키 서명에는 개인 키를 관리, 보호, 회전할 필요가 없다는 점을 포함하여 많은 이점이 있습니다. Cosign은 서명에 사용할 단기 키 쌍을 요청하고 이를 인증서 투명성 로그에 기록한 다음 삭제합니다. 키는 파이프라인을 실행한 사용자의 OIDC ID를 사용하여 GitLab 서버에서 얻은 토큰을 통해 생성됩니다. 이 토큰에는 CI/CD 파이프라인에서 토큰이 생성되었음을 인증하는 고유한 클레임이 포함되어 있습니다. 자세한 내용은 Cosign [설명서](https://docs.sigstore.dev/quickstart/quickstart-cosign/#example-working-with-containers)에서 서명 없는 키 서명을 참조하세요.

GitLab OIDC 클레임과 Fulcio 인증서 확장 간의 매핑에 대한 세부 정보는 [OIDC 토큰 클레임을 Fulcio OID로 매핑](https://github.com/sigstore/fulcio/blob/main/docs/oid-info.md#mapping-oidc-token-claims-to-fulcio-oids)의 GitLab 열을 참조하세요.

전제 조건:

- GitLab.com을 사용해야 합니다.
- 프로젝트의 CI/CD 구성은 프로젝트에 위치해야 합니다.

## Cosign을 사용하여 컨테이너 이미지 및 빌드 작업 서명 및 검증 {#sign-or-verify-container-images-and-build-artifacts-by-using-cosign}

Cosign을 사용하여 컨테이너 이미지 및 빌드 작업을 서명하고 검증할 수 있습니다.

전제 조건:

- Cosign 버전 `>= 2.0.1`을 사용해야 합니다.

**알려진 이슈**

- `id_tokens` 부분의 CI/CD 구성 파일은 빌드되고 서명되는 프로젝트에 위치해야 합니다. AutoDevOps, 다른 리포지토리에서 포함된 CI 파일 및 하위 파이프라인은 지원되지 않습니다. 이 제한을 제거하기 위한 작업은 [에픽 11637](https://gitlab.com/groups/gitlab-org/-/epics/11637)에서 추적되고 있습니다.

**Best practices**:

- 이미지/작업을 동일한 작업에서 빌드 및 서명하여 서명되기 전에 변조되는 것을 방지합니다.
- 컨테이너 이미지를 서명할 때 태그 대신 다이제스트(불변)를 서명합니다.

GitLab [ID 토큰](../secrets/id_token_authentication.md)을 Cosign에서 [서명 없는 키 서명](https://docs.sigstore.dev/quickstart/quickstart-cosign/#keyless-signing-of-a-container)에 사용할 수 있습니다. 토큰에는 `sigstore`이 [`aud`](../secrets/id_token_authentication.md#token-payload) 클레임으로 설정되어야 합니다. 토큰은 `SIGSTORE_ID_TOKEN` 환경 변수에 설정될 때 Cosign에서 자동으로 사용할 수 있습니다.

Cosign 설치 방법에 대한 자세한 내용은 [Cosign 설치 설명서](https://docs.sigstore.dev/cosign/system_config/installation/)를 참조하세요.

### 서명 {#signing}

#### 컨테이너 이미지 {#container-images}

[`Cosign.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Cosign.gitlab-ci.yml) 템플릿을 사용하여 GitLab CI에서 컨테이너 이미지를 빌드하고 서명할 수 있습니다. 서명은 이미지와 동일한 컨테이너 리포지토리에 자동으로 저장됩니다.

```yaml
include:
- template: Cosign.gitlab-ci.yml
```

컨테이너 서명에 대한 자세한 내용은 [Cosign 서명 컨테이너 설명서](https://docs.sigstore.dev/cosign/signing/signing_with_containers/)를 참조하세요.

#### 빌드 작업 {#build-artifacts}

다음 예에서는 GitLab CI에서 빌드 작업을 서명하는 방법을 보여줍니다. `cosign sign-blob`로 생성된 `cosign.bundle` 파일을 저장해야 하며, 이는 서명 검증에 사용됩니다.

작업 서명에 대한 자세한 내용은 [Cosign 서명 Blob 설명서](https://docs.sigstore.dev/cosign/signing/signing_with_blobs/)를 참조하세요.

```yaml
build_and_sign_artifact:
  stage: build
  image: alpine:latest
  variables:
    COSIGN_YES: "true"
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  before_script:
    - apk add --update cosign
  script:
    - echo "This is a build artifact" > artifact.txt
    - cosign sign-blob artifact.txt --bundle cosign.bundle
  artifacts:
    paths:
      - artifact.txt
      - cosign.bundle
```

### 검증 {#verification}

**Command-line arguments**

| 이름                        | 값 |
|-----------------------------|-------|
| `--certificate-identity`    | Fulcio에서 발급한 서명 인증서의 SAN입니다. 이미지/작업이 서명된 프로젝트의 다음 정보로 구성할 수 있습니다: GitLab 인스턴스 URL + 프로젝트 경로 + `//` + CI 구성 경로 + `@` \+ ref 경로입니다. |
| `--certificate-oidc-issuer` | 이미지/작업이 서명된 GitLab 인스턴스 URL입니다. 예를 들어, `https://gitlab.com`입니다. |
| `--bundle`                  | `cosign sign-blob`로 생성된 `bundle` 파일입니다. 빌드 작업 검증에만 사용됩니다. |

서명된 이미지/작업 검증에 대한 자세한 내용은 [Cosign 검증 설명서](https://docs.sigstore.dev/cosign/verifying/verify/)를 참조하세요.

#### 컨테이너 이미지 {#container-images-1}

다음 예에서는 GitLab CI에서 서명된 컨테이너 이미지를 검증하는 방법을 보여줍니다. 이전에 설명한 [명령줄 인수](#verification)를 사용하세요.

```yaml
verify_image:
  image: alpine:3.20
  stage: verify
  before_script:
    - apk add --update cosign docker
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
  script:
    - cosign verify "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG" --certificate-identity "https://gitlab.com/my-group/my-project//path/to/.gitlab-ci.yml@refs/heads/main" --certificate-oidc-issuer "https://gitlab.com"
```

**Additional details**:

- 프로젝트 경로와 `.gitlab-ci.yml` 경로 사이의 이중 백슬래시는 오류가 아니며 검증이 성공하려면 필수입니다. 단일 슬래시를 사용할 때 나타나는 일반적인 오류는 `Error: none of the expected identities matched what was in the certificate, got subjects`이며, 그 뒤에 프로젝트 경로와 `.gitlab-ci.yml` 경로 사이에 두 개의 슬래시가 있는 서명된 URL이 있습니다.
- 검증이 서명과 동일한 파이프라인에서 발생하는 경우 다음 경로를 사용할 수 있습니다: `"${CI_PROJECT_URL}//.gitlab-ci.yml@refs/heads/${CI_COMMIT_REF_NAME}"`

#### 빌드 작업 {#build-artifacts-1}

다음 예에서는 GitLab CI에서 서명된 빌드 작업을 검증하는 방법을 보여줍니다. 작업 검증에는 작업 자체와 `cosign sign-blob`로 생성된 `cosign.bundle` 파일이 모두 필요합니다. 이전에 설명한 [명령줄 인수](#verification)를 사용하세요.

```yaml
verify_artifact:
  stage: verify
  image: alpine:latest
  before_script:
    - apk add --update cosign
  script:
    - cosign verify-blob artifact.txt --bundle cosign.bundle --certificate-identity "https://gitlab.com/my-group/my-project//path/to/.gitlab-ci.yml@refs/heads/main" --certificate-oidc-issuer "https://gitlab.com"
```

**Additional details**:

- 프로젝트 경로와 `.gitlab-ci.yml` 경로 사이의 이중 백슬래시는 오류가 아니며 검증이 성공하려면 필수입니다. 단일 슬래시를 사용할 때 나타나는 일반적인 오류는 `Error: none of the expected identities matched what was in the certificate, got subjects`이며, 그 뒤에 프로젝트 경로와 `.gitlab-ci.yml` 경로 사이에 두 개의 슬래시가 있는 서명된 URL이 있습니다.
- 검증이 서명과 동일한 파이프라인에서 발생하는 경우 다음 경로를 사용할 수 있습니다: `"${CI_PROJECT_URL}//.gitlab-ci.yml@refs/heads/${CI_COMMIT_REF_NAME}"`

## Sigstore 및 npm을 사용하여 서명 없는 키 provenance 생성 {#use-sigstore-and-npm-to-generate-keyless-provenance}

Sigstore 및 npm을 GitLab CI/CD와 함께 사용하여 키 관리의 오버헤드 없이 빌드 작업에 디지털로 서명할 수 있습니다.

### npm provenance 정보 {#about-npm-provenance}

[npm CLI](https://docs.npmjs.com/cli/)를 사용하면 패키지 유지 관리자가 사용자에게 provenance 증명을 제공할 수 있습니다. npm CLI provenance 생성을 사용하면 사용자가 다운로드하고 사용하는 패키지가 귀사와 이를 빌드한 빌드 시스템에서 온 것임을 신뢰하고 확인할 수 있습니다.

npm 패키지 게시 방법에 대한 자세한 내용은 [GitLab npm 패키지 레지스트리](../../user/packages/npm_registry/_index.md)를 참조하세요.

### Sigstore {#sigstore}

[Sigstore](https://www.sigstore.dev/)는 패키지 관리자와 보안 전문가가 자신의 소프트웨어 공급망을 공격으로부터 보호하기 위해 사용할 수 있는 도구 모음입니다. Fulcio, Cosign, Rekor과 같은 무료 오픈 소스 기술을 모아서 디지털 서명, 검증, provenance 확인을 처리하여 오픈 소스 소프트웨어를 더 안전하게 배포하고 사용할 수 있도록 합니다.

**Related topics**:

- [SLSA Provenance 정의](https://slsa.dev/provenance/v1)
- [npm 설명서](https://docs.npmjs.com/generating-provenance-statements/)
- [npm Provenance RFC](https://github.com/npm/rfcs/blob/main/accepted/0049-link-packages-to-source-and-build.md#detailed-steps-to-publish)

### GitLab CI/CD에서 provenance 생성 {#generating-provenance-in-gitlab-cicd}

이제 Sigstore가 앞서 설명한 대로 GitLab OIDC를 지원하므로 npm provenance를 GitLab CI/CD 및 Sigstore와 함께 사용하여 GitLab CI/CD 파이프라인에서 npm 패키지에 대한 provenance를 생성하고 서명할 수 있습니다.

#### 전제 조건 {#prerequisites}

1. GitLab [ID 토큰](../secrets/id_token_authentication.md) `aud`을 `sigstore`으로 설정하세요.
1. `--provenance` 플래그를 추가하여 npm 게시를 수행합니다.

`.gitlab-ci.yml` 파일에 추가할 예제 내용:

```yaml
build:
  image: node:latest
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  script:
    - npm publish --provenance --access public
```

npm GitLab 템플릿은 이 기능도 제공하며, 예제는 [템플릿 설명서](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/npm.gitlab-ci.yml)에 있습니다.

## npm provenance 검증 {#verifying-npm-provenance}

npm CLI는 최종 사용자가 패키지의 provenance를 검증할 수 있는 기능도 제공합니다.

```plaintext
npm audit signatures
audited 1 package in 0s
1 package has a verified registry signature
```

### provenance 메타데이터 검사 {#inspecting-the-provenance-metadata}

Rekor 투명성 로그는 provenance로 게시된 모든 패키지에 대한 인증서 및 증명을 저장합니다. 예를 들어 다음은 [다음 예제의 항목](https://search.sigstore.dev/?logIndex=21076013)입니다.

npm에서 생성한 예제 provenance 문서:

```yaml
_type: https://in-toto.io/Statement/v0.1
subject:
  - name: pkg:npm/%40strongjz/strongcoin@0.0.13
    digest:
      sha512: >-
        924a134a0fd4fe6a7c87b4687bf0ac898b9153218ce9ad75798cc27ab2cddbeff77541f3847049bd5e3dfd74cea0a83754e7686852f34b185c3621d3932bc3c8
predicateType: https://slsa.dev/provenance/v0.2
predicate:
  buildType: https://github.com/npm/CLI/gitlab/v0alpha1
  builder:
    id: https://gitlab.com/strongjz/npm-provenance-example/-/runners/12270835
  invocation:
    configSource:
      uri: git+https://gitlab.com/strongjz/npm-provenance-example
      digest:
        sha1: 6e02e901e936bfac3d4691984dff8c505410cbc3
      entryPoint: deploy
    parameters:
      CI: 'true'
      CI_API_GRAPHQL_URL: https://gitlab.com/api/graphql
      CI_API_V4_URL: https://gitlab.com/api/v4
      CI_COMMIT_BEFORE_SHA: 7d3e913e5375f68700e0c34aa90b0be7843edf6c
      CI_COMMIT_BRANCH: main
      CI_COMMIT_REF_NAME: main
      CI_COMMIT_REF_PROTECTED: 'true'
      CI_COMMIT_REF_SLUG: main
      CI_COMMIT_SHA: 6e02e901e936bfac3d4691984dff8c505410cbc3
      CI_COMMIT_SHORT_SHA: 6e02e901
      CI_COMMIT_TIMESTAMP: '2023-05-19T10:17:12-04:00'
      CI_COMMIT_TITLE: trying to publish to gitlab reg
      CI_CONFIG_PATH: .gitlab-ci.yml
      CI_DEFAULT_BRANCH: main
      CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX: gitlab.com:443/strongjz/dependency_proxy/containers
      CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX: gitlab.com:443/strongjz/dependency_proxy/containers
      CI_DEPENDENCY_PROXY_SERVER: gitlab.com:443
      CI_DEPENDENCY_PROXY_USER: gitlab-ci-token
      CI_JOB_ID: '4316132595'
      CI_JOB_NAME: deploy
      CI_JOB_NAME_SLUG: deploy
      CI_JOB_STAGE: deploy
      CI_JOB_STARTED_AT: '2023-05-19T14:17:23Z'
      CI_JOB_URL: https://gitlab.com/strongjz/npm-provenance-example/-/jobs/4316132595
      CI_NODE_TOTAL: '1'
      CI_PAGES_DOMAIN: gitlab.io
      CI_PAGES_URL: https://strongjz.gitlab.io/npm-provenance-example
      CI_PIPELINE_CREATED_AT: '2023-05-19T14:17:21Z'
      CI_PIPELINE_ID: '872773336'
      CI_PIPELINE_IID: '40'
      CI_PIPELINE_SOURCE: push
      CI_PIPELINE_URL: https://gitlab.com/strongjz/npm-provenance-example/-/pipelines/872773336
      CI_PROJECT_CLASSIFICATION_LABEL: ''
      CI_PROJECT_DESCRIPTION: ''
      CI_PROJECT_ID: '45821955'
      CI_PROJECT_NAME: npm-provenance-example
      CI_PROJECT_NAMESPACE: strongjz
      CI_PROJECT_NAMESPACE_SLUG: strongjz
      CI_PROJECT_NAMESPACE_ID: '36018'
      CI_PROJECT_PATH: strongjz/npm-provenance-example
      CI_PROJECT_PATH_SLUG: strongjz-npm-provenance-example
      CI_PROJECT_REPOSITORY_LANGUAGES: javascript,dockerfile
      CI_PROJECT_ROOT_NAMESPACE: strongjz
      CI_PROJECT_TITLE: npm-provenance-example
      CI_PROJECT_URL: https://gitlab.com/strongjz/npm-provenance-example
      CI_PROJECT_VISIBILITY: public
      CI_REGISTRY: registry.gitlab.com
      CI_REGISTRY_IMAGE: registry.gitlab.com/strongjz/npm-provenance-example
      CI_REGISTRY_USER: gitlab-ci-token
      CI_RUNNER_DESCRIPTION: 3-blue.shared.runners-manager.gitlab.com/default
      CI_RUNNER_ID: '12270835'
      CI_RUNNER_TAGS: >-
        ["gce", "east-c", "linux", "ruby", "mysql", "postgres", "mongo",
        "git-annex", "shared", "docker", "saas-linux-small-amd64"]
      CI_SERVER_HOST: gitlab.com
      CI_SERVER_NAME: GitLab
      CI_SERVER_PORT: '443'
      CI_SERVER_PROTOCOL: https
      CI_SERVER_REVISION: 9d4873fd3c5
      CI_SERVER_SHELL_SSH_HOST: gitlab.com
      CI_SERVER_SHELL_SSH_PORT: '22'
      CI_SERVER_URL: https://gitlab.com
      CI_SERVER_VERSION: 16.1.0-pre
      CI_SERVER_VERSION_MAJOR: '16'
      CI_SERVER_VERSION_MINOR: '1'
      CI_SERVER_VERSION_PATCH: '0'
      CI_TEMPLATE_REGISTRY_HOST: registry.gitlab.com
      GITLAB_CI: 'true'
      GITLAB_FEATURES: >-
        elastic_search,ldap_group_sync,multiple_ldap_servers,seat_link,usage_quotas,zoekt_code_search,repository_size_limit,admin_audit_log,auditor_user,custom_file_templates,custom_project_templates,db_load_balancing,default_branch_protection_restriction_in_groups,extended_audit_events,external_authorization_service_api_management,geo,instance_level_scim,ldap_group_sync_filter,object_storage,pages_size_limit,project_aliases,password_complexity,enterprise_templates,git_abuse_rate_limit,required_ci_templates,runner_maintenance_note,runner_performance_insights,runner_upgrade_management,runner_jobs_statistics
      GITLAB_USER_ID: '31705'
      GITLAB_USER_LOGIN: strongjz
    environment:
      name: 3-blue.shared.runners-manager.gitlab.com/default
      architecture: linux/amd64
      server: https://gitlab.com
      project: strongjz/npm-provenance-example
      job:
        id: '4316132595'
      pipeline:
        id: '872773336'
        ref: .gitlab-ci.yml
  metadata:
    buildInvocationId: https://gitlab.com/strongjz/npm-provenance-example/-/jobs/4316132595
    completeness:
      parameters: true
      environment: true
      materials: false
    reproducible: false
  materials:
    - uri: git+https://gitlab.com/strongjz/npm-provenance-example
      digest:
        sha1: 6e02e901e936bfac3d4691984dff8c505410cbc3
```

---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 파이프라인 보안
description: "시크릿 관리, 작업 토큰, 보안 파일 및 클라우드 보안."
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## 시크릿 관리 {#secrets-management}

시크릿 관리는 개발자가 엄격한 접근 제어를 통해 안전한 환경에서 민감한 데이터를 안전하게 저장하기 위해 사용하는 시스템입니다. **secret**은 기밀로 유지해야 하는 민감한 자격증명입니다. 시크릿의 예시는 다음과 같습니다:

- 암호
- SSH 키
- 액세스 토큰
- 노출되면 조직에 해로울 수 있는 기타 모든 유형의 자격증명

## 시크릿 스토리지 {#secrets-storage}

### 시크릿 관리 제공자 {#secrets-management-providers}

가장 민감하고 가장 엄격한 정책에 따라 관리되는 시크릿은 시크릿 관리자에 저장해야 합니다. 시크릿 관리 솔루션을 사용할 때 시크릿은 GitLab 인스턴스 외부에 저장됩니다. 이 공간에는 [HashiCorp의 Vault](https://www.vaultproject.io), [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault), [Google Cloud Secret Manager](https://cloud.google.com/security/products/secret-manager)를 포함하여 많은 공급자가 있습니다.

특정 [외부 시크릿 관리 제공자](../secrets/_index.md)에 대해 GitLab 네이티브 통합을 사용하여 필요할 때 CI/CD 파이프라인에서 해당 시크릿을 검색할 수 있습니다.

### CI/CD 변수 {#cicd-variables}

[CI/CD 변수](../variables/_index.md)는 CI/CD 파이프라인에서 데이터를 저장하고 재사용하는 편리한 방법이지만, 변수는 시크릿 관리 제공자보다 보안이 낮습니다. 변수 값:

- GitLab 프로젝트, 그룹 또는 인스턴스 설정에 저장됩니다. 설정에 액세스할 수 있는 사용자는 [숨겨지지 않은](../variables/_index.md#hide-a-cicd-variable) 변수 값에 액세스할 수 있습니다.
- [재정의](../variables/_index.md#use-pipeline-variables)될 수 있으므로 어느 값이 사용되었는지 확인하기 어렵습니다.
- 실수로 인한 파이프라인 구성 오류로 인해 노출될 수 있습니다.

변수에 저장하기에 적합한 정보는 보안 위험 없이 노출될 수 있는 데이터(민감하지 않은 데이터)여야 합니다.

민감한 데이터는 시크릿 관리 솔루션에 저장해야 합니다. 시크릿 관리 솔루션이 없고 민감한 데이터를 CI/CD 변수에 저장하려면 다음을 항상 확인하세요:

- [변수 마스킹](../variables/_index.md#mask-a-cicd-variable).
- [변수 숨기기](../variables/_index.md#hide-a-cicd-variable).
- [변수 보호](../variables/_index.md#protect-a-cicd-variable) (가능한 경우).

## CI/CD 파이프라인에 매개변수 전달 {#pass-parameters-to-cicd-pipelines}

CI/CD 파이프라인에 매개변수를 전달할 때는 파이프라인 변수 대신 [CI/CD 입력](../inputs/_index.md)을 사용하세요.

입력은 다음을 제공합니다:

- 파이프라인 생성 시 타입 안정성 검증.
- 명시적 매개변수 계약.
- 보안을 향상시키는 범위 지정 가용성.

입력을 구현할 때 [파이프라인 변수 비활성화](../variables/_index.md#restrict-pipeline-variables)를 고려하여 보안 취약점을 방지하세요. 파이프라인 변수는 다음과 같은 이유 때문입니다:

- 타입 검증이 없습니다.
- 사전 정의된 변수를 재정의하여 예기치 않은 동작을 초래할 수 있습니다.
- 민감한 시크릿과 같은 범위 권한을 공유합니다.

## 파이프라인 무결성 {#pipeline-integrity}

파이프라인 무결성을 보장하기 위한 주요 보안 원칙은 다음과 같습니다:

- **Supply Chain Security**: 자산은 신뢰할 수 있는 소스에서 얻어야 하며 그 무결성이 검증되어야 합니다.
- **Reproducibility**: 파이프라인은 동일한 입력을 사용할 때 일관된 결과를 생성해야 합니다.
- **Auditability**: 모든 파이프라인 종속성은 추적 가능해야 하며 그 출처를 검증할 수 있어야 합니다.
- **Version Control**: 파이프라인 종속성에 대한 변경 사항은 추적되고 제어되어야 합니다.

### Docker 이미지 {#docker-images}

클라이언트 쪽 무결성 검증을 보장하기 위해 Docker 이미지에 항상 SHA 다이제스트를 사용하세요. 예를 들어:

- Node:
  - 사용: `image: node@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef`
  - 대신: `image: node:latest`
- Python:
  - 사용: `image: python@sha256:9876543210abcdef9876543210abcdef9876543210abcdef9876543210abcdef`
  - 대신: `image: python:3.9`

특정 태그를 사용하여 이미지의 SHA 다이제스트를 찾을 수 있습니다:

```shell
docker pull node:18.17.1
docker images --digests node:18.17.1
```

이미지 무결성을 보호하는 컨테이너 레지스트리에서 가져오는 것을 선호하세요:

- [보호된 컨테이너 리포지토리](../../user/packages/container_registry/container_repository_protection_rules.md)를 사용하여 컨테이너 리포지토리에서 컨테이너 이미지를 변경할 수 있는 사용자를 제한하세요.
- [보호된 태그](../../user/packages/container_registry/protected_container_tags.md)를 사용하여 컨테이너 태그를 푸시하고 삭제할 수 있는 사람을 제어하세요.

가능한 경우 컨테이너 참조에서 변수 사용을 피하세요. 변수는 악의적인 이미지를 가리키도록 수정될 수 있습니다. 예를 들어:

- 선호:
  - `image: my-registry.example.com/node:18.17.1`
- 대신:
  - `image: ${CUSTOM_REGISTRY}/node:latest`
  - `image: node:${VERSION}`

### 패키지 종속성 {#package-dependencies}

작업에서 패키지 종속성을 잠궈야 합니다. 잠금 파일에 정의된 정확한 버전을 사용하세요:

- npm:
  - 사용: `npm ci`
  - 대신: `npm install`
- yarn:
  - 사용: `yarn install --frozen-lockfile`
  - 대신: `yarn install`
- Python:
  - 사용:
    - `pip install -r requirements.txt --require-hashes`
    - `pip install -r requirements.lock`
  - 대신: `pip install -r requirements.txt`
- Go:
  - `go.sum`에서 정확한 버전을 사용하세요:
    - `go mod verify`
    - `go mod download`
  - 대신: `go get ./...`

예를 들어 CI/CD 작업에서:

```yaml
javascript-job:
  script:
    - npm ci
```

### 셸 명령 및 스크립트 {#shell-commands-and-scripts}

작업에서 도구를 설치할 때는 항상 정확한 버전을 지정하고 검증하세요. 예를 들어 Terraform 작업에서:

```yaml
terraform_job:
  script:
    # Download specific version
    - |
      wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
      # IMPORTANT: Always verify checksums
      echo "c0ed7bc32ee52ae255af9982c8c88a7a4c610485cf1d55feeb037eab75fa082c terraform_1.5.7_linux_amd64.zip" | sha256sum -c
      unzip terraform_1.5.7_linux_amd64.zip
      mv terraform /usr/local/bin/
    # Use the installed version
    - terraform init
    - terraform plan
```

### 버전 관리 도구 {#version-management-tools}

가능하면 버전 관리자를 사용하세요:

```yaml
node_build:
  script:
    # Use nvm to install and use a specific Node version
    - |
      nvm install 16.15.1
      nvm use 16.15.1
    - node --version  # Verify version
    - npm ci
    - npm run build
```

### 포함된 구성 {#included-configurations}

[`include` 키워드](../yaml/_index.md#include)를 사용하여 파이프라인에 구성 또는 CI/CD 구성 요소를 추가할 때 가능하면 특정 ref를 사용하세요. 예를 들어:

```yaml
include:
  - project: 'my-group/my-project'
    ref: 8b0c8b318857c8211c15c6643b0894345a238c4e  # Pin to a specific commit
    file: '/templates/build.yml'
  - project: 'my-group/security'
    ref: v2.1.0                                    # Pin to a protected tag
    file: '/templates/scan.yml'
  - component: 'my-group/security-scans'           # Pin to a specific version
    version: '1.2.3'
```

버전이 없는 포함을 피하세요:

```yaml
include:
  - project: 'my-group/my-project'                   # Unsafe
    file: '/templates/build.yml'
  - component: 'my-group/security-scans'             # Unsafe
  - remote: 'https://example.com/security-scan.yml'  # Unsafe
```

원격 파일을 포함하는 대신 파일을 다운로드하여 리포지토리에 저장하세요. 그런 다음 로컬 복사본을 포함할 수 있습니다:

```yaml
include:
  - local: '/ci/security-scan.yml'  # Verified and stored in the repository
```

### 관련 항목 {#related-topics}

1. [CIS Docker 벤치마크](https://www.cisecurity.org/benchmark/docker)
1. Google Cloud: [보안 배포 파이프라인 설계](https://cloud.google.com/architecture/design-secure-deployment-pipelines-bp)

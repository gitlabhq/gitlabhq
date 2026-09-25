---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "CI/CD 환경, 설정 스크립트, 캐싱, ID 토큰 및 GitLab Duo Agent Platform 플로우를 실행하는 러너를 구성합니다."
title: 플로우 실행 구성
---

{{< details >}}

- 티어:  [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/477166)되었습니다.

{{< /history >}}

플로우는 에이전트를 사용하여 작업을 실행합니다.

- GitLab UI에서 실행된 플로우는 CI/CD를 사용합니다.
- IDE에서 실행된 플로우는 로컬로 실행됩니다.

플로우가 CI/CD를 사용하여 실행되는 환경을 구성할 수 있습니다. [자신의 러너를 사용](#configure-runners-to-execute-flows)하고 [작업에서 변수를 지정](execution-variables.md)할 수도 있습니다.

## 실행기 아키텍처 {#executor-architecture}

{{< history >}}

- [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/600436)되어 GitLab 19.4에서 `npm` 패키지 대신 미리 컴파일된 바이너리를 사용하게 되었습니다.

{{< /history >}}

플로우가 CI/CD에서 실행될 때 러너는:

1. GitLab 패키지 레지스트리에서 운영 체제 및 아키텍처에 맞는 GitLab Duo CLI 바이너리를 다운로드합니다. Node.js 및 `npm`이 필요하지 않습니다.
1. GitLab Duo CLI를 실행하며, WebSocket을 사용하여 GitLab Duo 워크플로우 서비스에 연결합니다.
1. AI 모델의 지시에 따라 도구(파일 작업, Git 명령)를 실행합니다.

실행기 버전은 GitLab에서 관리하며 정기적인 릴리스의 일부로 업데이트됩니다.

## CI/CD 실행 구성 {#configure-cicd-execution}

플로우가 CI/CD에서 실행되는 방식을 사용자 지정하려면 프로젝트에서 에이전트 구성 파일을 생성합니다.

지원되는 키 및 해당 유형의 목록을 보려면 [`agent-config.yml` 참조](agent-config-yaml.md)를 참조하세요.

> [!note]
> `agent-config.yml`를 구성하기 위해 미리 정의된 CI/CD 변수를 사용할 수 없습니다. 플로우를 실행하는 작업에는 [변수](execution-variables.md#available-variables)를 사용해야 합니다.

### 에이전트 구성 파일 생성 {#create-the-agent-configuration-file}

1. 프로젝트의 리포지토리에서 `.gitlab/duo/` 폴더를 생성합니다.
1. 폴더에서 `agent-config.yml`이라는 구성 파일을 생성합니다.
1. 필요한 구성 옵션을 추가합니다.
1. 파일을 기본 브랜치에 커밋하고 푸시합니다.

플로우가 프로젝트에 대해 CI/CD에서 실행될 때 구성이 적용됩니다.

완전한 `agent-config.yml` 파일의 예시를 보려면 [`agent-config.yml` 참조](agent-config-yaml.md#complete-example)를 참조하세요.

> [!note]
> 구성 파일은 프로젝트의 기본 브랜치에서만 읽기 전용입니다. 다른 브랜치에 커밋된 파일은 무시되며, 해당 브랜치에서 플로우가 실행되는 경우에도 마찬가지입니다.

### 설정 스크립트 구성 {#configure-setup-scripts}

플로우 실행 전에 실행할 설정 스크립트를 정의할 수 있습니다. 이것은 종속성을 설치하고, 환경을 구성하거나, 초기화하는 데 유용합니다.

설정 스크립트를 추가하려면 `agent-config.yml` 파일에 다음 명령을 추가합니다.

```yaml
setup_script:
  - apt-get update && apt-get install -y curl
  - pip install -r requirements.txt
  - echo "Setup complete"
```

이 명령은 다음 작업을 완료합니다.

- 주 워크플로우 명령 전에 실행합니다.
- 지정된 순서대로 실행합니다.
- 단일 명령 또는 명령 배열일 수 있습니다.

`setup_script`의 사용자 컨텍스트는 Docker 이미지에 따라 다릅니다. 기본 GitLab 이미지는 `root`로 실행됩니다. 사용자 지정 이미지는 이미지의 `USER` 지시문에서 정의한 사용자로 실행됩니다. `setup_script`에 root 액세스가 필요한 경우(예: 시스템 패키지를 설치하려면) 사용자 지정 이미지가 그에 따라 구성되어 있는지 확인합니다.

> [!warning]
> `setup_script` 명령은 SRT가 적용되기 전에 실행되며 그 외부에서 실행됩니다. 이 명령은 플로우의 모든 환경 변수에 액세스할 수 있으며, 트리거하는 사용자의 OAuth 토큰, 서비스 토큰 및 ID 세부 정보를 포함합니다. 보안 모델 및 권장 보호에 대해서는 [`agent-config.yml`의 보안 영향](security-considerations.md#security-implications-of-agent-configyml)을 참조하세요.

### 캐싱 구성 {#configure-caching}

캐싱을 구성하여 후속 플로우 실행을 빠르게 하려면 `agent-config.yml` 파일을 구성하여 실행 간에 파일 및 디렉터리를 유지합니다. 캐싱은 `node_modules` 또는 Python 가상 환경과 같은 종속성 폴더에 유용할 수 있습니다.

#### 기본 캐시 구성 {#basic-cache-configuration}

특정 경로를 캐시하려면 `agent-config.yml` 파일에 다음을 추가합니다.

```yaml
cache:
  paths:
    - node_modules/
    - .npm/
```

#### 키를 포함한 캐시 {#cache-with-keys}

캐시 키를 사용하여 다양한 시나리오에 대해 다양한 캐시를 생성할 수 있습니다. 캐시 키는 캐시가 프로젝트의 상태를 기반으로 하도록 합니다.

##### 문자열 키 사용 {#use-a-string-key}

```yaml
cache:
  key: my-project-cache
  paths:
    - vendor/
    - .bundle/
```

##### 파일 기반 캐시 키 사용 {#use-file-based-cache-keys}

파일 내용(잠금 파일 등)을 기반으로 동적 캐시 키를 생성합니다. 이 파일이 변경되면 새 캐시가 생성됩니다. 이는 지정된 파일의 SHA 체크섬을 생성합니다.

```yaml
cache:
  key:
    files:
      - package-lock.json
      - yarn.lock
  paths:
    - node_modules/
```

##### 파일 기반 키로 접두사 사용 {#use-a-prefix-with-file-based-keys}

캐시 키 파일에 대해 계산된 SHA와 접두사를 결합합니다.

```yaml
cache:
  key:
    files:
      - package-lock.json
    prefix: $CI_JOB_NAME
  paths:
    - node_modules/
    - .npm/
```

이 예제에서 작업 이름이 `test`이고 SHA 체크섬이 `abc123`이면 캐시 키가 `test-abc123`이 됩니다.

#### 캐시 제한 {#cache-limitations}

- 캐시 키 생성을 위해 최대 두 개의 파일을 지정할 수 있습니다. 더 많은 파일을 지정하면 처음 두 개만 사용됩니다.
- 캐시 `paths` 필드는 필수입니다. 경로 없는 캐시 구성은 효과가 없습니다.
- 캐시 키는 `prefix` 필드의 CI/CD 변수를 지원합니다.

### ID 토큰 구성 {#configure-id-tokens}

{{< history >}}

- GitLab 19.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224940)되었습니다.

{{< /history >}}

플로우에서 타사 서비스를 인증하려면 [ID 토큰](../../../../ci/secrets/id_token_authentication.md)을 구성합니다.

ID 토큰은 GitLab CI/CD가 생성하고 장기 자격증명을 저장하지 않고 키 없는 OpenID Connect(OIDC) 인증을 위해 플로우를 실행하는 작업에 주입하는 JSON 웹 토큰(JWT)입니다. 예를 들어 ID 토큰을 사용하여 시크릿 관리자에서 시크릿을 검색하거나 바이너리 및 Git 커밋에 서명할 수 있습니다.

ID 토큰을 구성하려면 `agent-config.yml` 파일에 `id_tokens` 블록을 추가합니다. 각 토큰은 `aud`(대상) 클레임이 필요합니다.

```yaml
id_tokens:
  VAULT_ID_TOKEN:
    aud: https://vault.example.com

network_policy:
  allowed_domains:
    - vault.example.com
```

`aud` 클레임은 단일 문자열 또는 문자열 목록이 될 수 있습니다.

```yaml
id_tokens:
  MY_ID_TOKEN:
    aud:
      - https://first.service.example.com
      - https://second.service.example.com

network_policy:
  allowed_domains:
    - first.service.example.com
    - second.service.example.com
```

각 토큰은 토큰의 이름을 사용하는 환경 변수로 플로우 작업에서 사용 가능합니다. 이전 예제의 경우 플로우에서 `$VAULT_ID_TOKEN` 및 `$MY_ID_TOKEN`를 사용할 수 있습니다.

토큰 이름이 구성의 다른 곳에서 선언된 변수 이름과 일치하면 ID 토큰이 우선합니다.

> [!warning]
> ID 토큰은 `aud` 클레임을 신뢰하는 모든 서비스에 액세스 권한을 부여하는 자격증명입니다. 손상된 토큰이 가능한 한 적은 서비스로 인증할 수 있도록 각 토큰에 대해 가능한 가장 좁은 `aud` 값을 설정합니다. 구성 파일이 기본 브랜치에서 읽히므로 [권장 보호](security-considerations.md#recommended-protections)를 적용하여 플로우가 요청할 수 있는 토큰을 변경할 수 있는 사용자를 제어합니다.

토큰 페이로드 및 타사 서비스와의 신뢰를 구성하는 방법에 대한 자세한 내용은 [OpenID Connect(OIDC) 인증 사용(ID 토큰)](../../../../ci/secrets/id_token_authentication.md)을 참조하세요.

## 플로우를 실행하도록 러너 구성 {#configure-runners-to-execute-flows}

CI/CD를 사용하는 플로우는 러너에서 실행됩니다.

GitLab.com에서 플로우는 GitLab이 제공하는 [호스팅된 러너](../../../../ci/runners/hosted_runners/_index.md)를 사용할 수 있습니다. 이들은 기본적으로 활성화됩니다.

플로우에 대해 자신의 러너를 구성하는 옵션도 있습니다.

> [!note]
> 최상위 그룹에 [IP 주소 제한](../../../group/access_and_permissions.md#restrict-group-access-by-ip-address)이 활성화되어 있으면 호스팅된 러너를 플로우에 사용할 수 없습니다. 호스팅된 러너는 그룹의 IP 허용 목록에 추가할 수 없는 클라우드 공급자 풀의 동적 IP 주소를 사용합니다. 대신 최상위 그룹에서 자신의 그룹 러너를 구성합니다.

플로우에 대해 자신의 러너를 구성하려면:

1. [인스턴스 러너](../../../../ci/runners/runners_scope.md)를 생성하거나 최상위 그룹에 할당된 그룹 러너를 생성합니다. 플로우가 프로젝트 러너 또는 하위 그룹에 할당된 그룹 러너를 사용하려면 `duo_runner_restrictions` 기능 플래그를 끕니다(GitLab Self-Managed만 해당).
1. `gitlab--duo` 태그를 러너에 추가하여 플로우에 대한 작업을 선택하도록 합니다. 러너에 이 태그가 없으면 플로우가 있는 작업은 무한정 대기 상태로 유지됩니다. 다음 방법 중 하나를 사용합니다.
   - 러너를 생성할 때 **태그** 필드에 `gitlab--duo`를 입력합니다.
   - 기존 러너의 경우 [러너가 실행할 수 있는 작업 편집](../../../../ci/runners/configure_runners.md#control-jobs-that-a-runner-can-run)을 수행하고 **태그** 필드에 `gitlab--duo`를 입력합니다.
   - `config.toml` 파일로 러너를 구성하면 `[[runners]]` 섹션에 태그를 추가합니다.

     ```toml
     [[runners]]
       executor = "docker"
       tags = ["gitlab--duo"]
     ```

1. 러너를 구성하여 Docker 이미지를 지원하는 [실행기](https://docs.gitlab.com/runner/executors/)(예: `docker`, `docker-autoscaler` 또는 `kubernetes`)를 사용합니다. `shell` 실행기는 지원되지 않습니다.
1. 최상위 그룹이 [IP 주소 제한](../../../group/access_and_permissions.md#restrict-group-access-by-ip-address)을 켰으면 러너의 IP 주소를 그룹의 IP 허용 목록에 추가하여 러너가 그룹에 액세스할 수 있도록 합니다.
1. GitLab Self-Managed만 해당입니다. 러너가 플로우에 필요한 서비스에 도달할 수 있는지 확인합니다.
   - [GitLab 인스턴스에서 아웃바운드 연결 허용](../../../../administration/gitlab_duo/configure/_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo)을 Agent Platform으로 수행합니다.
   - [러너에서 아웃바운드 연결 허용](../../../../administration/gitlab_duo/configure/_index.md#allow-connections-from-the-runner)을 Agent Platform으로 수행합니다.
   - 인증서 체인의 자체 서명 인증서가 있는 인스턴스의 경우 [추가 GitLab Duo CLI 구성](../../../gitlab_duo_cli/use.md#certificate-errors)을 완료합니다.

### 실행 환경 샌드박스를 사용하여 플로우 보안 {#use-the-execution-environment-sandbox-to-secure-flows}

네트워크 및 파일 시스템 격리를 위해 [실행 환경 샌드박스](../../environment_sandbox.md)를 사용하여 러너에서 실행된 플로우를 보안합니다.

샌드박스를 사용하려면 다음 이미지 중 하나를 사용해야 합니다.

- Agent Platform용 기본 Docker 기본 이미지
- [강화된 UBI 9 최소 이미지](images.md#use-a-red-hat-universal-base-image-9-minimal)
- [SRT가 설치된 커스텀 이미지](../../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)

샌드박스를 사용하도록 러너를 구성하려면 `privileged = true`을 [러너 구성](https://docs.gitlab.com/runner/configuration/advanced-configuration/)에서 설정합니다.

예를 들어:

```toml
[[runners]]
  executor = "docker"
  tags = ["gitlab--duo"]
  [runners.docker]
    privileged = true
```

SRT가 설치되지 않은 커스텀 이미지에서는 샌드박스를 사용할 수 없습니다.

### 권한 모드 없이 샌드박스 요구 사항 {#sandbox-requirements-without-privileged-mode}

권한 모드는 샌드박스 요구 사항을 충족하는 한 가지 방법이지만 그 자체로는 충분하지 않으며 항상 필요한 것은 아닙니다.

샌드박스의 요구 사항은 작업이 사용자 및 마운트 네임스페이스를 생성할 수 있어야 한다는 것입니다. 런타임에 샌드박스는 `unshare -m`를 먼저 프로브한 다음 `unshare -rm`로 폴백합니다:

- `unshare -m`는 `CAP_SYS_ADMIN`이 필요하며, 이는 러너가 `privileged = true`로 구성되어 있을 때 루트로 실행되는 컨테이너가 가지고 있습니다.
- `unshare -rm`는 권한이 없는 사용자 네임스페이스를 생성하고 강화된 UBI 9 Minimal 이미지와 같이 루트가 아닌 사용자로 실행되는 이미지에서 작동합니다. `unshare -rm`는 컨테이너 사용자를 새 네임스페이스 내부의 루트에만 매핑합니다. 러너 호스트에 특별한 권한을 부여하지 않습니다.

`privileged = true` 설정은 샌드박스 초기화를 보장하지 않습니다. 다음과 같은 경우에는 여전히 실패합니다:

- 러너 호스트의 `user.max_user_namespaces`이 `0`로 설정되어 있습니다.
- seccomp 또는 AppArmor 프로필이 `CLONE_NEWUSER` 플래그를 차단합니다.
- 권한 모드는 러너에서 설정되지만 작업 컨테이너에 도달하지 않습니다. 이는 일부 `docker-autoscaler` 및 `kubernetes` 실행기 구성에서 발생할 수 있습니다.

사용 가능한 네임스페이스 모드가 없으면 플로우는 샌드박스 없이 실행되고 작업 로그에 다음 경고가 포함됩니다:

```plaintext
Warning: SRT found but can't create sandbox (insufficient privileges), running command directly
```

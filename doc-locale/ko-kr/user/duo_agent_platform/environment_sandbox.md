---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 원격 실행 환경 샌드박스
---

{{< history >}}

- [GitLab 18.7에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/578048) [기능 플래그](../../administration/feature_flags/_index.md) `ai_duo_agent_platform_network_firewall` 및 `ai_dap_executor_connects_over_ws` 포함
- 기능 플래그 `ai_duo_agent_platform_network_firewall`이 GitLab 18.7에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215950)되었습니다.
- 기능 플래그 `ai_dap_executor_connects_over_ws`이 GitLab 18.7에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215774)되었습니다.
- GitLab 18.8에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)합니다.
- `network_policy` 설정 [GitLab 18.10에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/590021)
- `allow_all_unix_sockets` 네트워크 정책 설정 [GitLab 18.11에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/590871)
- 인스턴스 수준 및 그룹 수준 네트워크 액세스 제어 [GitLab 18.11에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229531) [기능 플래그](../../administration/feature_flags/_index.md) `dap_instance_network_access_controls` 및 `dap_group_network_access_controls` 포함 기본적으로 비활성화됨.
- 기능 플래그 `dap_instance_network_access_controls` 및 `dap_group_network_access_controls` [GitLab 19.0에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235670)

{{< /history >}}

실행 환경 샌드박스는 GitLab Duo 에이전트 플랫폼 원격 플로우를 무단 네트워크 액세스 및 데이터 유출로부터 보호하는 데 도움이 되는 애플리케이션 수준의 네트워크 및 파일 시스템 격리를 제공합니다. 데이터 유출 시도, 외부 소스의 악성 코드 로드, 무단 데이터 수집을 방지하도록 설계되었으며, 합법적인 플로우 작업을 위한 필요한 연결성을 유지합니다.

## 샌드박스가 적용되는 경우 {#when-the-sandbox-is-applied}

실행 환경 샌드박스는 Anthropic Sandbox Runtime (SRT)가 설치된 호환 Docker 이미지를 사용할 때 자동으로 적용됩니다. 여기에는 기본 GitLab Docker 이미지(릴리스 [v0.0.6](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/tags/v0.0.6) 이상) 또는 [SRT가 설치된 사용자 정의 이미지](#install-anthropic-sandbox-runtime-srt-on-a-custom-image) 사용이 포함됩니다.

샌드박스는 다음 경우에 활성화됩니다:

- Anthropic Sandbox Runtime (SRT)이 Docker 이미지에서 사용 가능합니다.
- GitLab Duo 에이전트 플랫폼 세션이 러너에서 실행 중입니다(로컬 환경은 샌드박스되지 않음).

기본 및 사용자 정의 이미지 구성 간 CI/CD 변수 차이에 대한 정보는 [플로우 실행 변수](flows/execution_variables.md)를 참조하세요.

## 필수 요구 사항 {#prerequisites}

실행 환경 샌드박스를 사용하려면 다음이 필요합니다:

- 프로젝트에서 GitLab Duo 에이전트 플랫폼이 활성화되어 있습니다.
- 특권 러너 모드가 활성화됩니다. [샌드박싱 작동을 위해 필수](flows/execution.md#configure-runners)입니다.
- 호환 Docker 이미지: [기본 GitLab Docker](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/container_registry) 이미지(버전 `v0.0.6` 이상) 또는 [Anthropic Sandbox Runtime (SRT)이 설치된 사용자 정의 이미지](#install-anthropic-sandbox-runtime-srt-on-a-custom-image)가 될 수 있습니다.

## 작동 방식 {#how-it-works}

실행 환경 샌드박스는 [Anthropic Sandbox Runtime (SRT)](https://github.com/anthropic-experimental/sandbox-runtime)를 사용하여 다음 보호를 통해 플로우 실행을 래핑합니다:

- 네트워크 격리:  실행 환경을 떠나기 전에 모든 네트워크 요청을 차단하고 허용 목록에 있는 도메인과 비교하여 검증합니다.
- 파일 시스템 제한:  특정 디렉토리에 대한 읽기 및 쓰기 액세스를 제한하고 민감한 파일에 대한 액세스를 차단합니다.
- 우아한 폴백:  SRT를 사용할 수 없거나 필요한 운영 체제 권한이 없는 경우, 플로우는 경고 메시지와 함께 직접 실행됩니다.

## 사용자 정의 이미지에 Anthropic Sandbox Runtime (SRT) 설치 {#install-anthropic-sandbox-runtime-srt-on-a-custom-image}

사용자 정의 이미지를 사용하는 경우, 예를 들어 [`agent-config.yml`](flows/execution.md#create-the-configuration-file)가 있으면 Anthropic SRT 버전 `0.0.20` 이상이 설치되어 있고 환경에서 사용 가능해야 합니다.

SRT는 `npm`을(를) 통해 `@anthropic-ai/sandbox-runtime`로 제공됩니다. 다음 예제에서는 Dockerfile의 설치 스테이지를 보여줍니다:

```dockerfile
# Install srt sandboxing with cache clearing and verification
ARG SANDBOX_RUNTIME_VERSION=0.0.20
RUN npm cache clean --force && \
    npm install -g @anthropic-ai/sandbox-runtime@${SANDBOX_RUNTIME_VERSION} && \
    test -s "$(npm root -g)/@anthropic-ai/sandbox-runtime/package.json" && \
    srt --version

```

런타임에 러너는 SRT가 사용 가능하고 작동하는지 확인합니다:

```shell
$ if which srt > /dev/null; then
$ echo "SRT found, creating config..."
SRT found, creating config...
$ echo '{"network":{"allowedDomains":["host.docker.internal","localhost","gitlab.com","*.gitlab.com","duo-workflow-svc.runway.gitlab.net"],"deniedDomains":[],"allowAllUnixSockets":false},"filesystem":{"denyRead":["~/.ssh"],"allowWrite":["./","/tmp"],"denyWrite":["/opt/.gitlab-sandbox"],"allowGitConfig":true}}' > /opt/.gitlab-sandbox/srt-settings.json
$ echo "Testing SRT sandbox capabilities..."
Testing SRT sandbox capabilities...
```

런타임 중에 다음 오류가 발생할 수 있으며, SRT의 종속성을 사용할 수 없음을 나타낼 수 있습니다:

```shell
Warning: SRT found but can't create sandbox (insufficient privileges), running command directly
```

이를 해결하려면:

1. bash를 사용하여 다음 명령으로 이미지를 확인합니다:

   ```shell
   docker run --rm -it <image>:<tag> /bin/bash
   ```

1. `srt`을(를) 사용합니다:

   ```shell
   srt ls
   ```

1. 다음 오류가 표시되면 사용자 정의 이미지에 추가 종속성을 설치해야 합니다:

   ```shell
   Error: Sandbox dependencies are not available on this system. Required: ripgrep (rg), bubblewrap (bwrap), and socat.
   ```

## 네트워크 및 파일 시스템 제한 {#network-and-filesystem-restrictions}

실행 환경 샌드박스가 적용되면 다음 제한이 적용됩니다.

### 샌드박스 설정 구성 {#configure-sandbox-settings}

[`agent-config.yml`](flows/execution.md#create-the-configuration-file) 파일을 사용하여 샌드박스 설정의 일부를 구성합니다.

기본적으로 샌드박스는 다음 구성에 대한 액세스를 허용합니다:

- 기본 허용 목록 도메인. 이러한 설정은 자동으로 구성되며 변경하거나 업데이트할 수 없습니다.

### 환경 변수 {#environment-variables}

DAP 및 Git 작업을 실행하는 데 필요한 환경 변수 및 매개변수만 샌드박스 환경에서 액세스할 수 있습니다.

### 파일 시스템 구성 {#filesystem-configuration}

샌드박스는 다음 파일 시스템 제한을 적용합니다:

- 읽기 제한:  SSH 키(`~/.ssh`)는 차단됩니다.
- 쓰기 허용:  현재 디렉토리(`./`) 및 `/tmp`.
- 쓰기 제한: `/opt/.gitlab-sandbox` (샌드박스 설정과 같은 플랫폼 내부 파일에 사용).
- Git 구성 액세스:  허용됨.

### 네트워크 정책 구성 {#configure-a-network-policy}

SRT는 기본 GitLab 제공 Docker 이미지에 포함되어 있습니다. [사용자 정의 이미지에 SRT를 설치](#install-anthropic-sandbox-runtime-srt-on-a-custom-image)할 수도 있습니다.

SRT가 설치되면 플로우는 기본적으로 다음 도메인에만 액세스할 수 있습니다. 이러한 도메인은 항상 허용되며 제거할 수 없습니다:

- `localhost`
- `host.docker.internal`
- GitLab 인스턴스 도메인(예: `gitlab.com`, `*.gitlab.com`)
- GitLab Duo 워크플로 서비스 도메인

SRT 없이 사용자 정의 이미지를 사용하는 경우 네트워크 제한이 적용되지 않으며 플로우는 러너에서 연결할 수 있는 모든 도메인에 액세스할 수 있습니다.

> [!note]
> `network_policy`는 `"*"`을(를) `allowed_domains` 또는 `denied_domains`에서 허용하지 않습니다. SRT는 모든 네트워크 트래픽을 켜는 것을 지원하지 않습니다. 그러나 와일드카드는 도메인의 일부로 허용됩니다(예: `"*.domain.com"`).

#### 관리자 네트워크 정책 제어 {#administrator-network-policy-controls}

최상위 그룹 소유자가 GitLab.com에서 또는 인스턴스 관리자가 GitLab Self-Managed에서 네트워크 액세스 제어를 구성할 때, 해당 설정은 모든 플로우의 기본 정책을 정의합니다. **Allow projects to extend network sandbox settings** 확인란은 프로젝트 소유자가 `agent-config.yml`에서 구성할 때 어떤 설정이 적용되는지 결정합니다.

**Flexible mode** (**Allow projects to extend network sandbox settings** 활성화):

- `allowed_domains` from `agent-config.yml`는 관리자 허용 목록과 병합됩니다.
- `denied_domains` from `agent-config.yml`는 관리자 거부 목록과 병합됩니다.
- `include_recommended_allowed` in `agent-config.yml`는 관리자 설정을 재정의합니다.
- `allow_all_unix_sockets` in `agent-config.yml`는 관리자 설정을 재정의합니다.

**Strict mode** (**Allow projects to extend network sandbox settings** 비활성화):

- `denied_domains` from `agent-config.yml`는 관리자 거부 목록과 병합됩니다.
- `include_recommended_allowed`을(를) `false`로만 설정하여 관리자가 활성화한 설정을 강화할 수 있습니다. 관리자가 비활성화했을 때는 효과가 없습니다.
- `allow_all_unix_sockets`을(를) `false`로만 설정하여 관리자가 활성화한 설정을 강화할 수 있습니다. 관리자가 비활성화했을 때는 효과가 없습니다.
- `allowed_domains` from `agent-config.yml`는 무시됩니다.

#### 프로젝트 수준 설정 구성 {#configure-project-level-settings}

추가 도메인을 허용하거나 거부하려면 `network_policy`을(를) `agent-config.yml` 파일에 추가합니다:

```yaml
network_policy:
  include_recommended_allowed: true # default: false
  allow_all_unix_sockets: true      # default: false
  allowed_domains:
    - my-own-site.com
  denied_domains:
    - malicious.com
```

#### Unix 소켓 액세스 허용 {#allow-unix-socket-access}

`allow_all_unix_sockets` 설정을 사용하여 플로우가 호스트의 모든 Unix 도메인 소켓에 액세스할 수 있도록 합니다. 이는 기본적으로 비활성화되어 있습니다.

> [!warning]
> `allow_all_unix_sockets`를 활성화하면 모든 Unix 소켓에 액세스할 수 있습니다. 필요할 때만, 그리고 신뢰할 수 있는 환경에서만 활성화합니다.

### 인스턴스 또는 그룹을 위한 네트워크 액세스 제어 구성 {#configure-network-access-controls-for-your-instance-or-group}

{{< history >}}

- [GitLab 18.11에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229531) [기능 플래그](../../administration/feature_flags/_index.md) `dap_instance_network_access_controls` 및 `dap_group_network_access_controls` 포함 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트용으로 제공되지만 프로덕션 사용을 위해 준비되지 않았습니다.

[프로젝트 수준 `agent-config.yml` 설정](#configure-a-network-policy) 외에도 관리자 및 최상위 그룹 소유자는 GitLab UI를 통해 네트워크 액세스 제어를 관리할 수 있습니다. 이러한 설정은 인스턴스 수준(GitLab Self-Managed) 또는 최상위 그룹 수준(GitLab.com)에서 저장되며 아래의 모든 프로젝트에 상속됩니다.

이러한 설정이 프로젝트 수준 `agent-config.yml`과 결합되는 방식에 대한 설명은 [관리자 네트워크 정책 제어](#administrator-network-policy-controls)를 참조하세요.

#### 인스턴스 수준 네트워크 액세스 제어 구성 {#configure-instance-level-network-access-controls}

전제 조건:

- 관리자여야 합니다.

인스턴스 수준 네트워크 액세스 제어를 구성하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을(를) 선택합니다.
1. **데이터와 개인정보 보호** 아래의 **네크웍 억세스** 섹션에서 다음 설정을 구성합니다:
   - **Include recommended domains in the allowlist**:  권장 도메인의 선별된 목록이 자동으로 허용 목록에 포함됩니다.
   - **Allow all Unix sockets**:  모든 Unix 소켓은 GitLab Duo 에이전트 플랫폼 작업을 위해 허용됩니다.
   - **Allow projects to extend network sandbox settings**:  프로젝트에 대한 유지보수자 또는 소유자 역할을 가진 사용자는 `agent-config.yml` 파일을 통해 권장 도메인을 포함하고, 더 많은 도메인을 추가하고, 모든 Unix 소켓을 허용할 수 있습니다.
1. 선택사항. **허용된 도메인** 아래에서 허용 목록에 도메인을 추가하거나 제거합니다. **차단된 도메인** 아래에서 거부 목록에 도메인을 추가하거나 제거합니다.
1. **변경사항 저장**을 선택합니다.

#### 최상위 그룹 네트워크 액세스 제어 구성(GitLab.com) {#configure-top-level-group-network-access-controls-gitlabcom}

전제 조건:

- 최상위 그룹에 대한 소유자 역할이 있어야 합니다.
- 그룹은 GitLab.com의 최상위 그룹이어야 합니다. 하위 그룹은 최상위 그룹의 설정을 상속합니다.

그룹 수준 네트워크 액세스 제어를 구성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을(를) 선택하고 최상위 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정**을(를) 선택한 후 **GitLab Duo**를 선택합니다.
1. **구성 변경**을(를) 선택합니다.
1. **데이터와 개인정보 보호** 아래의 **네크웍 억세스** 섹션에서 [인스턴스 수준 네트워크 액세스 제어 구성](#configure-instance-level-network-access-controls)에서 설명한 것과 동일한 설정을 구성합니다.
1. **변경사항 저장**을 선택합니다.

#### 관련 API 리소스 {#related-api-resources}

- 인스턴스 수준 부울:  [`duoSettingsUpdate`](../../api/graphql/reference/_index.md#mutationduosettingsupdate) GraphQL 변경.
- 그룹 수준 부울:  [그룹 속성 업데이트](../../api/groups.md#update-group-attributes) REST API(`ai_settings_attributes` 매개변수 사용).
- 도메인 허용 목록 및 거부 목록: [`aiDomainSettingsInstanceUpdate`](../../api/graphql/reference/_index.md#mutationaidomainsettingsinstanceupdate) 및 [`aiDomainSettingsNamespaceUpdate`](../../api/graphql/reference/_index.md#mutationaidomainsettingsnamespaceupdate) GraphQL 변경.

### 허용된 도메인 켜기 {#turn-on-allowed-domains}

플로우에 패키지 레지스트리 및 개발 도구에 사용되는 외부 도메인 집합에 대한 액세스 권한을 부여하려면 `include_recommended_allowed` 설정을 켭니다.

이 설정은 기본적으로 비활성화되어 있습니다(`false`). 켜려면 `agent-config.yml` 파일에서 `include_recommended_allowed`을(를) `true`로 설정합니다.

네트워크 액세스 제어가 엄격한 모드에서 활성화되면(**Allow projects to extend network sandbox settings** 비활성화), `include_recommended_allowed`만 비활성화할 수 있습니다. `true`로 설정하면 관리자가 비활성화했을 때는 효과가 없습니다.

> [!warning]
> `include_recommended_allowed`를 활성화하면 광범위한 외부 도메인 집합에 대한 네트워크 액세스가 허용됩니다. 이러한 송신 끝점은 환경에서 데이터를 유출하는 데 사용될 수 있습니다. 필요할 때만, 그리고 신뢰할 수 있는 환경에서만 활성화합니다.

이 설정은 다음 도메인에 대한 액세스를 켭니다:

- `github.com`
- `www.github.com`
- `api.github.com`
- `npm.pkg.github.com`
- `raw.githubusercontent.com`
- `pkg-npm.githubusercontent.com`
- `objects.githubusercontent.com`
- `codeload.github.com`
- `avatars.githubusercontent.com`
- `camo.githubusercontent.com`
- `gist.github.com`
- `gitlab.com`
- `www.gitlab.com`
- `registry.gitlab.com`
- `bitbucket.org`
- `www.bitbucket.org`
- `api.bitbucket.org`
- `registry-1.docker.io`
- `auth.docker.io`
- `index.docker.io`
- `hub.docker.com`
- `www.docker.com`
- `production.cloudflare.docker.com`
- `download.docker.com`
- `gcr.io`
- `*.gcr.io`
- `ghcr.io`
- `mcr.microsoft.com`
- `*.data.mcr.microsoft.com`
- `public.ecr.aws`
- `cloud.google.com`
- `accounts.google.com`
- `gcloud.google.com`
- `storage.googleapis.com`
- `compute.googleapis.com`
- `container.googleapis.com`
- `artifactregistry.googleapis.com`
- `cloudresourcemanager.googleapis.com`
- `oauth2.googleapis.com`
- `www.googleapis.com`
- `login.microsoftonline.com`
- `packages.microsoft.com`
- `dotnet.microsoft.com`
- `dot.net`
- `dev.azure.com`
- `s3.amazonaws.com`
- `*.s3.amazonaws.com`
- `*.codeartifact.amazonaws.com`
- `*.s3.api.aws`
- `*.codeartifact.api.aws`
- `download.oracle.com`
- `yum.oracle.com`
- `registry.npmjs.org`
- `www.npmjs.com`
- `www.npmjs.org`
- `npmjs.com`
- `npmjs.org`
- `yarnpkg.com`
- `registry.yarnpkg.com`
- `pypi.org`
- `www.pypi.org`
- `files.pythonhosted.org`
- `pythonhosted.org`
- `test.pypi.org`
- `pypi.python.org`
- `pypa.io`
- `www.pypa.io`
- `rubygems.org`
- `www.rubygems.org`
- `api.rubygems.org`
- `index.rubygems.org`
- `ruby-lang.org`
- `www.ruby-lang.org`
- `rubyonrails.org`
- `www.rubyonrails.org`
- `rvm.io`
- `get.rvm.io`
- `crates.io`
- `www.crates.io`
- `index.crates.io`
- `static.crates.io`
- `rustup.rs`
- `static.rust-lang.org`
- `www.rust-lang.org`
- `proxy.golang.org`
- `sum.golang.org`
- `index.golang.org`
- `golang.org`
- `www.golang.org`
- `goproxy.io`
- `pkg.go.dev`
- `maven.org`
- `repo.maven.org`
- `central.maven.org`
- `repo1.maven.org`
- `jcenter.bintray.com`
- `gradle.org`
- `www.gradle.org`
- `services.gradle.org`
- `plugins.gradle.org`
- `kotlin.org`
- `www.kotlin.org`
- `spring.io`
- `repo.spring.io`
- `packagist.org`
- `www.packagist.org`
- `repo.packagist.org`
- `nuget.org`
- `www.nuget.org`
- `api.nuget.org`
- `pub.dev`
- `api.pub.dev`
- `hex.pm`
- `www.hex.pm`
- `cpan.org`
- `www.cpan.org`
- `metacpan.org`
- `www.metacpan.org`
- `api.metacpan.org`
- `cocoapods.org`
- `www.cocoapods.org`
- `cdn.cocoapods.org`
- `haskell.org`
- `www.haskell.org`
- `hackage.haskell.org`
- `swift.org`
- `www.swift.org`
- `archive.ubuntu.com`
- `security.ubuntu.com`
- `ubuntu.com`
- `www.ubuntu.com`
- `*.ubuntu.com`
- `ppa.launchpad.net`
- `launchpad.net`
- `www.launchpad.net`
- `dl.k8s.io`
- `pkgs.k8s.io`
- `k8s.io`
- `www.k8s.io`
- `releases.hashicorp.com`
- `apt.releases.hashicorp.com`
- `rpm.releases.hashicorp.com`
- `archive.releases.hashicorp.com`
- `hashicorp.com`
- `www.hashicorp.com`
- `repo.anaconda.com`
- `conda.anaconda.org`
- `anaconda.org`
- `www.anaconda.com`
- `anaconda.com`
- `continuum.io`
- `apache.org`
- `www.apache.org`
- `archive.apache.org`
- `downloads.apache.org`
- `eclipse.org`
- `www.eclipse.org`
- `download.eclipse.org`
- `nodejs.org`
- `www.nodejs.org`
- `sourceforge.net`
- `*.sourceforge.net`
- `packagecloud.io`
- `*.packagecloud.io`
- `json-schema.org`
- `www.json-schema.org`
- `json.schemastore.org`
- `www.schemastore.org`
- `*.modelcontextprotocol.io`

## 경고 및 폴백 동작 {#warnings-and-fallback-behavior}

샌드박싱을 사용할 수 없거나 적용할 수 없는 경우:

- 플로우는 샌드박스 보호 없이 직접 실행됩니다
- 경고 메시지가 CI 작업 로그 내에 표시되고 러너 구성 지침에 대한 링크가 있습니다

이를 통해 샌드박싱을 활성화할 수 없는 경우에도 플로우가 계속 실행되며, 동시에 상황을 알립니다.

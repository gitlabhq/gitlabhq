---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes용 에이전트 설치
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Kubernetes 클러스터를 GitLab에 연결하려면 클러스터에 에이전트를 설치해야 합니다.

## 사전 요구 사항 {#prerequisites}

클러스터에 에이전트를 설치하기 전에 다음이 필요합니다:

- 로컬 터미널에서 연결할 수 있는 [기존 Kubernetes 클러스터](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/). 클러스터가 없으면 클라우드 제공자에서 클러스터를 만들 수 있습니다. 예를 들어:
  - [Amazon Elastic Kubernetes Service (EKS)](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)
  - [Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/what-is-aks)
  - [Digital Ocean](https://docs.digitalocean.com/products/kubernetes/getting-started/quickstart/)
  - [Google Kubernetes Engine (GKE)](https://docs.cloud.google.com/kubernetes-engine/docs/deploy-app-cluster)
  - [코드 기반 인프라](../../../infrastructure/iac/_index.md) 기법을 사용하여 규모에 맞게 인프라 리소스를 관리해야 합니다.
- 에이전트 서버 액세스:
  - GitLab.com에서는 에이전트 서버를 `grpcs://kas.gitlab.com`에서 사용할 수 있습니다. WebSocket 주소 `wss://kas.gitlab.com`도 사용할 수 있습니다.
  - GitLab Self-Managed에서는 GitLab 관리자가 [에이전트 서버](../../../../administration/clusters/kas.md)를 설정해야 합니다. 그러면 기본적으로 `wss://gitlab.example.com/-/kubernetes-agent/`에서 사용할 수 있습니다.
  - GitLab Dedicated에서는 에이전트 서버를 `wss://kas.<instance-domain>`에서 사용할 수 있습니다. 예를 들어 `wss://kas.example.gitlab-dedicated.com`. GitLab Dedicated 인스턴스에 [사용자 지정 도메인](../../../../administration/dedicated/configure_instance/network_security.md#custom-domains)을 사용하는 경우 KAS 서비스에도 사용자 지정 도메인을 사용할 수 있습니다.

## Flux 지원을 통해 에이전트 부트스트랩(권장) {#bootstrap-the-agent-with-flux-support-recommended}

[GitLab CLI (`glab`)](../../../../editor_extensions/gitlab_cli/_index.md)와 Flux를 사용하여 에이전트를 부트스트랩하면 에이전트를 설치할 수 있습니다.

사전 요구 사항:

- 다음 명령줄 도구가 설치되어 있습니다:
  - `glab`
  - `kubectl`
  - `flux`
- `kubectl` 및 `flux`에서 작동하는 로컬 클러스터 연결이 있습니다.
- 클러스터에 [Flux를 부트스트랩](https://fluxcd.io/flux/installation/bootstrap/gitlab/)하고 `flux bootstrap`를 사용했습니다.
  - 호환되는 디렉터리에서 Flux와 에이전트를 부트스트랩해야 합니다. `--path` 옵션으로 Flux를 부트스트랩한 경우 `glab cluster agent bootstrap` 명령의 `--manifest-path` 옵션에 동일한 값을 전달해야 합니다.

에이전트를 설치하려면 다음 중 하나를 수행합니다:

- 대상 프로젝트의 Git 리포지토리 디렉터리 내에서 `glab cluster agent bootstrap`를 실행합니다:

  ```shell
  glab cluster agent bootstrap <agent-name> --manifest-path <same_path_used_in_flux_bootstrap>
  ```

- 대상 프로젝트의 Git 리포지토리 외부에서 명령을 실행해야 하는 경우 `glab -R path-with-namespace cluster agent bootstrap`를 실행합니다:

  ```shell
  glab -R <full/path/to/project> cluster agent bootstrap <agent-name> --manifest-path <same_path_used_in_flux_bootstrap>
  ```

기본적으로 명령은:

1. 에이전트를 등록합니다.
1. 에이전트를 구성합니다.
1. 에이전트용 대시보드가 있는 환경을 구성합니다.
1. 에이전트 토큰을 만듭니다.
1. 클러스터에서 에이전트 토큰을 포함한 Kubernetes 시크릿을 만듭니다.
1. Flux Helm 리소스를 Git 리포지토리에 커밋합니다.
1. Flux 조정을 트리거합니다.

사용자 지정 옵션의 경우 `glab cluster agent bootstrap --help`를 실행합니다. 최소한 `--path <flux_manifests_directory>` 옵션을 사용해야 합니다.

## 에이전트 수동 설치 {#install-the-agent-manually}

클러스터에 에이전트를 설치하려면 세 가지 단계가 필요합니다:

1. 선택 사항입니다. [에이전트 구성 파일 만들기](#create-an-agent-configuration-file).
1. [GitLab에 에이전트 등록](#register-the-agent-with-gitlab).
1. [클러스터에 에이전트 설치](#install-the-agent-in-the-cluster).

<i class="fa-youtube-play" aria-hidden="true"></i> [이 프로세스 안내](https://www.youtube.com/watch?v=XuBpKtsgGkE)를 시청합니다.
<!-- Video published on 2021-09-02 -->

### 에이전트 구성 파일 만들기 {#create-an-agent-configuration-file}

구성 설정을 위해 에이전트는 GitLab 프로젝트의 YAML 파일을 사용합니다. 에이전트 구성 파일 추가는 선택 사항입니다. 다음 경우에 이 파일을 만들어야 합니다:

- [GitLab CI/CD 워크플로우](../ci_cd_workflow.md#use-gitlab-cicd-with-your-cluster)를 사용하고 다른 프로젝트나 그룹이 에이전트에 액세스하도록 인증하려는 경우.
- [특정 프로젝트 또는 그룹 멤버가 Kubernetes에 액세스하도록 허용](../user_access.md)합니다.

에이전트 구성 파일을 만들려면:

1. 에이전트의 이름을 선택합니다. 에이전트 이름은 [RFC 1123의 DNS 레이블 표준](https://www.rfc-editor.org/info/rfc1123/)을 따릅니다. 이름은 다음을 충족해야 합니다:

   - 프로젝트 내에서 고유해야 합니다.
   - 최대 63자를 포함합니다.
   - 소문자 영숫자 문자 또는 `-`만 포함합니다.
   - 영숫자 문자로 시작합니다.
   - 영숫자 문자로 끝납니다.

1. 리포지토리에서 기본 브랜치에 에이전트 구성 파일을 만듭니다:

   ```plaintext
   .gitlab/agents/<agent-name>/config.yaml
   ```

지금은 파일을 비워둔 후 나중에 [구성](../work_with_agent.md#configure-your-agent)할 수 있습니다.

### GitLab에 에이전트 등록 {#register-the-agent-with-gitlab}

#### 옵션 1: 에이전트가 GitLab에 연결 {#option-1-agent-connects-to-gitlab}

GitLab UI에서 직접 새 에이전트 레코드를 만들 수 있습니다. 에이전트는 에이전트 구성 파일을 만들지 않고 등록할 수 있습니다.

클러스터에 에이전트를 설치하기 전에 에이전트를 등록해야 합니다. 에이전트를 등록하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다. [에이전트 구성 파일](#create-an-agent-configuration-file)이 있으면 이 프로젝트에 있어야 합니다. 클러스터 매니페스트 파일도 이 프로젝트에 있어야 합니다.
1. **운영** > **Kubernetes 클러스터**를 선택합니다.
1. **클러스터 연결 (에이전트)**를 선택합니다.
1. **새 에이전트 이름** 필드에 에이전트의 고유한 이름을 입력합니다.
   - 이 이름의 [에이전트 구성 파일](#create-an-agent-configuration-file)이 이미 있으면 사용됩니다.
   - 이 이름에 대한 구성이 없으면 기본 구성으로 새 에이전트가 만들어집니다.
1. **생성하고 등록**을 선택합니다.
1. GitLab은 에이전트에 대한 액세스 토큰을 생성합니다. 클러스터에 에이전트를 설치하려면 이 토큰이 필요합니다.

   > [!warning]
   > 에이전트 액세스 토큰을 안전하게 저장합니다. 악의적인 행위자는 이 토큰을 사용하여 에이전트의 구성 프로젝트의 소스 코드에 액세스하거나, GitLab 인스턴스의 모든 공개 프로젝트의 소스 코드에 액세스하거나, 매우 구체적인 조건에서 Kubernetes 매니페스트를 얻을 수 있습니다.

1. **권장 설치 방법**에서 명령을 복사합니다. 한 줄 설치 방법을 사용하여 클러스터에 에이전트를 설치할 때 필요합니다.

#### 옵션 2: GitLab이 에이전트(수용형 에이전트)에 연결 {#option-2-gitlab-connects-to-agent-receptive-agent}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.4에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/12180)되었습니다.

{{< /history >}}

> [!note]
> GitLab 에이전트 Helm 차트 릴리스는 mTLS 인증을 완전히 지원하지 않습니다. 대신 JWT 방법으로 인증해야 합니다. mTLS에 대한 지원은 [이슈 64](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/issues/64)에서 추적됩니다.

[수용형 에이전트](../_index.md#receptive-agents)를 사용하면 GitLab을 GitLab 인스턴스에 대한 네트워크 연결을 설정할 수 없지만 GitLab이 연결할 수 있는 Kubernetes 클러스터와 통합할 수 있습니다.

1. 옵션 1의 단계를 따라 클러스터에 에이전트를 등록합니다. 에이전트 토큰과 설치 명령을 나중에 사용하도록 저장하지만 아직 에이전트를 설치하지 마십시오.
1. 인증 방법을 준비합니다.

   GitLab과 에이전트의 연결은 일반 텍스트 gRPC (`grpc://`) 또는 암호화된 gRPC (`grpcs://`, 권장)일 수 있습니다. GitLab은 클러스터의 에이전트에 다음을 사용하여 인증할 수 있습니다:
   - JWT 토큰. `grpc://` 및 `grpcs://` 구성 모두에서 사용할 수 있습니다. 이 방법으로는 클라이언트 인증서를 생성할 필요가 없습니다.
1. [클러스터 에이전트 API](../../../../api/cluster_agents.md#create-a-url-configuration)를 사용하여 에이전트에 URL 구성을 추가합니다. URL 구성을 삭제하면 수용형 에이전트가 일반 에이전트가 됩니다. 수용형 에이전트를 한 번에 하나의 URL 구성과만 연결할 수 있습니다.
1. 에이전트를 클러스터에 설치합니다. 에이전트를 등록할 때 복사한 명령을 사용하되 `--set config.kasAddress=...` 매개변수를 제거합니다.

   JWT 토큰 인증 예제. 추가된 `config.receptive.enabled=true` 및 `config.api.jwt` 설정을 확인합니다:

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   helm upgrade --install my-agent gitlab/gitlab-agent \
    --namespace ns \
    --create-namespace \
    --set config.token=.... \
    --set config.receptive.enabled=true \
    --set config.api.jwtPublicKey=<public_key from the response>
   ```

GitLab이 새 에이전트에 연결을 시도하기 시작하는 데 최대 10분이 소요될 수 있습니다.

### 클러스터에 에이전트 설치 {#install-the-agent-in-the-cluster}

클러스터를 GitLab에 연결하려면 [Helm으로 등록된 에이전트를 설치](#install-the-agent-with-helm)합니다.

수용형 에이전트를 설치하려면 [GitLab이 에이전트(수용형 에이전트)에 연결](#option-2-gitlab-connects-to-agent-receptive-agent)의 단계를 따릅니다.

> [!note]
> 여러 클러스터에 연결하려면 각 클러스터에서 에이전트를 구성, 등록 및 설치해야 합니다. 각 에이전트에 고유한 이름을 지정해야 합니다.

#### Helm으로 에이전트 설치 {#install-the-agent-with-helm}

> [!warning]
> 간단하게 하기 위해 기본 Helm 차트 구성은 에이전트에 대한 서비스 계정을 `cluster-admin` 권한으로 설정합니다. 프로덕션 시스템에서는 이를 사용하면 안 됩니다. 프로덕션 시스템에 배포하려면 [Helm 설치 사용자 지정](#customize-the-helm-installation)의 지침을 따라 배포에 필요한 최소 권한을 가진 서비스 계정을 만들고 설치 중에 지정합니다.

Helm을 사용하여 클러스터에 에이전트를 설치하려면:

1. [Helm CLI 설치](https://helm.sh/docs/intro/install/).
1. 컴퓨터에서 터미널을 열고 [클러스터에 연결](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/)합니다.
1. [GitLab에 에이전트를 등록](#register-the-agent-with-gitlab)할 때 복사한 명령을 실행합니다. 명령은 다음과 같아야 합니다:

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   helm upgrade --install test gitlab/gitlab-agent \
       --namespace gitlab-agent-test \
       --create-namespace \
       --set image.tag=<current agentk version> \
       --set config.token=<your_token> \
       --set config.kasAddress=<address_to_GitLab_KAS_instance>
   ```

1. 선택 사항입니다. [Helm 설치 사용자 지정](#customize-the-helm-installation). 프로덕션 시스템에 에이전트를 설치하는 경우 Helm 설치를 사용자 지정하여 서비스 계정의 권한을 제한해야 합니다. 관련 사용자 지정 옵션은 아래에서 설명합니다.

##### Helm 설치 사용자 지정 {#customize-the-helm-installation}

기본적으로 GitLab에서 생성한 Helm 설치 명령:

- 배포를 위해 `gitlab-agent` 네임스페이스를 만듭니다 (`--namespace gitlab-agent`). `--create-namespace` 플래그를 생략하여 네임스페이스 만들기를 건너뛸 수 있습니다.
- 에이전트의 서비스 계정을 설정하고 `cluster-admin` 역할을 할당합니다. 다음을 수행할 수 있습니다.
  - `helm install` 명령에 `--set serviceAccount.create=false`을 추가하여 서비스 계정 만들기를 건너뜁니다. 이 경우 `serviceAccount.name`을 기존 서비스 계정으로 설정해야 합니다.
  - `helm install` 명령에 `--set rbac.useExistingRole <your role name>`을 추가하여 서비스 계정에 할당된 역할을 사용자 지정합니다. 이 경우 서비스 계정에서 사용할 수 있는 제한된 권한을 가진 미리 만들어진 역할이 있어야 합니다.
  - `helm install` 명령에 `--set rbac.create=false`을 추가하여 역할 할당을 완전히 건너뜁니다. 이 경우 `ClusterRoleBinding`을 수동으로 만들어야 합니다.
- 에이전트의 액세스 토큰에 대한 `Secret` 리소스를 만듭니다. 대신 토큰을 사용하여 자신의 시크릿을 가져오려면 토큰 (`--set token=...`)을 생략하고 대신 `--set config.secretName=<your secret name>`을 사용합니다.
- `agentk` 포드에 대한 `Deployment` 리소스를 만듭니다.

사용 가능한 전체 사용자 지정 목록을 보려면 Helm 차트의 [README](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/blob/main/README.md#values)를 참조하세요.

##### KAS가 자체 서명된 인증서 뒤에 있을 때 에이전트 사용 {#use-the-agent-when-kas-is-behind-a-self-signed-certificate}

[KAS](../../../../administration/clusters/kas.md)가 자체 서명된 인증서 뒤에 있으면 `config.kasCaCert`의 값을 인증서로 설정할 수 있습니다. 예를 들어:

```shell
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --set-file config.kasCaCert=my-custom-ca.pem
```

이 예제에서 `my-custom-ca.pem`은 KAS에서 사용하는 CA 인증서를 포함하는 로컬 파일의 경로입니다. 인증서는 자동으로 구성 맵에 저장되고 `agentk` 포드에 마운트됩니다.

KAS가 GitLab 차트와 함께 설치되고 차트가 [자동 생성된 자체 서명 와일드카드 인증서](https://docs.gitlab.com/charts/installation/tls/#option-4-use-auto-generated-self-signed-wildcard-certificate)를 제공하도록 구성된 경우 `RELEASE-wildcard-tls-ca` 시크릿에서 CA 인증서를 추출할 수 있습니다.

##### HTTP 프록시 뒤의 에이전트 사용 {#use-the-agent-behind-an-http-proxy}

Helm 차트를 사용할 때 HTTP 프록시를 구성하려면 환경 변수 `HTTP_PROXY`, `HTTPS_PROXY` 및 `NO_PROXY`을 사용할 수 있습니다. 대문자와 소문자 모두 허용됩니다.

`extraEnv` 값을 사용하여 이러한 변수를 설정할 수 있습니다. `name` 및 `value` 키가 있는 객체 목록으로: 예를 들어 환경 변수 `HTTPS_PROXY`를 값 `https://example.com/proxy`로만 설정하려면 다음을 실행할 수 있습니다:

```shell
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --set extraEnv[0].name=HTTPS_PROXY \
  --set extraEnv[0].value=https://example.com/proxy \
  ...
```

> [!note]
> DNS 리바인드 보호는 `HTTP_PROXY` 또는 `HTTPS_PROXY` 환경 변수가 설정되고 도메인 DNS를 확인할 수 없을 때 비활성화됩니다.

## 클러스터에 여러 에이전트 설치 {#install-multiple-agents-in-your-cluster}

> [!note]
> 대부분의 경우 클러스터당 하나의 에이전트를 실행하고 에이전트 가장 기능(Premium 및 Ultimate만 해당)을 사용하여 멀티테넌시를 지원해야 합니다. 여러 에이전트를 실행해야 하는 경우 발생하는 문제를 공유합니다. [이슈 454110](https://gitlab.com/gitlab-org/gitlab/-/issues/454110)에서 피드백을 제공할 수 있습니다.

클러스터에 두 번째 에이전트를 설치하려면 [이전 단계](#register-the-agent-with-gitlab)를 두 번째로 따를 수 있습니다. 클러스터 내 리소스 이름 충돌을 방지하려면 다음 중 하나를 수행해야 합니다:

- 에이전트에 다른 릴리스 이름을 사용하세요. 예를 들어 `second-gitlab-agent`:

  ```shell
  helm upgrade --install second-gitlab-agent gitlab/gitlab-agent ...
  ```

- 또는 에이전트를 다른 네임스페이스에 설치합니다. 예를 들어 `different-namespace`:

  ```shell
  helm upgrade --install gitlab-agent gitlab/gitlab-agent \
    --namespace different-namespace \
    ...
  ```

클러스터의 각 에이전트는 독립적으로 실행되므로 Flux 모듈이 활성화된 모든 에이전트에 의해 조정이 트리거됩니다. [이슈 357516](https://gitlab.com/gitlab-org/gitlab/-/issues/357516)은 이 동작을 변경하도록 제안합니다.

해결 방법으로 다음을 수행할 수 있습니다:

- 필요한 Flux 리소스만 액세스하도록 에이전트를 사용하여 RBAC를 구성합니다.
- 사용하지 않는 에이전트에서 Flux 모듈을 비활성화합니다.

## 예제 프로젝트 {#example-projects}

다음 예제 프로젝트는 에이전트를 시작하는 데 도움이 될 수 있습니다.

- [별개의 애플리케이션 및 매니페스트 리포지토리 예제](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service-gitops)
- [CI/CD 워크플로우를 사용하는 Auto DevOps 설정](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service)
- [CI/CD 워크플로우를 사용하는 클러스터 관리 프로젝트 템플릿 예제](https://gitlab.com/gitlab-examples/ops/gitops-demo/cluster-management)

## 업데이트 및 버전 호환성 {#updates-and-version-compatibility}

GitLab은 에이전트의 목록 페이지에서 클러스터에 설치된 에이전트 버전을 업데이트하도록 경고합니다.

최적의 환경을 위해 클러스터에 설치된 에이전트의 버전은 GitLab 주 버전 및 부 버전과 일치해야 합니다. 이전 및 다음 부 버전도 지원됩니다. 예를 들어 GitLab 버전이 v14.9.4(주 버전 14, 부 버전 9)인 경우 에이전트의 v14.9.0 및 v14.9.1 버전이 이상적이지만 에이전트의 v14.8.x 또는 v14.10.x 버전도 지원됩니다. Kubernetes용 GitLab 에이전트의 [릴리스 페이지](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/releases)를 참조하세요.

### 에이전트 버전 업데이트 {#update-the-agent-version}

> [!note]
> `--reuse-values` 대신 필요한 모든 값을 지정해야 합니다. `--reuse-values`을 사용하면 새 기본값을 놓치거나 더 이상 사용되지 않는 값을 사용할 수 있습니다. 이전 `--set` 인수를 검색하려면 `helm get values <release name>`를 사용합니다. 값을 `helm get values gitlab-agent > agent.yaml`로 파일에 저장하고 `-f`으로 Helm에 파일을 전달할 수 있습니다: `helm upgrade gitlab-agent gitlab/gitlab-agent -f agent.yaml`. 이는 `--reuse-values`의 동작을 안전하게 대체합니다.

에이전트를 최신 버전으로 업데이트하려면 다음을 실행할 수 있습니다:

```shell
helm repo update
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --namespace gitlab-agent
```

특정 버전을 설정하려면 `image.tag` 값을 재정의할 수 있습니다. 예를 들어 버전 `v14.9.1`를 설치하려면 다음을 실행합니다:

```shell
helm upgrade gitlab-agent gitlab/gitlab-agent \
  --namespace gitlab-agent \
  --set image.tag=v14.9.1
```

Helm 차트는 Kubernetes용 에이전트와 별도로 업데이트되며 때로는 최신 버전의 에이전트보다 뒤처질 수 있습니다. `helm repo update`을 실행하고 이미지 태그를 지정하지 않으면 에이전트는 차트에 지정된 버전을 실행합니다.

Kubernetes용 에이전트의 최신 릴리스를 사용하려면 이미지 태그를 가장 최근 에이전트 이미지와 일치하도록 설정합니다.

## 에이전트 제거 {#uninstall-the-agent}

[Helm으로 에이전트를 설치](#install-the-agent-with-helm)한 경우 Helm으로 제거할 수도 있습니다. 예를 들어 릴리스와 네임스페이스가 모두 `gitlab-agent`라고 불리면 다음 명령을 사용하여 에이전트를 제거할 수 있습니다:

```shell
helm uninstall gitlab-agent \
    --namespace gitlab-agent
```

## 문제 해결 {#troubleshooting}

Kubernetes용 에이전트를 설치할 때 다음 문제가 발생할 수 있습니다.

### 오류: `failed to reconcile the GitLab Agent` {#error-failed-to-reconcile-the-gitlab-agent}

`glab cluster agent bootstrap` 명령이 `failed to reconcile the GitLab Agent` 메시지와 함께 실패하면 `glab`이 Flux를 사용하여 에이전트를 조정할 수 없다는 의미입니다.

이 오류는 다음과 같은 이유로 발생할 수 있습니다:

- Flux 설정이 `glab`이 에이전트의 Flux 매니페스트를 배치한 디렉터리를 가리키지 않습니다. `--path` 옵션으로 Flux를 부트스트랩한 경우 `glab cluster agent bootstrap` 명령의 `--manifest-path` 옵션에 동일한 값을 전달해야 합니다.
- Flux는 `kustomization.yaml`이 없는 프로젝트의 루트 디렉터리를 가리키며, 이로 인해 Flux가 YAML 파일을 찾기 위해 하위 디렉터리를 탐색합니다. 에이전트를 사용하려면 `.gitlab/agents/<agent-name>/config.yaml`에 에이전트 구성 파일이 있어야 합니다. 이는 유효한 Kubernetes 매니페스트가 아닙니다. Flux가 이 파일을 적용하지 못하면 오류가 발생합니다. 해결하려면 Flux를 루트가 아닌 하위 디렉터리로 가리켜야 합니다.

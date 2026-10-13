---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes 클러스터를 GitLab에 연결하기 시작하기
---

이 페이지는 단일 프로젝트에서 기본 Kubernetes 통합을 설정하는 방법을 안내합니다. GitLab agent for Kubernetes, pull 기반 배포 또는 Flux를 처음 사용하는 경우 여기서 시작하세요.

작업을 완료하면 다음을 수행할 수 있습니다:

- 실시간 Kubernetes 대시보드로 Kubernetes 클러스터의 상태를 봅니다.
- Flux로 클러스터에 업데이트를 배포합니다.
- GitLab CI/CD로 클러스터에 업데이트를 배포합니다.

## 시작하기 전에 {#before-you-begin}

이 자습서를 완료하기 전에 다음이 있는지 확인하세요:

- `kubectl`로 로컬에서 액세스할 수 있는 Kubernetes 클러스터입니다. GitLab이 지원하는 Kubernetes 버전을 확인하려면 [GitLab 기능을 위해 지원되는 Kubernetes 버전](_index.md#supported-kubernetes-versions-for-gitlab-features)을 참조하세요.

  다음을 실행하여 모든 것이 제대로 구성되었는지 확인할 수 있습니다:

  ```shell
  kubectl cluster-info
  ```

## Flux 설치 및 구성 {#install-and-configure-flux}

[Flux](https://fluxcd.io/flux/)는 GitOps 배포(pull 기반 배포라고도 함)를 위한 권장 도구입니다. Flux는 성숙한 CNCF 프로젝트입니다.

Flux를 설치하려면:

- Flux 설명서에서 [Flux CLI 설치](https://fluxcd.io/flux/installation/#install-the-flux-cli)의 단계를 완료하세요.

다음을 실행하여 Flux CLI가 제대로 설치되었는지 확인하세요:

```shell
flux -v
```

### 개인 액세스 토큰 생성 {#create-a-personal-access-token}

Flux CLI로 인증하려면 `api` 범위로 개인 액세스 토큰을 만드세요:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **개인 액세스 토큰**을 선택합니다.
1. 토큰의 이름과 선택적 만료 날짜를 입력하세요.
1. `api` 범위를 선택하세요.
1. **개인 액세스 토큰 생성**을 선택하세요.

`api` 범위와 `maintainer` 역할이 있는 [프로젝트](../../project/settings/project_access_tokens.md) 또는 [그룹 액세스 토큰](../../group/settings/group_access_tokens.md)을 사용할 수도 있습니다.

### Flux 부트스트랩 {#bootstrap-flux}

이 섹션에서는 [`flux bootstrap`](https://fluxcd.io/flux/installation/bootstrap/gitlab/) 명령을 사용하여 Flux를 빈 GitLab 리포지토리로 부트스트랩합니다.

Flux 설치를 부트스트랩하려면:

- `flux bootstrap gitlab` 명령을 실행하세요. 예를 들어:

  ```shell
  flux bootstrap gitlab \
  --hostname=gitlab.example.org \
  --owner=my-group/optional-subgroup \
  --repository=my-repository \
  --branch=main \
  --path=clusters/testing \
  --deploy-token-auth
  ```

`bootstrap`의 인수는:

| 인수     | 설명 |
|--------------|-------------|
| `hostname`   | GitLab 인스턴스의 호스트 이름입니다. |
| `owner`      | Flux 리포지토리를 포함하는 GitLab 그룹입니다. |
| `repository` | Flux 리포지토리를 포함하는 GitLab 프로젝트입니다. |
| `branch`     | 변경 사항이 커밋되는 Git 브랜치입니다. |
| `path`       | Flux 구성이 저장되는 폴더의 파일 경로입니다. |

부트스트랩 스크립트는 다음을 수행합니다:

1. 배포 토큰을 만들어 Kubernetes `secret`로 저장합니다.
1. `--repository` 인수로 지정한 프로젝트가 없으면 빈 GitLab 프로젝트를 만듭니다.
1. `--path` 인수로 지정한 폴더에 프로젝트의 Flux 정의 파일을 생성합니다.
1. `--branch` 인수로 지정한 브랜치에 정의 파일을 커밋합니다.
1. 정의 파일을 클러스터에 적용합니다.

스크립트를 실행한 후 Flux는 자체 관리와 GitLab 프로젝트 및 경로에 추가한 다른 리소스를 관리할 준비가 됩니다.

이 자습서의 나머지 부분에서는 경로가 `clusters/testing`이고 프로젝트가 `my-group/optional-subgroup/my-repository` 아래에 있다고 가정합니다.

## 에이전트 연결 설정 {#set-up-the-agent-connection}

클러스터를 연결하려면 GitLab agent for Kubernetes를 설치해야 합니다. GitLab CLI(`glab`)로 에이전트를 부트스트랩하여 이를 수행할 수 있습니다.

1. [GitLab CLI 설치](https://gitlab.com/gitlab-org/cli/#installation)하세요.

   GitLab CLI를 사용할 수 있는지 확인하려면 다음을 실행하세요

   ```shell
   glab version
   ```

1. GitLab 인스턴스에 [`glab` 인증](https://gitlab.com/gitlab-org/cli/#installation)하세요.
1. Flux를 부트스트랩한 리포지토리에서 `glab cluster agent bootstrap` 명령을 실행하세요:

   ```shell
   glab cluster agent bootstrap --manifest-path clusters/testing testing
   ```

기본적으로 명령은:

1. 에이전트를 `testing`로 이름으로 등록합니다.
1. 에이전트를 구성합니다.
1. `testing`이라는 환경을 에이전트의 대시보드와 함께 구성합니다.
1. 에이전트 토큰을 만듭니다.
1. 클러스터에서 에이전트 토큰을 사용하여 Kubernetes 시크릿을 만듭니다.
1. Flux Helm 리소스를 Git 리포지토리에 커밋합니다.
1. Flux 조정을 트리거합니다.

에이전트 구성에 대한 자세한 내용은 [Kubernetes용 에이전트 설치](install/_index.md)를 참조하세요.

## Kubernetes 대시보드 확인 {#check-out-the-dashboard-for-kubernetes}

`glab cluster agent bootstrap`은 GitLab 내에서 환경을 만들고 [대시보드를 구성](../../../ci/environments/kubernetes_dashboard.md)했습니다.

대시보드를 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을 선택하세요.
1. 환경을 선택하세요. 예를 들어, `flux-system/gitlab-agent`입니다.
1. **Kubernetes 개요** 탭을 선택하세요.

## 배포 보안 {#secure-the-deployment}

{{< details >}}

- 티어:  Premium, Ultimate

{{< /details >}}

지금까지 `.gitlab/agents/testing/config.yaml` 파일을 사용하여 에이전트를 배포했습니다. 이 구성을 통해 에이전트 배포를 위해 구성된 서비스 계정을 사용하여 사용자 액세스를 활성화합니다. 사용자 액세스는 Kubernetes 대시보드 및 로컬 액세스에서 사용됩니다.

배포를 안전하게 유지하려면 이 설정을 변경하여 GitLab 사용자를 모방해야 합니다. 이 경우 일반 Kubernetes RBAC(역할 기반 액세스 제어)를 통해 클러스터 리소스에 대한 액세스를 관리할 수 있습니다.

사용자 모방을 활성화하려면:

1. `.gitlab/agents/testing/config.yaml` 파일에서 `user_access.access_as.agent: {}`를 `user_access.access_as.user: {}`로 바꾸세요.
1. Kubernetes용 구성된 대시보드로 이동하세요. 액세스가 제한되면 대시보드에 오류 메시지가 표시됩니다.
1. `clusters/testing/gitlab-user-read.yaml`에 다음 코드를 추가하세요:

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
      name: gitlab-user-view
   roleRef:
      name: view
      kind: ClusterRole
      apiGroup: rbac.authorization.k8s.io
   subjects:
      - name: gitlab:user
        kind: Group
   ```

1. 추가된 매니페스트를 Flux가 적용하도록 몇 초 정도 기다렸다가 Kubernetes 대시보드를 다시 확인하세요. 배포된 클러스터 역할 바인딩이 모든 GitLab 사용자에게 읽기 액세스 권한을 부여하므로 대시보드가 정상 상태로 돌아와야 합니다.

사용자 액세스에 대한 자세한 내용은 [사용자에게 Kubernetes 액세스 권한 부여](user_access.md)를 참조하세요.

## 모든 것을 최신 상태로 유지 {#keep-everything-up-to-date}

설치 후 Flux와 `agentk`를 업그레이드해야 할 수도 있습니다.

이렇게 하려면 다음을 수행합니다.

- `flux bootstrap gitlab` 및 `glab cluster agent bootstrap` 명령을 다시 실행하세요.

## 다음 단계 {#next-steps}

에이전트를 등록하고 Flux 매니페스트를 저장한 프로젝트에서 클러스터에 직접 배포할 수 있습니다. 에이전트는 다중 테넌시를 지원하도록 설계되었으며, 구성된 에이전트 및 Flux 설치로 다른 프로젝트 및 그룹으로 구성을 확장할 수 있습니다.

후속 자습서인 [Kubernetes에 배포 시작하기](getting_started_deployments.md)를 통해 작업하는 것을 고려하세요. GitLab에서 Kubernetes 사용에 대해 자세히 알아보려면 다음을 참조하세요:

- [Kubernetes와 GitLab 통합 사용을 위한 모범 사례](enterprise_considerations.md)
- 에이전트를 사용하여 [운영 컨테이너 스캔](vulnerabilities.md)하기
- 엔지니어를 위해 [원격 워크스페이스](../../workspace/_index.md) 제공하기

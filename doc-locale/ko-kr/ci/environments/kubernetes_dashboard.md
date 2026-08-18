---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes용 대시보드
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- [GitLab 16.1에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/390769), [기능 플래그](../../administration/feature_flags/_index.md) `environment_settings_to_graphql`, `kas_user_access`, `kas_user_access_project`, 및 `expose_authorized_cluster_agents` 포함. 이 기능은 [베타](../../policy/development_stages_support.md#beta) 단계입니다.
- 기능 플래그 `environment_settings_to_graphql`이(가) GitLab 16.2에서 [제거되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124177).
- 기능 플래그 `kas_user_access`, `kas_user_access_project`, 및 `expose_authorized_cluster_agents`이(가) GitLab 16.2에서 [제거되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125835).
- 16.10에서 환경 세부 정보 페이지로 [이동되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/431746).

{{< /history >}}

Kubernetes 대시보드를 사용하여 직관적인 시각적 인터페이스로 클러스터의 상태를 파악합니다. 대시보드는 CI/CD 또는 GitOps로 배포했는지 여부에 관계없이 연결된 모든 Kubernetes 클러스터와 함께 작동합니다.

![Kubernetes Pod 및 서비스의 상태를 보여주는 대시보드](img/kubernetes_summary_ui_v17_2.png)

## 대시보드 구성 {#configure-a-dashboard}

{{< history >}}

- 네임스페이스별 리소스 필터링이 GitLab 16.2에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/403618) [기능 플래그](../../administration/feature_flags/_index.md) `kubernetes_namespace_for_environment` 포함. 기본적으로 비활성화되어 있습니다.
- 네임스페이스별 리소스 필터링이 GitLab 16.3에서 [기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127043). 기능 플래그 `kubernetes_namespace_for_environment`이 제거되었습니다.
- 관련 Flux 리소스 선택이 GitLab 16.3에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128857) [기능 플래그](../../administration/feature_flags/_index.md) `flux_resource_for_environment` 포함.
- 관련 Flux 리소스 선택이 GitLab 16.4에서 [일반 공개됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130648). 기능 플래그 `flux_resource_for_environment`이 제거되었습니다.

{{< /history >}}

주어진 환경에 사용할 대시보드를 구성합니다. 이미 존재하는 환경에 대해 대시보드를 구성하거나 환경을 생성할 때 추가할 수 있습니다.

전제 조건:

- Kubernetes용 GitLab 에이전트가 [설치되어](../../user/clusters/agent/install/_index.md) 있고 [`user_access`](../../user/clusters/agent/user_access.md)이(가) 환경의 프로젝트 또는 상위 그룹에 대해 구성되어 있습니다.

{{< tabs >}}

{{< tab title="환경이 이미 존재함" >}}

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을(를) 선택합니다.
1. Kubernetes 에이전트와 연결될 환경을 선택합니다.
1. **편집**을(를) 선택합니다.
1. Kubernetes용 GitLab 에이전트를 선택합니다.
1. 선택 사항. **Kubernetes namespace** 드롭다운 목록에서 네임스페이스를 선택합니다.
1. 선택 사항. **Flux resource** 드롭다운 목록에서 Flux 리소스를 선택합니다.
1. **Save**를 선택합니다.

{{< /tab >}}

{{< tab title="환경이 존재하지 않음" >}}

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을(를) 선택합니다.
1. **새로운 환경**을(를) 선택합니다.
1. **이름** 필드를 작성합니다.
1. Kubernetes용 GitLab 에이전트를 선택합니다.
1. 선택 사항. **Kubernetes namespace** 드롭다운 목록에서 네임스페이스를 선택합니다.
1. 선택 사항. **Flux resource** 드롭다운 목록에서 Flux 리소스를 선택합니다.
1. **Save**를 선택합니다.

{{< /tab >}}

{{< /tabs >}}

### 동적 환경을 위한 대시보드 구성 {#configure-a-dashboard-for-a-dynamic-environment}

{{< history >}}

- GitLab 17.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467912)되었습니다.

{{< /history >}}

동적 환경을 위한 대시보드를 구성하려면:

- `.gitlab-ci.yml` 파일에서 에이전트를 지정합니다. 에이전트 구성 프로젝트의 전체 경로와 콜론 뒤에 에이전트의 이름을 지정해야 합니다.

예를 들어:

```yaml
deploy_review_app:
  stage: deploy
  script: make deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    kubernetes:
      agent: path/to/agent/project:agent-name
```

자세한 내용은 [CI/CD YAML 구문 참조](../yaml/_index.md#environmentkubernetes)를 참조합니다.

## 대시보드 보기 {#view-a-dashboard}

{{< history >}}

- Kubernetes Watch API 통합이 GitLab 16.6에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/422945) [기능 플래그](../../administration/feature_flags/_index.md) `k8s_watch_api` 포함. 기본적으로 비활성화되어 있습니다.
- Kubernetes Watch API 통합이 GitLab 16.7에서 [기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136831).
- GitLab 17.1에서 [일반 공개됨](https://gitlab.com/gitlab-org/gitlab/-/issues/427762). 기능 플래그 `k8s_watch_api`이 제거되었습니다.

{{< /history >}}

대시보드를 보고 연결된 클러스터의 상태를 확인합니다. Kubernetes 리소스 및 Flux 조정의 상태가 실시간으로 업데이트됩니다.

구성된 대시보드를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을(를) 선택합니다.
1. Kubernetes 에이전트와 연결된 환경을 선택합니다.
1. **Kubernetes 개요** 탭을 선택합니다.

Pod 목록이 표시됩니다. Pod을 선택하여 세부 정보를 봅니다.

### Flux 동기화 상태 {#flux-sync-status}

{{< history >}}

- GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/391581)되었습니다.
- Flux 리소스의 이름 사용자 정의가 GitLab 16.3에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128857) [기능 플래그](../../administration/feature_flags/_index.md) `flux_resource_for_environment` 포함.
- Flux 리소스의 이름 사용자 정의가 GitLab 16.4에서 [일반 공개됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130648). 기능 플래그 `flux_resource_for_environment`이 제거되었습니다.

{{< /history >}}

대시보드에서 Flux 배포의 동기화 상태를 검토할 수 있습니다. 배포 상태를 표시하려면 대시보드가 `Kustomization` 및 `HelmRelease` 리소스를 검색할 수 있어야 하며, 이를 위해서는 환경에 대해 상태를 구성해야 합니다.

GitLab은 환경 설정의 **Flux resource** 드롭다운 목록으로 지정된 `Kustomization` 및 `HelmRelease` 리소스를 검색합니다.

대시보드에는 다음 상태 배지 중 하나가 표시됩니다:

| 상태 | 설명 |
|---------|-------------|
| **회복됨** | 배포가 해당 환경과 성공적으로 조정되었습니다. |
| **회복중** | 조정이 진행 중입니다. |
| **정지됨** | 인적 개입 없이는 해결할 수 없는 오류로 인해 조정이 중단되었습니다. |
| **실패함** | 복구할 수 없는 오류로 인해 배포를 조정할 수 없습니다. |
| **알 수 없음** | 배포의 동기화 상태를 검색할 수 없습니다. |
| **사용할 수 없음** | `Kustomization` 또는 `HelmRelease` 리소스를 검색할 수 없습니다. |

### Flux 조정 트리거 {#trigger-flux-reconciliation}

{{< history >}}

- GitLab 17.3에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/434248).

{{< /history >}}

배포를 Flux 리소스와 수동으로 조정할 수 있습니다.

조정을 트리거하려면:

1. 대시보드에서 Flux 배포의 동기화 상태 배지를 선택합니다.
1. **조치** ({{< icon name="ellipsis_v" >}}) > **트리거 조정** ({{< icon name="retry" >}})을(를) 선택합니다.

### Flux 조정 일시 중단 또는 재개 {#suspend-or-resume-flux-reconciliation}

{{< history >}}

- GitLab 17.5에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/478380).

{{< /history >}}

UI에서 Flux 조정을 수동으로 일시 중단하거나 재개할 수 있습니다.

조정을 일시 중단하거나 재개하려면:

1. 대시보드에서 Flux 배포의 동기화 상태 배지를 선택합니다.
1. **조치** ({{< icon name="ellipsis_v" >}})를 선택하고 다음 중 하나를 선택합니다:
   - **조정 일시 중단**({{< icon name="stop" >}})으로 Flux 조정을 일시 중지합니다.
   - **조정 재개**({{< icon name="play" >}})로 Flux 조정을 다시 시작합니다.

### Pod 로그 보기 {#view-pod-logs}

{{< history >}}

- GitLab 17.2에서 [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/13793).

{{< /history >}}

구성된 대시보드에서 환경 전체의 문제를 빠르게 파악하고 해결하려는 경우 Pod 로그를 봅니다. Pod의 각 컨테이너에 대한 로그를 볼 수 있습니다.

- **로그 보기**를 선택한 다음 로그를 볼 컨테이너를 선택합니다.

Pod 세부 정보에서도 Pod 로그를 볼 수 있습니다.

### Pod 삭제 {#delete-a-pod}

{{< history >}}

- GitLab 17.3에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/467653).

{{< /history >}}

실패한 Pod을 다시 시작하려면 Kubernetes 대시보드에서 삭제합니다.

Pod을 삭제하려면:

1. **Kubernetes 개요** 탭에서 삭제할 Pod을 찾습니다.
1. **조치** ({{< icon name="ellipsis_v" >}}) > **Pod 삭제** ({{< icon name="remove" >}})을(를) 선택합니다.

Pod 세부 정보에서도 Pod을 삭제할 수 있습니다.

## 상세 대시보드 {#detailed-dashboard}

{{< history >}}

- GitLab 16.4에서 [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/11351), [기능 플래그](../../administration/feature_flags/_index.md) `k8s_dashboard` 포함. 기본적으로 비활성화되어 있습니다.
- GitLab 16.7에서 [GitLab.com에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/424237) 일부 사용자용.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트 가능하지만 프로덕션 사용 준비가 되지 않았습니다.

상세 대시보드는 다음 Kubernetes 리소스에 대한 정보를 제공합니다:

- Pod
- 서비스
- 배포
- ReplicaSet
- StatefulSet
- DaemonSet
- 작업
- CronJob

각 대시보드는 상태, 네임스페이스 및 사용 기간과 함께 리소스 목록을 표시합니다. 리소스를 선택하여 레이블, YAML 형식의 상태, 주석 및 사양을 포함한 자세한 정보가 있는 창을 열 수 있습니다.

![연결된 클러스터에 대한 상세 정보를 보여주는 대시보드](img/kubernetes_dashboard_deployments_v16_9.png)

[이 문제](https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/general/-/issues/53#note_1720060812)에 설명된 포커스 변경으로 인해 상세 대시보드의 작업이 일시 중지되었습니다.

상세 대시보드에 대한 피드백을 제공하려면 [이슈 460279](https://gitlab.com/gitlab-org/gitlab/-/issues/460279)를 참조합니다.

### 상세 대시보드 보기 {#view-a-detailed-dashboard}

전제 조건:

- Kubernetes용 GitLab 에이전트가 [구성되어](../../user/clusters/agent/install/_index.md) 있고 [`user_access`](../../user/clusters/agent/user_access.md) 키워드를 사용하여 환경의 프로젝트 또는 상위 그룹과 공유됩니다.

상세 대시보드는 사이드바 네비게이션에서 연결되지 않습니다. 상세 대시보드를 보려면:

1. Kubernetes 에이전트 ID 찾기:
   1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
   1. **운영** > **Kubernetes 클러스터**를 선택합니다.
   1. 액세스할 에이전트의 수치 ID를 복사합니다.
1. 다음 URL 중 하나로 이동하여 `<agent_id>`을(를) 에이전트 ID로 바꿉니다:

   | 리소스 유형 | URL |
   | --- | --- |
   | Pod | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/pods` |
   | 서비스 | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/services` |
   | 배포 | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/deployments` |
   | ReplicaSet | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/replicaSets` |
   | StatefulSet | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/statefulSets` |
   | DaemonSet | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/daemonSets` |
   | 작업 | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/jobs` |
   | CronJob | `https://myinstance.gitlab.com/-/kubernetes/<agent_id>/cronJobs` |

## 문제 해결 {#troubleshooting}

Kubernetes 대시보드를 사용할 때 다음 문제가 발생할 수 있습니다.

### 사용자가 API 그룹의 리소스를 나열할 수 없음 {#user-cannot-list-resource-in-api-group}

`Error: services is forbidden: User "gitlab:user:<user-name>" cannot list resource "<resource-name>" in API group "" at the cluster scope`를 명시하는 오류가 표시될 수 있습니다.

이 오류는 사용자가 [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)에서 지정된 작업을 수행할 수 없을 때 발생합니다.

해결하려면 [RBAC 구성](../../user/clusters/agent/user_access.md#configure-kubernetes-access)을(를) 확인합니다. RBAC이 올바르게 구성된 경우 Kubernetes 관리자에게 문의합니다.

### GitLab 에이전트 드롭다운 목록이 비어 있음 {#gitlab-agent-dropdown-list-is-empty}

새 환경을 구성할 때 Kubernetes 클러스터를 구성했더라도 **GitLab 에이전트** 드롭다운 목록이 비어 있을 수 있습니다.

**GitLab 에이전트** 드롭다운 목록을 채우려면 [`user_access`](../../user/clusters/agent/user_access.md) 키워드를 사용하여 에이전트에 Kubernetes 액세스 권한을 부여합니다.

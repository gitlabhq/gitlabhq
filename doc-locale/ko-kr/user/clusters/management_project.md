---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 클러스터 관리 프로젝트(더 이상 사용되지 않음)
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab Self-Managed에서 비활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/353410) GitLab 15.0.

{{< /history >}}

> [!flag]
> 이 기능은 GitLab Self-Managed에서 기본적으로 사용할 수 없습니다. 사용 가능하게 하려면 관리자가 `certificate_based_clusters`라는 [기능 플래그를 사용으로 설정](../../administration/feature_flags/_index.md)할 수 있습니다.

프로젝트를 클러스터의 관리 프로젝트로 지정할 수 있습니다.

> [!warning]
> 클러스터 관리 프로젝트는 GitLab 14.5에서 [더 이상 사용되지 않음](https://gitlab.com/groups/gitlab-org/configure/-/work_items/8)으로 표시되었습니다. 클러스터 애플리케이션을 관리하려면 [GitLab agent for Kubernetes](agent/_index.md)를 [클러스터 관리 프로젝트 템플릿](management_project_template.md)과 함께 사용합니다.

관리 프로젝트를 사용하여 Kubernetes [`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) 권한으로 배포 작업을 실행할 수 있습니다.

다음과 같은 경우에 유용합니다:

- 클러스터에 클러스터 전체 애플리케이션을 설치하는 파이프라인 생성, [관리 프로젝트 템플릿](management_project_template.md)에서 자세한 내용을 확인합니다.
- `cluster-admin` 권한이 필요한 모든 작업.

## 권한 {#permissions}

관리 프로젝트만 `cluster-admin` 권한을 받습니다. 다른 모든 프로젝트는 [네임스페이스 범위 `edit` 수준 권한](../project/clusters/cluster_access.md#rbac-cluster-resources)을 계속 받습니다.

관리 프로젝트는 다음으로 제한됩니다:

- 프로젝트 수준 클러스터의 경우 관리 프로젝트는 클러스터의 프로젝트와 같은 네임스페이스(또는 하위 항목)에 있어야 합니다.
- 그룹 수준 클러스터의 경우 관리 프로젝트는 클러스터의 그룹과 같은 그룹(또는 하위 항목)에 있어야 합니다.
- 인스턴스 수준 클러스터의 경우 이러한 제한이 없습니다.

## 클러스터 관리 프로젝트를 생성하고 구성하는 방법 {#how-to-create-and-configure-a-cluster-management-project}

클러스터 관리 프로젝트를 사용하여 클러스터를 관리하려면:

1. 클러스터의 클러스터 관리 프로젝트로 사용할 새 프로젝트를 생성합니다.
1. [클러스터를 관리 프로젝트와 연결](#associate-the-cluster-management-project-with-the-cluster)합니다.
1. [클러스터의 파이프라인 구성](#configuring-your-pipeline)합니다.
1. [환경 범위 설정](#setting-the-environment-scope)합니다.

### 클러스터 관리 프로젝트를 클러스터와 연결 {#associate-the-cluster-management-project-with-the-cluster}

사전 요구 사항:

- 인스턴스 클러스터를 연결하기 위한 관리자 액세스.

클러스터 관리 프로젝트를 클러스터와 연결하려면:

1. 적절한 구성 페이지로 이동합니다. 다음의 경우:
   - [프로젝트 수준 클러스터](../project/clusters/_index.md), 프로젝트의 **운영** > **Kubernetes 클러스터** 페이지로 이동합니다.
   - [그룹 수준 클러스터](../group/clusters/_index.md), 그룹의 **Kubernetes** 페이지로 이동합니다.
   - [인스턴스 수준 클러스터](../instance/clusters/_index.md):
     1. 오른쪽 위 모서리에서 **관리자**를 선택합니다.
     1. **Kubernetes**를 선택합니다.
1. **고급 설정**을 확장합니다.
1. **클러스터 관리 프로젝트** 드롭다운 목록에서 이전 단계에서 생성한 클러스터 관리 프로젝트를 선택합니다.

### 파이프라인 구성 {#configuring-your-pipeline}

프로젝트를 클러스터의 관리 프로젝트로 지정한 후 해당 프로젝트에 `.gitlab-ci.yml` 파일을 추가합니다. 예를 들어:

```yaml
configure cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: production
```

### 환경 범위 설정 {#setting-the-environment-scope}

[환경 범위](../project/clusters/multiple_kubernetes_clusters.md#setting-the-environment-scope)는 여러 클러스터를 같은 관리 프로젝트에 연결할 때 사용할 수 있습니다.

각 범위는 관리 프로젝트의 단일 클러스터에만 사용할 수 있습니다.

예를 들어 다음 Kubernetes 클러스터가 관리 프로젝트와 연결됩니다:

| 클러스터     | 환경 범위 |
| ----------- | ----------------- |
| 개발 | `*`               |
| 스테이징     | `staging`         |
| 프로덕션  | `production`      |

`.gitlab-ci.yml` 파일에 설정된 환경은 개발, 스테이징 및 프로덕션 클러스터에 배포됩니다.

```yaml
stages:
  - deploy

configure development cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: development

configure staging cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: staging

configure production cluster:
  stage: deploy
  script: kubectl get namespaces
  environment:
    name: production
```

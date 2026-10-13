---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 클러스터 환경 (지원 중단됨)
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!flag]
> 이 기능은 GitLab Self-Managed에서 기본적으로 사용할 수 없습니다. 사용 가능하게 하려면 관리자가 `certificate_based_clusters`라는 [기능 플래그를 사용으로 설정](../../administration/feature_flags/_index.md)할 수 있습니다.

클러스터 환경은 Kubernetes 클러스터에 배포된 CI [환경](../../ci/environments/_index.md)을 통합 보기로 제공합니다. 이 보기는 다음을 수행합니다:

- 배포와 관련된 프로젝트 및 환경을 표시합니다.
- 해당 환경의 파드 상태를 표시합니다.

클러스터 환경을 사용하면 다음을 파악할 수 있습니다:

- 클러스터에 배포된 프로젝트
- 각 프로젝트의 환경에서 사용 중인 파드 수
- 해당 환경에 배포하는 데 사용된 CI 작업

![프로젝트 목록, 환경 및 파드 상태를 표시하는 클러스터 환경 페이지입니다.](img/cluster_environments_table_v12_3.png)

클러스터 환경에 대한 액세스는 [그룹 유지관리자 및 소유자](../permissions.md#group-permissions)로 제한됩니다.

## 사용 {#usage}

다음을 수행하려면:

- 클러스터의 환경을 추적하려면 [Kubernetes 클러스터에 배포](../project/clusters/deploy_to_cluster.md)해야 합니다.
- 파드 사용량을 올바르게 표시하려면 [배포 보드 활성화](../project/deploy_boards.md#enabling-deploy-boards)해야 합니다.

그룹 수준 또는 인스턴스 수준 클러스터에 성공적으로 배포한 후:

1. 그룹의 **Kubernetes** 페이지로 이동합니다.
1. **환경** 탭을 선택합니다.

클러스터에 성공적으로 배포한 항목만 이 페이지에 포함됩니다. 클러스터가 아닌 환경은 포함되지 않습니다.

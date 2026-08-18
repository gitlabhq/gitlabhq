---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes 배포 구성(사용 중단됨)
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> 이 기능은 GitLab 14.5에서 [사용 중단](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)되었습니다.

프로젝트에 연결된 [Kubernetes 클러스터](../../user/infrastructure/clusters/_index.md)에 배포하는 경우 `.gitlab-ci.yml` 파일에서 이러한 배포를 구성할 수 있습니다.

> [!note]
> Kubernetes 구성은 [GitLab에서 관리하는](../../user/project/clusters/gitlab_managed_clusters.md) Kubernetes 클러스터에서는 지원되지 않습니다.

다음 구성 옵션이 지원됩니다:

- [`namespace`](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

다음 예제에서 작업은 애플리케이션을 `production` Kubernetes 네임스페이스에 배포합니다.

```yaml
deploy:
  stage: deploy
  script:
    - echo "Deploy to production server"
  environment:
    name: production
    url: https://example.com
    kubernetes:
      agent: path/to/agent/project:agent-name
      dashboard:
        namespace: production
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

GitLab Kubernetes 통합을 사용하여 Kubernetes 클러스터에 배포할 때 클러스터 및 네임스페이스 정보를 볼 수 있습니다. 배포 작업 페이지의 작업 트레이스 위에 표시됩니다:

![클러스터 및 네임스페이스가 포함된 배포 클러스터 정보](img/environments_deployment_cluster_v12_8.png)

## 점진적 롤아웃 구성 {#configure-incremental-rollouts}

Kubernetes 파드의 일부에만 프로덕션 변경 사항을 릴리스하는 방법을 알아봅니다. [점진적 롤아웃](incremental_rollouts.md) 참고자료를 살펴보세요.

## 관련 항목 {#related-topics}

- [배포 보드(사용 중단됨)](../../user/project/deploy_boards.md)

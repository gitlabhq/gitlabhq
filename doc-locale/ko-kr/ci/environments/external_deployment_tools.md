---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 배포 도구의 배포 추적
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab에서 [기본 제공 배포 솔루션](_index.md)을 제공하지만, Heroku나 ArgoCD와 같은 외부 배포 도구를 사용하는 것이 좋을 수 있습니다. GitLab은 이러한 외부 도구에서 배포 이벤트를 수신할 수 있으며, GitLab 내에서 배포를 추적할 수 있습니다. 예를 들어, 추적을 설정하여 다음 기능을 사용할 수 있습니다:

- [머지 리퀘스트가 배포되었을 때와 어느 환경에 배포되었는지 확인](../../user/project/merge_requests/widgets.md#post-merge-pipeline-status)합니다.
- [환경 또는 배포 날짜별로 머지 리퀘스트 필터링](../../user/project/merge_requests/_index.md#by-environment-or-deployment-date)합니다.
- [DevOps Research and Assessment (DORA) 메트릭](../../user/analytics/dora_metrics.md)입니다.
- [환경 및 배포 보기](_index.md#view-environments-and-deployments)합니다.
- [배포별 새로 포함된 머지 리퀘스트 추적](deployments.md#track-newly-included-merge-requests-per-deployment)합니다.

> [!note]
> 일부 기능은 GitLab에서 외부 배포를 승인하고 활용할 수 없기 때문에 사용할 수 없습니다. 여기에는 [보호 환경](protected_environments.md), [배포 승인](deployment_approvals.md), [배포 안전](deployment_safety.md), [배포 롤백](deployments.md#deployment-rollback)이 포함됩니다.

## 배포 추적 설정 방법 {#how-to-set-up-deployment-tracking}

외부 배포 도구는 일반적으로 배포 상태가 변경될 때 추가 API 요청을 실행하기 위해 [웹후크](https://en.wikipedia.org/wiki/Webhook)를 제공합니다. 도구를 구성하여 GitLab [Deployment API](../../api/deployments.md)에 요청을 보낼 수 있습니다. 다음은 이벤트 및 API 요청 플로우의 개요입니다:

- 배포가 실행을 시작하면, [상태 `running`로 배포를 생성](../../api/deployments.md#create-a-deployment)합니다.
- 배포가 성공하면, [배포 상태를 `success`로 업데이트](../../api/deployments.md#update-a-deployment)합니다.
- 배포가 실패하면, [배포 상태를 `failed`로 업데이트](../../api/deployments.md#update-a-deployment)합니다.

> [!note]
> GitLab API 인증을 위해 [프로젝트 액세스 토큰](../../user/project/settings/project_access_tokens.md)을 생성할 수 있습니다.

### 예: ArgoCD의 배포 추적 {#example-track-deployments-of-argocd}

[ArgoCD 웹후크](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/services/webhook/)를 사용하여 GitLab Deployment API로 배포 이벤트를 보낼 수 있습니다. 다음은 ArgoCD가 새 리비전을 성공적으로 배포할 때 GitLab에 `success` 배포 레코드를 생성하는 예제 설정입니다:

1. 새 웹후크를 생성합니다. 다음 매니페스트 파일을 저장하고 `kubectl apply -n argocd -f <manifiest-file-path>`로 적용할 수 있습니다:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: argocd-notifications-cm
   data:
     trigger.on-deployed: |
       - description: Application is synced and healthy. Triggered once per commit.
         oncePer: app.status.sync.revision
         send:
         - gitlab-deployment-status
         when: app.status.operationState.phase in ['Succeeded'] and app.status.health.status == 'Healthy'
     template.gitlab-deployment-status: |
       webhook:
         gitlab:
           method: POST
           path: /projects/<your-project-id>/deployments
           body: |
             {
               "status": "success",
               "environment": "production",
               "sha": "{{.app.status.operationState.operation.sync.revision}}",
               "ref": "main",
               "tag": "false"
             }
     service.webhook.gitlab: |
       url: https://gitlab.com/api/v4
       headers:
       - name: PRIVATE-TOKEN
         value: <your-access-token>
       - name: Content-type
         value: application/json
   ```

1. 애플리케이션에서 새 구독을 생성합니다:

   ```shell
   kubectl patch app <your-app-name> -n argocd -p '{"metadata": {"annotations": {"notifications.argoproj.io/subscribe.on-deployed.gitlab":""}}}' --type merge
   ```

> [!note]
> 배포가 예상대로 생성되지 않은 경우, [`argocd-notifications` 도구](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/troubleshooting/)로 문제를 해결할 수 있습니다. 예를 들어, `argocd-notifications template notify gitlab-deployment-status <your-app-name> --recipient gitlab:argocd-notifications`는 API 요청을 즉시 트리거하고 GitLab API 서버에서 오류 메시지가 있으면 렌더링합니다.

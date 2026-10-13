---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Managed Apps에서 Cluster Management Projects로 마이그레이션(더 이상 사용되지 않음)
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Managed Apps는 사용자 제어 Cluster Management 프로젝트를 지원하기 위해 더 이상 사용되지 않습니다. 프로젝트를 통해 클러스터 애플리케이션을 관리하면 기존 GitLab Managed Apps를 사용하는 것보다 클러스터를 훨씬 유연하게 관리할 수 있습니다. 클러스터 관리 프로젝트로 마이그레이션하려면 [러너](../../ci/runners/_index.md)를 사용 가능하게 하고 [Helm](https://helm.sh/)에 익숙해야 합니다.

## Cluster Management Project로 마이그레이션 {#migrate-to-a-cluster-management-project}

GitLab Managed Apps에서 Cluster Management Project로 마이그레이션하려면 아래 단계를 따르세요. 예제가 포함된 [비디오 설명](#video-walk-throughs)도 참조하세요.

1. [Cluster Management Project 템플릿](management_project_template.md#create-a-project-based-on-the-cluster-management-project-template)을 기반으로 새 프로젝트를 생성합니다.
1. 이 프로젝트에 대한 [에이전트 설치](agent/install/_index.md)를 클러스터에서 수행합니다.
1. `KUBE_CONTEXT` CI/CD 변수를 새로 설치된 에이전트의 컨텍스트로 설정합니다. 이는 Project Template의 `.gitlab-ci.yml`에 나와 있는 대로 수행합니다.
1. 사전 구성된 [`.gitlab-ci.yml`](management_project_template.md#the-gitlab-ciyml-file) 파일을 사용하여 Helm v2 릴리스를 통해 배포된 앱을 감지합니다:

   - 기본 GitLab Managed Apps 네임스페이스를 덮어쓴 경우 `.gitlab-ci.yml`을(를) 편집하고 스크립트가 인수로 올바른 네임스페이스를 받고 있는지 확인합니다:

     ```yaml
     script:
       - gl-fail-if-helm2-releases-exist <your_custom_namespace>
     ```

   - 기본 이름(`gitlab-managed-apps`)을 유지한 경우 스크립트가 이미 설정되어 있습니다.

   어느 경우든 [파이프라인을 수동으로 실행](../../ci/pipelines/_index.md#run-a-pipeline-manually)하고 `detect-helm2-releases` 작업의 로그를 읽어 보유 중인 Helm v2 릴리스를 확인합니다(있는 경우).

1. Helm v2 릴리스가 없으면 이 단계를 건너뜁니다. 그렇지 않으면 [Helm v2에서 Helm v3으로 마이그레이션하는 방법](https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/)에 대한 공식 Helm 설명서를 따르고, Helm v2 릴리스가 성공적으로 마이그레이션되었음을 확인한 후 정리합니다.

1. 이 단계에서는 Helm v3 릴리스만 있어야 합니다. 주 [`./helmfile.yaml`](management_project_template.md#the-main-helmfileyml-file)에서 이 프로젝트로 관리할 애플리케이션의 경로를 주석 처리 해제합니다. 한 번에 관리할 모든 경로를 주석 처리 해제할 수 있지만, 프로세스 중에 혼동을 피하기 위해 각 앱에 대해 다음 단계를 별도로 반복해야 합니다.
1. 관련 `applications/{app}/helmfiles.yaml`을(를) 편집하여 앱에 배포된 차트 버전과 일치시킵니다. GitLab Runner Helm v3 릴리스를 예로 들어봅시다:

   다음 명령은 릴리스와 해당 버전을 나열합니다:

   ```shell
   helm ls -n gitlab-managed-apps

   NAME NAMESPACE REVISION UPDATED STATUS CHART APP VERSION
   runner gitlab-managed-apps 1 2021-06-09 19:36:55.739141644 +0000 UTC deployed gitlab-runner-0.28.0 13.11.0
   ```

   `CHART` 열의 버전을 가져옵니다. 이는 `{release}-v{chart_version}` 형식입니다. 그런 다음 `./applications/gitlab-runner/helmfile.yaml`에서 `version:` 속성을 편집하여 배포한 버전과 일치시킵니다. 이는 마이그레이션 중에 버전 업그레이드를 피하기 위한 안전한 단계입니다. 앱을 다른 네임스페이스에 배포한 경우 이전 명령에서 `gitlab-managed-apps`을(를) 바꾸어야 합니다.

1. 앱과 관련된 `applications/{app}/values.yaml`을(를) 편집하여 배포된 값과 일치시킵니다. 예를 들어 GitLab Runner의 경우:

   1. 다음 명령의 출력을 복사합니다(크기가 클 수 있음):

      ```shell
      helm get values runner -n gitlab-managed-apps -a --output yaml
      ```

   1. `applications/gitlab-runner/values.yaml`을(를) 이전 명령의 출력으로 덮어씁니다.

   이 안전한 단계는 예기치 않은 기본값이 배포된 값을 덮어쓰지 않음을 보장합니다. 예를 들어 GitLab Runner의 `gitlabUrl` 또는 `runnerRegistrationToken`이(가) 실수로 덮어써질 수 있습니다.

1. 일부 앱은 특별한 주의가 필요합니다:

   - Ingress: 기존 [차트 문제](https://github.com/helm/charts/pull/13646)로 인해 [`./gl-helmfile`](management_project_template.md#the-gitlab-ciyml-file) 명령을 실행하려고 할 때 `spec.clusterIP: Invalid value`이(가) 표시될 수 있습니다. 이 문제를 해결하려면 `applications/ingress/values.yaml`의 릴리스 값을 덮어쓴 후 `omitClusterIP: false`의 모든 항목을 덮어쓰고 `omitClusterIP: true`로 설정해야 할 수 있습니다. 다른 방법은 `kubectl get services -n gitlab-managed-apps`을(를) 실행하여 이러한 IP를 수집한 다음 해당 명령에서 얻은 값으로 불만을 야기하는 각 `ClusterIP`를 덮어쓰는 것입니다.

   - Vault: 이 애플리케이션은 Helm v2에서 사용되는 차트에서 Helm v3에서 사용되는 차트로의 주요 변경 사항을 도입합니다. 따라서 이를 이 Cluster Management Project와 통합하는 유일한 방법은 이 앱을 실제로 제거하고 `applications/vault/values.yaml`에서 제안하는 차트 버전을 수락하는 것입니다.

   - Cert-manager:

     - Kubernetes 버전 1.20 이상을 사용하는 사용자의 경우, 더 이상 사용되지 않는 cert-manager v0.10은 더 이상 유효하지 않으며 업그레이드에는 주요 변경 사항이 포함됩니다. 따라서 [cert-manager v0.10을 백업 및 제거](#backup-and-uninstall-cert-manager-v010)하고 대신 최신 cert-manager를 설치해야 합니다. 이 버전을 설치하려면 [`./helmfile.yaml`](management_project_template.md#the-main-helmfileyml-file)에서 `applications/cert-manager/helmfile.yaml`의 주석을 처리 해제합니다. 이는 새 버전을 설치하기 위한 파이프라인을 트리거합니다.
     - Kubernetes 버전이 1.20 미만인 사용자는 프로젝트의 주 Helmfile([`./helmfile.yaml`](management_project_template.md#the-main-helmfileyml-file))에서 `applications/cert-manager-legacy/helmfile.yaml`의 주석을 처리 해제하여 v0.10을 유지할 수 있습니다.

       > [!warning]
       > Cert-manager v0.10은 Kubernetes가 버전 1.20 이상으로 업그레이드될 때 중단됩니다.

1. 위의 모든 단계를 따른 후 [파이프라인을 수동으로 실행](../../ci/pipelines/_index.md#run-a-pipeline-manually)하고 `apply` 작업 로그를 확인하여 애플리케이션이 성공적으로 감지되고 설치되었는지, 예기치 않은 업데이트가 있었는지 확인합니다.

   일부 주석 체크섬은 업데이트될 것으로 예상되며, 이 속성도 마찬가지입니다:

   ```diff
   --- heritage: Tiller
   +++ heritage: Tiller
   ```

성공적인 파이프라인을 얻은 후 Cluster Management Project로 관리할 기타 배포된 앱에 대해 이 단계를 반복합니다.

## Cert-manager v0.10 백업 및 제거 {#backup-and-uninstall-cert-manager-v010}

1. cert-manager v0.10 데이터를 백업하는 방법에 대해 [공식 문서](https://cert-manager.io/docs/devops-tips/backup/)를 참조하세요.
1. `applications/cert-manager/helmfile.yaml` 파일을 편집하여 cert-manager를 제거하고 `installed: true`의 모든 항목을 `installed: false`로 설정합니다.
1. 다음 명령을 실행하여 남아 있는 리소스를 검색합니다: `kubectl get Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges,Secrets,ConfigMaps -n gitlab-managed-apps | grep certmanager`.
1. 이전 단계에서 찾은 각 리소스에 대해 `kubectl delete -n gitlab-managed-apps {ResourceType} {ResourceName}`을(를) 사용하여 삭제합니다. 예를 들어 `ConfigMap` 유형의 리소스를 찾은 경우 `cert-manager-controller`이라는 이름으로 `kubectl delete configmap -n gitlab-managed-apps cert-manager-controller`을(를) 실행하여 삭제합니다.

## 비디오 설명 {#video-walk-throughs}

GMA에서 Cluster Management 프로젝트로 마이그레이션하는 방법에 대한 예제가 포함된 이 비디오를 볼 수 있습니다:

- [새로운 클러스터 관리 프로젝트를 사용하여 처음부터 마이그레이션](https://youtu.be/jCUFGWT0jS0). Helm v2 앱 마이그레이션도 다룹니다.
- [기존 GitLab managed apps CI/CD 프로젝트에서 마이그레이션](https://youtu.be/U2lbBGZjZmc).

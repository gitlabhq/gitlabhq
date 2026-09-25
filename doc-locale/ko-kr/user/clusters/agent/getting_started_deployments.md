---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes에 배포 시작하기
---

이 페이지에서는 GitLab에서 지원하는 방법을 사용하여 Kubernetes에 배포하는 방법을 소개합니다. 최종적으로 다음을 이해하게 됩니다:

- Flux를 사용하여 배포하는 방법
- GitLab CI/CD 파이프라인에서 클러스터에 대해 명령을 배포하거나 실행하는 방법
- 최적의 결과를 위해 Flux와 GitLab CI/CD를 결합하는 방법

## 시작하기 전에 {#before-you-begin}

이 자습서는 [Kubernetes 클러스터를 GitLab에 연결 시작](getting_started.md)에서 생성한 프로젝트를 기반으로 합니다. 해당 자습서에서 생성한 것과 동일한 프로젝트를 사용합니다. 그러나 연결된 Kubernetes 클러스터와 부트스트랩된 Flux 설치가 있는 모든 프로젝트를 사용할 수 있습니다.

## GitLab CI/CD에서 클러스터에 대해 명령 실행 {#run-commands-against-your-cluster-from-gitlab-cicd}

Kubernetes용 에이전트는 [GitLab CI/CD 파이프라인과 통합](ci_cd_workflow.md)됩니다. CI/CD를 사용하여 `kubectl apply`와 `helm upgrade` 같은 명령을 안전하고 확장 가능한 방식으로 클러스터에 대해 실행할 수 있습니다.

이 섹션에서는 GitLab 파이프라인 통합을 사용하여 클러스터에서 비밀을 생성하고 이를 사용하여 GitLab 컨테이너 레지스트리에 액세스합니다. 이 자습서의 나머지 부분에서는 배포된 비밀을 사용합니다.

1. [배포 토큰 생성](../../project/deploy_tokens/_index.md#create-a-deploy-token)할 때 `read_registry` 범위를 사용합니다.
1. 배포 토큰과 사용자 이름을 `CONTAINER_REGISTRY_ACCESS_TOKEN`과 `CONTAINER_REGISTRY_ACCESS_USERNAME`라고 불리는 CI/CD 변수로 저장합니다.
   - 두 변수 모두에 대해 환경을 `container-registry-secret*`로 설정합니다.
   - `CONTAINER_REGISTRY_ACCESS_TOKEN`의 경우:
     - [변수 마스킹](../../../ci/variables/_index.md#mask-a-cicd-variable)합니다.
     - [변수 보호](../../../ci/variables/_index.md#protect-a-cicd-variable)합니다.
1. `.gitlab-ci.yml` 파일에 다음 스니펫을 추가하고, 프로젝트의 경로와 일치하도록 `AGENT_KUBECONTEXT` 변수를 모두 업데이트합니다:

   ```yaml
   stages:
   - setup
   - deploy
   - stop

   create-registry-secret:
     stage: setup
     image: "portainer/kubectl-shell:latest"
     variables:
       AGENT_KUBECONTEXT: my-group/optional-subgroup/my-repository:testing
     before_script:
       # The available agents are automatically injected into the runner environment
       # You need to select the agent to use
       - kubectl config use-context $AGENT_KUBECONTEXT
     script:
       - kubectl delete secret gitlab-registry-auth -n flux-system --ignore-not-found
       - kubectl create secret docker-registry gitlab-registry-auth -n flux-system
         --docker-password="${CONTAINER_REGISTRY_ACCESS_TOKEN}" --docker-username="${CONTAINER_REGISTRY_ACCESS_USERNAME}" --docker-server="${CI_REGISTRY}"
     environment:
       name: container-registry-secret
       on_stop: delete-registry-secret

   delete-registry-secret:
     stage: stop
     image: ""
     variables:
       AGENT_KUBECONTEXT: my-group/optional-subgroup/my-repository:testing
     before_script:
       # The available agents are automatically injected into the runner environment
       # You need to select the agent to use
       - kubectl config use-context $AGENT_KUBECONTEXT
     script:
       - kubectl delete secret -n flux-system gitlab-registry-auth
     environment:
       name: container-registry-secret
       action: stop
     when: manual
   ```

계속하기 전에 CI/CD를 사용하여 다른 명령을 실행할 수 있는 방법을 생각해 보세요.

## 간단한 매니페스트를 OCI 이미지로 빌드하고 클러스터에 배포 {#build-a-simple-manifest-into-an-oci-image-and-deploy-it-to-the-cluster}

프로덕션 사용 사례의 경우 Git 리포지토리와 FluxCD 사이의 캐싱 계층으로 OCI 리포지토리를 사용하는 것이 모범 사례입니다. FluxCD는 OCI 리포지토리에서 새 이미지를 확인하는 한편, GitLab 파이프라인은 Flux 규격 OCI 이미지를 빌드합니다. 엔터프라이즈 모범 사례에 대해 자세히 알아보려면 [엔터프라이즈 고려 사항](enterprise_considerations.md)을 참조하세요.

이 섹션에서는 간단한 Kubernetes 매니페스트를 OCI 아티팩트로 빌드한 후 클러스터에 배포합니다.

1. 다음 `flux` CLI 명령을 실행하여 Flux에 지정된 OCI 이미지를 검색할 위치와 콘텐츠를 배포할 위치를 알립니다. `--url` 값을 GitLab 인스턴스에 맞게 조정합니다. **배포** > **컨테이너 레지스트리**에서 컨테이너 레지스트리 URL을 찾을 수 있습니다. 생성된 `clusters/testing/nginx.yaml` 파일을 검사하여 Flux가 배포할 매니페스트를 찾는 방법을 더 잘 이해할 수 있습니다.

   ```shell
   flux create source oci nginx-example \
    --url oci://registry.gitlab.example.org/my-group/optional-subgroup/my-repository/nginx-example \
    --tag latest \
    --secret-ref gitlab-registry-auth \
    --interval 1m \
    --namespace flux-system \
    --export > clusters/testing/nginx.yaml
    flux create kustomization nginx-example \
    --source OCIRepository/nginx-example \
    --path "." \
    --prune true \
    --target-namespace default \
    --interval 1m \
    --namespace flux-system \
    --export >> clusters/testing/nginx.yaml
   ```

1. NGINX를 예제로 배포합니다. `clusters/applications/nginx/nginx.yaml`에 다음 YAML을 추가합니다:

   ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-example
      namespace: default
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: nginx-example
      template:
        metadata:
          labels:
            app: nginx-example
        spec:
          containers:
            - name: nginx
              image: nginx:1.25
              ports:
                - containerPort: 80
                  protocol: TCP
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx-example
      namespace: default
    spec:
      ports:
        - port: 80
          targetPort: 80
          protocol: TCP
      selector:
        app: nginx-example
   ```

1. 이제 이전 YAML을 OCI 이미지로 패키징해 보겠습니다. `.gitlab-ci.yml` 파일을 다음 스니펫으로 확장하고, `AGENT_KUBECONTEXT` 변수를 다시 한 번 업데이트합니다:

   ```yaml
    nginx-deployment:
        stage: deploy
        variables:
            IMAGE_NAME: nginx-example   # Image name to push
            IMAGE_TAG: latest
            MANIFEST_PATH: "./clusters/applications/nginx"
            IMAGE_TITLE: NGINX example   # Image title to use in OCI annotation
            AGENT_KUBECONTEXT: my-group/optional-subgroup/my-repository:testing
            FLUX_OCI_REPO_NAME: nginx-example  # Flux OCIRepository to reconcile
            NAMESPACE: flux-system  # Namespace for the OCIRepository resource
        # This section configures a GitLab environment for the nginx deployment specifically
        environment:
            name: applications/nginx
            kubernetes:
                agent: $AGENT_KUBECONTEXT
                dashboard:
                  namespace: default
                  flux_resource_path: kustomize.toolkit.fluxcd.io/v1/namespaces/flux-system/kustomizations/nginx-example  # You will deploy this resource in the next step
        image:
            name: "fluxcd/flux-cli:v2.4.0"
            entrypoint: [""]
        before_script:
            - kubectl config use-context $AGENT_KUBECONTEXT
        script:
            # This line builds and pushes the OCI container to the GitLab container registry.
            # You can read more about this command in https://fluxcd.io/flux/cmd/flux_push_artifact/
            - flux push artifact oci://${CI_REGISTRY_IMAGE}/${IMAGE_NAME}:${IMAGE_TAG}
                --source="${CI_REPOSITORY_URL}"
                --path="${MANIFEST_PATH}"
                --revision="${CI_COMMIT_SHORT_SHA}"
                --creds="${CI_REGISTRY_USER}:${CI_REGISTRY_PASSWORD}"
                --annotations="org.opencontainers.image.url=${CI_PROJECT_URL}"
                --annotations="org.opencontainers.image.title=${IMAGE_TITLE}"
                --annotations="com.gitlab.job.id=${CI_JOB_ID}"
                --annotations="com.gitlab.job.url=${CI_JOB_URL}"
            # This line triggers an immediate reconciliation of the resource. Otherwise Flux would reconcile following its configured reconciliation period.
            # You can read more about the various reconcile commands in https://fluxcd.io/flux/cmd/flux_reconcile/
            - flux reconcile source oci -n ${NAMESPACE} ${FLUX_OCI_REPO_NAME}
   ```

1. 프로젝트에 변경 사항을 커밋하고 푸시한 후 빌드 파이프라인이 완료될 때까지 기다립니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을 선택하고 사용 가능한 [Kubernetes 대시보드](../../../ci/environments/kubernetes_dashboard.md)를 확인합니다. `applications/nginx` 환경이 정상이어야 합니다.

## GitLab 파이프라인 액세스 보안 {#secure-the-gitlab-pipeline-access}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이전에 배포된 에이전트는 `.gitlab/agents/testing/config.yaml` 파일을 사용하여 구성됩니다. 기본적으로 구성은 GitLab 파이프라인이 실행되는 프로젝트에 구성된 클러스터에 대한 액세스를 활성화합니다. 기본적으로 이 액세스는 배포된 에이전트의 서비스 계정을 사용하여 클러스터에 대해 명령을 실행합니다. 이 액세스는 정적 서비스 계정 ID로 제한하거나 클러스터에서 CI/CD 작업을 ID로 사용하여 제한할 수 있습니다. 마지막으로 일반 Kubernetes RBAC를 사용하여 클러스터에서 CI/CD 작업의 액세스를 제한할 수 있습니다.

이 섹션에서는 모든 CI/CD 작업에 ID를 추가하고 클러스터에서 작업을 가장함으로써 CI/CD 액세스를 제한하는 방법을 보여줍니다.

1. CI/CD 작업 가장을 구성하려면 `.gitlab/agents/testing/config.yaml` 파일을 편집하고 다음 스니펫을 추가합니다(`path/to/project`를 바꿈):

   ```yaml
   ci_access:
      projects:
         - id: my-group/optional-subgroup/my-repository
           access_as:
              ci_job: {}
   ```

1. CI/CD 작업에 아직 클러스터 바인딩이 없으므로 GitLab CI/CD에서 Kubernetes 명령을 실행할 수 없습니다. CI/CD 작업이 `flux-system` 네임스페이스에서 `Secret` 객체를 생성할 수 있도록 합시다. `clusters/testing/gitlab-ci-job-secret-write.yaml` 파일을 다음 내용으로 생성합니다:

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
      name: secret-manager
      namespace: default
   rules:
      - apiGroups: [""]
        resources: ["secrets"]
        verbs: ["create", "delete"]
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
      name: gitlab-ci-secrets-binding
      namespace: default
   subjects:
      - kind: Group
        name: gitlab:ci_job
        apiGroup: rbac.authorization.k8s.io
   roleRef:
      kind: Role
      name: secret-manager
      apiGroup: rbac.authorization.k8s.io
   ```

1. CI/CD 작업이 FluxCD 조정도 트리거할 수 있도록 합시다. `clusters/testing/gitlab-ci-job-flux-reconciler.yaml` 파일을 다음 내용으로 생성합니다:

   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
       name: ci-job-admin
   roleRef:
       name: flux-edit-flux-system
       kind: ClusterRole
       apiGroup: rbac.authorization.k8s.io
   subjects:
       - name: gitlab:ci_job
         kind: Group
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
       name: ci-job-view
   roleRef:
       name: flux-view-flux-system
       kind: ClusterRole
       apiGroup: rbac.authorization.k8s.io
   subjects:
       - name: gitlab:ci_job
         kind: Group
   ```

CI/CD 액세스에 대한 자세한 내용은 [Kubernetes 클러스터와 함께 GitLab CI/CD 사용](ci_cd_workflow.md)을 참조하세요.

## 리소스 정리 {#clean-up-resources}

마지막으로 배포된 리소스를 제거하고 컨테이너 레지스트리에 액세스하는 데 사용한 비밀을 삭제합니다:

1. `clusters/testing/nginx.yaml` 파일을 삭제합니다. Flux는 클러스터에서 관련 리소스를 제거하는 작업을 처리합니다.
1. `container-registry-secret` 환경을 중지합니다. 환경을 중지하면 `on_stop` 작업이 트리거되어 클러스터에서 비밀이 제거됩니다.

## 다음 단계 {#next-steps}

이 자습서의 기법을 사용하여 프로젝트 전체에 배포를 확장할 수 있습니다. OCI 이미지를 다른 프로젝트에서 빌드할 수 있으며, Flux가 올바른 레지스트리를 가리키는 한 Flux는 이를 검색합니다. 이 연습은 사용자를 위해 남겨집니다.

더 많은 연습을 위해 `/clusters/testing/flux-system/gotk-sync.yaml`에서 원래 Flux `GitRepository`을 `OCIRepository`로 변경해 보세요.

마지막으로 Flux 및 Kubernetes와의 GitLab 통합에 대한 자세한 정보는 다음 리소스를 참조하세요:

- Kubernetes 통합을 위한 [엔터프라이즈 고려 사항](enterprise_considerations.md)
- 에이전트를 사용하여 [운영 컨테이너 스캔](vulnerabilities.md)합니다
- 에이전트를 사용하여 엔지니어를 위한 [원격 워크스페이스](../../workspace/_index.md)를 제공합니다

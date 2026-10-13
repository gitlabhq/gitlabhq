---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 레거시 GitOps에서 Flux로 마이그레이션
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

대부분의 사용자는 추가 작업이나 다운타임 없이 레거시 에이전트 기반 GitOps 솔루션에서 Flux로 마이그레이션할 수 있습니다. 대부분의 경우, Flux는 재시작 없이 기존 워크로드를 인수받을 수 있습니다.

## GitOps 구성 예제 {#example-gitops-configuration}

레거시 GitOps 설정에 다음과 같은 에이전트 구성이 포함될 수 있습니다:

```yaml
gitops:
  manifest_projects:
  - id: <your-group>/<your-repository>
    paths:
    - glob: 'manifests/*.yaml'
```

`manifests` 디렉터리는 `paths.glob`에서 참조되며 두 개의 매니페스트를 포함할 수 있습니다. 한 매니페스트는 `Namespace`를 정의합니다:

```yaml
# /manifests/namespace.yaml

---
apiVersion: v1
kind: Namespace
metadata:
  name: production
```

다른 매니페스트는 `Deployment`를 정의합니다:

```yaml
# /manifests/deployment.yaml

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: production
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

이 페이지의 항목은 이 구성을 사용하여 Flux로의 마이그레이션을 보여줍니다.

## 에이전트에서 레거시 GitOps 기능 비활성화 {#disable-legacy-gitops-functionality-in-the-agent}

GitOps 구성이 제거되면 에이전트는 적용한 실행 중인 워크로드를 삭제하지 않습니다. 에이전트에서 GitOps 기능을 제거하려면:

- 에이전트 구성 파일에서 `gitops` 섹션을 삭제합니다.

여전히 기능 있는 에이전트가 필요하므로 전체 `config.yaml` 파일을 삭제하지 마세요.

`gitops.manifest_projects` 아래에 또는 `paths` 목록 아래에 여러 항목이 있는 경우, 특정 프로젝트 또는 경로만 제거하여 한 번에 한 부분씩 마이그레이션할 수 있습니다.

## Flux 부트스트랩 {#bootstrap-flux}

시작하기 전에:

- 에이전트에서 GitOps 기능을 비활성화했습니다.
- 클러스터에 액세스할 수 있는 터미널에 Flux CLI를 설치했습니다.

Flux를 부트스트랩하려면:

- 터미널에서 `flux bootstrap gitlab` 명령을 실행합니다. 예를 들어:

  ```shell
  flux bootstrap gitlab \
  --owner=<your-group> \
  --repository=<your-repository> \
  --branch=main \
  --path=manifests/ \
  --deploy-token-auth
  ```

Flux가 클러스터에 설치되고 필요한 Flux 구성 파일이 `manifests/flux-system`에 커밋되며, 이는 Flux와 전체 `manifests` 디렉터리를 동기화합니다.

워크로드(`Namespace` 및 `Deployment` 매니페스트)가 이미 `manifests` 디렉터리에 선언되어 있으므로 추가 작업이 필요하지 않습니다.

Flux를 GitLab으로 구성하는 방법에 대한 자세한 내용은 [자습서: GitOps에 대한 Flux 설정](../getting_started.md)을 참조하세요.

## 문제 해결 {#troubleshooting}

### `flux bootstrap`이 매니페스트를 올바르게 조정하지 않습니다 {#flux-bootstrap-doesnt-reconcile-manifests-correctly}

`flux bootstrap` 명령은 `manifests` 디렉터리를 가리키는 `kustomizations.kustomize.toolkit.fluxcd.io` 리소스를 생성합니다. 이 리소스는 [Kustomization 파일](https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#kustomization) 없이 디렉터리의 모든 Kubernetes 매니페스트에 적용됩니다.

이 프로세스는 구성에서 작동하지 않을 수 있습니다. 문제를 해결하려면 Flux Kustomization 상태를 검토하여 잠재적 문제를 확인하세요:

```shell
kubectl get kustomizations.kustomize.toolkit.fluxcd.io -n flux-system
```

### 에이전트 구성에서 `default_namespace` 사용 {#use-a-default_namespace-in-the-agent-configuration}

레거시 에이전트 기반 GitOps 설정이 에이전트 구성에서 `default_namespace`를 참조하지만 매니페스트 자체에서 이 네임스페이스를 생략하는 경우 문제가 발생할 수 있습니다. 이로 인해 부트스트랩된 Flux가 기존 매니페스트가 `default_namespace`에 적용된다는 것을 모르는 오류가 발생합니다.

이 문제를 해결하려면 다음 중 하나를 수행할 수 있습니다:

- 이전에 존재하는 리소스 YAML에서 네임스페이스를 수동으로 설정합니다.
- 리소스를 전용 디렉터리로 이동하고 `kustomize.toolkit.fluxcd.io/Kustomization`을 사용하여 Flux를 가리키며, `spec.targetNamespace`이 네임스페이스를 지정합니다.
- 리소스를 하위 디렉터리로 이동하고 `kustomization.yaml` 파일을 추가하여 `spec.namespace` 속성을 설정합니다.

Flux에 대해 이미 구성된 경로 외부로 리소스를 이동하려면 `kustomize.toolkit.fluxcd.io/Kustomization`을 사용해야 합니다. Flux가 이미 감시하고 있는 경로의 하위 디렉터리로 리소스를 이동하려면 `kustomize.config.k8s.io/Kustomization`을 사용해야 합니다.

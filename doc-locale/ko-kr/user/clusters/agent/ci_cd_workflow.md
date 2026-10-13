---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes 클러스터에서 GitLab CI/CD 사용
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 에이전트 연결 공유 제한이 GitLab 17.0에서 100에서 500으로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149844)되었습니다.

{{< /history >}}

GitLab CI/CD를 사용하여 Kubernetes 클러스터를 안전하게 연결, 배포 및 업데이트할 수 있습니다.

이를 위해 [클러스터에 에이전트를 설치](install/_index.md)합니다. 완료되면 Kubernetes 컨텍스트를 갖게 되고 GitLab CI/CD 파이프라인에서 Kubernetes API 명령을 실행할 수 있습니다.

클러스터의 액세스를 안전하게 보장하려면:

- 각 에이전트는 별도의 컨텍스트(`kubecontext`)를 갖습니다.
- 에이전트가 구성된 프로젝트와 승인한 추가 프로젝트만 클러스터의 에이전트에 액세스할 수 있습니다.

GitLab CI/CD를 사용하여 클러스터와 상호 작용하려면 러너가 GitLab에 등록되어야 합니다. 그러나 이 러너들이 에이전트가 있는 클러스터에 있을 필요는 없습니다.

사전 요구 사항:

- [GitLab CI/CD가 활성화](../../../ci/pipelines/settings.md#disable-gitlab-cicd-pipelines)되었는지 확인합니다.

## 클러스터에서 GitLab CI/CD 사용 {#use-gitlab-cicd-with-your-cluster}

GitLab CI/CD로 Kubernetes 클러스터를 업데이트하려면:

1. 작동 중인 Kubernetes 클러스터가 있고 매니페스트가 GitLab 프로젝트에 있는지 확인합니다.
1. 같은 GitLab 프로젝트에서 [GitLab Kubernetes용 에이전트를 등록 및 설치](install/_index.md)합니다.
1. [`.gitlab-ci.yml` 파일을 업데이트](#update-your-gitlab-ciyml-file-to-run-kubectl-commands)하여 에이전트의 Kubernetes 컨텍스트를 선택하고 Kubernetes API 명령을 실행합니다.
1. 파이프라인을 실행하여 클러스터를 배포하거나 업데이트합니다.

Kubernetes 매니페스트가 포함된 여러 GitLab 프로젝트가 있는 경우:

1. 자신의 프로젝트에 또는 Kubernetes 매니페스트를 유지하는 GitLab 프로젝트 중 하나에 [GitLab Kubernetes용 에이전트를 설치](install/_index.md)합니다.
1. GitLab 프로젝트에서 [에이전트 액세스를 승인](#authorize-agent-access)합니다.
1. 선택 사항입니다. 추가 보안을 위해 [위장을 사용](#restrict-project-and-group-access-by-using-impersonation)합니다.
1. [`.gitlab-ci.yml` 파일을 업데이트](#update-your-gitlab-ciyml-file-to-run-kubectl-commands)하여 에이전트의 Kubernetes 컨텍스트를 선택하고 Kubernetes API 명령을 실행합니다.
1. 파이프라인을 실행하여 클러스터를 배포하거나 업데이트합니다.

## 에이전트 액세스 승인 {#authorize-agent-access}

Kubernetes 매니페스트가 포함된 여러 프로젝트가 있는 경우, 이 프로젝트들에 에이전트에 액세스하도록 승인해야 합니다. 개별 프로젝트, 그룹 또는 하위 그룹에 대해 에이전트 액세스를 승인할 수 있으므로 모든 프로젝트가 액세스 권한을 가질 수 있습니다. 추가 보안을 위해 [위장을 사용](#restrict-project-and-group-access-by-using-impersonation)할 수도 있습니다.

인증 구성을 전파하는 데 1~2분이 걸릴 수 있습니다.

### 프로젝트가 에이전트에 액세스하도록 승인 {#authorize-your-projects-to-access-the-agent}

{{< history >}}

- GitLab 18.1에서 다른 최상위 그룹에 속한 그룹의 인증을 허용하도록 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/377932)되었습니다.

{{< /history >}}

Kubernetes 매니페스트를 유지하는 GitLab 프로젝트가 에이전트에 액세스하도록 승인하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 [에이전트 구성 파일](install/_index.md#create-an-agent-configuration-file)(`config.yaml`)이 포함된 프로젝트를 찾습니다.
1. `config.yaml` 파일을 편집합니다. `ci_access` 키워드 아래에 `projects` 속성을 추가합니다.
1. `id`의 경우 프로젝트 경로를 추가합니다.

   ```yaml
   ci_access:
     projects:
       - id: path/to/project
   ```

   - 승인된 프로젝트는 에이전트의 구성 프로젝트와 동일한 최상위 그룹 또는 사용자 네임스페이스를 가져야 합니다. [인스턴스 수준의 인증](#authorize-all-projects-in-your-gitlab-instance-to-access-the-agent) 애플리케이션 설정이 활성화되지 않은 경우입니다.
   - 추가 계층을 수용하기 위해 동일한 클러스터에 추가 에이전트를 설치할 수 있습니다.
   - 최대 500개의 프로젝트를 승인할 수 있습니다.

이 변경을 수행한 후:

- 모든 CI/CD 작업에는 이제 공유 에이전트 연결마다 컨텍스트가 있는 `kubeconfig` 파일이 포함됩니다.
- `kubeconfig` 경로는 `$KUBECONFIG` 환경 변수에서 사용 가능합니다.
- CI/CD 스크립트에서 `kubectl` 명령을 실행할 컨텍스트를 선택할 수 있습니다.

### 그룹의 프로젝트가 에이전트에 액세스하도록 승인 {#authorize-projects-in-your-groups-to-access-the-agent}

{{< history >}}

- GitLab 18.1에서 다른 최상위 그룹에 속한 그룹의 인증을 허용하도록 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/377932)되었습니다.

{{< /history >}}

그룹 또는 하위 그룹의 모든 GitLab 프로젝트가 에이전트에 액세스하도록 승인하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 [에이전트 구성 파일](install/_index.md#create-an-agent-configuration-file)(`config.yaml`)이 포함된 프로젝트를 찾습니다.
1. `config.yaml` 파일을 편집합니다. `ci_access` 키워드 아래에 `groups` 속성을 추가합니다.
1. `id`의 경우 경로를 추가합니다:

   ```yaml
   ci_access:
     groups:
       - id: path/to/group/subgroup
   ```

   - 승인된 그룹은 에이전트의 구성 프로젝트와 동일한 최상위 그룹을 가져야 합니다. [인스턴스 수준의 인증](#authorize-all-projects-in-your-gitlab-instance-to-access-the-agent) 애플리케이션 설정이 활성화되지 않은 경우입니다.
   - 추가 계층을 수용하기 위해 동일한 클러스터에 추가 에이전트를 설치할 수 있습니다.
   - 승인된 그룹의 모든 하위 그룹도 같은 에이전트에 액세스할 수 있습니다(개별적으로 지정할 필요 없음).
   - 최대 500개의 그룹을 승인할 수 있습니다.

이 변경을 수행한 후:

- 그룹 및 하위 그룹에 속한 모든 프로젝트가 이제 에이전트에 액세스하도록 승인됩니다.
- 모든 CI/CD 작업에는 이제 공유 에이전트 연결마다 컨텍스트가 있는 `kubeconfig` 파일이 포함됩니다.
- `kubeconfig` 경로는 `$KUBECONFIG` 환경 변수에서 사용 가능합니다.
- CI/CD 스크립트에서 `kubectl` 명령을 실행할 컨텍스트를 선택할 수 있습니다.

### GitLab 인스턴스의 모든 프로젝트가 에이전트에 액세스하도록 승인 {#authorize-all-projects-in-your-gitlab-instance-to-access-the-agent}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/357516)되었습니다.

{{< /history >}}

사전 요구 사항:

- 관리자 권한이 있어야 합니다.

GitLab 인스턴스의 모든 프로젝트를 승인하도록 에이전트를 구성할 수 있도록 하려면:

{{< tabs >}}

{{< tab title="UI 사용" >}}

1. **운영자** 영역에서 **설정** > **일반**을 선택하고 **Kubernetes용 GitLab 에이전트** 섹션을 확장합니다.
1. **인스턴스 수준의 인증을 활성화**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< tab title="API 사용" >}}

1. [애플리케이션 설정 업데이트](../../../api/settings.md#update-application-settings) `organization_cluster_agent_authorization_enabled`를 `true`로 변경합니다.

{{< /tab >}}

{{< /tabs >}}

에이전트가 모든 GitLab 프로젝트에 액세스하도록 승인하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 [에이전트 구성 파일](install/_index.md#create-an-agent-configuration-file)(`config.yaml`)이 포함된 프로젝트를 찾습니다.
1. `config.yaml` 파일을 편집합니다. `ci_access` 키워드 아래에 `instance` 속성을 추가합니다:

   ```yaml
   ci_access:
     instance: {}
   ```

에이전트 구성 파일에 이 변경을 수행한 후:

- 인스턴스의 모든 프로젝트에 있는 모든 CI/CD 작업이 에이전트에 액세스할 수 있도록 승인됩니다. CI/CD 작업 위장을 RBAC와 함께 사용하여 필요에 따라 액세스를 부여하거나 제한할 수 있습니다. 자세한 정보는 [위장을 사용하여 프로젝트 및 그룹 액세스 제한](#restrict-project-and-group-access-by-using-impersonation)을 참조합니다.
- 모든 CI/CD 작업에는 공유 에이전트 연결마다 컨텍스트가 있는 `kubeconfig` 파일이 포함됩니다.
- `kubeconfig` 경로는 `$KUBECONFIG` 환경 변수에서 사용 가능합니다.
- CI/CD 스크립트에서 `kubectl` 명령을 실행할 컨텍스트를 선택할 수 있습니다.

## `.gitlab-ci.yml` 파일을 업데이트하여 `kubectl` 명령 실행 {#update-your-gitlab-ciyml-file-to-run-kubectl-commands}

Kubernetes 명령을 실행할 프로젝트에서 프로젝트의 `.gitlab-ci.yml` 파일을 편집합니다.

`script` 키워드 아래의 첫 번째 명령에서 에이전트의 컨텍스트를 설정합니다. `<path/to/agent/project>:<agent-name>` 형식을 사용합니다. 예를 들어:

```yaml
deploy:
  image: debian:13-slim
  variables:
    KUBECTL_VERSION: v1.34
    DEBIAN_FRONTEND: noninteractive
  script:
    # Follows https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
    - apt-get update
    - apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl gnupg
    - curl --fail --silent --show-error --location "https://pkgs.k8s.io/core:/stable:/${KUBECTL_VERSION}/deb/Release.key" | gpg --dearmor --output /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    - chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    - echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBECTL_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
    - chmod 644 /etc/apt/sources.list.d/kubernetes.list
    - apt-get update
    - apt-get install -y --no-install-recommends kubectl
    - kubectl config get-contexts
    - kubectl config use-context path/to/agent/project:agent-name
    - kubectl get pods
```

에이전트의 컨텍스트를 확실하지 않으면, 에이전트에 액세스하려는 CI/CD 작업에서 `kubectl config get-contexts`을 실행합니다.

### Auto DevOps를 사용하는 환경 {#environments-that-use-auto-devops}

Auto DevOps가 활성화되면 CI/CD 변수 `KUBE_CONTEXT`을 정의해야 합니다. `KUBE_CONTEXT`의 값을 Auto DevOps에서 사용하려는 에이전트의 컨텍스트로 설정합니다:

```yaml
deploy:
  variables:
    KUBE_CONTEXT: path/to/agent/project:agent-name
```

서로 다른 Auto DevOps 작업에 다른 에이전트를 할당할 수 있습니다. 예를 들어 Auto DevOps는 `staging` 작업에 하나의 에이전트를 사용하고 `production` 작업에 다른 에이전트를 사용할 수 있습니다. 여러 에이전트를 사용하려면 각 에이전트에 대해 [환경 범위 CI/CD 변수](../../../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable)를 정의합니다. 예를 들어:

1. `KUBE_CONTEXT`이라는 두 개의 변수를 정의합니다.
1. 첫 번째 변수의 경우:
   1. `environment`를 `staging`로 설정합니다.
   1. 스테이징 에이전트의 컨텍스트로 값을 설정합니다.
1. 두 번째 변수의 경우:
   1. `environment`를 `production`로 설정합니다.
   1. 프로덕션 에이전트의 컨텍스트로 값을 설정합니다.

### 인증서 기반 및 에이전트 기반 연결이 모두 있는 환경 {#environments-with-both-certificate-based-and-agent-based-connections}

[인증서 기반 클러스터](../../infrastructure/clusters/_index.md)(더 이상 사용되지 않음)와 에이전트 연결이 모두 있는 환경에 배포할 때:

- 인증서 기반 클러스터의 컨텍스트를 `gitlab-deploy`이라고 합니다. 이 컨텍스트는 기본적으로 항상 선택됩니다.
- 에이전트 컨텍스트가 `$KUBECONFIG`에 포함됩니다. `kubectl config use-context <path/to/agent/project>:<agent-name>`을 사용하여 선택할 수 있습니다.

인증서 기반 연결이 있을 때 에이전트 연결을 사용하려면 새로운 `kubectl` 구성 컨텍스트를 수동으로 구성할 수 있습니다. 예를 들어:

```yaml
deploy:
  variables:
    KUBE_CONTEXT: my-context # The name to use for the new context
    AGENT_ID: 1234 # replace with your agent's numeric ID
    K8S_PROXY_URL: https://<KAS_DOMAIN>/k8s-proxy/ # For agent server (KAS) deployed in Kubernetes cluster (for gitlab.com use kas.gitlab.com); replace with your URL
    # K8S_PROXY_URL: https://<GITLAB_DOMAIN>/-/kubernetes-agent/k8s-proxy/ # For agent server (KAS) in Omnibus
    # Include any additional variables
  before_script:
    - kubectl config set-credentials agent:$AGENT_ID --token="ci:${AGENT_ID}:${CI_JOB_TOKEN}"
    - kubectl config set-cluster gitlab --server="${K8S_PROXY_URL}"
    - kubectl config set-context "$KUBE_CONTEXT" --cluster=gitlab --user="agent:${AGENT_ID}"
    - kubectl config use-context "$KUBE_CONTEXT"
  # Include the remaining job configuration
```

### 자체 서명된 인증서를 사용하는 KAS가 있는 환경 {#environments-with-kas-that-use-self-signed-certificates}

KAS와 자체 서명된 인증서가 있는 환경을 사용하는 경우 Kubernetes 클라이언트가 인증서를 서명한 인증 기관(CA)을 신뢰하도록 구성해야 합니다.

클라이언트를 구성하려면 다음 중 하나를 수행합니다:

- CI/CD 변수 `SSL_CERT_FILE`을 KAS 인증서(PEM 형식)로 설정합니다.
- Kubernetes 클라이언트를 `--certificate-authority=$KAS_CERTIFICATE`로 구성합니다. 여기서 `KAS_CERTIFICATE`는 KAS의 CA 인증서가 포함된 CI/CD 변수입니다.
- 컨테이너 이미지를 업데이트하거나 러너를 통해 마운트하여 인증서를 작업 컨테이너의 적절한 위치에 배치합니다.
- 권장되지 않습니다. Kubernetes 클라이언트를 `--insecure-skip-tls-verify=true`로 구성합니다.

## 위장을 사용하여 프로젝트 및 그룹 액세스 제한 {#restrict-project-and-group-access-by-using-impersonation}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

기본적으로 CI/CD 작업은 클러스터에 에이전트를 설치하는 데 사용되는 서비스 계정의 모든 권한을 상속합니다. 클러스터에 대한 액세스를 제한하려면 [위장](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#user-impersonation)을 사용할 수 있습니다.

위장을 지정하려면 에이전트 구성 파일에 `access_as` 속성을 사용하고 Kubernetes RBAC 규칙을 사용하여 위장된 계정 권한을 관리합니다.

위장할 수 있는 것:

- 에이전트 자체(기본값).
- 클러스터에 액세스하는 CI/CD 작업.
- 클러스터 내에 정의된 특정 사용자 또는 시스템 계정.

인증 구성을 전파하는 데 1~2분이 걸릴 수 있습니다.

### 에이전트 위장 {#impersonate-the-agent}

에이전트는 기본적으로 위장됩니다. 이를 위장하기 위해 아무 작업도 할 필요가 없습니다.

### 클러스터에 액세스하는 CI/CD 작업 위장 {#impersonate-the-cicd-job-that-accesses-the-cluster}

클러스터에 액세스하는 CI/CD 작업을 위장하려면 `access_as` 키 아래에 `ci_job: {}` 키-값을 추가합니다.

에이전트가 실제 Kubernetes API에 요청할 때 다음과 같은 방식으로 위장 자격 증명을 설정합니다:

- `UserName`이 `gitlab:ci_job:<job id>`로 설정됩니다. 예: `gitlab:ci_job:1074499489`.
- `Groups`이 다음으로 설정됩니다:

  - CI 작업에서 오는 모든 요청을 식별하는 `gitlab:ci_job`.
  - 프로젝트가 속한 그룹의 ID 목록.
  - 프로젝트 ID.
  - 이 작업이 속한 환경의 슬러그 및 티어.

    예: `group1/group1-1/project1`의 CI 작업의 경우:

    - 그룹 `group1`의 ID는 23입니다.
    - 그룹 `group1/group1-1`의 ID는 25입니다.
    - 프로젝트 `group1/group1-1/project1`의 ID는 150입니다.
    - `prod` 환경에서 실행되는 작업으로, `production` 환경 티어를 갖습니다.

  그룹 목록은 `[gitlab:ci_job, gitlab:group:23, gitlab:group_env_tier:23:production, gitlab:group:25, gitlab:group_env_tier:25:production, gitlab:project:150, gitlab:project_env:150:prod, gitlab:project_env_tier:150:production]`입니다.

- `Extra`은 요청에 대한 추가 정보를 포함합니다. 위장된 ID에 다음 속성이 설정됩니다:

| 속성                             | 설명                                                                  |
| ------------------------------------ | ---------------------------------------------------------------------------- |
| `agent.gitlab.com/id`                | 에이전트 ID를 포함합니다.                                                       |
| `agent.gitlab.com/config_project_id` | 에이전트의 구성 프로젝트 ID를 포함합니다.                               |
| `agent.gitlab.com/project_id`        | CI 프로젝트 ID를 포함합니다.                                                  |
| `agent.gitlab.com/ci_pipeline_id`    | CI 파이프라인 ID를 포함합니다.                                                 |
| `agent.gitlab.com/ci_job_id`         | CI 작업 ID를 포함합니다.                                                      |
| `agent.gitlab.com/username`          | CI 작업이 실행 중인 사용자의 사용자 이름을 포함합니다.                  |
| `agent.gitlab.com/environment_slug`  | 환경의 슬러그를 포함합니다. 환경에서 실행되는 경우에만 설정됩니다. |
| `agent.gitlab.com/environment_tier`  | 환경의 티어를 포함합니다. 환경에서 실행되는 경우에만 설정됩니다. |

CI/CD 작업의 ID로 액세스를 제한하는 예 `config.yaml`:

```yaml
ci_access:
  projects:
    - id: path/to/project
      access_as:
        ci_job: {}
```

#### CI/CD 작업을 제한하는 RBAC 예 {#example-rbac-to-restrict-cicd-jobs}

다음 `RoleBinding` 리소스는 모든 CI/CD 작업을 보기 권한만으로 제한합니다.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ci-job-view
roleRef:
  name: view
  kind: ClusterRole
  apiGroup: rbac.authorization.k8s.io
subjects:
  - name: gitlab:ci_job
    kind: Group
```

### 정적 ID 위장 {#impersonate-a-static-identity}

주어진 연결의 경우 위장에 정적 ID를 사용할 수 있습니다.

`access_as` 키 아래에 `impersonate` 키를 추가하여 제공된 ID를 사용하여 요청을 수행합니다.

ID는 다음 키로 지정할 수 있습니다:

- `username`(필수)
- `uid`
- `groups`
- `extra`

[공식 Kubernetes 설명서 참조](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#user-impersonation)를 참조합니다.

## 특정 환경으로 프로젝트 및 그룹 액세스 제한 {#restrict-project-and-group-access-to-specific-environments}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

기본적으로 에이전트가 [프로젝트에 사용 가능](#authorize-agent-access)하면 프로젝트의 모든 CI/CD 작업이 해당 에이전트를 사용할 수 있습니다.

특정 환경이 있는 작업에만 에이전트에 대한 액세스를 제한하려면 `environments`을 `ci_access.projects` 또는 `ci_access.groups`에 추가합니다. 예를 들어:

  ```yaml
  ci_access:
    projects:
      - id: path/to/project-1
      - id: path/to/project-2
        environments:
          - staging
          - review/*
    groups:
      - id: path/to/group-1
        environments:
          - production
  ```

이 예에서:

- `project-1` 아래의 모든 CI/CD 작업이 에이전트에 액세스할 수 있습니다.
- `project-2` 아래의 CI/CD 작업이 `staging` 또는 `review/*` 환경을 사용하면 에이전트에 액세스할 수 있습니다.
  - `*`은 와일드카드이므로 `review/*`는 `review` 아래의 모든 환경과 일치합니다.
- `group-1` 아래의 프로젝트에 대한 CI/CD 작업이 `production` 환경을 사용하면 에이전트에 액세스할 수 있습니다.

## 보호된 브랜치에 대한 에이전트 액세스 제한 {#restrict-access-to-the-agent-to-protected-branches}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `kubernetes_agent_protected_branches`라는 이름의 [기능 플래그](../../../administration/feature_flags/_index.md)로 GitLab 17.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467936)되었습니다. 기본적으로 사용 중지됩니다.
- GitLab 17.10에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/467936)되었습니다. `kubernetes_agent_protected_branches` 기능 플래그가 제거되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능성은 기능 플래그로 제어합니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트 가능하지만 프로덕션 사용은 준비되지 않았습니다.

[보호된 브랜치](../../project/repository/branches/protected.md)에서만 실행되는 작업에 대해 에이전트에 대한 액세스를 제한하려면:

- `protected_branches_only: true`을 `ci_access.projects` 또는 `ci_access.groups`에 추가합니다. 예를 들어:

  ```yaml
  ci_access:
    projects:
      - id: path/to/project-1
        protected_branches_only: true
    groups:
      - id: path/to/group-1
        protected_branches_only: true
        environments:
          - production
  ```

기본적으로 `protected_branches_only`은 `false`로 설정되며 에이전트는 보호되지 않은 브랜치와 보호된 브랜치에서 액세스할 수 있습니다.

추가 보안을 위해 이 기능을 [환경 제한](#restrict-project-and-group-access-to-specific-environments)과 결합할 수 있습니다.

프로젝트에 여러 구성이 있는 경우 가장 구체적인 구성만 사용됩니다. 예를 들어 다음 구성은 `example` 그룹이 보호된 브랜치에만 액세스하도록 구성되어 있더라도 `example/my-project`의 보호되지 않은 브랜치에 액세스합니다:

```yaml
# .gitlab/agents/my-agent/config.yaml
ci_access:
  project:
    - id: example/my-project # Project of the group below
      protected_branches_only: false # This configuration supersedes the group configuration
      environments:
        - dev
  groups:
    - id: example
      protected_branches_only: true
      environments:
        - dev
```

자세한 정보는 [CI/CD에서 Kubernetes로의 액세스](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_ci_access.md#apiv4joballowed_agents-api)를 참조합니다.

## 관련 항목 {#related-topics}

- [자기 속도의 교실 워크숍](https://gitlab-for-eks.awsworkshop.io)(AWS EKS를 사용하지만 다른 Kubernetes 클러스터에 사용할 수 있음)
- [Auto DevOps 구성](../../../topics/autodevops/cloud_deployments/auto_devops_with_gke.md#configure-auto-devops)

## 문제 해결 {#troubleshooting}

### `~/.kube/cache`에 대한 쓰기 권한 부여 {#grant-write-permissions-to-kubecache}

`kubectl`, Helm, `kpt`, `kustomize`과 같은 도구는 클러스터에 대한 정보를 `~/.kube/cache`에 캐시합니다. 이 디렉토리를 쓸 수 없으면 도구가 각 호출에서 정보를 가져와서 상호 작용을 더 느리게 하고 클러스터에 불필요한 로드를 만듭니다. 최상의 환경을 위해 `.gitlab-ci.yml` 파일에서 사용하는 이미지에서 이 디렉토리를 쓸 수 있는지 확인합니다.

### TLS 활성화 {#enable-tls}

GitLab Self-Managed를 사용하는 경우 인스턴스가 TLS(전송 계층 보안)로 구성되었는지 확인합니다.

TLS 없이 `kubectl`을 사용하려고 하면 다음과 같은 오류가 발생할 수 있습니다:

```shell
$ kubectl get pods
error: You must be logged in to the server (the server has asked for the client to provide credentials)
```

### 서버에 연결할 수 없음: 알 수 없는 인증 기관에서 서명한 인증서 {#unable-to-connect-to-the-server-certificate-signed-by-unknown-authority}

KAS 및 자체 서명된 인증서가 있는 환경을 사용하는 경우 `kubectl` 호출이 이 오류를 반환할 수 있습니다:

```plaintext
kubectl get pods
Unable to connect to the server: x509: certificate signed by unknown authority
```

작업이 KAS 인증서를 서명한 인증 기관(CA)을 신뢰하지 않기 때문에 오류가 발생합니다.

문제를 해결하려면 [`kubectl`이 CA를 신뢰하도록 구성](#environments-with-kas-that-use-self-signed-certificates)합니다.

### 유효성 검사 오류 {#validation-errors}

`kubectl` 버전 v1.27.0 또는 v1.27.1을 사용하는 경우 다음 오류가 발생할 수 있습니다:

```plaintext
error: error validating "file.yml": error validating data: the server responded with the status code 426 but did not return more information; if you choose to ignore these errors, turn validation off with --validate=false
```

이 문제는 [버그](https://github.com/kubernetes/kubernetes/issues/117463)로 인해 발생합니다. `kubectl`와 공유 Kubernetes 라이브러리를 사용하는 기타 도구.

문제를 해결하려면 `kubectl`의 다른 버전을 사용합니다.

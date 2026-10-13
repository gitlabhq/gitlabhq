---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 관리형 Kubernetes 리소스
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.9에서 `gitlab_managed_cluster_resources` [기능 플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/groups/gitlab-org/-/epics/16130)되었습니다. 기본적으로 사용 중지됩니다.
- 기능 플래그 `gitlab_managed_cluster_resources` [제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/520042) (GitLab 18.1).

{{< /history >}}

환경 템플릿을 사용하여 GitLab 관리형 Kubernetes 리소스로 Kubernetes 리소스를 프로비저닝합니다. 환경 템플릿을 사용하여 다음 작업을 수행할 수 있습니다:

- 새로운 환경에 대해 네임스페이스 및 서비스 계정을 자동으로 생성합니다
- 역할 바인딩을 통해 액세스 권한을 관리합니다
- 필요한 다른 Kubernetes 리소스를 구성합니다

개발자가 애플리케이션을 배포할 때 GitLab은 환경 템플릿을 기반으로 리소스를 생성합니다.

## GitLab 관리형 Kubernetes 리소스 구성 {#configure-gitlab-managed-kubernetes-resources}

사전 요구 사항:

- 구성된 [Kubernetes용 GitLab 에이전트](install/_index.md)가 필요합니다.
- [에이전트를 인증](ci_cd_workflow.md#authorize-agent-access)하여 관련 프로젝트 또는 그룹에 액세스할 수 있도록 합니다.
- (선택 사항) 권한 에스컬레이션을 방지하기 위해 [에이전트 가장](ci_cd_workflow.md#restrict-project-and-group-access-by-using-impersonation)을 구성합니다. 기본 환경 템플릿은 [`ci_job` 가장](ci_cd_workflow.md#impersonate-the-cicd-job-that-accesses-the-cluster)이 구성되어 있다고 가정합니다.

### Kubernetes 리소스 관리 활성화 {#turn-on-kubernetes-resource-management}

#### 에이전트 구성 파일에서 {#in-your-agent-configuration-file}

리소스 관리를 활성화하려면 에이전트 구성 파일을 수정하여 필요한 권한을 포함합니다:

```yaml
ci_access:
  projects:
    - id: <your_group/your_project>
      access_as:
        ci_job: {}
      resource_management:
        enabled: true
  groups:
    - id: <your_other_group>
      access_as:
        ci_job: {}
      resource_management:
        enabled: true
```

#### CI/CD 작업에서 {#in-your-cicd-jobs}

에이전트가 환경의 리소스를 관리하도록 하려면 배포 작업에서 에이전트를 지정합니다. 예를 들어:

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    kubernetes:
      agent: path/to/agent/project:agent-name
```

에이전트 경로에서 CI/CD 변수를 사용할 수 있습니다. 자세한 내용은 [변수를 사용할 수 있는 위치](../../../ci/variables/where_variables_can_be_used.md)를 참조하세요.

### 환경 템플릿 생성 {#create-environment-templates}

환경 템플릿은 생성, 업데이트 또는 제거할 Kubernetes 리소스를 정의합니다.

[기본 환경 템플릿](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/managed_resources/server/default_template.yaml)은 `Namespace`을 생성하고 CI/CD 작업용 `RoleBinding`을 구성합니다.

기본 템플릿을 덮어쓰려면 에이전트 디렉터리에 `default.yaml`이라고 하는 템플릿 구성 파일을 추가합니다:

```plaintext
.gitlab/agents/<agent-name>/environment_templates/default.yaml
```

#### 지원되는 Kubernetes 리소스 {#supported-kubernetes-resources}

다음 Kubernetes 리소스 (`kind`)가 지원됩니다:

- `Namespace`
- `ServiceAccount`
- `RoleBinding`
- FluxCD Source Controller 객체:
  - `GitRepository`
  - `HelmRepository`
  - `HelmChart`
  - `Bucket`
  - `OCIRepository`
- FluxCD Kustomize Controller 객체:
  - `Kustomization`
- FluxCD Helm Controller 객체:
  - `HelmRelease`
- FluxCD Notification Controller 객체:
  - `Alert`
  - `Provider`
  - `Receiver`

#### 환경 템플릿 예시 {#example-environment-template}

다음 예시는 네임스페이스를 생성하고 그룹 관리자에게 클러스터에 대한 액세스 권한을 부여합니다.

```yaml
objects:
  - apiVersion: v1
    kind: Namespace
    metadata:
      name: '{{ .environment.slug }}-{{ .project.id }}-{{ .agent.id }}'
  - apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: bind-{{ .environment.slug }}-{{ .project.id }}-{{ .agent.id }}
      namespace: '{{ .environment.slug }}-{{ .project.id }}-{{ .agent.id }}'
    subjects:
      - kind: Group
        apiGroup: rbac.authorization.k8s.io
        name: gitlab:project_env:{{ .project.id }}:{{ .environment.slug }}
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: admin

# Resource lifecycle configuration
apply_resources: on_start    # Resources are applied when environment is started/restarted
delete_resources: on_stop    # Resources are removed when environment is stopped
```

### 템플릿 변수 {#template-variables}

환경 템플릿은 제한된 변수 치환을 지원합니다. 다음 변수를 사용할 수 있습니다:

| 범주       | 변수                      | 설명               | 형식    | 설정되지 않은 경우 기본값 |
|----------------|-------------------------------|---------------------------|---------|----------------------------|
| 에이전트          | `{{ .agent.id }}`             | 에이전트 ID입니다.             | 정수 | N/A                       |
| 에이전트          | `{{ .agent.name }}`           | 에이전트 이름입니다.           | 문자열  | N/A                       |
| 에이전트          | `{{ .agent.url }}`            | 에이전트 URL입니다.            | 문자열  | N/A                       |
| 환경    | `{{ .environment.id }}`       | 환경 ID입니다.       | 정수 | N/A                       |
| 환경    | `{{ .environment.name }}`     | 환경 이름입니다.     | 문자열  | N/A                       |
| 환경    | `{{ .environment.slug }}`     | 환경 이름을 기반으로 한 환경 슬러그입니다. 최대 24자의 소문자 영숫자, `-` 포함, 문자로 시작하며 `-`로 끝나지 않습니다. | 문자열  | N/A                       |
| 환경    | `{{ .environment.url }}`      | 환경 URL입니다.      | 문자열  | 빈 문자열               |
| 환경    | `{{ .environment.page_url }}` | 환경 페이지 URL입니다. | 문자열  | N/A                       |
| 환경    | `{{ .environment.tier }}`     | 환경 티어입니다.     | 문자열  | N/A                       |
| 프로젝트        | `{{ .project.id }}`           | 프로젝트 ID.           | 정수 | N/A                       |
| 프로젝트        | `{{ .project.slug }}`         | 프로젝트 슬러그입니다. 프로젝트 경로의 수정되지 않은 마지막 구성 요소입니다.        | 문자열  | N/A                       |
| 프로젝트        | `{{ .project.path }}`         | 프로젝트 경로입니다.         | 문자열  | N/A                       |
| 프로젝트        | `{{ .project.url }}`          | 프로젝트 URL입니다.          | 문자열  | N/A                       |
| CI/CD 파이프라인 | `{{ .ci_pipeline.id }}`       | 파이프라인 ID입니다.          | 정수 | 영                       |
| CI/CD 작업      | `{{ .ci_job.id }}`            | CI/CD 작업 ID입니다.         | 정수 | 영                       |
| 사용자           | `{{ .user.id }}`              | 사용자 ID입니다.              | 정수 | N/A                       |
| 사용자           | `{{ .user.username }}`        | 사용자명입니다.             | 문자열  | N/A                       |
| 네임스페이스      | `{{ .legacy_namespace }}`     | 사용되지 않는 인증서 기반 클러스터 통합이 이 환경에 대해 생성했을 Kubernetes 네임스페이스입니다. 이 네임스페이스는 인증서 기반 클러스터 통합에서 GitLab 관리형 리소스로의 마이그레이션용으로만 사용됩니다. 다른 용도로는 사용하지 마세요. | 문자열 | N/A |

모든 변수는 이중 중괄호 구문을 사용하여 참조해야 합니다(예: `{{ .project.id }}`). [`text/template`](https://pkg.go.dev/text/template) 문서를 참조하여 사용된 템플릿 시스템에 대한 자세한 내용을 알아보세요.

### 템플릿 함수 {#template-functions}

환경 템플릿은 변수 값을 조작하는 제한된 함수를 지원합니다. 다음 함수를 사용할 수 있습니다:

| 이름         | 인수                | 설명                                          | 예제                                    |
|--------------|--------------------------|------------------------------------------------------|--------------------------------------------|
| `lower`      | `<string>`               | 소문자로 변환합니다.                               | `lower "HELLO"` -> `"hello"`               |
| `substr`     | `<start> <end> <string>` | 문자열에서 부분 문자열을 가져옵니다.                      | `substr 0 5 "hello world"` -> `"hello"`    |
| `replace`    | `<old> <new> <string>`   | 문자열의 부분 문자열의 모든 항목을 바꿉니다. | `replace "_" "-" "foo_bar"` -> `"foo-bar"` |
| `trimPrefix` | `<prefix> <string>`      | 문자열에서 접두사를 제거합니다.                   | `trimPrefix "-" "-hello"` -> `"hello"`     |
| `trimSuffix` | `<suffix> <string>`      | 문자열에서 접미사를 제거합니다.                   | `trimSuffix "-" "hello-"` -> `"hello"`   |
| `slugify`    | `[<len>] <string>`       | RFC1123에 따라 주어진 문자열을 슬러그화합니다. 기본적으로 `63` 문자로 트리밍합니다. | `slugify "hello WORLD"` -> `"hello-world"`   |

Kubernetes 값을 준수하도록 변수를 만들기 위해 함수의 개수는 의도적으로 네임스페이스 이름이나 레이블과 같은 최소 함수 집합으로 제한됩니다.

### 리소스 수명 주기 관리 {#resource-lifecycle-management}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/507486)되었습니다.

{{< /history >}}

다음 설정을 사용하여 Kubernetes 리소스를 제거해야 하는 시점을 구성합니다:

```yaml
# Never delete resources
delete_resources: never

# Delete resources when environment is stopped
delete_resources: on_stop
```

기본값은 `on_stop`이며, 이는 [기본 환경 템플릿](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/managed_resources/server/default_template.yaml)에서 지정됩니다.

### 관리형 리소스 레이블 및 주석 {#managed-resource-labels-and-annotations}

GitLab에서 생성한 리소스는 추적 및 문제 해결 목적으로 일련의 레이블 및 주석을 사용합니다.

다음 레이블은 GitLab에서 생성한 모든 리소스에 정의되어 있습니다. 값은 의도적으로 비어 있습니다:

- `agent.gitlab.com/id-<agent_id>: ""`
- `agent.gitlab.com/project_id-<project_id>: ""`
- `agent.gitlab.com/env-<gitlab_environment_slug>-<project_id>-<agent_id>: ""`
- `agent.gitlab.com/environment_slug-<gitlab_environment_slug>: ""`

GitLab에서 생성한 모든 리소스에 `agent.gitlab.com/env-<gitlab_environment_slug>-<project_id>-<agent_id>` 주석이 정의됩니다. 주석의 값은 다음 키가 있는 JSON 개체입니다:

| 키 | 설명                                      |
|-----|--------------------------------------------------|
| `environment_id` | GitLab 환경 ID입니다.                       |
| `environment_name` | GitLab 환경 이름입니다.                     |
| `environment_slug` | GitLab 환경 슬러그입니다.                     |
| `environment_url` | 환경에 대한 링크입니다. 선택 사항입니다.           |
| `environment_page_url` | GitLab 환경 페이지에 대한 링크입니다.         |
| `environment_tier` | GitLab 환경 배포 티어입니다.          |
| `agent_id` | 에이전트 ID입니다.                                    |
| `agent_name` | 에이전트 이름입니다.                                  |
| `agent_url` | 에이전트 등록 프로젝트의 에이전트 URL입니다. |
| `project_id` | GitLab 프로젝트 ID입니다.                           |
| `project_slug` | GitLab 프로젝트 슬러그입니다.                         |
| `project_path` | 전체 GitLab 프로젝트 경로입니다.                    |
| `project_url` | GitLab 프로젝트에 대한 링크입니다.                  |
| `template_name` | 사용된 템플릿의 이름입니다.                   |

### GitLab 관리형 Kubernetes 리소스 비활성화 {#disable-gitlab-managed-kubernetes-resources}

대시보드와 같은 다른 Kubernetes 기능을 계속 사용하면서 특정 환경에 대해 GitLab 관리형 Kubernetes 리소스를 비활성화할 수 있습니다. 관리형 리소스 비활성화는 기본적으로 관리형 리소스가 활성화된 글로벌 에이전트로 작업할 때 유용하지만, 특정 프로젝트 또는 환경을 옵트아웃해야 할 경우입니다.

환경에 대해 관리형 리소스를 비활성화하려면 `managed_resources.enabled: false` 구성을 추가합니다:

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    kubernetes:
      agent: path/to/agent/project:agent-name
      managed_resources:
        enabled: false
```

## 문제 해결 {#troubleshooting}

관리형 Kubernetes 리소스와 관련된 모든 오류는 다음에서 찾을 수 있습니다:

- GitLab 프로젝트의 환경 페이지
- 파이프라인에서 기능을 사용할 때 CI/CD 작업 로그

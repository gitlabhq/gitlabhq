---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용자에게 Kubernetes 액세스 권한 부여
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- [에이전트 연결 공유 제한이 100에서 500으로 상향됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149844). GitLab 17.0
- `user_access` 매개변수 `access_as` [은 선택 사항이 됨](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/merge_requests/2749). GitLab 18.3 기본값은 에이전트 가장하기입니다.
- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/557818). GitLab 18.4에서 서로 다른 최상위 그룹에 속하는 프로젝트 및 그룹의 권한 부여를 허용합니다.

{{< /history >}}

조직의 Kubernetes 클러스터 관리자로서, 특정 프로젝트 또는 그룹의 멤버에게 Kubernetes 액세스 권한을 부여할 수 있습니다.

액세스 권한 부여는 프로젝트 또는 그룹에 대해 [Kubernetes용 대시보드](../../../ci/environments/kubernetes_dashboard.md)도 활성화합니다.

GitLab Self-Managed 인스턴스의 경우 다음 중 하나를 확인합니다:

- GitLab 인스턴스와 [KAS](../../../administration/clusters/kas.md)를 같은 도메인에서 호스팅합니다.
- KAS를 GitLab의 하위 도메인에서 호스팅합니다. 예를 들어, GitLab을 `gitlab.com`에서, KAS를 `kas.gitlab.com`에서 호스팅합니다.

## Kubernetes 액세스 구성 {#configure-kubernetes-access}

사용자에게 Kubernetes 클러스터에 대한 액세스 권한을 부여하려면 액세스 권한을 구성합니다.

사전 요구 사항:

- Kubernetes 에이전트가 Kubernetes 클러스터에 설치되어 있습니다.
- Developer 역할 이상이 필요합니다.

액세스 권한을 구성하려면:

- 에이전트 구성 파일에서 `user_access` 키워드를 정의하고 다음 매개변수를 포함합니다:

  - `projects`: 액세스 권한을 가져야 하는 멤버를 포함할 프로젝트 목록입니다. 최대 500개의 프로젝트를 승인할 수 있습니다.
  - `groups`: 액세스 권한을 가져야 하는 멤버를 포함할 그룹 목록입니다. 최대 500개의 그룹을 승인할 수 있습니다. 그룹과 모든 하위 그룹에 액세스 권한을 부여합니다.
  - `access_as`: 에이전트 ID로 액세스하려면 값이 `{ agent: {...} }`입니다.

권한이 부여된 프로젝트 및 그룹은 [인스턴스 수준 권한 부여](ci_cd_workflow.md#authorize-all-projects-in-your-gitlab-instance-to-access-the-agent) 애플리케이션 설정이 활성화되지 않는 한 에이전트의 구성 프로젝트와 같은 최상위 그룹 또는 사용자 네임스페이스를 가져야 합니다.

액세스 권한을 구성한 후 요청은 에이전트 서비스 계정을 사용하여 API 서버로 전달됩니다. 예를 들어:

```yaml
# .gitlab/agents/my-agent/config.yaml

user_access:
  access_as:
    agent: {}
  projects:
    - id: group-1/project-1
    - id: group-2/project-2
  groups:
    - id: group-2
    - id: group-3/subgroup
```

## 사용자 가장으로 액세스 권한 구성 {#configure-access-with-user-impersonation}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Kubernetes 클러스터에 대한 액세스 권한을 부여하고 인증된 사용자에 대한 가장 요청으로 요청을 변환할 수 있습니다.

사전 요구 사항:

- Kubernetes 에이전트가 Kubernetes 클러스터에 설치되어 있습니다.
- Developer 역할 이상이 필요합니다.

사용자 가장으로 액세스 권한을 구성하려면:

- 에이전트 구성 파일에서 `user_access` 키워드를 정의하고 다음 매개변수를 포함합니다:

  - `projects`: 액세스 권한을 가져야 하는 멤버를 포함할 프로젝트 목록입니다.
  - `groups`: 액세스 권한을 가져야 하는 멤버를 포함할 그룹 목록입니다.
  - `access_as`: 사용자 가장으로 값이 `{ user: {...} }`입니다.

액세스 권한을 구성한 후 요청은 인증된 사용자에 대한 가장 요청으로 변환됩니다.

### 사용자 가장 워크플로우 {#user-impersonation-workflow}

설치된 `agentk`은 다음과 같이 지정된 사용자를 가장합니다:

- `UserName`은 `gitlab:user:<username>`입니다.
- `Groups`은:
  - `gitlab:user`: GitLab 사용자로부터 들어오는 모든 요청에 공통입니다.
  - 각 권한이 부여된 프로젝트의 각 역할에 대해 `gitlab:project_role:<project_id>:<role>`입니다.
  - 각 권한이 부여된 그룹의 각 역할에 대해 `gitlab:group_role:<group_id>:<role>`입니다.
- `Extra`은 요청에 대한 추가 정보를 포함합니다:
  - `agent.gitlab.com/id`: 에이전트 ID입니다.
  - `agent.gitlab.com/username`: GitLab 사용자의 사용자 이름입니다.
  - `agent.gitlab.com/config_project_id`: 에이전트 구성 프로젝트 ID입니다.
  - `agent.gitlab.com/access_type`: `personal_access_token` 또는 `session_cookie` 중 하나입니다. Ultimate만 해당입니다.

구성 파일의 `user_access` 아래에 직접 나열된 프로젝트 및 그룹만 가장됩니다. 예를 들어:

```yaml
# .gitlab/agents/my-agent/config.yaml

user_access:
  access_as:
    user: {}
  projects:
    - id: group-1/project-1 # group_id=1, project_id=1
    - id: group-2/project-2 # group_id=2, project_id=2
  groups:
    - id: group-2 # group_id=2
    - id: group-3/subgroup # group_id=3, group_id=4
```

이 구성에서:

- 사용자가 `group-1`의 멤버인 경우에만 Kubernetes RBAC 그룹 `gitlab:project_role:1:<role>`만 수신합니다.
- 사용자가 `group-2`의 멤버인 경우 두 Kubernetes RBAC 그룹을 모두 수신합니다:
  - `gitlab:project_role:2:<role>`,
  - `gitlab:group_role:2:<role>`.

### RBAC 권한 부여 {#rbac-authorization}

가장된 요청은 Kubernetes 내에서 리소스 권한을 식별하기 위해 `ClusterRoleBinding` 또는 `RoleBinding`가 필요합니다. 적절한 구성은 [RBAC 권한 부여](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)를 참조합니다.

예를 들어, `awesome-org/deployment` 프로젝트(ID: 123)의 유지 관리자가 Kubernetes 워크로드를 읽도록 허용하려면 Kubernetes 구성에 `ClusterRoleBinding` 리소스를 추가해야 합니다:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: my-cluster-role-binding
roleRef:
  name: view
  kind: ClusterRole
  apiGroup: rbac.authorization.k8s.io
subjects:
  - name: gitlab:project_role:123:maintainer
    kind: Group
```

## Kubernetes API로 클러스터에 액세스 {#access-a-cluster-with-the-kubernetes-api}

Kubernetes API를 사용하여 클러스터에 액세스할 수 있도록 에이전트를 구성할 수 있습니다.

사전 요구 사항:

- `user_access` 항목으로 구성된 에이전트가 있습니다.

### GitLab CLI를 사용하여 로컬 액세스 구성(권장) {#configure-local-access-with-the-gitlab-cli-recommended}

[GitLab CLI `glab`](../../../editor_extensions/gitlab_cli/_index.md)를 사용하여 Kubernetes 구성 파일을 생성하거나 업데이트하여 에이전트 Kubernetes API에 액세스할 수 있습니다.

`glab cluster agent` 명령을 사용하여 클러스터 연결을 관리합니다:

1. 프로젝트와 연결된 모든 에이전트의 목록을 봅니다:

```shell
glab cluster agent list --repo '<group>/<project>'

# If your current working directory is the Git repository of the project with the agent, you can omit the --repo option:
glab cluster agent list
```

1. 출력의 첫 번째 열에 제시된 수치 에이전트 ID를 사용하여 `kubeconfig`을 업데이트합니다:

```shell
glab cluster agent update-kubeconfig --repo '<group>/<project>' --agent '<agent-id>' --use-context
```

1. `kubectl` 또는 기본 설정하는 Kubernetes 도구로 업데이트를 확인합니다:

```shell
kubectl get nodes
```

`update-kubeconfig` 명령은 `glab cluster agent get-token`를 Kubernetes 도구에 대한 [자격 증명 플러그인](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-go-credential-plugins)으로 설정하여 토큰을 검색합니다. `get-token` 명령은 현재 날짜의 끝까지 유효한 개인 액세스 토큰을 생성하고 반환합니다. Kubernetes 도구는 토큰이 만료되거나 API가 권한 부여 오류를 반환하거나 프로세스가 종료될 때까지 토큰을 캐시합니다. Kubernetes 도구에 대한 모든 후속 호출이 새 토큰을 생성할 것으로 예상합니다.

`glab cluster agent update-kubeconfig` 명령은 여러 명령줄 플래그를 지원합니다. `glab cluster agent update-kubeconfig --help`로 지원되는 모든 플래그를 볼 수 있습니다.

몇 가지 예:

```shell
# When the current working directory is the Git repository where the agent is registered the --repo / -R flag can be omitted
glab cluster agent update-kubeconfig --agent '<agent-id>'

# When the --use-context option is specified the `current-context` of the kubeconfig file is changed to the agent context
glab cluster agent update-kubeconfig --agent '<agent-id>' --use-context

# The --kubeconfig flag can be used to specify an alternative kubeconfig path
glab cluster agent update-kubeconfig --agent '<agent-id>' --kubeconfig ~/gitlab.kubeconfig
```

### 개인 액세스 토큰을 사용하여 로컬 액세스를 수동으로 구성 {#configure-local-access-manually-using-a-personal-access-token}

장기 개인 액세스 토큰을 사용하여 Kubernetes 클러스터에 대한 액세스를 구성할 수 있습니다:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **Kubernetes 클러스터**를 선택하고 액세스하려는 에이전트의 수치 ID를 검색합니다. 전체 API 토큰을 구성하려면 ID가 필요합니다.
1. [개인 액세스 토큰](../../profile/personal_access_tokens.md)을 `k8s_proxy` 범위로 생성합니다. 전체 API 토큰을 구성하려면 액세스 토큰이 필요합니다.
1. `kubeconfig` 항목을 생성하여 클러스터에 액세스합니다:
   1. 올바른 `kubeconfig`이 선택되었는지 확인합니다. 예를 들어, `KUBECONFIG` 환경 변수를 설정할 수 있습니다.
   1. GitLab KAS 프록시 클러스터를 `kubeconfig`에 추가합니다:

      ```shell
      kubectl config set-cluster <cluster_name> --server "https://kas.gitlab.com/k8s-proxy"
      ```

      `server` 인수는 GitLab 인스턴스의 KAS 주소를 가리킵니다. GitLab.com에서 이것은 `https://kas.gitlab.com/k8s-proxy`입니다. 에이전트를 등록할 때 인스턴스의 KAS 주소를 얻을 수 있습니다.

   1. 수치 에이전트 ID 및 개인 액세스 토큰을 사용하여 API 토큰을 구성합니다:

      ```shell
      kubectl config set-credentials <gitlab_user> --token "pat:<agent-id>:<token>"
      ```

   1. 클러스터와 사용자를 결합하기 위한 컨텍스트를 추가합니다:

      ```shell
      kubectl config set-context <gitlab_agent> --cluster <cluster_name> --user <gitlab_user>
      ```

   1. 새 컨텍스트를 활성화합니다:

      ```shell
      kubectl config use-context <gitlab_agent>
      ```

1. 구성이 작동하는지 확인합니다:

   ```shell
   kubectl get nodes
   ```

구성된 사용자는 Kubernetes API를 사용하여 클러스터에 액세스할 수 있습니다.

## 관련 항목 {#related-topics}

- [아키텍처 청사진](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_user_access.md)
- [Kubernetes용 대시보드](https://gitlab.com/groups/gitlab-org/-/work_items/2493)

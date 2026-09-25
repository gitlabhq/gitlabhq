---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes 인스턴스에 대한 에이전트 관리
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Kubernetes 에이전트로 작업할 때 다음 작업을 사용합니다.

## 에이전트 보기 {#view-your-agents}

설치된 `agentk` 버전이 **에이전트** 탭에 표시됩니다.

사전 요구 사항:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

에이전트 목록을 보려면:

1. **검색 또는 이동**을 선택하고 에이전트 구성 파일이 포함된 프로젝트를 찾습니다. 에이전트 구성 파일이 없는 프로젝트에서는 등록된 에이전트를 볼 수 없습니다.
1. **운영** > **Kubernetes 클러스터**를 선택합니다.
1. **에이전트** 탭을 선택하여 에이전트를 통해 GitLab에 연결된 클러스터를 봅니다.

이 페이지에서 다음을 볼 수 있습니다:

- 현재 프로젝트의 모든 등록된 에이전트.
- 연결 상태.
- 클러스터에 설치된 `agentk`의 버전.
- 각 에이전트 구성 파일의 경로.

### 에이전트 구성 {#configure-your-agent}

에이전트를 구성하려면:

- `config.yaml` 파일에 콘텐츠를 추가합니다. 이 파일은 [설치 중에](install/_index.md#create-an-agent-configuration-file) 선택적으로 생성됩니다.

에이전트 목록에서 에이전트 구성 파일을 빠르게 찾을 수 있습니다. **구성** 열은 `config.yaml` 파일의 위치를 나타내거나 파일 생성 방법을 보여줍니다.

에이전트 구성 파일은 다양한 에이전트 기능을 관리합니다:

- GitLab CI/CD 워크플로우의 경우 [에이전트가 프로젝트에 액세스할 수 있도록 권한을 부여](ci_cd_workflow.md#authorize-agent-access)한 다음, [`kubectl` 명령을 `.gitlab-ci.yml` 파일에 추가](ci_cd_workflow.md#update-your-gitlab-ciyml-file-to-run-kubectl-commands)해야 합니다.
- GitLab UI 또는 로컬 터미널에서 클러스터에 [사용자 액세스](user_access.md)의 경우
- [운영 컨테이너 스캔](vulnerabilities.md) 구성의 경우
- [원격 워크스페이스](../../workspace/gitlab_agent_configuration.md) 구성의 경우

### 사용 가능한 구성 파일 필드 {#available-configuration-file-fields}

에이전트의 구성 파일 형식은 소스 리포지토리에서 [프로토콜 버퍼 메시지](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/pkg/agentcfg/agentcfg.proto)로 정의됩니다.

사용 가능한 모든 구성 파일 필드를 보려면:

1. [`ConfigurationFile`](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/pkg/agentcfg/agentcfg_proto_docs.md#configurationfile)로 이동하여 [생성된 설명서](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/pkg/agentcfg/agentcfg_proto_docs.md)에서 전체 에이전트 구성 파일의 필드를 봅니다.
1. 필드 구조에 대한 자세한 정보를 보려면 필드 유형을 선택합니다.

## 공유된 에이전트 보기 {#view-shared-agents}

프로젝트가 소유한 에이전트 외에도 [`ci_access`](ci_cd_workflow.md) 및 [`user_access`](user_access.md) 키워드로 공유된 에이전트를 볼 수 있습니다. 에이전트가 프로젝트와 공유되면 프로젝트 에이전트 탭에 자동으로 나타납니다.

공유된 에이전트 목록을 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **Kubernetes 클러스터**를 선택합니다.
1. **에이전트** 탭을 선택합니다.

공유된 에이전트 목록과 해당 클러스터가 표시됩니다.

## 에이전트의 활동 정보 보기 {#view-an-agents-activity-information}

활동 로그는 문제를 파악하고 문제 해결에 필요한 정보를 얻을 수 있습니다. 현재 날짜 기준 1주일 전의 이벤트를 볼 수 있습니다. 에이전트의 활동을 보려면:

1. **검색 또는 이동**을 선택하고 에이전트 구성 파일이 포함된 프로젝트를 찾습니다.
1. **운영** > **Kubernetes 클러스터**를 선택합니다.
1. 활동을 보려는 에이전트를 선택합니다.

활동 목록에는 다음이 포함됩니다:

- 에이전트 등록 이벤트. 새 토큰이 생성될 때
- 연결 이벤트. 에이전트가 클러스터에 성공적으로 연결될 때

연결 상태는 처음 에이전트를 연결할 때 또는 1시간 이상 비활성 상태가 지난 후에 로깅됩니다.

[이 에픽](https://gitlab.com/groups/gitlab-org/-/epics/4739)에서 UI에 대한 의견을 보고 제공합니다.

## 에이전트 디버깅 {#debug-the-agent}

에이전트의 클러스터 측 구성요소(`agentk`)를 디버깅하려면 사용 가능한 옵션에 따라 로그 수준을 설정합니다:

- `error`
- `info`
- `debug`

에이전트에는 두 개의 로거가 있습니다:

- 일반 목적 로거로, 기본값은 `info`입니다.
- gRPC 로거로, 기본값은 `error`입니다.

[에이전트 구성 파일](#configure-your-agent)에서 최상위 `observability` 섹션을 사용하여 로그 수준을 변경할 수 있습니다. 예를 들어 수준을 `debug` 및 `warn`로 설정합니다:

```yaml
observability:
  logging:
    level: debug
    grpc_level: warn
```

`grpc_level`이(가) `info` 이하로 설정되면 많은 gRPC 로그가 생성됩니다.

구성 변경 사항을 커밋하고 에이전트 서비스 로그를 검사합니다:

```shell
kubectl logs -f -l=app=gitlab-agent -n gitlab-agent
```

디버깅에 대한 자세한 내용은 [문제 해결 설명서](troubleshooting.md)를 참조하세요.

## 에이전트 토큰 재설정 {#reset-the-agent-token}

에이전트는 한 번에 두 개의 활성 토큰만 가질 수 있습니다.

가동 중지 시간 없이 에이전트 토큰을 재설정하려면:

1. 새 토큰을 생성합니다:
   1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
   1. **운영** > **Kubernetes 클러스터**를 선택합니다.
   1. 토큰을 생성할 에이전트를 선택합니다.
   1. **액세스 토큰** 탭에서 **토큰 생성**을 선택합니다.
   1. 토큰의 이름과 설명(선택 사항)을 입력한 다음 **토큰 생성**을 선택합니다.
1. 생성된 토큰을 안전하게 저장합니다.
1. 토큰을 사용하여 [클러스터에 에이전트를 설치](install/_index.md#install-the-agent-in-the-cluster)하고 [에이전트를 업데이트](install/_index.md#update-the-agent-version)하여 다른 버전으로 업그레이드합니다.
1. 더 이상 사용하지 않는 토큰을 삭제하려면 토큰 목록으로 돌아가서 **해지**({{< icon name="remove" >}})를 선택합니다.

## 에이전트 제거 {#remove-an-agent}

[GitLab UI](#remove-an-agent-through-the-gitlab-ui) 또는 [GraphQL API](#remove-an-agent-with-the-gitlab-graphql-api)를 사용하여 에이전트를 제거할 수 있습니다. 에이전트와 연결된 모든 토큰이 GitLab에서 제거되지만 Kubernetes 클러스터에서는 변경 사항이 없습니다. 해당 리소스를 수동으로 정리해야 합니다.

### GitLab UI를 통해 에이전트 제거 {#remove-an-agent-through-the-gitlab-ui}

UI에서 에이전트를 제거하려면:

1. **검색 또는 이동**을 선택하고 에이전트 구성 파일이 포함된 프로젝트를 찾습니다.
1. **운영** > **Kubernetes 클러스터**를 선택합니다.
1. 표에서 에이전트 행의 **옵션** 열에서 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택합니다.
1. **에이전트 삭제**를 선택합니다.

### GitLab GraphQL API를 사용하여 에이전트 제거 {#remove-an-agent-with-the-gitlab-graphql-api}

1. 대화형 GraphQL 탐색기에서 쿼리로부터 `<cluster-agent-token-id>`을(를) 가져옵니다.
   - GitLab.com의 경우 <https://gitlab.com/-/graphql-explorer>로 이동하여 GraphQL 탐색기를 엽니다.
   - GitLab Self-Managed의 경우 `https://gitlab.example.com/-/graphql-explorer`로 이동하여 `gitlab.example.com`를 인스턴스의 URL로 바꿉니다.

   ```graphql
   query{
     project(fullPath: "<full-path-to-agent-configuration-project>") {
       clusterAgent(name: "<agent-name>") {
         id
         tokens {
           edges {
             node {
               id
             }
           }
         }
       }
     }
   }
   ```

1. `clusterAgentToken`을(를) 삭제하여 GraphQL로 에이전트 레코드를 제거합니다.

   ```graphql
   mutation deleteAgent {
     clusterAgentDelete(input: { id: "<cluster-agent-id>" } ) {
       errors
     }
   }

   mutation deleteToken {
     clusterAgentTokenDelete(input: { id: "<cluster-agent-token-id>" }) {
       errors
     }
   }
   ```

1. 제거가 성공적으로 발생했는지 확인합니다. Pod 로그의 출력에 `unauthenticated`이(가) 포함되면 에이전트가 성공적으로 제거된 것입니다:

   ```json
   {
       "level": "warn",
       "time": "2021-04-29T23:44:07.598Z",
       "msg": "GetConfiguration.Recv failed",
       "error": "rpc error: code = Unauthenticated desc = unauthenticated"
   }
   ```

1. 클러스터에서 에이전트를 삭제합니다:

   ```shell
   kubectl delete -n gitlab-kubernetes-agent -f ./resources.yml
   ```

## 관련 항목 {#related-topics}

- [에이전트의 워크스페이스 관리](../../workspace/_index.md#manage-workspaces-at-the-agent-level)

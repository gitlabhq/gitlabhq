---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AI 카탈로그의 사용자 지정 에이전트를 MCP 서버를 사용하여 외부 데이터 소스 및 타사 서비스에 연결합니다.
title: AI 카탈로그의 MCP 서버
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- GitLab 18.10에서 `ai_catalog_mcp_servers`라는 [기능 플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/590708)되었습니다. 기본적으로 비활성화되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능성은 기능 플래그로 제어합니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트 가능하지만 프로덕션 사용은 준비되지 않았습니다.

AI 카탈로그의 사용자 지정 에이전트는 [Model Context Protocol](https://modelcontextprotocol.io/) (MCP)을 통해 외부 데이터 소스 및 타사 서비스(예: Jira 또는 Linear)에 연결할 수 있습니다.

이 기능은 [실험](../../../policy/development_stages_support.md#experiment)입니다. [이슈 593219](https://gitlab.com/gitlab-org/gitlab/-/work_items/593219)에서 의견을 공유합니다.

AI 카탈로그의 MCP 서버를 사용하면 다음을 수행할 수 있습니다:

- MCP 서버를 조직의 카탈로그에 추가합니다(이름, URL, 전송 유형).
- MCP 서버를 사용자 지정 에이전트와 연결합니다.
- 각 에이전트에 연결된 MCP 서버를 확인합니다.
- OAuth 지원 MCP 서버로 인증합니다.

전용 **MCP** 탭이 AI 카탈로그 네비게이션에 **에이전트** 및 **플로우**와 함께 나타납니다. 네임스페이스에서 활성화된 에이전트와 연결된 MCP 서버는 그룹 및 프로젝트 수준 모두에서 **AI** > **MCP 서버**에서도 사용 가능합니다.

## 사전 요구 사항 {#prerequisites}

- [GitLab Duo Agent Platform 사전 요구 사항](../../duo_agent_platform/_index.md#prerequisites)을 충족합니다.
- GitLab.com에서는 [GitLab Duo 실험 및 베타 기능을 켜진](../turn_on_off.md#on-gitlabcom-2) 최상위 그룹의 멤버여야 합니다.
- GitLab Self-Managed에서는 인스턴스가 [GitLab Duo 실험 및 베타 기능이 켜져 있어야](../turn_on_off.md#on-gitlab-self-managed-2) 합니다.
- GitLab Self-Managed에서는 관리자가 `mcp_client` [기능 플래그](../../../administration/feature_flags/_index.md)를 활성화했습니다.
- MCP 서버는 다음이어야 합니다:
  - 검증됨 또는 파트너 MCP 서버입니다. 임의의 URL은 허용되지 않습니다.
  - 원격 MCP 서버입니다.

## AI 카탈로그에 MCP 서버 추가 {#add-an-mcp-server-to-the-ai-catalog}

{{< details >}}

- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

사전 요구 사항:

- 인스턴스의 관리자 액세스 권한

GitLab Self-Managed 및 GitLab Dedicated에서 인스턴스 관리자는 [사용 가능한 MCP 서버](#available-mcp-servers) 목록에서 인스턴스의 AI 카탈로그에 MCP 서버를 추가할 수 있습니다.

> [!note]
> GitLab.com에서는 최상위 그룹 멤버가 이것이 GitLab.com 관리자에 의해 중앙에서 관리되므로 AI 카탈로그에 MCP 서버를 추가할 수 없습니다.

AI 카탈로그에 MCP 서버를 추가하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. **빌드** > **AI 카탈로그**를 선택합니다.
1. **MCP** 탭을 선택합니다.
1. **새 MCP 서버**를 선택합니다.
1. 필드를 완성합니다:
   - **Name (이름)**: MCP 서버의 설명적인 이름(예: `Jira`)입니다.
   - **설명** (선택 사항): 서버가 제공하는 것에 대한 간단한 설명입니다.
   - **URL**: MCP 서버의 HTTP 엔드포인트입니다.
   - **홈페이지 URL** (선택 사항): MCP 서버의 홈페이지 또는 문서 URL입니다.
   - **전송**: **HTTP**를 선택합니다. HTTP 전송만 지원됩니다. SSE 및 stdio 전송은 사용할 수 없습니다.
   - **인증 유형**: 다음 중 하나를 선택합니다.
     - **없음**: 인증이 필요하지 않습니다.
     - **OAuth**: OAuth 2.0으로 인증합니다. 서버가 [OAuth 2.0 Dynamic Client Registration](https://tools.ietf.org/html/rfc7591)을 지원하면 GitLab은 첫 번째 연결 시 자신을 OAuth 클라이언트로 자동 등록합니다.
1. **MCP 서버 생성**을 선택합니다.

이제 MCP 서버를 조직의 카탈로그에서 사용할 수 있으며 에이전트와 연결할 수 있습니다.

## MCP 서버 편집 {#edit-an-mcp-server}

{{< details >}}

- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

사전 요구 사항:

- 인스턴스의 관리자 액세스 권한

GitLab Self-Managed 및 GitLab Dedicated에서 인스턴스 관리자는 인스턴스의 AI 카탈로그에서 MCP 서버를 편집할 수 있습니다.

> [!note]
> GitLab.com에서는 최상위 그룹 멤버가 이것이 GitLab.com 관리자에 의해 중앙에서 관리되므로 AI 카탈로그에서 MCP 서버를 편집할 수 없습니다.

MCP 서버를 편집하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. **빌드** > **AI 카탈로그**를 선택합니다.
1. **MCP** 탭을 선택합니다.
1. 편집할 MCP 서버를 선택합니다.
1. **편집**을 선택합니다.
1. 필요에 따라 필드를 업데이트합니다.
1. **변경 사항 저장**을 선택합니다.

## MCP 서버를 사용자 지정 에이전트에 연결 {#connect-an-mcp-server-to-a-custom-agent}

MCP 서버를 사용자 지정 에이전트에 연결하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. **빌드** > **AI 카탈로그**를 선택합니다.
1. **에이전트** 탭을 선택합니다.
1. 구성할 에이전트를 선택한 다음 **편집**을 선택합니다.
1. **MCP 서버** 섹션에서 이 에이전트와 연결할 MCP 서버를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

에이전트는 이제 실행 중 연결된 MCP 서버가 제공하는 모든 도구를 사용할 수 있습니다.

특정 MCP 서버 도구 사용을 에이전트에서 제한할 수 없습니다.

## 사용자 지정 에이전트에 연결된 MCP 서버 보기 {#view-mcp-servers-connected-to-a-custom-agent}

사용자 지정 에이전트에 연결된 MCP 서버를 확인하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. **빌드** > **AI 카탈로그**를 선택합니다.
1. **에이전트** 탭을 선택합니다.
1. 에이전트를 선택합니다.

에이전트 세부정보 페이지는 연결된 모든 MCP 서버를 나열합니다.

## 사용자 지정 에이전트에서 MCP 서버 연결해제 {#disconnect-an-mcp-server-from-custom-agents}

{{< history >}}

- GitLab 18.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227157)되었습니다.

{{< /history >}}

MCP 서버를 연결된 모든 사용자 지정 에이전트에서 연결해제할 수 있습니다. 특정 에이전트에서 MCP 서버를 연결해제할 수 없습니다.

연결해제한 후에도 기존 사용자 지정 에이전트 채팅은 MCP 서버에서 이미 검색된 콘텐츠를 참조할 수 있습니다. 그러나 에이전트는 더 이상 새로운 콘텐츠를 가져오거나 작업을 수행할 수 없습니다.

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. **빌드** > **AI 카탈로그**를 선택합니다.
1. **MCP** 탭을 선택합니다.
1. 연결해제하려는 MCP 서버의 경우 **연결해제**를 선택합니다.
1. 확인 대화에서 **연결해제**를 선택합니다.

## 네임스페이스의 MCP 서버 보기 {#view-mcp-servers-for-a-namespace}

**AI** > **MCP 서버** 페이지는 네임스페이스에서 활성화된 에이전트와 연결된 모든 MCP 서버를 표시합니다. 각 서버는 사용하는 에이전트의 수를 표시하며, 에이전트 이름은 마우스 오버 시 도구팁으로 표시됩니다.

이 페이지는 그룹 및 프로젝트 수준 모두에서 사용 가능합니다:

- **그룹 수준**은 그룹 전체에서 에이전트와 연결된 MCP 서버를 표시합니다.
- **프로젝트 수준**은 프로젝트에 구성된 에이전트와 연결된 MCP 서버를 표시합니다.

그룹 또는 프로젝트 수준에서 MCP 서버를 확인하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 그룹 또는 프로젝트를 찾습니다.
1. **AI** > **MCP 서버**를 선택합니다.

아직 인증하지 않은 OAuth 지원 서버의 경우 **연결** 옵션이 표시됩니다.

## MCP 서버로 인증 {#authenticate-with-an-mcp-server}

OAuth 지원 MCP 서버로 인증하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 그룹 또는 프로젝트를 찾습니다.
1. **AI** > **MCP 서버**를 선택합니다.
1. MCP 서버를 찾고 **연결**을 선택합니다.
1. MCP 서버의 권한 부여 페이지에서 권한 부여 요청을 검토하고 승인합니다.
1. GitLab은 향후 요청을 위해 액세스 토큰을 안전하게 저장합니다.

서버가 [OAuth 2.0 Dynamic Client Registration](https://tools.ietf.org/html/rfc7591)을 지원하면 GitLab은 첫 번째 연결 시 자신을 OAuth 클라이언트로 자동 등록합니다. OAuth 자격증명을 수동으로 제공할 필요가 없습니다.

## 사용 가능한 MCP 서버 {#available-mcp-servers}

{{< details >}}

- 제공 서비스: GitLab.com

{{< /details >}}

AI 카탈로그에서 다음 MCP 서버를 사용자 지정 에이전트에 추가할 수 있습니다. 카탈로그에 제안된 더 많은 서버는 [이슈 591969](https://gitlab.com/gitlab-org/gitlab/-/work_items/591969)를 참조하세요.

### Linear {#linear}

Linear MCP 서버는 AI 에이전트와 워크플로우가 실시간으로 Linear 데이터와 상호 작용하도록 허용합니다. 여기에는 이슈, 프로젝트 및 댓글을 찾고, 생성하고, 업데이트하는 것이 포함됩니다.

| 속성 | 값 |
|---|---|
| URL | `https://mcp.linear.app/mcp` |
| 전송 | HTTP |
| 인증 | OAuth |

### Atlassian {#atlassian}

Atlassian MCP 서버는 AI 에이전트와 워크플로우가 실시간으로 Jira 및 Confluence 데이터와 상호 작용하도록 허용합니다. 여기에는 이슈, 페이지 및 프로젝트 콘텐츠를 검색하고, 생성하고, 업데이트하는 것이 포함됩니다.

| 속성 | 값 |
|---|---|
| URL | `https://mcp.atlassian.com/v1/mcp` |
| 전송 | HTTP |
| 인증 | OAuth |

연결하기 전에 Atlassian 인스턴스를 GitLab을 승인된 도메인으로 신뢰하도록 구성합니다:

1. Atlassian에서 관리 페이지로 이동합니다.
1. **앱** > **AI 설정** > **Rovo MCP 서버**를 선택합니다.
1. `https://gitlab.com/**`을 신뢰할 수 있는 도메인 목록에 추가합니다.

### Context7 {#context7}

Context7 MCP는 소스에서 최신의 버전별 문서 및 코드 예제를 가져와 프롬프트에 추가합니다.

| 속성 | 값 |
|---|---|
| URL | `https://mcp.context7.com/mcp` |
| 전송 | HTTP |
| 인증 | 없음 |

## 관련 항목 {#related-topics}

- [GitLab MCP 서버](../../model_context_protocol/mcp_server.md)

## 문제 해결 {#troubleshooting}

AI 카탈로그에서 MCP 서버를 사용할 때 다음 문제가 발생할 수 있습니다.

### 아웃바운드 요청 제한으로 인한 MCP 서버 문제 {#mcp-server-issues-due-to-outbound-request-restrictions}

{{< details >}}

- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 웹후크 및 통합과 같은 다른 아웃바운드 요청을 검증하는 방식과 동일하게 MCP 서버의 URL을 검증합니다. GitLab Self-Managed 인스턴스가 [아웃바운드 요청](../../../security/webhooks.md)을 제한하면 URL 자체가 유효한 경우에도 MCP 서버를 추가, 편집 또는 연결하려는 시도가 실패할 수 있습니다.

이 문제를 해결하는 방법은 MCP 서비스가 호스팅되는 위치에 따라 다릅니다.

추가 문제 해결 정보는 [아웃바운드 요청 필터링](../../../security/webhooks.md#troubleshooting)을 참조하세요.

#### 공개 MCP 서버 {#public-mcp-server}

공개 MCP 서버는 검증됨 또는 파트너 서버이거나 인터넷을 통해 연결 가능한 자체 서버일 수 있습니다.

인스턴스가 [허용 목록의 항목을 제외한 모든 아웃바운드 요청을 차단](../../../security/webhooks.md#filter-requests)하면 인스턴스 관리자에게 MCP 서버의 도메인 또는 IP 주소를 [아웃바운드 요청 허용 목록](../../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains)에 추가하도록 요청합니다.

인스턴스가 이를 수행하지 않으면 추가 조치가 필요하지 않습니다.

#### 내부 또는 로컬 MCP 서버 {#internal-or-local-mcp-server}

내부 또는 로컬 MCP 서버는 `localhost`에서 실행되는 서버이거나 개인 또는 내부 네트워크에 있을 수 있습니다.

기본적으로 GitLab은 서버 측 요청 위조로부터 보호하기 위해 로컬 및 개인 네트워크 주소로의 요청을 차단합니다.

요청을 허용하려면 인스턴스 관리자에게 다음 중 하나를 수행하도록 요청합니다:

- [웹후크 및 통합에서 로컬 네트워크로의 요청 허용](../../../security/webhooks.md#allow-requests-to-the-local-network-from-webhooks-and-integrations)합니다. 이는 MCP 서버만이 아닌 모든 로컬 및 개인 네트워크 주소로의 요청을 허용합니다.
- MCP 서버의 도메인 또는 IP 주소(필요한 경우 포트)만을 아웃바운드 요청 허용 목록에 추가합니다. 이 옵션은 전체 로컬 네트워크에 대한 액세스를 열지 않으므로 더 제한적입니다.

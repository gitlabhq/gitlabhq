---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 로컬 에이전트 실행으로 GitLab 편집기 확장 및 CLI 도구를 사용할 때의 보안 고려 사항입니다.
title: 편집기 확장 및 CLI 도구의 보안 고려 사항
---

GitLab 편집기 확장 및 CLI 도구는 로컬 환경에서 AI 에이전트를 실행할 수 있습니다. 보안 영향을 이해하고 개발 환경을 보호하기 위한 모범 사례를 따릅니다.

## 로컬 AI 에이전트 실행 위험 {#local-agent-execution-risks}

편집기 확장 및 CLI 도구가 로컬로 에이전트를 실행하면 에이전트는 컨테이너 격리 없이 실행되며 시스템 리소스에 직접 액세스할 수 있습니다.

### 파일 시스템 액세스 {#file-system-access}

AI 에이전트는 작업 유형에 따라 다양한 파일 액세스 수준을 가집니다.

#### 파일 작업 {#file-operations}

AI 에이전트는 다음에서 파일 작업(읽기, 쓰기, 편집, 검색 및 나열)을 수행할 수 있습니다:

- GitLab 프로젝트의 Git 리포지토리에 위치한 파일입니다.
- `.gitignore` 규칙으로 제외되지 않은 파일입니다.
- Git 리포지토리 내의 파일을 가리키는 유효하거나 해석 가능한 심볼릭 링크입니다.

#### 파일의 셸 작업 {#shell-operations-on-files}

AI 에이전트가 실행하는 셸 명령은 Git 리포지토리 외부의 파일을 포함하여 모든 파일에 액세스할 수 있으며 `.gitignore` 패턴과 일치하는 파일도 액세스할 수 있습니다.

### 환경 변수 액세스 {#environment-variable-access}

AI 에이전트는 다음을 제외한 셸 세션의 모든 환경 변수에 액세스할 수 있습니다:

- `CI_JOB_TOKEN`
- `GITLAB_OAUTH_TOKEN`
- `DUO_WORKFLOW_SERVICE_TOKEN`

### 시스템 리소스 {#system-resources}

AI 에이전트는 다음 시스템 리소스에 액세스할 수 있습니다:

- 네트워크 요청: AI 에이전트는 워크스테이션에서 네트워크 요청을 수행할 수 있습니다.
- 프로세스 실행: AI 에이전트는 셸 환경에서 명령을 실행할 수 있습니다.

### 보안 위협 {#security-threats}

격리가 제대로 이루어지지 않았으므로 다음 위협이 발생할 수 있습니다:

- 프롬프트 인젝션: 악의적인 프롬프트가 AI 에이전트 동작을 조작하고 의도하지 않은 작업을 실행합니다.
- AI 에이전트 손상: 손상된 AI 에이전트는 워크스테이션 리소스에 대한 액세스를 제공합니다.
- 데이터 유출: 워크스테이션의 모든 데이터(암호, 소스 코드 및 개인 파일과 같은 민감한 데이터 포함)를 도용할 수 있습니다.
- 수평 이동: 노출된 자격 증명은 다른 시스템 및 서비스에 대한 액세스를 가능하게 합니다.

## 권장 보안 사례 {#recommended-security-practices}

개발 환경을 보호하려면 다음 보안 모범 사례를 따릅니다.

### 승인 전에 도구 호출 검토 {#review-tool-calls-before-approval}

AI 에이전트가 작업을 실행할 수 있는 승인을 요청할 때 승인 전에 각 도구 호출을 신중하게 검토합니다.

다음을 확인합니다:

- 명령 및 파일 작업이 의도한 작업과 일치합니다.
- 파일 경로가 심볼릭 링크 대상 파일을 포함하는 예상 디렉터리 내에 있습니다.
- 명령 인수에 예상치 못한 플래그나 매개 변수가 포함되어 있지 않습니다.
- 민감한 파일 액세스 및 네트워크 요청이 작업에 필요합니다.

관리자는 각 호출을 승인하는 대신 세션에 대해 한 번 도구를 승인할 수 있는지 여부를 제어할 수 있습니다. 자세한 내용은 [도구 승인](../user/gitlab_duo_chat/agentic_chat.md#tool-approvals)을 참조하세요.

GitLab Duo CLI를 헤드리스 모드로 사용하면 도구 호출이 자동으로 승인됩니다. 개발 컨테이너와 같은 제어된 샌드박스 환경에서 헤드리스 모드를 신중하게 사용합니다.

### MCP 서버 소스 및 권한 확인 {#verify-mcp-server-sources-and-permissions}

GitLab Duo로 Model Context Protocol(MCP) 서버를 안전하게 사용하려면:

- 신뢰할 수 있는 소스에서만 MCP 서버를 활성화합니다.
- 각 MCP 서버가 요청하는 권한과 기능을 검토합니다.
- MCP 서버를 활성화하기 전에 액세스할 수 있는 데이터를 검토합니다.
- 환경에서 활성화된 MCP 서버를 정기적으로 감사합니다.

### 격리를 위해 개발 컨테이너 사용 {#use-development-containers-for-isolation}

개발 컨테이너를 사용하여 로컬 실행 위험을 완화합니다.

GitLab Duo CLI 사용자의 경우 헤드리스 모드는 수동 도구 승인을 우회하므로 개발 컨테이너가 특히 중요합니다.

개발 컨테이너는 다음을 제공합니다:

- 프로세스 격리: 호스트 머신에 직접 실행하지 않고 격리된 컨테이너 환경에서 AI 에이전트를 실행합니다.
- 제한된 파일 시스템 액세스: 컨테이너를 구성하여 필요한 파일에만 액세스를 제한합니다.
- 자격 증명 격리: 자격 증명을 별도로 관리하고 필요에 따라 컨테이너에 주입합니다.
- 네트워크 격리:  외부 액세스를 제한하기 위해 컨테이너 네트워킹을 제한합니다.

GitLab for VS Code 확장은 VS Code Dev Containers와 호환됩니다. 자세한 내용은 [Visual Studio Code Dev Container에서 확장 사용](visual_studio_code/setup.md#install-in-a-visual-studio-code-dev-container)을 참조하세요.

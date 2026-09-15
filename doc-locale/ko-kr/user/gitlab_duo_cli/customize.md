---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab Duo CLI를 위한 후크, 사용자 지정 슬래시 명령어, 플러그인 및 네트워크 설정을 구성합니다."
title: GitLab Duo CLI 사용자 지정
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.0 릴리스 중에 사용자 수준 Agent Skills를 사용으로 설정하는 환경 변수 및 옵션이 GitLab Duo CLI 8.83.0에서 [실험적](../../policy/development_stages_support.md#experiment)으로 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.83.0)되었습니다.

{{< /history >}}

GitLab Duo CLI는 다음 사용자 지정을 지원합니다.

- 후크를 사용하여 GitLab Duo CLI 수명 주기의 특정 지점에서 사용자 지정 명령을 실행합니다.
- 사용자 지정 슬래시 명령을 사용하여 CLI를 워크플로 또는 사용 사례에 더 잘 정렬합니다.
- 플러그인을 사용하여 마켓플레이스에서 Agent Skills, 사용자 지정 슬래시 명령어 및 Model Context Protocol(MCP) 서버를 설치합니다.
- GitLab Duo Agent Platform을 위해 설정된 [사용자 지정 방법](../duo_agent_platform/customize/_index.md)을 사용하여 워크플로, 코딩 표준 또는 프로젝트 요구 사항과 일치하도록 합니다.

## 후크 {#hooks}

{{< details >}}

- 상태:  실험적

{{< /details >}}

{{< history >}}

- GitLab 19.1 릴리스 중 GitLab Duo CLI 8.95.0에서 [실험적](../../policy/development_stages_support.md#experiment)으로 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2209)되었습니다.

{{< /history >}}

후크를 사용하여 GitLab Duo CLI 수명 주기의 특정 지점에서 사용자 지정 명령을 실행합니다.

예를 들어 환경에 대한 정보를 수집하는 스크립트를 실행하여 모든 새 채팅 세션에 추가 컨텍스트를 주입할 수 있습니다.

GitLab Duo CLI는 두 수준에서 후크를 지원합니다.

- 사용자 수준(전역): 모든 프로젝트에 적용됩니다.
- 프로젝트 수준: 특정 프로젝트에만 적용됩니다. 프로젝트 수준 후크는 체크아웃한 리포지토리에서 임의 코드 실행을 방지하기 위해 기본적으로 사용 중지됩니다.

사용자 수준 및 프로젝트 수준 `hooks.json` 파일이 모두 있으면 CLI는 후크를 병합하고 사용자 수준 후크를 먼저 실행합니다.

> [!note]
> 보안상의 이유로 중요한 환경 변수(`GITLAB_TOKEN`, `GITLAB_OAUTH_TOKEN`, `CI_JOB_TOKEN`)는 후크 프로세스에서 제외됩니다.

### 후크 실행 {#hook-execution}

후크이 실행될 때 GitLab Duo CLI는 다음을 수행합니다.

1. 세션 메타데이터가 있는 JSON 개체를 명령의 표준 입력으로 보냅니다.

   ```json
   {
     "session_id": "abc-123",
     "cwd": "/path/to/project",
     "transcript_path": "",
     "hook_event_name": "SessionStart",
     "source": "startup"
   }
   ```

1. 후크 프로세스에 대해 환경 변수 `DUO_SESSION_ID` 및 `DUO_PROJECT_DIR`를 설정합니다.
1. 명령의 표준 출력을 세션에 대한 추가 컨텍스트로 수집합니다.

후크는 표준 출력에 일반 텍스트 또는 JSON 개체를 반환할 수 있습니다.

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Your context string here"
  }
}
```

후크가 0이 아닌 상태로 종료되거나 시간 초과되면 경고로 로그되지만 세션이 시작되는 것을 차단하지는 않습니다.

### 후크 만들기 {#create-hooks}

GitLab Duo CLI는 새 세션이 시작되거나 기존 세션이 다시 시작될 때 실행되는 `SessionStart` 이벤트를 지원합니다.

후크를 만들려면 다음을 수행합니다.

1. `hooks.json` 파일을 만듭니다.
   - 사용자 수준 후크의 경우:
     - Linux 또는 macOS에서 파일을 `~/.gitlab/duo/hooks.json`에 만듭니다.
     - Windows에서 파일을 `%APPDATA%\GitLab\duo\hooks.json`에 만듭니다.
   - 프로젝트 수준 후크의 경우 프로젝트의 루트에 파일을 만듭니다. `<project>/.gitlab/duo/hooks.json`.
1. 파일에서 후크를 정의합니다.
   - 후크를 트리거해야 하는 각 `SessionStart` 이벤트 소스(`startup` 또는 `resume`)에 대해 일치 그룹을 만듭니다.
   - 각 일치 그룹에는 선택적 정규식 `matcher` 값과 명령 후크 배열이 있습니다.

     | 필드 | 설명 |
     |-------|-------------|
     | `matcher` | 선택 사항입니다. 이벤트 소스(`SessionStart`의 경우 `startup` 또는 `resume`)에 대해 테스트된 정규식입니다. 모두 일치시키려면 생략합니다. |
     | `hooks[].type` | `"command"`이어야 합니다. |
     | `hooks[].command` | 실행할 셸 명령입니다. |
     | `hooks[].timeout` | 선택 사항입니다. 초 단위 시간 초과입니다. 기본값: 30\. |

   - 예를 들어:

     ```json
     {
       "hooks": {
         "SessionStart": [
           {
             "matcher": "startup",
             "hooks": [
               {
                 "type": "command",
                 "command": "cat ~/.my-coding-preferences.md",
                 "timeout": 10
               }
             ]
          }
         ]
       }
     }
     ```

1. 프로젝트 수준 후크가 있는 경우 GitLab Duo CLI를 시작할 때 사용으로 설정합니다.

   {{< tabs >}}

   {{< tab title="glab" >}}

   ```shell
   glab duo cli --enable-project-hooks
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   ```shell
   duo --enable-project-hooks
   ```

   {{< /tab >}}

   {{< /tabs >}}

   또는 환경 변수를 설정합니다.

   ```shell
   export GITLAB_ENABLE_PROJECT_HOOKS=true
   ```

## 사용자 지정 슬래시 명령 {#custom-slash-commands}

{{< history >}}

- GitLab 19.2 릴리스 중 GitLab Duo CLI 9.2.0에서 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3617)되었습니다.

{{< /history >}}

자주 사용하는 프롬프트에 대한 사용자 지정 슬래시 명령을 만듭니다.

GitLab Duo CLI는 두 수준에서 사용자 지정 슬래시 명령을 지원합니다.

- 사용자 수준: 모든 프로젝트에 적용됩니다.
- 프로젝트 수준: 특정 프로젝트에만 적용됩니다.

사용자 수준 명령과 프로젝트 수준 명령이 같은 이름을 공유하면 프로젝트 수준 명령이 우선합니다. 사용자 지정 슬래시 명령은 기본 제공 슬래시 명령 또는 [Agent Skills 슬래시 명령](../duo_agent_platform/customize/agent_skills.md#expose-skills-as-slash-commands)을 재정의할 수 없습니다.

### 사용자 지정 슬래시 명령 만들기 {#create-a-custom-slash-command}

사용자 지정 슬래시 명령을 만들려면 Markdown 파일을 만듭니다.

파일 이름은 명령 이름이고 파일 내용은 프롬프트입니다.

예를 들어 `daily.md`라는 파일은 `/daily` 명령을 만듭니다.

1. `commands` 디렉터리를 만듭니다.
   - 프로젝트 수준 명령의 경우 프로젝트의 루트에 디렉터리를 만듭니다: `<project>/.agents/commands/`
   - 사용자 수준 명령의 경우 다음 위치 중 하나를 사용합니다.
     - 명령을 다른 GitLab Duo 사용자 지정 파일과 함께 유지하려면 다음과 같이 수행합니다.
       - Linux 또는 macOS에서 디렉터리를 `~/.gitlab/duo/commands/`에 만듭니다.
       - Windows에서 디렉터리를 `%APPDATA%\GitLab\duo\commands\`에 만듭니다.
       - `GLAB_CONFIG_DIR` 또는 `XDG_CONFIG_HOME`을 설정한 경우 `$GLAB_CONFIG_DIR/commands/` 또는 `$XDG_CONFIG_HOME/gitlab/duo/commands/`을 사용합니다. 둘 다 설정한 경우 `GLAB_CONFIG_DIR`이 우선합니다.
     - 다른 AI 도구와 명령을 공유하려면 다음을 수행합니다.
       - Linux 또는 macOS에서 디렉터리를 `~/.agents/commands/`에 만듭니다.
       - Windows에서 디렉터리를 `%USERPROFILE%\.agents\commands\`에 만듭니다.
1. 디렉터리에서 Markdown 파일을 만듭니다. 파일 이름으로 명령 이름을 사용합니다. 명령 이름은 문자나 숫자로 시작해야 하며 문자, 숫자, 하이픈 및 밑줄만 포함할 수 있습니다.
1. 파일에 프롬프트를 추가합니다.
1. 선택 사항입니다. 파일 상단의 YAML 머리말에 `description` 필드를 추가합니다. 설명은 슬래시 명령 메뉴에서 명령 옆에 나타납니다.

   예를 들어 `daily.md`에서 정의된 `/daily` 명령입니다.

   ```markdown
   ---
   description: Prepare a daily report
   ---

   Use `glab todo list` to fetch my open TODO items. Give me a concise morning report ranked by priority.
   ```

1. GitLab Duo CLI를 다시 시작합니다. CLI는 시작할 때 사용자 지정 슬래시 명령을 검색합니다.

### 사용자 지정 슬래시 명령 사용 {#use-a-custom-slash-command}

대화형 모드에서 프롬프트에 슬래시 명령을 입력하고 <kbd>Enter</kbd>를 누릅니다. GitLab Duo CLI는 파일 내용을 프롬프트로 보냅니다.

명령 이름 뒤에 입력한 모든 텍스트는 프롬프트 끝에 추가됩니다.

추가 텍스트를 사용하여 사용자 지정 슬래시 명령이 수행하는 작업을 사용자 지정합니다.

예를 들어, `/daily prioritize my milestone deliverables`입니다.

## 플러그인 {#plugins}

{{< details >}}

- 상태:  실험적

{{< /details >}}

{{< history >}}

- GitLab Duo CLI 9.10.0에서 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.10.0)되었으며, GitLab 19.3 릴리스 중 [실험](../../policy/development_stages_support.md#experiment)으로 제공됩니다.

{{< /history >}}

플러그인을 사용하여 GitLab Duo CLI를 추가 기능으로 확장합니다.

플러그인은 GitLab Duo CLI을 번들로 제공하는 디렉토리입니다. 플러그인은 [Agent Skills](../duo_agent_platform/customize/agent_skills.md), [사용자 지정 슬래시 명령](#custom-slash-commands) 및 [MCP 서버](../gitlab_duo/model_context_protocol/mcp_clients.md)를 번들로 제공할 수 있습니다.

마켓플레이스는 Git 리포지토리 또는 로컬 디렉토리의 사용 가능한 플러그인 카탈로그입니다. `marketplace.json` 파일은 사용 가능한 플러그인과 위치를 나열합니다.

플러그인을 사용하려면 플러그인을 포함하는 마켓플레이스를 등록한 다음 해당 마켓플레이스에서 플러그인을 설치합니다. 플러그인은 `<plugin>@<marketplace>`로 식별됩니다.

기존 커뮤니티 플러그인 생태계와의 호환성을 위해 GitLab Duo CLI는 `.claude-plugin/marketplace.json` 파일도 읽습니다. 기존 플러그인 마켓플레이스는 GitLab Duo CLI와 수정 없이 작동합니다.

사전 요구 사항:

- [GitLab Duo CLI 설정](set_up.md)합니다.
- Git 리포지토리에서 마켓플레이스를 추가하려면 Git이 필요합니다.

### 마켓플레이스 등록 {#register-a-marketplace}

플러그인을 설치하기 전에 플러그인을 포함하는 마켓플레이스를 등록해야 합니다.

플러그인을 처음 사용할 때 GitLab Duo CLI는 공식 GitLab 마켓플레이스인 [`gitlab-duo-plugins`](https://gitlab.com/gitlab-org/ai/gitlab-duo-plugins)를 자동으로 등록합니다. 이 마켓플레이스를 제거하면 GitLab Duo CLI는 다시 등록하지 않습니다.

마켓플레이스를 등록하려면 다음을 수행합니다.

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace add <source>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace add <source>
```

{{< /tab >}}

{{< /tabs >}}

`<source>`은(는) 다음 중 하나입니다.

| 소스 유형      | 형식                                                                                     | 예제                                          |
|-------------------|---------------------------------------------------------------------------------------------|---------------------------------------------------|
| Git 리포지토리    | `git clone`이(가) 수용하는 URL입니다. 선택 사항으로 `#<ref>`를 추가하여 브랜치 또는 태그를 고정합니다.          | `https://gitlab.com/group/marketplace.git#stable` |
| 로컬 디렉토리   | 절대 또는 상대 경로입니다. `~`은(는) 홈 디렉토리로 확장됩니다.                       | `~/marketplaces/internal`                        |

예를 들어:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace add https://gitlab.com/example-group/example-marketplace.git
```

```shell
glab duo plugin marketplace add ~/marketplaces/internal
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace add https://gitlab.com/example-group/example-marketplace.git
```

```shell
duo plugin marketplace add ~/marketplaces/internal
```

{{< /tab >}}

{{< /tabs >}}

GitLab Duo CLI는 `marketplace.json` 파일의 `name` 필드로 마켓플레이스를 식별합니다.

#### 마켓플레이스에서 플러그인 자동 업데이트 {#automatically-update-plugins-from-a-marketplace}

마켓플레이스에서 설치하는 플러그인을 자동으로 업데이트하려면 `--auto-update` 옵션으로 마켓플레이스를 등록합니다.

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace add <source> --auto-update
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace add <source> --auto-update
```

{{< /tab >}}

{{< /tabs >}}

GitLab Duo CLI가 시작되면 이 마켓플레이스에서 설치한 플러그인을 확인 없이 백그라운드에서 업데이트합니다. 플러그인이 업데이트되면 GitLab Duo CLI에서 새 버전을 로드하기 위해 다시 시작하라는 메시지를 표시합니다.

#### 등록된 마켓플레이스 나열 {#list-registered-marketplaces}

등록한 마켓플레이스를 나열하려면 다음을 수행합니다.

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace list
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace list
```

{{< /tab >}}

{{< /tabs >}}

각 마켓플레이스에 대해 GitLab Duo CLI는 다음을 표시합니다.

- 마켓플레이스 소스입니다.
- 마켓플레이스가 마지막으로 업데이트되었을 때입니다.
- 마켓플레이스가 가지고 있는 플러그인의 개수입니다.
- 마켓플레이스에 대해 자동 업데이트가 사용으로 설정되어 있는지 여부입니다.

#### 사용 가능한 마켓플레이스 플러그인 나열 {#list-available-marketplace-plugins}

마켓플레이스가 제공하는 플러그인을 나열하려면 다음을 수행합니다.

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace show <name>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace show <name>
```

{{< /tab >}}

{{< /tabs >}}

각 플러그인에 대해 GitLab Duo CLI는 버전, 설명 및 플러그인이 설치된 위치(있는 경우)를 표시합니다.

#### 마켓플레이스 업데이트 {#update-a-marketplace}

마켓플레이스의 카탈로그를 소스에서 새로 고치려면 다음을 수행합니다.

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace update <name>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace update <name>
```

{{< /tab >}}

{{< /tabs >}}

#### 마켓플레이스 제거 {#remove-a-marketplace}

등록된 마켓플레이스를 제거하려면 다음을 수행합니다.

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace remove <name>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace remove <name>
```

{{< /tab >}}

{{< /tabs >}}

> [!warning]
> 마켓플레이스를 제거하면 해당 마켓플레이스에서 설치한 모든 플러그인도 제거됩니다.

### 플러그인 설치 및 관리 {#install-and-manage-plugins}

플러그인을 설치할 때 범위를 선택합니다. 범위는 GitLab Duo CLI가 업데이트하는 구성 파일과 설치가 적용되는 대상을 결정합니다.

| 범위               | 구성 파일                          | 용도                                                            |
|----------------------|----------------------------------------------|------------------------------------------------------------------------|
| `user` (기본값)     | `<config dir>/plugins.json`                 | 모든 프로젝트의 플러그인입니다.                                       |
| `project`            | 프로젝트의 `.gitlab/duo/plugins.json`   | 팀이 공유하는 플러그인입니다. 이 파일을 리포지토리에 커밋합니다.           |
| `local`              | 프로젝트의 `.gitlab/duo/plugins.local.json` | 개인별, 프로젝트별 플러그인입니다. 이 파일을 `.gitignore`에 추가합니다. |

`<config dir>`은(는) Linux 및 macOS에서 `~/.gitlab/duo`이고, Windows에서는 `%APPDATA%\GitLab\duo`입니다.

등록된 마켓플레이스에서 플러그인을 설치하려면 다음을 수행합니다.

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin install <plugin>@<marketplace> [--scope user|project|local]
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin install <plugin>@<marketplace> [--scope user|project|local]
```

{{< /tab >}}

{{< /tabs >}}

`--scope`을(를) 지정하지 않으면 GitLab Duo CLI는 `user` 범위를 사용합니다.

예를 들어:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin install my-plugin@my-marketplace
```

```shell
glab duo plugin install my-plugin@my-marketplace --scope project
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin install my-plugin@my-marketplace
```

```shell
duo plugin install my-plugin@my-marketplace --scope project
```

{{< /tab >}}

{{< /tabs >}}

#### 설치 후 사용으로 설정된 상태 {#enabled-state-after-installation}

플러그인을 설치하면 GitLab Duo CLI는 범위의 구성 파일에서 플러그인이 사용으로 설정되어 있는지 기록합니다. 초기 상태를 결정하기 위해 GitLab Duo CLI는 다음 순서로 사용합니다.

1. 대상 범위 또는 더 넓은 범위에서 플러그인에 대해 이전에 기록한 사용하는 또는 사용 중지된 설정입니다. 예를 들어, 플러그인을 사용 중지하고 제거한 다음 다시 설치하면 플러그인은 사용 중지 상태를 유지합니다.
1. 플러그인의 마켓플레이스 카탈로그 항목의 `defaultEnabled` 값입니다.
1. 플러그인의 `plugin.json` 매니페스트의 `defaultEnabled` 값입니다.

이 중 어느 것도 설정되지 않으면 플러그인은 사용됩니다.

#### 설치된 플러그인 나열 {#list-installed-plugins}

설치된 플러그인을 나열하려면 다음을 수행합니다.

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin list
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin list
```

{{< /tab >}}

{{< /tabs >}}

설치된 플러그인은 범위별로 그룹화되며, 목록에는 각 플러그인이 사용으로 설정되어 있는지 표시합니다.

#### 플러그인 사용 또는 사용 중지 {#enable-or-disable-a-plugin}

플러그인을 사용, 사용 중지 또는 제거하면 이름만으로 식별할 수 있습니다. 동일한 플러그인 이름이 두 개 이상의 마켓플레이스에서 설치된 경우 전체 `<plugin>@<marketplace>` 식별자를 사용합니다.

설치된 플러그인을 사용 또는 사용 중지하려면 다음을 수행합니다.

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin enable <plugin> [--scope user|project|local]
glab duo plugin disable <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin enable <plugin> [--scope user|project|local]
duo plugin disable <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< /tabs >}}

플러그인을 여러 범위에서 사용 또는 사용 중지하는 경우, 가장 구체적인 범위가 우선하며 그 순서는 `local`, `project`, `user`입니다.

#### 플러그인 업데이트 {#update-a-plugin}

플러그인을 마켓플레이스에서 사용 가능한 최신 버전으로 업데이트하려면 다음을 수행합니다.

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin update <plugin>@<marketplace>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin update <plugin>@<marketplace>
```

{{< /tab >}}

{{< /tabs >}}

업데이트는 플러그인이 설치된 모든 범위에 적용됩니다.

#### 플러그인 제거 {#uninstall-a-plugin}

플러그인을 제거하려면 다음을 수행합니다.

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin uninstall <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin uninstall <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< /tabs >}}

제거하면 구성에서 플러그인이 제거됩니다.

### 설치된 플러그인 사용 {#use-an-installed-plugin}

플러그인을 설치하고 사용으로 설정한 후에 GitLab Duo CLI는 다음으로 시작될 때 플러그인이 번들로 제공하는 모든 항목을 검색합니다.

- Skills는 다른 Agent Skills과 동일한 방식으로 사용 가능합니다.
- 사용자 지정 슬래시 명령은 슬래시 명령 메뉴에 표시됩니다. 기본 제공 슬래시 명령, Agent Skills 슬래시 명령 및 사용자 지정 슬래시 명령은 동일한 이름의 플러그인 명령보다 우선합니다.
- MCP 서버는 구성한 MCP 서버와 함께 로드되며 동일한 방식으로 [도구 승인](../gitlab_duo/model_context_protocol/mcp_clients.md#configure-tool-approval)을 요구합니다. 서버의 출처를 식별하기 위해 GitLab Duo CLI는 서버 이름 앞에 플러그인 이름을 붙입니다.

### 마켓플레이스 만들기 {#create-a-marketplace}

마켓플레이스를 만들면 Git 리포지토리 또는 로컬 디렉토리의 루트에 `marketplace.json` 파일을 추가합니다. 예를 들어:

```json
{
  "name": "my-marketplace",
  "owner": {
    "name": "Your Name"
  },
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./plugins/my-plugin",
      "description": "A short description of the plugin."
    }
  ]
}
```

`plugins`의 각 항목은 `source`를 `./`로 시작하는 마켓플레이스 루트에 상대적인 경로로 설정해야 합니다.

### 플러그인 만들기 {#create-a-plugin}

플러그인은 선택 사항인 `plugin.json` 매니페스트 및 플러그인이 번들로 제공하는 확장 프로그램(스킬, 사용자 지정 슬래시 명령, MCP 서버)을 포함하는 디렉토리입니다.

`plugin.json` 매니페스트는 다음 필드를 지원합니다.

| 필드             | 필수 | 설명                                              |
|--------------------|----------|--------------------------------------------------------------|
| `name`             | 예      | 플러그인의 이름입니다.                                            |
| `version`          | 아니요       | 플러그인의 버전입니다.                                         |
| `description`      | 아니요       | 플러그인에 대한 간단한 설명입니다.                            |
| `defaultEnabled`   | 아니요       | 플러그인이 설치할 때 기본적으로 사용을 설정되는지 여부입니다.      |

예를 들어:

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "A short description of the plugin.",
  "defaultEnabled": true
}
```

기존 커뮤니티 플러그인과의 호환성을 위해 GitLab Duo CLI는 `.claude-plugin/plugin.json`에서 매니페스트도 읽습니다.

플러그인과 함께 확장을 번들로 제공하려면 다음을 수행합니다.

- Skills: `SKILL.md` 파일을 플러그인의 `skills/<skill-name>/` 디렉토리에 추가합니다. `SKILL.md` 파일 형식은 [기술 만들기](../duo_agent_platform/customize/agent_skills.md#create-skills)를 참조하세요.
- 사용자 지정 슬래시 명령: Markdown 파일을 플러그인의 `commands/` 디렉토리에 추가합니다. 파일 이름은 명령 이름이며, 파일 형식은 [사용자 지정 슬래시 명령](#create-a-custom-slash-command)과 동일합니다.
- MCP 서버: `.mcp.json` 파일을 플러그인의 루트에 추가합니다. 파일 형식은 [MCP 구성 형식](../gitlab_duo/model_context_protocol/mcp_clients.md#configuration-format)과 동일합니다. 플러그인 내부의 파일을 참조하려면 플러그인이 설치된 디렉토리로 확인되는 `${DUO_PLUGIN_ROOT}` 변수를 사용합니다.

예를 들어, skill, 사용자 지정 슬래시 명령, MCP 서버를 번들로 제공하는 하나의 플러그인이 있는 마켓플레이스 리포지토리입니다:

```plaintext
my-marketplace/
├── marketplace.json
└── plugins/
    └── my-plugin/
        ├── plugin.json
        ├── .mcp.json
        ├── commands/
        │   └── my-command.md
        └── skills/
            └── my-skill/
                └── SKILL.md
```

GitLab Duo CLI는 플러그인의 버전을 다음 순서로 결정합니다.

1. 플러그인의 `plugin.json`의 `version` 필드입니다.
1. 마켓플레이스 `marketplace.json`의 플러그인 항목에 있는 `version` 필드입니다.

두 필드가 모두 설정되지 않으면 플러그인의 버전은 `unknown`입니다.

## 관련 항목 {#related-topics}

- [GitLab Duo CLI 전체 참조](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [GitLab Duo Agent Platform 사용자 지정](../duo_agent_platform/customize/_index.md)
- [Agent Skills](../duo_agent_platform/customize/agent_skills.md)

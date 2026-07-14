---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 에이전트 스킬
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 프로젝트 수준의 에이전트 스킬 [추가됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2951) GitLab 18.10.
  - GitLab for VS Code 6.71.4에 [도입됨](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases/v6.71.4).
  - GitLab Duo CLI 8.73.0에 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.73.0).
- GitLab 19.0에 사용자 수준의 에이전트 스킬 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3140).
  - GitLab Duo CLI 8.83.0 [실험](../../../policy/development_stages_support.md#experiment)으로 [도입됨](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.83.0).

{{< /history >}}

GitLab Duo는 [에이전트 스킬 명세](https://agentskills.io/specification)를 지원합니다. 에이전트에 새로운 기능과 전문성을 제공하기 위한 새로운 표준입니다.

에이전트 스킬을 사용하여 특정 작업에 대한 특화된 지식과 워크플로우를 에이전트에 제공합니다. 예를 들어, 특정 프레임워크에서 테스트를 작성하는 경우입니다. 에이전트는 작업을 만날 때마다 관련 스킬을 자동으로 로드하고 작업하면서 정보를 사용합니다.

`SKILL.md` 파일을 지정하면 스킬을 GitLab Duo 에이전트 플랫폼과 명세를 지원하는 다른 AI 도구에서 사용할 수 있습니다.

GitLab Duo에서 에이전트 스킬을 사용하도록 지정합니다:

- 로컬 환경의 GitLab Duo Chat.
- 사용자 지정 플로우 제외하고 기초 및 사용자 지정 플로우, Code Review 플로우 제외.

사용자 수준의 스킬은 GitLab Duo CLI에서만 사용할 수 있습니다.

## GitLab Duo가 에이전트 스킬을 사용하는 방법 {#how-gitlab-duo-uses-agent-skills}

에이전트가 작업을 시작하면 GitLab Duo는 모든 사용 가능한 스킬의 메타데이터를 에이전트의 컨텍스트에 추가합니다. 에이전트가 스킬의 설명과 일치하는 작업을 만나면 스킬을 자동으로 로드하고 이를 사용하여 작업을 완료합니다.

스킬 이름, 파일 경로 또는 슬래시 명령으로 GitLab Duo를 수동으로 지시할 수도 있습니다.

GitLab Duo는 다음 유형의 스킬을 지원합니다:

| 수준                                                              | GitLab UI | 편집기 확장 | GitLab Duo CLI |
|--------------------------------------------------------------------|-------------------------------|-------------------|----------------|
| 사용자 수준: 모든 프로젝트에 적용      | {{< no >}}                    | {{< no >}}        | {{< yes >}}    |
| 프로젝트 수준: 특정 프로젝트에만 적용 | {{< yes >}} <sup>1</sup>                   | {{< yes >}}       | {{< yes >}}    |

**각주**:

1. GitLab UI에서는 기초 및 사용자 지정 플로우(코드 검토 제외)만 프로젝트 수준의 스킬을 지원합니다. GitLab UI의 GitLab Duo Chat은 스킬을 지원하지 않습니다.

## GitLab Duo에서 에이전트 스킬 사용 {#use-agent-skills-with-gitlab-duo}

> [!note]
> 기존 대화와 플로우는 새 스킬이나 업데이트된 스킬에 자동으로 액세스할 수 없습니다. 새 대화를 시작하거나 GitLab Duo에 스킬을 이름이나 상대 경로로 로드하도록 요청합니다.

### 전제 조건 {#prerequisites}

- [에이전트 플랫폼 필수 구성 요소](../_index.md#prerequisites)를 충족합니다.
- 로컬 환경의 GitLab Duo Chat을 위해 다음 중 하나를 설치하고 구성해야 합니다.
  - 프로젝트 수준의 스킬의 경우:
    - [GitLab for VS Code](../../../editor_extensions/visual_studio_code/setup.md) 6.71.4 이상.
    - [GitLab Duo CLI](../../gitlab_duo_cli/_index.md#set-up-the-gitlab-duo-cli) 8.73.0 이상.
  - 사용자 수준의 스킬의 경우:
    - [GitLab Duo CLI](../../gitlab_duo_cli/_index.md#set-up-the-gitlab-duo-cli) 8.83.0 이상.
- 프로젝트 수준의 스킬과 사용자 지정 플로우의 경우 플로우의 구성 파일을 업데이트하여 실행기에서 전달된 `workspace_agent_skills` 컨텍스트에 액세스합니다:

  ```yaml
  components:
  - name: "my_agent"
     type: AgentComponent
     prompt_id: "my_prompt"
     inputs:
     - from: "context:inputs.workspace_agent_skills"
        as: "workspace_agent_skills"
      optional: true
  ```

  `optional: true`을 설정하여 플로우는 에이전트 스킬이 없는 경우를 정상적으로 처리합니다. 에이전트는 추가 컨텍스트와 함께 또는 없이 작동합니다.

### 스킬 생성 {#create-skills}

프로젝트 수준 또는 사용자 수준에서 스킬을 생성할 수 있습니다.

IDE에서 다중 루트 워크스페이스를 사용하는 경우 워크스페이스의 각 프로젝트에 대해 프로젝트 수준의 스킬을 생성할 수 있습니다.

사용자 수준의 스킬과 프로젝트 수준의 스킬이 동일한 이름을 공유하면 프로젝트 수준의 스킬이 우선 순위를 갖습니다. 이를 통해 사용자 수준의 스킬을 프로젝트 특정 버전으로 재정의할 수 있습니다.

다중 루트 워크스페이스에서 여러 프로젝트가 동일한 이름의 스킬을 정의하면 GitLab Duo는 처음 만나는 스킬을 로드합니다.

#### 프로젝트 수준의 스킬 생성 {#create-project-level-skills}

프로젝트 수준의 스킬은 특정 프로젝트에 적용됩니다. 이를 프로젝트의 `skills/<skill-name>/` 디렉터리에 있는 `SKILL.md` 파일로 정의합니다.

프로젝트 수준의 스킬을 생성하려면:

1. 프로젝트의 루트에서 `skills` 디렉터리를 생성합니다.
1. 새 디렉터리에서 특정 스킬을 위한 다른 디렉터리를 생성합니다. 스킬 이름을 디렉터리 이름으로 사용합니다.
1. `SKILL.md` 파일을 생성하고 다음 형식을 사용하여 지침을 포함합니다. `name` 및 `description` YAML 전문 필드가 필수입니다.

   ```markdown
   ---
   name: <skill_name>
   description: <skill_description>
   ---

   <your_instructions_and_context_for_the_skill>
   ```

    예를 들어, `skills/cosign-blob/SKILL.md`에서 [cosign을 사용하여 아티팩트 서명](../../../ci/yaml/signing_examples.md)하는 스킬:

    ````markdown
    ---
    name: cosign-blob
    description: Sign artifacts using cosign with local keypairs and Sigstore v3 bundles. Integrate with 1Password for secure key management.
    ---

    ## Cosign Blob Signing

    Sign artifacts locally using cosign with Sigstore v3 bundles for artifact verification and integrity.

    ### Generate a Local Keypair

    Generate a new cosign keypair:

    ```shell
    cosign generate-key-pair
    ```

    This creates two files:
    - `cosign.key` - Private key (encrypted)
    - `cosign.pub` - Public key

    Store the private key securely, preferably in a password manager like 1Password.

    ### Store Private Key in 1Password

    1. Create a new login item in 1Password with:
      - Title: "Duo Skills cosign"
      - Username: (optional)
      - Password: Your cosign private key password

    2. Save the secret reference path (for example, `op://Employee/Duo Skills cosign/password`)

    ### Sign Artifacts with Cosign

    Sign a file and generate a Sigstore v3 bundle:

    ```shell
    COSIGN_PASSWORD=$(op read "op://Employee/Duo Skills cosign/password") \
      timeout -v 4 cosign sign-blob \
        --key ~/.gitlab/duo/cosign.key \
        --bundle <filename>.bundle \
        --new-bundle-format \
        --yes \
        <filename>
    ```

    Replace:
    - `<filename>` with the file to sign (for example, `SKILL.md`)
    - The bundle output will be saved as `<filename>.bundle`

    ### Key Points

    - Use timeout to fail-fast and report the error back to the user.
    - Use `--bundle` with `$file.bundle` format for Sigstore v3 bundles
    - Use `--yes` to skip interactive prompts
    - Use `--new-bundle-format` to output a v3 Sigstore bundle rather than the legacy format
    - Set `COSIGN_PASSWORD` environment variable to avoid password prompts
    - Integrate with 1Password CLI for secure credential management
    - The bundle file contains the signature and can be verified later
    ````

1. 파일을 저장합니다.
1. 새 대화 또는 플로우를 시작합니다. 에이전트의 컨텍스트 혼동을 피하기 위해 `SKILL.md` 파일을 변경하거나 추가할 때마다 이 작업을 수행해야 합니다.

#### 사용자 수준의 스킬 생성 {#create-user-level-skills}

{{< details >}}

- 상태:  실험적 기능

{{< /details >}}

사용자 수준의 스킬은 모든 프로젝트에 적용됩니다. 이를 홈 디렉터리의 `skills/<skill-name>/` 디렉터리에 있는 `SKILL.md` 파일로 정의합니다.

사용자 수준의 스킬은 GitLab Duo CLI에서만 사용할 수 있습니다.

##### 사용자 수준의 스킬에 대한 디렉터리 생성 {#create-a-directory-for-user-level-skills}

다음 위치 중 하나에서 스킬 디렉터리를 생성할 수 있습니다:

- 스킬을 다른 GitLab Duo 사용자 지정 파일과 함께 보관하려면:
  - Linux 또는 macOS의 경우 `~/.gitlab/duo/skills/`에서 디렉터리를 생성합니다.
  - Windows의 경우 `%APPDATA%\GitLab\duo\skills\`에서 디렉터리를 생성합니다.
  - `GLAB_CONFIG_DIR` 또는 `XDG_CONFIG_HOME`를 설정한 경우 `$GLAB_CONFIG_DIR/skills/` 또는 `$XDG_CONFIG_HOME/gitlab/duo/skills/`를 사용합니다. 둘 다 설정된 경우 `GLAB_CONFIG_DIR`가 우선 순위를 갖습니다.
- 에이전트 스킬 명세를 지원하는 다른 AI 도구와 스킬을 공유하려면:
  - Linux 또는 macOS의 경우 `~/.agents/skills/`에서 디렉터리를 생성합니다.
  - Windows의 경우 `%USERPROFILE%\.agents\skills\`에서 디렉터리를 생성합니다.

##### 사용자 수준의 스킬 파일 생성 {#create-a-user-level-skill-file}

사용자 수준의 스킬을 생성하려면:

1. GitLab Duo CLI를 시작할 때 전역 스킬을 활성화합니다:

   {{< tabs >}}

   {{< tab title="glab" >}}

   ```shell
   glab duo cli --enable-global-skills
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   ```shell
   duo --enable-global-skills
   ```

   {{< /tab >}}

   {{< /tabs >}}

   또는 환경 변수를 설정합니다:

   ```shell
   export GITLAB_ENABLE_GLOBAL_SKILLS=true
   ```

1. `skills` 디렉터리에서 특정 스킬을 위한 다른 디렉터리를 생성합니다. 스킬 이름을 디렉터리 이름으로 사용합니다. 예를 들어, `~/.gitlab/duo/skills/<skill_name>/`입니다.
1. `SKILL.md` 파일을 생성하고 다음 형식을 사용하여 지침을 포함합니다. `name` 및 `description` YAML 전문 필드가 필수입니다.

   ```markdown
   ---
   name: <skill_name>
   description: <skill_description>
   ---

   <your_instructions_and_context_for_the_skill>
   ```

1. 새 대화를 시작합니다. 스킬을 모든 프로젝트에서 사용할 수 있습니다.

#### 슬래시 명령으로 스킬 노출 {#expose-skills-as-slash-commands}

스킬을 사용자 지정 슬래시 명령으로 활성화하려면 `slash-command: enabled`를 `SKILL.md` 파일의 YAML 전문 메타데이터에 추가합니다:

```yaml
---
name: <skill_name>
description: <skill_description>
metadata:
  slash-command: enabled
---
```

메타데이터를 추가한 후 새 세션에서 `/<skill_name>`을 사용하여 GitLab Duo에 스킬 사용을 지시할 수 있습니다. 예를 들어, `/fix-bugs`입니다.

### 스킬 수동 사용 {#use-skills-manually}

GitLab Duo를 특정 스킬 사용으로 지시하려면 다음 방법 중 하나를 사용합니다:

- GitLab Duo에 프롬프트에서 스킬 이름이나 파일 경로로 스킬을 사용하도록 지시합니다.
- 프롬프트를 스킬의 슬래시 명령으로 시작합니다.

현재 세션의 컨텍스트에서 사용 가능한 모든 스킬을 나열하려면 `/skills`을 사용합니다.

## 관련 항목 {#related-topics}

- [사용자 지정 규칙](custom_rules.md)

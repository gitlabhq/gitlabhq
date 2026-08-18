---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Git 서버 훅
description: Git 서버 훅을 구성합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [이름 변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/372991): GitLab 15.6에서 서버 훅에서 Git 서버 훅으로 변경되었습니다.

{{< /history >}}

Git 서버 훅은 GitLab 서버에서 사용자 지정 로직을 실행합니다. 다음과 같은 Git 관련 작업을 실행하는 데 사용할 수 있습니다:

- 특정 커밋 정책을 적용합니다.
- 리포지토리 상태에 따라 작업을 수행합니다.

Git 서버 훅은 `pre-receive`, `post-receive`, `update` Git 서버 측 훅을 사용합니다.

GitLab 관리자는 `gitaly` 명령을 사용하여 서버 훅을 구성하며, 이는 다음과 같은 역할을 합니다:

- Gitaly 서버를 시작하는 데 사용됩니다.
- 여러 하위 명령을 제공합니다.
- Gitaly gRPC API에 연결합니다.

`gitaly` 명령에 액세스할 수 없는 경우 서버 훅의 대안은 다음과 같습니다:

- [웹후크](../user/project/integrations/webhooks.md).
- [GitLab CI/CD](../ci/_index.md).
- [푸시 규칙](../user/project/repository/push_rules.md)(사용자 지정 가능한 Git 훅 인터페이스용).

GitLab Helm 차트 인스턴스의 경우 [Gitaly 차트의 전역 서버 훅](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#global-server-hooks)에 대한 정보를 참조하세요.

> [!note]
> [Geo](geo/_index.md)는 서버 훅을 보조 노드에 복제하지 않습니다.

## 전제 조건 {#prerequisites}

- [스토리지 이름](gitaly/configure_gitaly.md#gitlab-requires-a-default-repository-storage), Gitaly 구성 파일의 경로(Linux 패키지 인스턴스의 기본값은 `/var/opt/gitlab/gitaly/config.toml`), [리포지토리 상대 경로](repository_storage_paths.md#from-project-name-to-hashed-path)(리포지토리용).
- 훅에 필요한 모든 언어 런타임 및 유틸리티를 Gitaly를 실행하는 각 서버에 설치해야 합니다.

## 리포지토리의 서버 훅 설정 {#set-server-hooks-for-a-repository}

리포지토리의 서버 훅을 설정하려면:

1. 사용자 지정 훅을 포함하는 타르볼을 생성합니다:
   1. 서버 훅이 예상대로 작동하도록 하려면 코드를 작성합니다. Git 서버 훅은 모든 프로그래밍 언어로 작성할 수 있습니다. 상단의 shebang이 언어 유형을 반영하는지 확인합니다. 예를 들어 스크립트가 Ruby이면 shebang은 아마도 `#!/usr/bin/env ruby`입니다.

      - 단일 서버 훅을 생성하려면 훅 유형과 일치하는 이름의 파일을 생성합니다. 예를 들어 `pre-receive` 서버 훅의 경우 파일 이름은 `pre-receive`이고 확장명이 없어야 합니다.
      - 많은 서버 훅을 생성하려면 훅 유형과 일치하는 훅의 디렉터리를 생성합니다. 예를 들어 `pre-receive` 서버 훅의 경우 디렉터리 이름은 `pre-receive.d`이어야 합니다. 해당 디렉터리에 훅의 파일을 배치합니다.

   1. 서버 훅 파일이 실행 가능하고 백업 파일 패턴(`*~`)과 일치하지 않는지 확인합니다. 서버 훅은 타르볼의 루트에 있는 `custom_hooks` 디렉터리에 있어야 합니다.
   1. tar 명령으로 사용자 지정 훅 아카이브를 생성합니다. 예를 들어, `tar -cf custom_hooks.tar custom_hooks`.
1. `hooks set` 하위 명령을 실행하고 필요한 옵션을 사용하여 리포지토리의 Git 훅을 설정합니다. 예를 들어:

   ```shell
   cat custom_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>
   ```

   - 노드에 연결하기 위해 유효한 Gitaly 구성에 대한 경로가 필요하며 `--config` 플래그에 제공됩니다.
   - 사용자 지정 훅 타르볼은 `stdin`을(를) 통해 전달되어야 합니다. 예를 들어:

     ```shell
     cat custom_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>
     ```

1. Gitaly Cluster(Praefect)를 사용하는 경우 모든 Gitaly 노드에서 `hooks set` 하위 명령을 실행해야 합니다.

서버 훅 코드를 올바르게 구현했다면 Git 훅이 다음에 트리거될 때 실행되어야 합니다.

### Gitaly Cluster(Praefect)의 서버 훅 {#server-hooks-on-a-gitaly-cluster-praefect}

Gitaly Cluster(Praefect)를 사용하는 경우 개별 리포지토리가 Praefect의 여러 Gitaly 스토리지에 복제될 수 있습니다. 따라서 훅 스크립트는 리포지토리의 복제본이 있는 모든 Gitaly 노드에 복사되어야 합니다. 이를 수행하려면 해당 버전의 사용자 지정 리포지토리 훅 설정을 위해 동일한 단계를 따르고 각 스토리지에 대해 반복합니다.

스크립트를 복사할 위치는 리포지토리가 저장되는 위치에 따라 달라집니다. 새 리포지토리는 Praefect 생성 복제 경로를 사용하여 생성되며, 이는 해시된 스토리지 경로가 아닙니다. 복제 경로를 식별하려면 [Praefect 리포지토리 메타데이터를 쿼리](gitaly/praefect/troubleshooting.md#view-repository-metadata)하고 `-relative-path` 옵션을 사용하여 예상된 GitLab 해시된 스토리지 경로를 지정합니다.

## 모든 리포지토리의 전역 서버 훅 생성 {#create-global-server-hooks-for-all-repositories}

모든 리포지토리에 적용되는 Git 훅을 생성하려면 전역 서버 훅을 설정합니다. 전역 서버 훅은 다음에도 적용됩니다:

- 프로젝트 및 그룹 wiki 리포지토리. 스토리지 디렉터리 이름은 `<id>.wiki.git` 형식입니다.
- 프로젝트의 설계 관리 리포지토리. 스토리지 디렉터리 이름은 `<id>.design.git` 형식입니다.

### 서버 훅 디렉터리 선택 {#choose-a-server-hook-directory}

전역 서버 훅을 생성하기 전에 디렉터리를 선택해야 합니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

디렉터리는 `gitlab.rb`의 `gitaly['configuration'][:hooks][:custom_hooks_dir]`에서 설정됩니다. 다음 중 하나를 수행할 수 있습니다:

- `/var/opt/gitlab/gitaly/custom_hooks` 디렉터리의 기본 제안을 사용하여 주석 처리를 제거합니다.
- 자신의 설정을 추가합니다.

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

- 디렉터리는 `gitaly/config.toml`의 `[hooks]` 섹션에서 설정됩니다. 그러나 GitLab은 `gitaly/config.toml`의 값이 비어 있거나 존재하지 않으면 `gitlab-shell/config.yml`의 `custom_hooks_dir` 값을 사용합니다.
- 기본 디렉터리는 `/home/git/gitlab-shell/hooks`입니다.

{{< /tab >}}

{{< /tabs >}}

### 전역 서버 훅 생성 {#create-the-global-server-hook}

모든 리포지토리의 전역 서버 훅을 생성하려면:

1. GitLab 서버에서 구성된 전역 서버 훅 디렉터리로 이동합니다.
1. 구성된 전역 서버 훅 디렉터리에서 훅 유형과 일치하는 훅의 디렉터리를 생성합니다. 예를 들어 `pre-receive` 서버 훅의 경우 디렉터리 이름은 `pre-receive.d`이어야 합니다.
1. 이 새 디렉터리 내에 서버 훅을 추가합니다. Git 서버 훅은 모든 프로그래밍 언어로 작성할 수 있습니다. 상단의 shebang(`#!`)이 언어 유형을 반영하는지 확인합니다. 예를 들어 스크립트가 Ruby이면 shebang은 아마도 `#!/usr/bin/env ruby`입니다.
1. 훅 파일을 실행 가능하게 하고, Git 사용자가 소유하도록 확인하고, 백업 파일 패턴(`*~`)과 일치하지 않도록 확인합니다.

서버 훅 코드를 올바르게 구현했다면 Git 훅이 다음에 트리거될 때 실행되어야 합니다. 훅은 훅 유형 하위 디렉터리의 파일명 알파벳 순서로 실행됩니다.

## 리포지토리의 서버 훅 제거 {#remove-server-hooks-for-a-repository}

서버 훅을 제거하려면 리포지토리에 훅이 없어야 함을 나타내기 위해 `hook set`에 빈 타르볼을 전달합니다. 예를 들어:

```shell
cat empty_hooks.tar | sudo -u git -- /opt/gitlab/embedded/bin/gitaly hooks set --storage <storage> --repository <relative path> --config <config path>
```

## 연결된 서버 훅 {#chained-server-hooks}

GitLab은 서버 훅을 체인 방식으로 실행할 수 있습니다. GitLab은 다음 순서로 서버 훅을 검색하고 실행합니다:

- 기본 제공 GitLab 서버 훅. 이 서버 훅은 사용자가 사용자 지정할 수 없습니다.
- `<project>.git/custom_hooks/<hook_name>`:  프로젝트별 훅. 이 위치는 이전 버전과의 호환성을 위해 유지됩니다.
- `<project>.git/custom_hooks/<hook_name>.d/*`:  프로젝트별 훅의 위치.
- `<custom_hooks_dir>/<hook_name>.d/*`:  편집기 백업 파일을 제외한 모든 실행 가능한 전역 훅 파일의 위치.

서버 훅 디렉터리에서 훅은:

- 알파벳 순서로 실행됩니다.
- 훅이 0이 아닌 값으로 종료되면 실행이 중지됩니다.

## 서버 훅에서 사용 가능한 환경 변수 {#environment-variables-available-to-server-hooks}

서버 훅에 환경 변수를 전달할 수 있지만 지원되는 환경 변수만 사용해야 합니다.

다음 GitLab 환경 변수는 모든 서버 훅에 대해 지원됩니다:

| 환경 변수 | 설명 |
|:---------------------|:------------|
| `GL_ID`              | 푸시를 시작한 사용자 또는 SSH 키의 GitLab 식별자. 예를 들어 `user-2234` 또는 `key-4`. |
| `GL_PROJECT_PATH`    | GitLab 프로젝트 경로. |
| `GL_PROTOCOL`        | 이 변경에 사용된 프로토콜. 다음 중 하나:  `http`(HTTP를 사용한 Git `push`), `ssh`(SSH를 사용한 Git `push`), 또는 `web`(모든 다른 작업). |
| `GL_REPOSITORY`      | `project-` 접두사가 있는 GitLab 프로젝트 ID. 예를 들어 `project-1234` |
| `GL_USERNAME`        | 푸시를 시작한 사용자의 GitLab 사용자 이름. |

다음 Git 환경 변수는 `pre-receive` 및 `post-receive` 서버 훅에 대해 지원됩니다:

| 환경 변수               | 설명 |
|:-----------------------------------|:------------|
| `GIT_ALTERNATE_OBJECT_DIRECTORIES` | [격리 환경](https://git-scm.com/docs/git-receive-pack#_quarantine_environment)의 대체 객체 디렉터리. |
| `GIT_OBJECT_DIRECTORY`             | 격리 환경의 GitLab 프로젝트 경로. |
| `GIT_PUSH_OPTION_COUNT`            | [푸시 옵션](../topics/git/commit.md#push-options)의 수. |
| `GIT_PUSH_OPTION_<i>`              | 특정 푸시 옵션의 값. `<i>`은 `0`에서 `GIT_PUSH_OPTION_COUNT`에 정의된 값보다 하나 적은 값까지입니다. |

## 사용자 지정 오류 메시지 {#custom-error-messages}

서버 훅이 푸시를 거부할 때 사용자가 푸시가 거부된 이유와 문제를 해결하는 방법을 이해할 수 있도록 명확한 오류 메시지를 제공합니다. 사용자 지정 오류 메시지는 GitLab UI 및 훅이 푸시를 거부할 때 사용자의 터미널에 나타납니다.

사용자 지정 오류 메시지가 없으면 사용자는 `(pre-receive hook declined)`과(와) 같은 일반 메시지만 표시됩니다. 명확한 오류 메시지는 사용자를 돕습니다:

- 푸시가 거부된 이유를 이해합니다.
- 관리자에게 연락하지 않고 문제를 해결합니다.
- 지원 요청을 줄입니다.

사용자 지정 오류 메시지를 표시하려면 스크립트가 다음을 수행해야 합니다:

- 사용자 지정 오류 메시지를 스크립트의 `stdout` 또는 `stderr`로 보냅니다.
- 각 메시지에 `GL-HOOK-ERR:` 접두사를 붙이고 접두사 앞에 문자가 없어야 합니다.

예를 들어:

```shell
# Bad: Generic message
echo "GL-HOOK-ERR: Commit rejected.";

# Good: Specific message with action
echo "GL-HOOK-ERR: Commit rejected: Commit message must include an issue reference (for example, #1234).";
```

## 관련 항목 {#related-topics}

- [시스템 훅](system_hooks.md)
- [파일 훅](file_hooks.md)
- [Praefect 생성 복제 경로](gitaly/praefect/_index.md#praefect-generated-replica-paths)

## 문제 해결 {#troubleshooting}

Git 서버 훅을 사용할 때 다음 문제가 발생할 수 있습니다.

### 오류: `pre-receive hook declined` {#error-pre-receive-hook-declined}

사용자가 GitLab 리포지토리에 푸시할 때 `(pre-receive hook declined)`을(를) 포함하는 오류 메시지가 표시될 수 있습니다. 예를 들어:

```plaintext
! [remote rejected] main (pre-receive hook declined)
error: failed to push some refs to 'https://gitlab.example.com/group/project'
```

이 오류는 사전 수신 훅이 푸시를 거부했음을 나타냅니다. 사전 수신 훅은 리포지토리의 참조가 업데이트되기 전에 실행됩니다. Git은 푸시를 거부할 수 있는 세 개의 서버 측 훅을 제공합니다:

- `pre-receive`:  참조가 업데이트되기 전에 실행됩니다. 전체 푸시를 거부할 수 있습니다.
- `update`:  업데이트되는 각 브랜치마다 한 번 실행됩니다. 개별 브랜치를 거부할 수 있습니다.
- `post-receive`:  모든 참조가 업데이트된 후 실행됩니다. 푸시를 거부할 수 없지만 훅이 실패하면 오류를 발생할 수 있습니다.

`(pre-receive hook declined)` 오류는 일반적으로 `pre-receive` 또는 `update` 훅에서 발생합니다. 문제를 식별하려면:

1. `(pre-receive hook declined)` 메시지 바로 앞의 출력을 확인합니다. 출력에는 푸시가 거부된 이유에 대한 정보가 포함되어 있습니다. 예를 들어:

   ```plaintext
   remote: GitLab: The default branch of a project cannot be deleted.
   ! [remote rejected] main (pre-receive hook declined)
   ```

1. 훅이 실패한 이유에 대한 자세한 정보는 Gitaly 로그를 확인합니다:

   ```shell
   sudo grep PreReceiveHook /var/log/gitlab/gitaly/current | jq .
   ```

1. 리포지토리에 사용자 지정 서버 훅이 구성되어 있으면 사용자 지정 훅 코드에서 문제를 검토합니다.

다음은 사전 수신 훅 실패의 일반적인 원인입니다:

- 기본 브랜치 보호:  기본 브랜치를 삭제하거나 강제 업데이트하는 푸시는 거부됩니다. 이는 원본 리포지토리의 기본 브랜치가 대상 리포지토리와 다를 때 `git push --mirror`에서 발생합니다.
- 푸시 규칙:  푸시가 커밋 메시지 요구 사항, 파일 크기 제한, 작성자 이메일 제한 등의 구성된 푸시 규칙을 위반합니다.
- 사용자 지정 서버 훅:  사용자 지정 서버 훅 스크립트가 푸시를 거부했습니다. 사용자 지정 훅 코드와 오류 메시지를 검토합니다.
- 시간 초과:  훅을 실행하는 데 너무 오래 걸려 중단되었습니다. 시간 초과 오류는 Gitaly 로그를 확인합니다.
- LFS 객체:  필요한 Git LFS 객체가 리포지토리에서 누락되었습니다.

사용자가 훅 실패를 이해하도록 돕기 위해 [사용자 지정 오류 메시지](#custom-error-messages)를 사용하여 푸시가 거부된 이유에 대한 명확한 피드백을 제공합니다. 사용자 지정 오류 메시지는 GitLab UI 및 사용자의 터미널에 나타납니다.

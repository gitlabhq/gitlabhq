---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 새로운 러너 등록 워크플로우로 마이그레이션
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!disclaimer]

GitLab 16.0에서는 러너 인증 토큰을 사용하여 러너를 등록하는 새로운 러너 생성 워크플로우를 도입했습니다. 등록 토큰을 사용하는 레거시 워크플로우는 권장되지 않습니다. 대신 [러너 생성 워크플로우](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)를 사용하세요.

새로운 워크플로우의 현재 개발 상태에 대한 정보는 [에픽 7663](https://gitlab.com/groups/gitlab-org/-/epics/7663)을 참조하세요.

새로운 아키텍처의 기술적 설계 및 이유에 대한 정보는 [다음 GitLab Runner 토큰 아키텍처](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/runner_tokens/)를 참조하세요.

새로운 러너 등록 워크플로우에 문제가 있거나 우려 사항이 있거나 추가 정보가 필요한 경우 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/387993)에서 알려주세요.

## 새로운 러너 등록 워크플로우 {#the-new-runner-registration-workflow}

새로운 러너 등록 워크플로우의 경우 다음을 수행합니다:

1. [러너 생성](runners_scope.md)하거나 [프로그래밍 방식으로](#creating-runners-programmatically) GitLab UI에서 직접 수행합니다.
1. 러너 인증 토큰을 받습니다.
1. 이 구성으로 러너를 등록할 때 등록 토큰 대신 러너 인증 토큰을 사용합니다. 여러 호스트에 등록된 러너 매니저는 GitLab UI의 동일한 러너 아래에 나타나지만 고유한 시스템 ID가 있습니다.

새로운 러너 등록 워크플로우의 장점은 다음과 같습니다:

- 러너에 대한 소유권 기록을 유지하고 사용자에게 미치는 영향을 최소화합니다.
- 고유한 시스템 ID를 추가하면 여러 러너에서 동일한 인증 토큰을 재사용할 수 있습니다. 자세한 내용은 [GitLab Runner 구성 재사용](https://docs.gitlab.com/runner/fleet_scaling/#reusing-a-gitlab-runner-configuration)을 참조하세요.

## 계획된 변경 사항의 예상 기간 {#estimated-time-frame-for-planned-changes}

- GitLab 15.10 이상에서는 새로운 러너 등록 워크플로우를 사용할 수 있습니다.

## 러너 등록 워크플로우 손상 방지 {#prevent-your-runner-registration-workflow-from-breaking}

GitLab 16.11 이전 버전에서는 레거시 러너 등록 워크플로우를 사용할 수 있습니다.

GitLab 17.0 이상에서는 인스턴스 관리자 또는 그룹 소유자가 레거시 러너 등록 워크플로우를 비활성화할 수 있습니다. 자세한 내용은 [GitLab 17.0 이후 등록 토큰 사용](#using-registration-tokens-after-gitlab-170)을 참조하세요.

새로운 워크플로우로 마이그레이션하지 않고 러너를 등록하면 러너 등록이 손상되고 `gitlab-runner register` 명령이 `410 Gone - runner registration disallowed` 오류를 반환합니다.

손상된 워크플로우를 방지하려면 다음을 수행해야 합니다:

1. [러너 생성](runners_scope.md)하고 인증 토큰을 얻습니다.
1. 러너 등록 워크플로우의 등록 토큰을 인증 토큰으로 바꿉니다.

## GitLab 17.0 이후 등록 토큰 사용 {#using-registration-tokens-after-gitlab-170}

GitLab 17.0 이후에도 등록 토큰을 계속 사용하려면:

- GitLab.com에서 최상위 그룹 설정의 [레거시 러너 등록 프로세스 활성화](runners_scope.md#enable-use-of-runner-registration-tokens-in-projects-and-groups)를 수동으로 수행할 수 있습니다.
- GitLab Self-Managed에서는 **운영자** 영역 설정의 [레거시 러너 등록 프로세스 활성화](../../administration/settings/continuous_integration.md#control-runner-registration)를 수동으로 수행할 수 있습니다.

## 기존 러너에 미치는 영향 {#impact-on-existing-runners}

기존 러너는 GitLab 17.0으로 업그레이드한 후에도 계속 정상적으로 작동합니다. 이 변경은 새로운 러너 등록에만 영향을 미칩니다.

[GitLab Runner Helm 차트](https://docs.gitlab.com/runner/install/kubernetes/)는 작업이 실행될 때마다 새로운 러너 포드를 생성합니다. 이러한 러너의 경우 [레거시 러너 등록 활성화](#using-registration-tokens-after-gitlab-170)하여 등록 토큰을 사용합니다.

## `gitlab-runner register` 명령 구문 변경 {#changes-to-the-gitlab-runner-register-command-syntax}

`gitlab-runner register` 명령은 등록 토큰 대신 러너 인증 토큰을 허용합니다. **러너** 페이지의 **운영자** 영역에서 토큰을 생성할 수 있습니다. 러너 인증 토큰은 `glrt-` 접두사로 식별할 수 있습니다.

GitLab UI에서 러너를 생성할 때 이전에 `gitlab-runner register` 명령으로 프롬프트된 명령줄 옵션이었던 구성 값을 지정합니다.

러너 인증 토큰을 다음으로 지정하는 경우:

- `--token` 명령줄 옵션이면 `gitlab-runner register` 명령이 구성 값을 허용하지 않습니다.
- `--registration-token` 명령줄 옵션이면 `gitlab-runner register` 명령이 구성 값을 무시합니다.

| 토큰                                  | 등록 명령 |
|----------------------------------------|----------------------|
| 러너 인증 토큰            | `gitlab-runner register --token $RUNNER_AUTHENTICATION_TOKEN` |
| 러너 등록 토큰(레거시)     | `gitlab-runner register --registration-token $RUNNER_REGISTRATION_TOKEN <runner configuration arguments>` |

인증 토큰에는 `glrt-` 접두사가 있습니다.

자동화 워크플로우의 최소 중단을 보장하기 위해 러너 인증 토큰이 레거시 매개변수 `--registration-token`에서 지정되면 [레거시 호환 등록 처리](https://docs.gitlab.com/runner/register/#legacy-compatible-registration-process)가 트리거됩니다.

GitLab 15.9의 예제 명령:

```shell
gitlab-runner register \
    --non-interactive \
    --executor "shell" \
    --url "https://gitlab.com/" \
    --tag-list "shell,mac,gdk,test" \
    --run-untagged "false" \
    --locked "false" \
    --access-level "not_protected" \
    --registration-token "REDACTED"
```

GitLab 15.10 이상에서는 UI에서 러너를 생성하고 태그 목록, 잠금 상태 및 액세스 수준과 같은 속성을 설정할 수 있습니다. GitLab 15.11 이상에서는 `glrt-` 접두사가 있는 러너 인증 토큰이 지정되면 이러한 속성이 더 이상 `register`에 대한 인수로 허용되지 않습니다.

다음 예제는 새 명령을 보여줍니다:

```shell
gitlab-runner register \
    --non-interactive \
    --executor "shell" \
    --url "https://gitlab.com/" \
    --token "REDACTED"
```

## 자동 크기 조정에 미치는 영향 {#impact-on-autoscaling}

GitLab Runner 운영자 또는 GitLab Runner Helm 차트와 같은 자동 크기 조정 시나리오에서 UI에서 생성된 러너 인증 토큰이 등록 토큰을 대체합니다. 이는 각 작업에 대해 러너를 생성하는 대신 동일한 러너 구성이 작업 전반에서 재사용됨을 의미합니다. 특정 러너는 러너 프로세스가 시작될 때 생성되는 고유한 시스템 ID로 식별할 수 있습니다.

## 러너 프로그래밍 방식으로 생성 {#creating-runners-programmatically}

GitLab 15.11 이상에서는 [POST /user/runners REST API](../../api/users.md#create-a-runner-linked-to-a-user)를 사용하여 인증된 사용자로 러너를 생성할 수 있습니다. 이는 러너 구성이 동적이거나 재사용 가능하지 않은 경우에만 사용해야 합니다. 러너 구성이 정적이면 기존 러너의 러너 인증 토큰을 재사용해야 합니다.

러너 생성 및 등록을 자동화하는 방법에 대한 지침은 [러너 생성 및 등록 자동화](../../tutorials/automate_runner_creation/_index.md) 튜토리얼을 참조하세요.

## Helm 차트를 사용한 GitLab Runner 설치 {#installing-gitlab-runner-with-helm-chart}

러너 등록 토큰이 비활성화되면 러너 등록 중에 설정할 수 없는 여러 러너 구성 옵션이 있습니다. 이러한 옵션은 다음으로만 구성할 수 있습니다:

- UI에서 러너를 생성할 때입니다.
- `user/runners` REST API 엔드포인트를 사용합니다.

다음 구성 옵션은 이 시나리오에서 [`values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/main/values.yaml)에서 지원되지 않습니다:

```yaml
## If a runner authentication token is specified in runnerRegistrationToken, the registration will succeed, however the
## other values will be ignored.
runnerRegistrationToken: ""
locked: true
tags: ""
maximumTimeout: ""
runUntagged: true
protected: true
```

Kubernetes의 GitLab Runner에서 Helm 배포는 러너 인증 토큰을 러너 워커 포드로 전달하고 러너 구성을 생성합니다. GitLab 17.0 이상에서는 GitLab.com에 연결된 Kubernetes 호스팅 러너에서 `runnerRegistrationToken` 토큰 필드를 사용하면 러너 워커 포드가 생성 중에 레거시 등록 API 메서드를 사용하려고 시도합니다.

잘못된 `runnerRegistrationToken` 필드를 `runnerToken` 필드로 바꿉니다. `secrets`에 저장된 러너 인증 토큰도 수정해야 합니다.

레거시 러너 등록 워크플로우에서는 필드가 다음과 같이 지정되었습니다:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-runner-secret
type: Opaque
data:
  runner-registration-token: "REDACTED" # DEPRECATED, set to ""
  runner-token: ""
```

새로운 러너 등록 워크플로우에서는 `runner-token`를 대신 사용해야 합니다:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-runner-secret
type: Opaque
data:
  runner-registration-token: "" # need to leave as an empty string for compatibility reasons
  runner-token: "REDACTED"
```

> [!note]
> 비밀 관리 솔루션이 `runner-registration-token`에 대해 빈 문자열을 설정하도록 허용하지 않으면 모든 문자열로 설정할 수 있습니다. 이 값은 `runner-token`이 있을 때 무시됩니다.

## 알려진 이슈 {#known-issues}

### 러너 세부 정보 페이지에 포드 이름이 표시되지 않음 {#pod-name-is-not-visible-in-runner-details-page}

새로운 등록 워크플로우를 사용하여 Helm 차트로 러너를 등록할 때 러너 세부 정보 페이지에 포드 이름이 나타나지 않습니다. 자세한 내용은 [이슈 423523](https://gitlab.com/gitlab-org/gitlab/-/issues/423523)을 참조하세요.

### 러너 인증 토큰이 회전할 때 업데이트되지 않음 {#runner-authentication-token-does-not-update-when-rotated}

#### 여러 러너 매니저에 등록된 동일한 러너로 토큰 회전 {#token-rotation-with-the-same-runner-registered-in-multiple-runner-managers}

자동 토큰 회전을 통해 새로운 워크플로우로 여러 호스트 머신에 러너를 등록할 때 첫 번째 러너 매니저만 새 토큰을 받습니다. 나머지 러너 매니저는 계속해서 유효하지 않은 토큰을 사용하며 연결이 끊깁니다. 이러한 매니저를 수동으로 업데이트하여 새 토큰을 사용해야 합니다.

#### GitLab 운영자의 토큰 회전 {#token-rotation-in-gitlab-operator}

새로운 워크플로우를 통해 GitLab 운영자로 러너를 등록하는 동안 사용자 지정 리소스 정의의 러너 인증 토큰은 토큰 회전 중에 업데이트되지 않습니다. 이는 다음 경우에 발생합니다:

- 비밀에서 `glrt-`로 접두사가 지정된 러너 인증 토큰을 사용 중이며 [사용자 지정 리소스 정의로 참조됨](https://docs.gitlab.com/runner/install/operator/#install-gitlab-runner).
- 러너 인증 토큰이 만료될 예정입니다. 러너 인증 토큰 만료에 대한 자세한 내용은 [인증 토큰 보안](configure_runners.md#authentication-token-security)을 참조하세요.

자세한 내용은 [이슈 186](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/186)을 참조하세요.

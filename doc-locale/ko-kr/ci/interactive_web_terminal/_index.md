---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 대화형 웹 터미널
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

대화형 웹 터미널은 CI 파이프라인의 일회성 명령을 실행하기 위해 GitLab의 터미널에 접근합니다. SSH로 디버깅하는 방법과 비슷하지만, 작업 페이지에서 직접 수행합니다. [GitLab Runner](https://docs.gitlab.com/runner/)가 배포된 환경에 사용자 셸 액세스 권한을 부여하므로, 사용자를 보호하기 위해 일부 [보안 예방 조치](../../administration/integration/terminal.md#security)를 취했습니다.

> [!note]
> [GitLab.com의 인스턴스 러너](../runners/_index.md)는 대화형 웹 터미널을 제공하지 않습니다. [이 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/24674)를 팔로우하여 지원 추가 진행 상황을 확인할 수 있습니다. GitLab.com에 호스팅된 그룹 및 프로젝트의 경우, 자신의 그룹 또는 프로젝트 러너를 사용할 때 대화형 웹 터미널을 사용할 수 있습니다.

## 구성 {#configuration}

대화형 웹 터미널이 작동하려면 두 가지를 구성해야 합니다:

- 러너에 [`[session_server]` 설정이 올바르게](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-session_server-section) 되어 있어야 합니다.
- GitLab 인스턴스와 함께 역방향 프록시를 사용하는 경우 웹 터미널을 [활성화](../../administration/integration/terminal.md#enabling-and-disabling-terminal-support)해야 합니다.

### Helm 차트에 대한 부분 지원 {#partial-support-for-helm-chart}

대화형 웹 터미널은 `gitlab-runner` Helm 차트에서 부분적으로 지원됩니다. 다음의 경우에 활성화됩니다:

- 복제본의 수가 1개일 때
- `loadBalancer` 서비스를 사용할 때

이러한 제한 사항을 수정하기 위한 지원은 다음 이슈에서 추적됩니다:

- [두 개 이상의 복제본 지원](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/323)
- [더 많은 서비스 유형 지원](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/324)

## 실행 중인 작업 디버깅 {#debugging-a-running-job}

> [!note]
> 모든 실행기가 [지원되지는 않습니다](https://docs.gitlab.com/runner/executors/#compatibility-chart).
>
> `docker` 실행기는 빌드 스크립트가 완료된 후 계속 실행되지 않습니다. 이 시점에서 터미널은 자동으로 연결이 끊기고 사용자가 완료할 때까지 기다리지 않습니다. [이 이슈](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3605)를 팔로우하여 이 동작 개선에 대한 업데이트를 받을 수 있습니다.

때로는 작업이 실행 중일 때 예상대로 진행되지 않을 수 있습니다. 디버깅을 돕기 위해 셸에 액세스할 수 있으면 도움이 됩니다. 작업이 실행되면 오른쪽 패널에 `debug` 버튼({{< icon name="external-link" >}})이 표시되어 현재 작업의 터미널을 엽니다. 작업을 시작한 사람만 이를 디버깅할 수 있습니다.

![터미널을 사용 가능한 작업 실행 예제](img/interactive_web_terminal_running_job_v17_3.png)

선택하면 터미널 페이지의 새 탭이 열리며, 여기서 터미널에 액세스하고 표준 셸처럼 명령을 입력할 수 있습니다.

![작업의 터미널 페이지에서 명령 실행](img/interactive_web_terminal_page_v11_1.png)

작업이 완료된 후 터미널이 열려 있으면, 구성된 [`[session_server].session_timeout`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-session_server-section) 지속 시간이 경과할 때까지 작업이 완료되지 않습니다. 이를 방지하려면 작업이 완료된 후 터미널을 닫을 수 있습니다.

![활성 터미널 세션이 있는 완료된 작업](img/finished_job_with_terminal_open_v11_2.png)

---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab.com 또는 GitLab Self-Managed에서 GitLab Ultimate 평가판을 시작합니다.
title: Ultimate 평가판
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

GitLab Ultimate 티어의 평가판 라이선스를 받을 수 있습니다.

평가판 기간 동안 거의 모든 Ultimate 기능에 액세스할 수 있습니다.

Ultimate 평가판 라이선스는 30일 동안 유효합니다.

평가판은 활성화 코드가 포함된 확인 이메일을 받을 때 시작되며, 활성화할 때가 아닙니다.

평가판 기간이 끝나면 유료 기능에 대한 액세스가 차단됩니다. 액세스를 유지하려면 [구독 구매](manage_subscription.md#buy-a-subscription)할 수 있습니다.

## GitLab Ultimate Duo Agent Platform 평가판 {#gitlab-duo-agent-platform-trials}

전제 조건:

- GitLab Self-Managed의 경우 GitLab 18.9 이상이 필요합니다.
- GitLab.com의 경우 평가판이 2026년 2월 10일 이후에 시작해야 합니다.

Free 티어에 있고 Ultimate 평가판을 시작하는 경우, 평가판에 사용자당 24개의 [GitLab Credits](gitlab_credits.md#included-credits)가 포함됩니다. 크레딧을 사용하여 GitLab Ultimate Duo Agent Platform 기능을 테스트할 수 있습니다.

GitLab.com의 경우 이미 [월간 약정 풀을 구매](gitlab_credits.md#for-the-free-tier)한 경우 평가판 기간 동안 추가 크레딧이 할당되지 않습니다. 평가판 기간 동안 사용된 크레딧은 풀에서 차감됩니다.

크레딧은 평가판 기간(30일) 동안 유효합니다. 사용하지 않은 크레딧은 구독을 구매하거나 평가판이 끝날 때 이월되지 않습니다. 평가판이 끝나기 전에 포함된 모든 크레딧을 사용하면 추가 크레딧을 받을 수 없습니다.

[기본 GitLab Ultimate Duo 네임스페이스](../user/profile/preferences.md#set-a-default-gitlab-duo-namespace)를 설정하지 않은 경우 평가판 기간 동안 프록시 엔드포인트 사용이 필요한 AI 기능을 사용할 수 없습니다. 이는 외부 에이전트 및 직접 `/v1/proxy` API 호출(예: CLI, IDE 또는 GitLab 토큰으로 프록시를 호출하는 사용자 지정 스크립트)을 포함합니다. 이 제한은 에이전틱 채트 또는 사용자 지정 및 기본 에이전트 및 플로우에 영향을 미치지 않습니다.

크레딧이 포함되지 않은 평가판을 이미 시작하거나 완료한 경우 새로운 평가판을 시작할 수 있습니다:

- 평가판이 만료되었으면 즉시 새로운 평가판을 시작할 수 있습니다.
- 평가판이 아직 활성화 중이면 새로운 평가판을 시작하기 전에 현재 평가판 기간을 완료해야 합니다.

Premium 티어에 있는 경우 평가판은 기존 사용자당 포함된 크레딧 이상의 추가 크레딧을 제공하지 않습니다. GitLab Ultimate Duo Agent Platform 기능을 시도하기 위해 추가 [임시 평가용 크레딧](gitlab_credits.md#temporary-evaluation-credits)을 요청할 수 있습니다.

## GitLab.com에서 평가판 시작 {#start-a-trial-on-gitlabcom}

GitLab 계정에 가입하지 않았더라도 평가판을 시작할 수 있습니다.

### 계정이 없는 경우 {#if-you-dont-have-an-account}

GitLab 계정이 없는 경우 무료 평가판을 시작하려면:

1. <https://gitlab.com/-/trial_registrations/new>로 이동합니다.
1. 양식 세부 정보를 입력하고 **계속**을 선택합니다.
1. 남은 단계를 완료하고 **프로젝트 생성**을 선택합니다. 새 프로젝트로 이동하여 생성한 새 사용자로 로그인됩니다.
1. 왼쪽 사이드바의 맨 아래에서 평가판 유형과 평가판에서 남은 일수를 표시하는 위젯이 있습니다.

### 이미 계정이 있는 경우 {#if-you-already-have-an-account}

이미 GitLab 계정이 있는 경우 그룹 설정에서 직접 평가판을 시작할 수 있습니다.

전제 조건:

- 평가판을 적용할 최상위 그룹에 대한 소유자 역할이 있어야 합니다. 그룹 멤버십을 통한 간접 소유권은 충분하지 않습니다.
- 최상위 그룹은 이전에 GitLab Credits로 평가판을 진행하지 않았어야 합니다.

평가판을 시작하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **결제**를 선택합니다.
1. **무료 평가판 시작**을 선택합니다.
1. 필드를 완성하세요.
1. **계속**을 선택합니다.
1. 평가판을 적용할 그룹을 선택합니다.
1. **평가판 활성화**를 선택합니다.

평가판이 즉시 시작됩니다. 왼쪽 사이드바의 맨 아래에서 평가판 유형과 평가판에서 남은 일수를 표시하는 위젯이 있습니다.

## GitLab Self-Managed에서 평가판 시작 {#start-a-trial-on-gitlab-self-managed}

GitLab Self-Managed에 대한 평가판을 시작하려면 양식을 완료하여 이메일로 평가판 라이선스를 받으세요.

전제 조건:

- GitLab Self-Managed 인스턴스가 [설치](../install/_index.md)되어 있고 구성되어야 합니다.
- 인스턴스는 GitLab과 [구독 데이터를 동기화](manage_subscription.md#subscription-data-synchronization)할 수 있어야 합니다.
- 관리자여야 합니다.

평가판을 시작하려면:

1. [GitLab Ultimate](https://about.gitlab.com/free-trial/?hosted=self-managed) 평가판 페이지로 이동합니다.
1. 필드를 완성하세요.
1. **시작하기**를 선택합니다.
1. 평가판 활성화 코드에 대한 이메일을 확인합니다. 활성화 코드가 포함된 이메일은 평가판 요청 제출 직후에 평가판 요청 양식에 제공된 이메일 주소로 발송됩니다. 활성화 코드는 한 번만 사용할 수 있습니다.
1. 관리자로 GitLab에 로그인합니다.
1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Subscription**을 선택합니다.
1. **활성화 코드**에 활성화 코드를 붙여넣습니다.
1. 서비스 약관을 읽고 수락합니다.
1. **활성화**를 선택합니다.

구독이 활성화되었습니다.

## 남은 평가판 기간 일수 보기 {#view-remaining-trial-period-days}

남은 평가판 기간을 추적하여 구독 업그레이드를 계획하는 데 도움이 될 수 있습니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바의 맨 아래에서 평가판 유형과 평가판에서 남은 일수를 표시하는 위젯이 있습니다.
1. GitLab Self-Managed에서 업그레이드할 때 사용 가능한 기능에 대한 정보에 액세스하려면 **자세히 알아보기**를 선택합니다.

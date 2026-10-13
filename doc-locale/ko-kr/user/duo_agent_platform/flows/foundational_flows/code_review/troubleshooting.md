---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Code Review 플로우 문제 해결
---

Code Review 플로우를 사용할 때 다음과 같은 문제가 발생할 수 있습니다.

## `Error DCR4000` {#error-dcr4000}

`Code Review Flow is not enabled. Contact your group administrator to enable the foundational flow in the top-level group. Error code: DCR4000`라는 오류가 표시될 수 있습니다.

이 오류는 [기본 플로우](../_index.md) 또는 Code Review 플로우가 꺼져 있을 때 발생합니다.

관리자에게 연락하여 최상위 그룹에 대해 Code Review 플로우를 켜달라고 요청합니다.

## `Error DCR4001` {#error-dcr4001}

`Code Review Flow is enabled but the service account needs to be verified. Contact your administrator. Error code: DCR4001`라는 오류가 표시될 수 있습니다.

이 오류는 Code Review 플로우가 켜져 있지만 최상위 그룹의 서비스 계정이 존재하지 않거나 준비가 되지 않은 경우에 발생합니다.

관리자에게 [서비스 계정이 존재하는지 확인](../../../troubleshooting.md#foundational-flow-service-account-not-created)하고 문제를 해결하기 위한 단계를 따르도록 요청하십시오.

## `Error DCR4002` {#error-dcr4002}

`No GitLab Credits remain for this billing period. To continue using Code Review Flow, contact your administrator. Error code: DCR4002`라는 오류가 표시될 수 있습니다.

이 오류는 현재 청구 기간에 할당된 GitLab Credits을 모두 사용했을 때 발생합니다.

관리자에게 연락하여 추가 크레딧을 구매하거나 다음 청구 기간이 시작될 때 크레딧이 재설정될 때까지 기다립니다.

## `Error DCR4003` {#error-dcr4003}

`<User>, you don't have permission to create a pipeline for Code Review Flow in this project. Contact your administrator to update your permissions. Error code: DCR4003`라는 오류가 표시될 수 있습니다.

이 오류는 Code Review 플로우가 CI/CD 파이프라인에서 실행되고 이 프로젝트에서 파이프라인을 생성할 권한이 없기 때문에 발생합니다.

관리자에게 연락하여 필요한 [파이프라인 실행 권한](../../../../permissions.md)을 부여해 달라고 요청합니다.

## `Error DCR4004` {#error-dcr4004}

`<User>, you need to set a default GitLab Duo namespace to use Code Review Flow in this project. Please set a default GitLab Duo namespace in your preferences. Error code: DCR4004`라는 오류가 표시될 수 있습니다.

이 오류는 GitLab Duo가 검토를 시작한 사용자의 기본 GitLab Duo 네임스페이스를 식별할 수 없을 때 발생합니다.

설정에서 기본 GitLab Duo 네임스페이스를 [설정](../../../../profile/preferences.md#set-a-default-gitlab-duo-namespace)한 후 검토를 다시 요청합니다.

## `Error DCR4005` {#error-dcr4005}

`Code Review Flow could not obtain the required authentication tokens to connect to the GitLab AI Gateway and the GitLab API. Please request a new review. If the issue persists, contact your administrator. Error code: DCR4005`라는 오류가 표시될 수 있습니다.

Code Review 플로우는 GitLab AI Gateway 및 GitLab API에 연결하기 위해 인증 토큰이 필요합니다. 이 오류는 일반적으로 GitLab Duo 설정이 잘못되었거나 일시적 인프라 문제로 인해 해당 토큰을 생성할 수 없을 때 발생합니다.

자체 관리 인스턴스의 경우 관리자에게 [GitLab Duo 설정](../../../../../administration/gitlab_duo/configure/_index.md)을 확인해 달라고 요청합니다.

## `Error DCR4006` {#error-dcr4006}

`Code Review Flow could not add the service account to this project. Contact your administrator to verify that the service account has the required project access. Error code: DCR4006`라는 오류가 표시될 수 있습니다.

이 오류는 서비스 계정을 프로젝트의 멤버로 추가할 수 없을 때 발생합니다. 그룹 멤버십 잠금이 활성화되었거나 서비스 계정에 필요한 액세스 권한이 없을 때 발생할 수 있습니다.

관리자에게 연락하여 서비스 계정을 Developer로서 프로젝트에 추가할 수 있는지 확인해 달라고 요청합니다.

## `Error DCR4007` {#error-dcr4007}

`Code Review Flow is not available for this project. Contact your administrator to verify that the flow is enabled and the required configuration is in place. Error code: DCR4007`라는 오류가 표시될 수 있습니다.

이 오류는 플로우가 비활성화되었거나 프로젝트에 필요한 설정이 없을 때 발생합니다.

관리자에게 연락하여 프로젝트에 대해 [플로우가 활성화](../_index.md#turn-foundational-flows-on-or-off)되었는지 확인해 달라고 요청합니다.

## `Error DCR4008` {#error-dcr4008}

`Code Review Flow could not create the required CI/CD pipeline. Please request a new review. If the problem persists, contact your administrator. Error code: DCR4008`라는 오류가 표시될 수 있습니다.

이 오류는 러너 가용성 문제 또는 내부 설정 문제로 인해 Code Review 플로우가 검토를 실행할 CI/CD 파이프라인을 생성하거나 설정할 수 없을 때 발생합니다.

검토를 다시 시작해 봅니다. 오류가 지속되면 관리자에게 연락합니다.

## `Error DCR4009` {#error-dcr4009}

`Code Review Flow could not retrieve the source branch for this merge request. Please request a new review. Error code: DCR4009`라는 오류가 표시될 수 있습니다.

이 오류는 Code Review 플로우가 머지 리퀘스트의 소스 브랜치를 검색할 수 없을 때 발생합니다.

검토를 다시 시작해 봅니다.

## `Error DCR4011` {#error-dcr4011}

`Code Review Flow could not start because the project has no runner available. It needs an instance runner or a top-level group runner with the gitlab--duo tag and a Docker-compatible executor. Error code: DCR4011`라는 오류가 표시될 수 있습니다.

Code Review 플로우가 CI/CD 파이프라인에서 실행되지만 적격 러너를 사용할 수 없을 때 이 오류가 발생합니다. 플로우에는 최상위 그룹에 할당된 인스턴스 러너 또는 그룹 러너가 필요하며, `gitlab--duo` 태그와 Docker 호환 실행기가 필요합니다.

전체 러너 요구 사항 및 구성 방법은 [플로우의 작업 또는 세션이 시작되지 않음](../../../troubleshooting.md#a-flows-job-or-session-fails-to-start)을 참조하세요.

## `Error DCR4012` {#error-dcr4012}

`Code Review Flow could not start because the namespace has run out of compute minutes. Ask someone with billing access to add compute minutes before trying again. Error code: DCR4012`라는 오류가 표시될 수 있습니다.

네임스페이스가 모든 컴퓨팅 분을 사용했을 때 이 오류가 발생하며, 이는 호스팅된(인스턴스) 러너에 대한 액세스도 제거합니다. 프로젝트 및 최상위 그룹 러너는 영향을 받지 않습니다.

청구 액세스 권한이 있는 사용자에게 컴퓨팅 분을 추가하도록 요청한 후 새로운 검토를 요청하세요. 자세한 내용은 [플로우의 작업 또는 세션이 시작되지 않음](../../../troubleshooting.md#a-flows-job-or-session-fails-to-start)을 참조하세요.

## `Error DCR5000` {#error-dcr5000}

`Something went wrong while starting Code Review Flow. Please try again later. Error code: DCR5000`라는 오류가 표시될 수 있습니다.

이 오류는 내부 오류로 인해 GitLab Duo Agent Platform이 Code Review 플로우를 시작할 수 없을 때 발생합니다.

검토를 다시 시작해 봅니다. 오류가 지속되면 관리자에게 연락합니다.

## `Error DCR5001` {#error-dcr5001}

`Code Review Flow completed the review but could not post the review comments. Please request a new review to try again. Error code: DCR5001`라는 오류가 표시될 수 있습니다.

이 오류는 Code Review 플로우가 검토를 완료했지만 여러 시도 후 검토 주석을 게시할 수 없는 경우에 발생합니다. 이는 종종 일시적 인프라 문제로 인해 발생합니다.

새 검토를 요청하십시오. 오류가 지속되면 관리자에게 연락합니다.

## 큰 머지 리퀘스트 검토에서 누락된 문맥 {#missing-context-in-large-merge-request-reviews}

Code Review 플로우는 머지 리퀘스트에 많은 큰 변경된 파일이 포함될 때 문맥을 놓칠 수 있습니다.

사전 검사 결과가 [파일 및 컨텍스트 제한](_index.md#file-and-context-limits)을 초과하고 검토 전에 데이터가 잘린 경우 이 문제가 발생할 수 있습니다.

검토를 개선하려면:

- 머지 리퀘스트를 더 작은 머지 리퀘스트로 분할합니다.
- [문맥 제외](../../../context.md#exclude-context-from-gitlab-duo)를 검토와 관련이 없는 파일에 대해 수행합니다.
- 그룹 소유자 또는 인스턴스 관리자에게 [GitLab.com](../../../model_selection.md#select-a-model-for-a-feature) 또는 [GitLab Self-Managed 및 GitLab Dedicated](../../../../../administration/gitlab_duo/model_selection.md#select-a-model-for-code-review-flow)에 대해 다른 모델을 선택하도록 요청하세요.

## 설정 진단 스크립트 {#configuration-diagnostic-script}

문서화된 오류 코드에서 Code Review 플로우 문제의 원인을 식별할 수 없는 경우 진단 스크립트를 실행하여 GitLab Duo 설정을 확인할 수 있습니다.

스크립트는 모든 GitLab Duo Agent Platform 기능에 적용되는 검사를 포함하여 Code Review 플로우에 필요한 전체 설정 체인을 확인합니다.

자세한 정보는 [설정 진단 스크립트 실행](../../../troubleshooting.md#run-the-configuration-diagnostic-script)을 참조하세요.

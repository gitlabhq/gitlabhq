---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 코드 소유자를 머지 리퀘스트 준비가 완료되었을 때 검토자로 자동으로 할당합니다.
title: 자동 검토자 할당
---

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.10 에서 `auto_assign_code_owner_reviewers` [플래그](../../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224175)되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 19.1에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239965)합니다. 기능 플래그 `auto_assign_code_owner_reviewers`이 제거되었습니다.

{{< /history >}}

자동 검토자 할당을 활성화하면 GitLab은 변경된 파일의 [코드 소유자](../../codeowners/_index.md)를 의 검토자로 할당합니다. `CODEOWNERS` 파일에서 검토자를 직접 선택할 필요가 없습니다.

## 전제 조건 {#prerequisites}

- 프로젝트에는 [`CODEOWNERS` 파일](../../codeowners/_index.md)이 있어야 합니다.
- 프로젝트에 대한 Maintainer 또는 Owner 역할.

## 자동 검토자 할당 활성화 {#enable-automatic-reviewer-assignment}

프로젝트의 자동 검토자 할당을 활성화하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **설정** > **머지 리퀘스트**를 선택합니다.
1. **Automatic reviewer assignment** 섹션으로 이동합니다.
1. **Automatically assign all code owners as reviewers**을 선택합니다.
1. **변경사항 저장**을 선택합니다.

## GitLab이 검토자를 할당하는 시기 {#when-gitlab-assigns-reviewers}

설정을 활성화한 후 GitLab은 다음의 경우에 코드 소유자를 검토자로 할당합니다:

- 준비가 완료된 상태로 를 생성합니다.
- 초안 를 준비 완료로 표시합니다.

GitLab은 에서 변경된 파일과 일치하는 모든 코드 소유자를 할당합니다.

GitLab이 자동 할당을 건너뛰는 경우:

- 가 초안 상태입니다.
- 에 이미 검토자가 있습니다. [`@GitLabDuo`](../duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)는 이 확인에서 제외됩니다.
- 코드 소유자가 에서 변경된 파일과 일치하지 않습니다.
- 작성자에게 메타데이터를 설정할 권한이 없습니다.

## 검토자 할당 전략 {#reviewer-assignment-strategy}

{{< history >}}

- **Assign reviewers with GitLab Duo Agent Platform** 전략을 GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236211)했으며 [기능 플래그](../../../../administration/feature_flags/_index.md)로 명명된 `dap_powered_recommend_reviewers`로 제공합니다. 기본적으로 비활성화되어 있습니다.

{{< /history >}}

> [!flag]
> **Assign reviewers with GitLab Duo Agent Platform** 전략의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트 가능하지만 프로덕션 사용 준비가 되지 않았습니다.

[GitLab Duo Agent Platform](../../../../user/duo_agent_platform/_index.md)이 프로젝트에서 사용 가능하면, **Automatic reviewer assignment** 섹션에 단일 체크박스 대신 **Reviewer assignment strategy** 설정이 표시됩니다. 다음 옵션 중 하나를 선택합니다:

- **Do not assign reviewers automatically**: GitLab이 검토자를 할당하지 않습니다.
- **Assign all code owners as reviewers**: GitLab은 변경된 파일과 일치하는 `CODEOWNERS` 파일의 모든 코드 소유자를 할당합니다.
- **Assign reviewers with GitLab Duo Agent Platform**: GitLab Duo Agent Platform이 각 승인 규칙을 만족하는 데 필요한 최소 검토자 수를 권장하고 할당합니다.

### GitLab Duo Agent Platform으로 검토자 할당 {#assign-reviewers-with-gitlab-duo-agent-platform}

이 전략을 선택하면, GitLab Duo Agent Platform이 머지 리퀘스트에 필요한 승인 규칙을 읽습니다. 각 규칙에 대해 규칙을 만족하는 데 필요한 최소 검토자 수를 권장하고, 할당한 후, 선택을 설명하는 주석을 추가합니다. 이 전략은 코드 소유자뿐만 아니라 모든 승인 규칙 유형에 적용됩니다.

규칙에 대한 적격 승인자 중에서 선택하려면, GitLab Duo Agent Platform이 각 승인자에 대해 다음을 고려합니다:

- 가용성(해당 [상태](../../../profile/_index.md#set-your-status)에 기반).
- 검토 워크로드(검토 대기 중인 열린 머지 리퀘스트의 수에 기반).
- 현지 시간(프로필의 시간대에 기반).
- 가장 최근 활동.

GitLab이 머지 리퀘스트가 준비 상태가 되면 검토자를 할당하며, 이는 코드 소유자 전략과 같습니다. 권장 사항이 백그라운드에서 실행되므로 검토자가 표시되는 데 약간의 시간이 걸릴 수 있습니다. GitLab이 0개의 승인을 요구하는 승인 규칙을 무시합니다.

## 관련 항목 {#related-topics}

- [코드 소유자](../../codeowners/_index.md)
- [머지 리퀘스트 검토](_index.md)
- [머지 리퀘스트 승인 규칙](../approvals/rules.md)

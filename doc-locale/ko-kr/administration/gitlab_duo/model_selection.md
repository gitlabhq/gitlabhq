---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo 기능을 위해 대규모 언어 모델을 구성합니다.
title: 모델 선택
---

{{< details >}}

- 계층:  Premium, Ultimate
- 추가 기능:  GitLab Duo Core, Pro 또는 Enterprise
- 제공:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

모든 GitLab Duo 기능은 GitLab이 선택한 기본 대규모 언어 모델(LLM)을 가지고 있습니다.

GitLab은 기능 성능을 최적화하기 위해 이 기본 모델을 업데이트할 수 있습니다. 따라서 사용자가 어떤 조치를 취하지 않아도 기능의 모델이 변경될 수 있습니다.

각 기능에 대해 기본 모델을 사용하지 않으려고 하거나 특정 요구 사항이 있는 경우 사용 가능한 여러 지원 모델 중에서 선택할 수 있습니다.

기능에 대해 특정 모델을 선택하면 다른 모델을 선택할 때까지 해당 기능은 그 모델을 사용합니다.

## 인스턴스에 대한 모델 선택 {#select-a-model-for-the-instance}

{{< history >}}

- [GitLab 18.4에서 도입됨](https://gitlab.com/groups/gitlab-org/-/epics/19144) (적용 가능한 [기능 플래그](../feature_flags/_index.md) `instance_level_model_selection`). 기본적으로 활성화됨.
- [GitLab 18.5에서 GitLab Dedicated로 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208017).
- 기능 플래그 `instance_level_model_selection` [GitLab 18.6에서 제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209698).
- [GitLab 18.6에서 GitLab Duo Core 및 Pro를 포함하도록 변경됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210969).

{{< /history >}}

전체 인스턴스에 적용되는 기능에 대한 모델을 선택할 수 있습니다. 특정 모델을 선택하지 않으면 모든 GitLab Duo 기능이 기본 GitLab 모델을 사용합니다.

> [!note]
> 오프라인 라이선스가 있는 GitLab Self-Managed 인스턴스에서 GitLab Duo Agent Platform의 기능에 대한 모델을 변경하려면 [GitLab Duo Agent Platform Self-Hosted](../../subscriptions/subscription-add-ons.md) 추가 기능이 있어야 합니다.

전제 조건:

- 관리자여야 합니다.

기능에 대한 모델을 선택하려면:

1. 오른쪽 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **Configure AI features**에서 **GitLab Duo 모델 구성**을 선택합니다. **Configure AI features**가 표시되지 않으면 GitLab Duo Enterprise 추가 기능이 인스턴스에 구성되어 있는지 확인합니다.
1. 구성하려는 기능에 대해 드롭다운 목록에서 모델을 선택합니다.
1. 선택사항. 섹션의 모든 기능에 모델을 적용하려면 **모두에 적용**을 선택합니다.

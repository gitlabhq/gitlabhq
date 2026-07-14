---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab.com의 컴퓨팅 분 단위에 대한 비용 팩터 설정을 구성합니다.
title: GitLab.com의 컴퓨팅 분 단위 관리
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com

{{< /details >}}

GitLab.com 관리자는 [GitLab Self-Managed](compute_minutes.md)에서 사용 가능한 기능 이상으로 컴퓨팅 분 단위에 대한 추가 제어 기능을 사용할 수 있습니다.

## 비용 팩터 설정 {#set-cost-factors}

전제 조건:

- GitLab.com의 관리자여야 합니다.

러너에 대한 비용 팩터를 설정하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **러너**를 선택합니다.
1. 업데이트하려는 러너에서 **편집** ({{< icon name="pencil" >}})을 선택합니다.
1. **공개 프로젝트 컴퓨팅 비용 팩터** 텍스트 상자에 공개 비용 팩터를 입력합니다.
1. **비공개 프로젝트 컴퓨팅 비용 팩터** 텍스트 상자에 비공개 비용 팩터를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 커뮤니티 기여에 대한 비용 팩터 감소 {#reduce-cost-factors-for-community-contributions}

기능 플래그 `ci_minimal_cost_factor_for_gitlab_namespaces`이 네임스페이스에 대해 활성화되면, 활성화된 네임스페이스의 프로젝트를 대상으로 하는 포크에서의 머지 리퀘스트 파이프라인은 감소된 비용 팩터를 사용합니다. 이를 통해 커뮤니티 기여가 과도한 컴퓨팅 분 단위를 사용하지 않도록 합니다.

전제 조건:

- 기능 플래그를 제어할 수 있어야 합니다.
- 감소된 비용 팩터를 활성화하려는 네임스페이스 ID가 필요합니다.

네임스페이스가 감소된 비용 팩터를 사용하도록 활성화하려면:

1. [기능 플래그 활성화](../feature_flags/_index.md#how-to-enable-and-disable-features-behind-flags) `ci_minimal_cost_factor_for_gitlab_namespaces`를 포함할 네임스페이스 ID에 대해 수행합니다.

이 기능은 GitLab.com에서만 사용하도록 권장됩니다. 커뮤니티 기여자는 GitLab 프로젝트를 대상으로 하는 머지 리퀘스트에 포함되지 않은 파이프라인을 실행할 때 분 단위 누적을 방지하기 위해 커뮤니티 포크를 기여에 사용해야 합니다.

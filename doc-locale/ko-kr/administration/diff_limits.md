---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: GitLab Self-Managed에서 표시할 최대 diff 크기를 구성합니다.
title: Diff 한도 관리
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

큰 파일의 전체 내용을 표시하면 머지 리퀘스트가 느려질 수 있습니다. 이를 방지하려면 머지 리퀘스트에 표시되는 diff의 한도를 구성할 수 있습니다. 여기에는 최대 diff 크기, 변경된 파일 수, 변경된 라인 수, diff 버전 및 diff 커밋이 포함됩니다. 이 한도는 GitLab UI 및 diff 정보를 반환하는 API 엔드포인트 모두에 적용됩니다.

diff가 최대 diff 패치 크기, 최대 diff 파일 또는 최대 diff 라인 값의 10%에 도달하면 GitLab은 diff를 확장할 수 있는 링크가 있는 축소된 보기로 파일을 표시합니다. 이 세 값 중 하나를 초과하는 diff는 **Too large**으로 표시되며 UI에서 이를 확장할 수 없습니다.

최대 diff 버전 및 최대 diff 커밋 값은 머지 리퀘스트 업데이트를 제한합니다. 이 한도에 도달한 머지 리퀘스트는 더 이상 업데이트할 수 없습니다:

| 값                       | 정의                                                              | 기본값 | 최대값 |
|-----------------------------|-------------------------------------------------------------------------|:-------------:|:-------------:|
| **최대 diff 패치 크기** | 전체 diff의 바이트 단위 총 크기입니다.                           |    200 KB     |    500 KB     |
| **Maximum diff files**      | diff에서 변경된 파일의 총 개수입니다.                            |     1000      |     3000      |
| **Maximum diff lines**      | diff에서 변경된 라인의 총 개수입니다.                            |    50,000     |    100,000    |
| **Maximum diff versions**   | 머지 리퀘스트당 diff 버전의 개수입니다.                          |     1,000     |     없음      |
| **Maximum diff commits**    | 머지 리퀘스트당 모든 버전에 걸친 diff 커밋의 총 개수입니다. |   1,000,000   |     없음      |

[Diff 한도는 GitLab.com에서 구성할 수 없습니다](../user/gitlab_com/_index.md#diff-display-limits).

diff 파일에 대한 자세한 내용은 [파일 간 변경 사항 보기](../user/project/merge_requests/changes.md)를 참조하세요. 머지 리퀘스트 및 diff의 [기본 제공 한도](instance_limits.md#merge-requests)에 대해 자세히 알아보세요.

## Diff 한도 구성 {#configure-diff-limits}

> [!warning]
> 이 설정은 실험적입니다. 최대값을 높이면 인스턴스의 리소스 사용량이 증가합니다. 최대값을 조정할 때 이를 염두에 두세요.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

머지 리퀘스트에서 diff 표시를 위한 최대값을 설정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **Diff 한도**를 확장합니다.
1. diff 한도에 대한 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

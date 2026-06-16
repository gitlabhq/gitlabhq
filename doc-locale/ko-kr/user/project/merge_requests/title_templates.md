---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 머지 리퀘스트 제목 템플릿을 사용하여 프로젝트의 새로운 머지 리퀘스트에 대한 기본 제목 형식을 설정합니다.
title: 머지 리퀘스트 제목 템플릿
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228442) 되었으며 [기능 플래그](../../../administration/feature_flags/_index.md)는 `mr_default_title_template`로 명명되었습니다. 기본적으로 비활성화됨. 이 기능은 [베타](../../../policy/development_stages_support.md#beta) 단계입니다.
- GitLab 19.0에서 일반 공개되었습니다. 기능 플래그 `mr_default_title_template`이(가) [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235642)되었습니다.

{{< /history >}}

머지 리퀘스트 제목 템플릿은 프로젝트의 새로운 머지 리퀘스트에 대한 기본 제목을 정의합니다. 템플릿을 사용하여 팀 전체에서 머지 리퀘스트 명명 규칙을 표준화합니다.

템플릿은 소스 브랜치 이름이나 첫 번째 커밋 메시지와 같은 값으로 확장되는 변수를 지원합니다. 사용자는 머지 리퀘스트를 생성하기 전에 제목을 편집할 수 있습니다.

## 머지 리퀘스트 제목 템플릿 구성 {#configure-a-merge-request-title-template}

전제 조건:

- 프로젝트에 대해 최소한 관리자 역할이 있어야 합니다.

머지 리퀘스트 제목 템플릿을 구성하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **설정** > **머지 리퀘스트**를 선택합니다.
1. **Merge request title template**으로 스크롤합니다.
1. 정적 텍스트와 [지원되는 변수](#supported-variables)를 사용하여 템플릿을 입력합니다. 템플릿은 100자로 제한됩니다.
1. **변경사항 저장**을 선택합니다.

템플릿을 제거하고 기본 동작을 복원하려면 템플릿 필드를 지우고 **변경사항 저장**을 선택합니다.

## 지원되는 변수 {#supported-variables}

제목 템플릿은 다음 변수를 지원합니다:

| 변수               | 설명                                                                                                    | 출력 예시 |
|------------------------|----------------------------------------------------------------------------------------------------------------|----------------|
| `%{source_branch}`     | 소스 브랜치의 이름입니다.                                                                                 | `my-feature-branch` |
| `%{target_branch}`     | 대상 브랜치의 이름입니다.                                                                                 | `main`         |
| `%{title_from_branch}` | 소스 브랜치 이름을 사람이 읽을 수 있는 형식으로 변환합니다. 하이픈과 언더스코어는 공백으로 바뀝니다. | `My feature branch` |
| `%{first_commit_title}` | 머지 리퀘스트의 첫 번째 커밋의 제목(첫 번째 줄)입니다.                                            | `Update README.md` |
| `%{issue_id}`           | 소스 브랜치 이름을 통해 연결된 이슈의 IID(예: `123` from `123-fix-bug`)입니다. 이슈가 감지되지 않으면 공백입니다. | `123` |
| `%{issue_title}`        | 소스 브랜치 이름을 통해 연결된 이슈의 제목입니다. 이슈가 감지되지 않으면 공백입니다.                   | `Fix login bug` |

## 템플릿 예시 {#template-examples}

| 템플릿                                          | 결과 |
|---------------------------------------------------|--------|
| `%{source_branch}`                                | `my-feature-branch` |
| `%{title_from_branch}`                            | `My feature branch` |
| `%{first_commit_title}`                           | `Update README.md` |
| `Draft: %{title_from_branch}`                     | `Draft: My feature branch` |
| `[%{source_branch}] %{first_commit_title}`        | `[my-feature-branch] Update README.md` |
| `Resolve %{issue_id} "%{issue_title}"`            | `Resolve 123 "Fix login bug"` |

## 제목 템플릿 할당 {#title-template-assignment}

머지 리퀘스트를 생성할 때 GitLab은 다음 순서로 제목을 할당합니다:

1. 제목을 제공하면 GitLab은 이를 사용합니다.
1. 제목 템플릿이 구성되어 있으면 GitLab은 확장된 템플릿을 사용합니다.
1. 템플릿이 설정되지 않으면 GitLab은 [기본 제목 동작](#default-title-behavior)을 사용합니다.

## 기본 제목 동작 {#default-title-behavior}

제목 템플릿이 구성되지 않았고 제목을 제공하지 않으면 GitLab은 다음 조건을 순서대로 확인하여 제목을 생성합니다:

1. 머지 리퀘스트에 단일 커밋이 있으면 커밋 제목입니다.
1. 머지 리퀘스트에 여러 커밋이 있으면 여러 줄 커밋 메시지가 있는 첫 번째 커밋의 제목입니다.
1. 소스 브랜치 이름이 이슈 IID로 시작하고 하이픈이 뒤따르면(예: `123-fix-typo`), 제목은 `Resolve "<your_issue_title>"`입니다.
1. 그 외에는 소스 브랜치 이름이며 하이픈과 언더스코어는 공백으로 바뀝니다.

머지 리퀘스트에 커밋이 없거나 이를 초안으로 표시하면 GitLab은 `Draft:`을(를) 제목 앞에 붙입니다.

## 관련 항목 {#related-topics}

- [커밋 메시지 템플릿](commit_templates.md)
- [머지 리퀘스트 생성](creating_merge_requests.md)

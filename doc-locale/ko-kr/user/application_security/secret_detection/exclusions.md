---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 시크릿 검색 제외
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- GitLab 17.5에서 `secret_detection_project_level_exclusions` [기능 플래그](../../../administration/feature_flags/list.md)의 [실험적 기능](../../../policy/development_stages_support.md)으로 [도입](https://gitlab.com/groups/gitlab-org/-/epics/14878)되었습니다. 기본적으로 사용으로 설정됩니다.
- GitLab 17.7에서 `secret_detection_project_level_exclusions` 기능 플래그가 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/499059)되었습니다.

{{< /history >}}

시크릿 검색은 실제로 시크릿이 아닌 것을 감지할 수 있습니다. 예를 들어, 코드에서 자리 표시자로 가짜 값을 사용하면 감지되어 차단될 수 있습니다.

거짓 양성을 방지하고 [성능을 최적화](secret_push_protection/_index.md#optimize-performance)하려면 시크릿 검색에서 다음을 제외할 수 있습니다:

- 경로.
- 원본 값.
- 기본 규칙 집합의 규칙.

프로젝트에 대해 여러 제외를 정의할 수 있습니다.

## 제한 사항 {#restrictions}

다음 제한 사항이 적용됩니다:

- 제외는 각 프로젝트에 대해서만 정의할 수 있습니다.
- 제외는 [비밀 푸시 방지](secret_push_protection/_index.md)에만 적용됩니다.
- 프로젝트당 경로 기반 제외의 최대 개수는 10개입니다.
- 경로 기반 제외의 최대 깊이는 20입니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [시크릿 검색 제외 - 데모](https://www.youtube.com/watch?v=vh_Uh4_4aoc)를 참조하세요.
<!-- Video published on 2024-10-12 -->

## 제외 추가 {#add-an-exclusion}

시크릿 검색에서 거짓 양성을 방지하기 위해 제외를 정의합니다.

전제 조건:

- 프로젝트의 보안 관리자, 유지 관리자 또는 소유자 역할이 있어야 합니다.

제외를 정의하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **비밀 푸시 방지**까지 스크롤합니다.
1. **시크릿 푸시 보호** 토글을 켭니다.
1. **비밀 탐지 구성**({{< icon name="settings" >}})을 선택합니다.
1. **실행 추가**를 선택하여 제외 양식을 엽니다.
1. 제외의 세부 정보를 입력한 다음 **실행 추가**를 선택합니다.

경로 제외는 Ruby 메서드 [`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)로 지원되고 해석되는 글로브 패턴을 지원하며, [플래그](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29) `File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`를 사용합니다.

규칙 제외는 [기본 규칙 집합](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules)에 나열된 모든 ID를 지원합니다. 예를 들어, `gitlab_personal_access_token`는 GitLab 개인 액세스 토큰의 규칙 ID입니다.

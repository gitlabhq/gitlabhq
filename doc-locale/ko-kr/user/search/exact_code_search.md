---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "정확한 코드 검색을 사용하여 특정 프로젝트 또는 모든 GitLab에서 코드를 찾습니다."
title: 정확한 코드 검색
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed
- 상태:  제한된 가용성

{{< /details >}}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) GitLab 15.9에서 [베타](../../policy/development_stages_support.md#beta) 로 [플래그](../../administration/feature_flags/_index.md) `index_code_with_zoekt` 및 `search_code_with_zoekt`로 명명됨. 기본적으로 비활성화됨.
- [GitLab.com 및 GitLab Self-Managed에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/388519) GitLab 16.6에서.
- 전역 코드 검색 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147077) GitLab 16.11에서 [플래그](../../administration/feature_flags/_index.md) `zoekt_cross_namespace_search`로 명명됨. 기본적으로 비활성화됨.
- 기능 플래그 `index_code_with_zoekt` 및 `search_code_with_zoekt` [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378) GitLab 17.1에서.
- [변경됨](https://gitlab.com/groups/gitlab-org/-/epics/17918) 베타에서 제한된 가용성으로 GitLab 18.6에서.
- 기능 플래그 `zoekt_cross_namespace_search` [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213413) GitLab 18.7에서.

{{< /history >}}

> [!warning]
> 이 기능은 [제한된 가용성](../../policy/development_stages_support.md#limited-availability) 상태입니다. 자세한 내용은 [에픽 9404](https://gitlab.com/groups/gitlab-org/-/epics/9404)를 참조하세요. [이슈 420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920)에서 피드백을 제공하세요.

정확한 코드 검색을 사용하면 정확히 일치하는 모드와 정규 표현식 모드를 사용하여 모든 GitLab 또는 특정 프로젝트에서 코드를 검색할 수 있습니다.

정확한 코드 검색은 Zoekt로 구동되며 기능이 활성화된 그룹에서 기본적으로 사용됩니다.

## 정확한 코드 검색 사용 {#use-exact-code-search}

전제 조건:

- 정확한 코드 검색을 활성화해야 합니다:
  - GitLab.com의 경우 정확한 코드 검색은 유료 구독에서 기본적으로 활성화됩니다.
  - GitLab Self-Managed의 경우 관리자가 [Zoekt 설치](../../integration/zoekt/_index.md#install-zoekt) 및 [정확한 코드 검색 활성화](../../integration/zoekt/_index.md#enable-exact-code-search)해야 합니다.

정확한 코드 검색을 사용하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하세요.
1. 검색 상자에 검색 용어를 입력하세요.
1. 왼쪽 사이드바에서 **코드**를 선택하세요.

프로젝트 또는 그룹에서도 정확한 코드 검색을 사용할 수 있습니다.

## 사용 가능한 범위 {#available-scopes}

범위는 검색하고 있는 데이터의 유형을 설명합니다. 다음 범위는 정확한 코드 검색에 사용할 수 있습니다:

| 범위 | 전역 <sup>1</sup> <sup>2</sup> |    그룹    | 프로젝트     |
|-------|:--------------------------------:|:-----------:|:-----------:|
| 코드  |           {{< no >}}             | {{< yes >}} | {{< yes >}} |

**각주**:

1. 관리자는 [전역 검색 범위 비활성화](_index.md#disable-global-search-scopes)할 수 있습니다. GitLab 18.6 이전 버전에서 GitLab Self-Managed에서 전역 검색을 활성화하려면 관리자가 `zoekt_cross_namespace_search` 기능 플래그도 활성화해야 합니다.
1. GitLab.com에서는 전역 검색이 활성화되지 않습니다.

## Zoekt 검색 API {#zoekt-search-api}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143666) GitLab 16.9에서 [플래그](../../administration/feature_flags/_index.md) `zoekt_search_api`로 명명됨. 기본적으로 활성화됨.
- [일반적으로 사용 가능](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17522) GitLab 18.4에서. 기능 플래그 `zoekt_search_api` 제거됨.

{{< /history >}}

Zoekt 검색 API를 사용하면 정확한 코드 검색을 위해 검색 API를 사용할 수 있습니다. 대신 고급 검색 또는 기본 검색을 사용하려면 [검색 유형 지정](_index.md#specify-a-search-type)하세요.

## 검색 모드 {#search-modes}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/434417) GitLab 16.8에서 [플래그](../../administration/feature_flags/_index.md) `zoekt_exact_search`로 명명됨. 기본적으로 비활성화됨.
- [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/436457) GitLab 17.3에서. 기능 플래그 `zoekt_exact_search` 제거됨.

{{< /history >}}

GitLab은 두 가지 검색 모드를 제공합니다:

- **Exact match mode**: 쿼리와 정확히 일치하는 결과를 반환합니다.
- **Regular expression mode**: 정규식 및 부울 표현식을 지원합니다.

정확히 일치하는 모드가 기본적으로 사용됩니다. 정규 표현식 모드로 전환하려면 검색 상자 오른쪽에서 **Use regular expression** ({{< icon name="regular-expression" >}})을 선택하세요.

### 구문 {#syntax}

{{< history >}}

- `repo:` 필터 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/488467) GitLab 19.0에서.

{{< /history >}}

<!-- Remember to also update the table in `doc/drawers/exact_code_search_syntax.md` -->

이 표는 정확히 일치하는 모드와 정규 표현식 모드의 몇 가지 예제 쿼리를 보여줍니다.

| 쿼리                | 정확히 일치하는 모드                                                                | 정규 표현식 모드                                                         |
|----------------------|---------------------------------------------------------------------------------|---------------------------------------------------------------------------------|
| `"foo"`              | `"foo"`                                                                         | `foo`                                                                           |
| `foo file:^doc/`     | `foo`이 있는 디렉토리에서 시작하는 `/doc`                                     | `foo`이 있는 디렉토리에서 시작하는 `/doc`                                     |
| `"class foo"`        | `"class foo"`                                                                   | `class foo`                                                                     |
| `class foo`          | `class foo`                                                                     | `class` 및 `foo`                                                               |
| `foo or bar`         | `foo or bar`                                                                    | `foo` 또는 `bar`                                                                  |
| `class Foo`          | `class Foo` (대소문자 구분)                                                    | `class` (대소문자 미구분) 및 `Foo` (대소문자 구분)                           |
| `class Foo case:yes` | `class Foo` (대소문자 구분)                                                    | `class` 및 `Foo` (모두 대소문자 구분)                                         |
| `foo -bar`           | `foo -bar`                                                                      | `foo`이지만 `bar`은 아님                                                             |
| `foo file:js`        | `foo`을 포함하는 이름을 가진 파일에서 `js`                                     | `foo`을 포함하는 이름을 가진 파일에서 `js`                                     |
| `foo -file:test`     | `foo`을 포함하지 않는 이름을 가진 파일에서 `test`                            | `foo`을 포함하지 않는 이름을 가진 파일에서 `test`                            |
| `foo lang:ruby`      | Ruby 소스 코드의 `foo`                                                       | Ruby 소스 코드의 `foo`                                                       |
| `foo file:\.js$`     | `foo`로 끝나는 이름을 가진 파일에서 `.js`                                   | `foo`로 끝나는 이름을 가진 파일에서 `.js`                                   |
| `foo.*bar`           | `foo.*bar` (리터럴)                                                            | `foo.*bar` (정규 표현식)                                                 |
| `sym:foo`            | 클래스, 메서드 및 변수 이름과 같은 기호의 `foo`                         | 클래스, 메서드 및 변수 이름과 같은 기호의 `foo`                         |
| `test repo:(?i)foo`  | 프로젝트 이름에 `foo`가 있는 `test` (대소문자 미구분) | 프로젝트 이름에 `foo`가 있는 `test` (대소문자 미구분) |

## 알려진 이슈 {#known-issues}

- 1 MB보다 작은 파일을 `20_000` 트라이그램 미만으로만 검색할 수 있습니다. 자세한 내용은 [이슈 455073](https://gitlab.com/gitlab-org/gitlab/-/issues/455073)을 참조하세요.
- 프로젝트의 기본 브랜치에서만 정확한 코드 검색을 사용할 수 있습니다. 자세한 내용은 [이슈 403307](https://gitlab.com/gitlab-org/gitlab/-/issues/403307)을 참조하세요.
- 한 줄의 여러 일치 항목은 하나의 결과로 계산됩니다.
- 줄바꿈이 올바르게 표시되지 않는 결과가 나타나면 `gitlab-zoekt`을 버전 1.5.0 이상으로 업데이트하세요.

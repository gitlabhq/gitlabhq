---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 보안 센터
description: 여러 프로젝트에 걸친 취약성을 확인할 수 있는 구성 가능한 공간입니다.
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

보안 센터는 여러 프로젝트의 취약성 데이터를 포함한 구성 가능한 개인 공간입니다. 속한 프로젝트 중 어디에서나 보안 센터에 최대 1,000개의 프로젝트를 추가할 수 있습니다.

> [!note]
> 보안 센터 설정 페이지의 **프로젝트** 목록은 최대 100개의 프로젝트를 표시합니다. 처음 100개 프로젝트에 표시되지 않는 프로젝트를 찾으려면 검색 필터를 사용하세요.

보안 센터는 다음을 표시합니다:

- 추가한 프로젝트에 대한 보안 대시보드입니다.
- 추가한 프로젝트에 대한 [취약성 보고서](../vulnerability_report/_index.md)입니다.
- 프로젝트를 추가하거나 제거할 수 있는 설정 영역입니다.

## 보안 센터 보기 {#view-the-security-center}

보안 센터를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택합니다.
1. **귀하의 작업**을 선택합니다.
1. **보안** > **보안 대시보드**를 선택합니다.

보안 센터는 기본적으로 비어 있습니다. 최소한 하나의 보안 스캐너로 구성된 하나 이상의 프로젝트를 추가해야 합니다.

## 보안 센터에 프로젝트 추가 {#add-projects-to-the-security-center}

프로젝트를 추가하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택합니다.
1. **귀하의 작업**을 선택합니다.
1. **보안**을 확장합니다.
1. **설정**을 선택합니다.
1. **프로젝트 검색** 텍스트 상자를 사용하여 프로젝트를 검색하고 선택합니다.
1. **프로젝트 추가**를 선택합니다.

프로젝트를 추가한 후 보안 대시보드와 취약성 보고서는 해당 프로젝트의 기본 브랜치에서 발견된 취약성을 표시합니다.

## 보안 센터에서 프로젝트 제거 {#remove-projects-from-the-security-center}

보안 센터는 최대 100개의 프로젝트를 표시하므로 프로젝트를 제거하기 위해 검색 기능을 사용해야 할 수도 있습니다. 프로젝트를 제거하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택합니다.
1. **귀하의 작업**을 선택합니다.
1. **보안**을 확장합니다.
1. **설정**을 선택합니다.
1. **프로젝트 검색** 텍스트 상자를 사용하여 프로젝트를 검색합니다.
1. **대시보드에서 프로젝트 제거** ({{< icon name="remove" >}})를 선택합니다.

프로젝트를 제거한 후 보안 대시보드와 취약성 보고서는 해당 프로젝트의 기본 브랜치에서 발견된 취약성을 더 이상 표시하지 않습니다.

## 내보내기 {#exporting}

{{< history >}}

- `vulnerabilities_pdf_export`라는 이름의 [기능 플래그](../../../administration/feature_flags/_index.md)로 GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/546219)되었습니다. 기본적으로 사용으로 설정됩니다.
- GitLab 18.5에서 일반적으로 사용 가능합니다. `vulnerabilities_pdf_export` 기능 플래그가 제거되었습니다.

{{< /history >}}

보안 대시보드에 나열된 취약성의 세부 정보를 포함하는 PDF 파일을 내보낼 수 있습니다.

내보내기에 포함된 차트:

- 기간별 취약성
- 프로젝트 보안 상태
- 프로젝트의 보안 대시보드

### 내보내기 세부 정보 {#export-details}

보안 대시보드에 나열된 모든 취약성의 세부 정보를 내보내려면 **내보내기**를 선택합니다.

내보낸 세부 정보를 사용할 수 있을 때 GitLab에서 이메일을 보냅니다. 내보낸 세부 정보를 다운로드하려면 이메일의 링크를 선택합니다.

## 관련 항목 {#related-topics}

- [보안 대시보드](../security_dashboard/_index.md)
- [취약성 보고서](../vulnerability_report/_index.md)
- [취약성 페이지](../vulnerabilities/_index.md)

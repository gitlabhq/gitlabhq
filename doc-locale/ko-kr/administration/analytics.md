---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: GitLab에서 데이터 분석을 위해 ClickHouse를 활성화하고 구성합니다.
title: 분석 보고서를 위해 ClickHouse를 사용합니다
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- ClickHouse 데이터 수집기가 GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/414610) 되었으며 [기능 플래그](feature_flags/_index.md) `clickhouse_data_collection`로 명명되었습니다. 기본적으로 비활성화됨.
- 기능 플래그 `clickhouse_data_collection`이(가) GitLab 17.0에서 제거되었으며 애플리케이션 설정으로 대체되었습니다.

{{< /history >}}

[기여 분석](../user/group/contribution_analytics/_index.md) 보고서, [CI/CD 분석 대시보드](../user/analytics/ci_cd_analytics.md) , 그리고 [Value Streams Dashboard](../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports) 기여자 수 메트릭이 ClickHouse를 데이터 소스로 사용할 수 있습니다.

전제 조건:

- 인스턴스에서 [ClickHouse 구성](../integration/clickhouse.md)됨.
- 관리자 액세스 권한이 있어야 합니다.

ClickHouse를 활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **분석** 섹션에서 **ClickHouse 활성화** 확인란을 선택합니다.

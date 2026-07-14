---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Grafana 구성
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab과 함께 제공되는 Grafana는 GitLab 16.0에서 [더 이상 사용되지 않습니다](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7772).
- GitLab과 함께 제공되는 Grafana는 GitLab 16.3에서 [제거되었습니다](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7772).

{{< /history >}}

[Grafana](https://grafana.com/)는 그래프와 대시보드를 통해 시계열 메트릭을 시각화할 수 있는 도구입니다. GitLab은 성능 데이터를 Prometheus에 작성하며, Grafana를 사용하면 데이터를 조회하여 그래프를 표시할 수 있습니다.

## GitLab UI와 통합 {#integrate-with-gitlab-ui}

전제 조건:

- 관리자 액세스.

Grafana를 설정한 후 GitLab 사이드바에서 액세스할 수 있는 링크를 활성화할 수 있습니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **측정항목 및 프로파일링**을 선택합니다.
1. **측정항목 - Grafana**를 확장합니다.
1. **Grafana에 대한 링크 추가** 확인란을 선택합니다.
1. **Grafana URL**을 구성합니다. Grafana 인스턴스의 전체 URL을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

GitLab은 링크를 **운영자** 영역의 **모니터링** > **측정항목 대시보드** 아래에 표시합니다.

## 필수 범위 {#required-scopes}

이전 프로세스를 통해 Grafana를 설정할 때 **운영자** 영역의 **응용 프로그램** > **GitLab Grafana** 아래에 범위가 표시되지 않습니다. 그러나 `read_user` 범위는 필수이며 응용 프로그램에 자동으로 제공됩니다. `read_user` 이외의 범위를 `read_user`을 포함하지 않고 설정하면 GitLab을 OAuth 공급자로 사용하여 로그인하려고 할 때 다음 오류가 발생합니다:

```plaintext
The requested scope is invalid, unknown, or malformed.
```

이 오류가 표시되면 GitLab Grafana 구성 화면에서 다음 중 하나가 참인지 확인합니다:

- 범위가 표시되지 않습니다.
- `read_user` 범위가 포함됩니다.

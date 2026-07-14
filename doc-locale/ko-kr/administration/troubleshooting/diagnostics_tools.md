---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 진단 도구
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab 지원 팀은 문제 해결 중에 이러한 진단 도구를 사용합니다. 이 도구들은 투명성을 위해 여기에 나열되어 있으며, GitLab 문제 해결 경험이 있는 사용자를 위한 것입니다.

GitLab에 문제가 있는 경우 이 도구를 사용하기 전에 [지원 옵션](https://about.gitlab.com/support/)을 확인하는 것이 좋습니다.

## SOS 스크립트 {#sos-scripts}

{{< history >}}

- `gitlabsos`을(를) Linux 패키지 및 Docker 이미지와 함께 번들링하는 것이 GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8565)되었습니다.

{{< /history >}}

- [`gitlabsos`](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos/)는 Linux 패키지 또는 Docker 기반 GitLab 인스턴스 및 해당 운영 체제에서 정보 및 최근 로그를 수집합니다.

  ```shell
  sudo gitlabsos
  ```

- [`kubesos`](https://gitlab.com/gitlab-com/support/toolbox/kubesos/)는 Kubernetes 클러스터 구성 및 GitLab Helm 차트 배포에서 최근 로그를 수집합니다.
- [`gitlab:db:sos`](../raketasks/maintenance.md#collect-information-and-statistics-about-the-database)는 데이터베이스에 대한 자세한 진단 데이터를 수집합니다.

## `strace-parser` {#strace-parser}

[`strace-parser`](https://gitlab.com/gitlab-com/support/toolbox/strace-parser)는 원본 `strace` 데이터를 분석하고 요약합니다. [`strace` 지인](https://wizardzines.com/zines/strace/)은 컨텍스트를 위해 권장됩니다.

## `gitlabrb_sanitizer` {#gitlabrb_sanitizer}

[`gitlabrb_sanitizer`](https://gitlab.com/gitlab-com/support/toolbox/gitlabrb_sanitizer/)는 민감한 값이 제거된 `/etc/gitlab/gitlab.rb` 콘텐츠의 복사본을 출력합니다.

`gitlabsos`은(는) 구성을 정제하기 위해 자동으로 `gitlabrb_sanitizer`를 사용합니다.

## `fast-stats` {#fast-stats}

{{< history >}}

- `fast-stats`을(를) Linux 패키지 및 Docker 이미지와 함께 번들링하는 것이 GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/8618)되었습니다.

{{< /history >}}

성능 및 구성 문제를 디버그하기 위해 [`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#fast-stats)는 오류 및 리소스 집약적인 사용 통계를 빠르게 요약합니다.

`fast-stats`을(를) 사용하여 대량의 로그를 파싱하고 비교하거나 알 수 없는 문제 해결을 시작합니다.

```shell
/opt/gitlab/embedded/bin/fast-stats
```

## `greenhat` {#greenhat}

[`greenhat`](https://gitlab.com/gitlab-com/support/toolbox/greenhat/) 는 [SOS 로그](#sos-scripts)를 분석, 필터링 및 요약하기 위한 대화형 셸을 제공합니다.

## GitLab Detective {#gitlab-detective}

[GitLab Detective](https://gitlab.com/gitlab-com/support/toolbox/gitlab-detective)는 GitLab 인스턴스에서 자동화된 검사를 실행하여 일반적인 문제를 식별하고 해결합니다.

## `soslab` {#soslab}

[soslab](https://gitlab.com/gitlab-com/support/toolbox/soslab)은 다중 노드 배포 전반에서 GitLab SOS 번들을 문제 해결하기 위한 로그 분석기입니다. 패턴 클러스터링, 상관 관계 추적, 시스템 메트릭 대시보드, PowerSearch, 자동 분석 및 기본 제공 터미널 액세스를 제공합니다. soslab을 사용하여 대규모 GitLab 인프라 전체에서 문제를 식별합니다.

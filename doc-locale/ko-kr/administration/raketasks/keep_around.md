---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Keep-around 고아 참조 Rake 태스크
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Rake 태스크의 개선 사항이 GitLab 18.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/475246)되었습니다.

{{< /history >}}

`gitlab:keep_around:orphaned`는 프로젝트 리포지토리의 모든 keep-around 참조와 Git 커밋에 대한 모든 데이터베이스 참조의 CSV 보고서를 생성합니다.

CSV 보고서에는 세 개의 열이 있습니다:

- 참조 유형입니다. keep-around 참조의 경우 `keep` 또는 데이터베이스 참조의 경우 `usage`입니다.
- Git 커밋 ID입니다.
- 알려진 경우 참조의 소스입니다. 예를 들어, `Pipeline`.

## 고아 참조 보고서 실행 {#run-orphaned-reference-report}

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:keep_around:orphaned PROJECT_PATH=project/path FILENAME=/tmp/report.csv
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

```shell
bundle exec rake gitlab:keep_around:orphaned RAILS_ENV=production PROJECT_PATH=project/path FILENAME=/tmp/report.csv
```

{{< /tab >}}

{{< /tabs >}}

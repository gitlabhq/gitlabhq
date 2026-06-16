---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 가져오기 및 내보내기 Rake 작업
description: 대규모 프로젝트를 가져오고 내보내기 위한 Rake 작업입니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 [프로젝트 가져오기 및 내보내기](../../user/project/settings/import_export.md)를 위한 Rake 작업을 제공합니다.

[호환되는](../../user/project/settings/import_export.md#compatibility) GitLab 인스턴스에서만 가져올 수 있습니다.

## 대규모 프로젝트 가져오기 {#import-large-projects}

[Rake 작업](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/import_export/import.rake)은 대규모 GitLab 프로젝트 내보내기를 가져오는 데 사용됩니다.

이 작업의 일부로 직접 업로드도 비활성화합니다. 이렇게 하면 거대한 아카이브를 GCS에 업로드하는 것을 피할 수 있으며, 유휴 트랜잭션 타임아웃을 방지할 수 있습니다.

터미널에서 이 작업을 실행할 수 있습니다:

매개변수:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `username`      | 문자열 | 예 | 사용자 이름 |
| `namespace_path` | 문자열 | 예 | 네임스페이스 경로 |
| `project_path` | 문자열 | 예 | 프로젝트 경로 |
| `archive_path` | 문자열 | 예 | 가져올 내보낸 프로젝트 tarball의 경로 |

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
gitlab-rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file.tar.gz]"
```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

```shell
bundle exec rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file.tar.gz]" RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## 대규모 프로젝트 내보내기 {#export-large-projects}

Rake 작업을 사용하여 대규모 프로젝트를 내보낼 수 있습니다.

매개변수:

| 속성 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `username`      | 문자열 | 예 | 사용자 이름 |
| `namespace_path` | 문자열 | 예 | 네임스페이스 경로 |
| `project_path` | 문자열 | 예 | 프로젝트 이름 |
| `archive_path` | 문자열 | 예 | 내보낸 프로젝트 tarball을 저장할 파일의 경로 |

```shell
gitlab-rake "gitlab:import_export:export[username, namespace_path, project_path, archive_path]"
```

---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 리포지토리 점검
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[`git fsck`](https://git-scm.com/docs/git-fsck)를 사용하여 리포지토리에 커밋된 모든 데이터의 무결성을 확인할 수 있습니다. GitLab 관리자는 다음을 수행할 수 있습니다:

- [프로젝트에 대해 이 점검을 수동으로 트리거](#check-a-projects-repository-using-gitlab-ui)합니다.
- [이 점검을 예약](#enable-repository-checks-for-all-projects)하여 모든 프로젝트에 대해 자동으로 실행합니다.
- [명령줄에서 이 점검을 실행](#run-a-check-using-the-command-line)합니다.
- [Rake task](raketasks/check.md#repository-integrity)를 실행하여 Git 리포지토리를 확인합니다. 이를 사용하여 `git fsck`를 모든 리포지토리에 대해 실행하고 리포지토리 체크섬을 생성하여 다른 서버의 리포지토리를 비교할 수 있습니다.

명령줄에서 수동으로 실행되지 않는 점검은 Gitaly 노드를 통해 실행됩니다. Gitaly 리포지토리 일관성 점검, 비활성화된 일부 점검 및 일관성 점검 구성 방법에 대한 정보는 [리포지토리 일관성 점검](gitaly/consistency_checks.md)을 참조하세요.

## GitLab UI를 사용하여 프로젝트의 리포지토리 점검 {#check-a-projects-repository-using-gitlab-ui}

GitLab UI를 사용하여 프로젝트의 리포지토리를 점검하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **프로젝트**를 선택합니다.
1. 점검할 프로젝트를 선택합니다.
1. **리포지토리 점검** 섹션에서 **리포지토리 검사 트리거**를 선택합니다.

점검이 비동기적으로 실행되므로 **운영자** 영역의 프로젝트 페이지에 점검 결과가 표시되기까지 몇 분이 걸릴 수 있습니다. 점검이 실패하면 [할 일](#what-to-do-if-a-check-failed)을 참조하세요.

## 모든 프로젝트에 대해 리포지토리 검사 활성화 {#enable-repository-checks-for-all-projects}

리포지토리를 수동으로 확인하는 대신 GitLab을 주기적으로 점검을 실행하도록 구성할 수 있습니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **리포지토리**를 선택합니다.
1. **리포지토리 유지 보수**를 확장합니다.
1. **리포지토리 검사 활성화**를 활성화합니다.

활성화되면 GitLab은 모든 프로젝트 리포지토리 및 wiki 리포지토리에 대해 주기적으로 리포지토리 점검을 실행하여 가능한 데이터 손상을 감지합니다. 프로젝트는 월 1회 이상 확인되지 않으며 새 프로젝트는 최소 24시간 동안 확인되지 않습니다.

GitLab Self-Managed 관리자는 리포지토리 검사의 빈도를 구성할 수 있습니다. 빈도를 편집하려면:

- Linux 패키지 설치의 경우 `gitlab_rails['repository_check_worker_cron']`을 `/etc/gitlab/gitlab.rb`에서 편집합니다.
- 소스 기반 설치의 경우 `[gitlab.cron_jobs.repository_check_worker]`을 `/home/git/gitlab/config/gitlab.yml`에서 편집합니다.

프로젝트가 리포지토리 검사에 실패하면 모든 GitLab 관리자는 상황에 대한 이메일 알림을 받습니다. 기본적으로 이 알림은 일주일에 한 번 일요일 시작 시 자정에 전송됩니다.

알려진 점검 실패가 있는 리포지토리는 `/admin/projects?last_repository_check_failed=true`에서 찾을 수 있습니다.

## 명령줄을 사용하여 점검 실행 {#run-a-check-using-the-command-line}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

[`git fsck`](https://git-scm.com/docs/git-fsck) 를 [Gitaly 서버](gitaly/_index.md)의 리포지토리에서 명령줄을 사용하여 실행할 수 있습니다. 리포지토리를 찾으려면:

1. 리포지토리에 대한 저장소 위치로 이동합니다:
   - Linux 패키지 설치의 경우 리포지토리는 기본적으로 `/var/opt/gitlab/git-data/repositories` 디렉터리에 저장됩니다.
   - GitLab Helm 차트 설치의 경우 리포지토리는 기본적으로 Gitaly Pod 내부의 `/home/git/repositories` 디렉터리에 저장됩니다.
1. [리포지토리를 포함하는 하위 디렉터리를 식별](repository_storage_paths.md#from-project-name-to-hashed-path)합니다. 확인해야 할 항목입니다.
1. 점검을 실행합니다. 예를 들어:

   ```shell
   sudo -u git /opt/gitlab/embedded/bin/git \
      -C /var/opt/gitlab/git-data/repositories/@hashed/0b/91/0b91...f9.git fsck --no-dangling
   ```

   오류 `fatal: detected dubious ownership in repository`은(는) 잘못된 계정을 사용하여 명령을 실행하고 있음을 의미합니다. 예를 들어, `root`.

## 점검이 실패한 경우 수행할 작업 {#what-to-do-if-a-check-failed}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

리포지토리 점검이 실패하면 [`repocheck.log` 파일](logs/_index.md#repochecklog)에서 오류를 찾습니다. 디스크의 위치:

- Linux 패키지 설치의 경우 `/var/log/gitlab/gitlab-rails`
- 자체 컴파일된 설치의 경우 `/home/git/gitlab/log`
- GitLab Helm 차트 설치의 경우 Sidekiq Pod에서 `/var/log/gitlab`

주기적인 리포지토리 검사로 인해 거짓 경보가 발생하면 모든 리포지토리 검사 상태를 지울 수 있습니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **리포지토리**를 선택합니다.
1. **리포지토리 유지 보수**를 확장합니다.
1. **모든 리포지토리 검사 지우기**를 선택합니다.

## 문제 해결 {#troubleshooting}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

리포지토리 검사로 작업할 때 다음 문제가 발생할 수 있습니다.

### 오류: `failed to parse commit <commit SHA> from object database for commit-graph` {#error-failed-to-parse-commit-commit-sha-from-object-database-for-commit-graph}

리포지토리 점검 로그에서 `failed to parse commit <commit SHA> from object database for commit-graph` 오류를 볼 수 있습니다. 이 오류는 `commit-graph` 캐시가 만료된 경우 발생합니다. `commit-graph` 캐시는 보조 캐시이며 정상적인 Git 작업에는 필요하지 않습니다.

메시지는 안전하게 무시할 수 있지만 이슈 [오류: 커밋 그래프를 위한 객체 데이터베이스에서 읽을 수 없음](https://gitlab.com/gitlab-org/gitaly/-/issues/2359)에서 자세한 내용을 확인하세요.

### Dangling 커밋, 태그 또는 blob 메시지 {#dangling-commit-tag-or-blob-messages}

리포지토리 점검 출력에는 종종 잘려야 하는 태그, blob 및 커밋이 포함됩니다:

```plaintext
dangling tag 5c6886c774b713a43158aae35c4effdb03a3ceca
dangling blob 3e268c23fcd736db92e89b31d9f267dd4a50ac4b
dangling commit 919ff61d8d78c2e3ea9a32701dff70ecbefdd1d7
```

이는 Git 리포지토리에서 일반적입니다. 브랜치에 강제 푸시와 같은 작업으로 생성되므로 이는 ref 또는 다른 커밋으로 더 이상 참조되지 않는 리포지토리에서 커밋을 생성합니다.

리포지토리 점검이 실패하면 출력에 이러한 경고가 포함될 가능성이 높습니다.

이러한 메시지를 무시하고 다른 출력에서 리포지토리 점검 실패의 근본 원인을 파악합니다.

[GitLab 15.8 이상](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5230)은 더 이상 점검 출력에 이러한 메시지를 포함하지 않습니다. 명령줄에서 실행할 때 억제하려면 `--no-dangling` 옵션을 사용합니다.

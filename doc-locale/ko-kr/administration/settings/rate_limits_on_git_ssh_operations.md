---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Self-Managed에서 Git SSH 작업에 대한 속도 제한을 구성합니다.
title: Git SSH 작업에 대한 속도 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab은 사용자 계정 및 프로젝트별로 SSH를 사용하는 Git 작업에 속도 제한을 적용합니다. 사용자가 속도 제한을 초과하면 GitLab이 해당 사용자의 프로젝트에 대한 추가 연결 요청을 거부합니다.

속도 제한은 Git 명령([plumbing](https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain)) 수준에서 적용됩니다. 각 명령은 분당 600의 속도 제한을 가집니다. 예를 들어:

- `git push`은 분당 600의 속도 제한을 가집니다.
- `git pull`은 분당 600의 자체 속도 제한을 가집니다.

`git-upload-pack`, `git pull`, 그리고 `git clone` 명령은 공유하는 명령으로 인해 속도 제한을 공유합니다.

## GitLab Shell 작업 제한 구성 {#configure-gitlab-shell-operation-limit}

{{< history >}}

- GitLab 16.2에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123761).

{{< /history >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

`Git operations using SSH`은 기본적으로 활성화됩니다. 기본값은 사용자당 분당 600입니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **Git SSH operations rate limit**을 확장합니다.
1. **분당 최대 Git 작업 수**에 대한 값을 입력합니다.
   - 속도 제한을 비활성화하려면 `0`으로 설정합니다.
1. **변경 사항 저장**을 선택합니다.

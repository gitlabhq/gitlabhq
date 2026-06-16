---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: GitLab에서 Git LFS에 대한 속도 제한을 구성합니다.
title: Git LFS의 속도 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Git Large File Storage(LFS)](../../topics/git/lfs/_index.md)는 대용량 파일을 처리하기 위한 Git 확장입니다. Git LFS를 리포지토리에서 사용하면 일반적인 Git 작업으로 많은 Git LFS 요청이 생성될 수 있습니다. [일반 사용자 및 IP 속도 제한](user_and_ip_rate_limits.md)을 적용할 수 있지만, 일반 설정을 재정의하여 Git LFS 요청에 추가 속도 제한을 적용할 수도 있습니다. 이 재정의는 웹 애플리케이션의 보안과 내구성을 개선할 수 있습니다.

## GitLab.com {#on-gitlabcom}

GitLab.com에서 Git LFS 요청은 [인증된 웹 요청 속도 제한](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom)의 제약을 받습니다. 이러한 속도 제한은 사용자당 분당 1000개 요청으로 설정됩니다.

업로드되거나 다운로드된 각 Git LFS 개체는 이 속도 제한에 포함되는 HTTP 요청을 생성합니다.

> [!note]
> 대용량 파일이 여러 개 있는 리포지토리에서는 HTTP 속도 제한 오류가 발생할 수 있습니다. CI/CD 파이프라인 같은 자동화된 환경에서 단일 IP 주소로 수행할 때 클론 또는 풀 중에 이 오류가 발생합니다.

## GitLab Self-Managed {#on-gitlab-self-managed}

Git LFS 속도 제한은 GitLab Self-Managed 인스턴스에서 기본적으로 비활성화됩니다. 관리자는 Git LFS 트래픽에 특별히 전용 속도 제한을 구성할 수 있습니다. 활성화되면 이러한 전용 LFS 속도 제한이 기본 [사용자 및 IP 속도 제한](user_and_ip_rate_limits.md)을 재정의합니다.

### Git LFS 속도 제한 구성 {#configure-git-lfs-rate-limits}

전제 조건:

- 인스턴스의 관리자여야 합니다.

Git LFS 속도 제한을 구성하려면 다음을 수행합니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **Git LFS Rate Limits**를 확장합니다.
1. **인증된 Git LFS 요청 속도 제한 활성화**를 선택합니다.
1. **사용자당 기간당 최대 인증된 Git LFS 요청**에 대한 값을 입력합니다.
1. **인증된 Git LFS 속도 제한 기간(초)**에 대한 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 관련 항목 {#related-topics}

- [속도 제한](../../security/rate_limits.md)
- [사용자 및 IP 속도 제한](user_and_ip_rate_limits.md)

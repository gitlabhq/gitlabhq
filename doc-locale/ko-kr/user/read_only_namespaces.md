---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 읽기 전용 네임스페이스 및 프로젝트
---

## 읽기 전용 네임스페이스 {#read-only-namespaces}

{{< details >}}

- 티어:  Free
- 제공 서비스: GitLab.com

{{< /details >}}

네임스페이스는 [무료 사용자 제한](free_user_limit.md)을 초과하고 네임스페이스 공개 상태가 비공개일 때 읽기 전용 상태로 전환됩니다.

네임스페이스와 프로젝트의 읽기 전용 상태를 제거하려면 다음을 수행할 수 있습니다:

- 네임스페이스의 [멤버 수 감소](free_user_limit.md#manage-members-in-your-group-namespace)
- [무료 평가판 시작](https://gitlab.com/-/trial_registrations/new) \- 무제한 멤버 수 포함
- [유료 티어 구매](https://about.gitlab.com/pricing/)

### 제한된 작업 {#restricted-actions}

네임스페이스가 읽기 전용 상태일 때는 다음 표에 나열된 작업을 실행할 수 없습니다. 제한된 작업을 실행하려고 하면 `404` 오류가 발생할 수 있습니다.

| 기능 | 제한된 작업 |
|---------|-------------------|
| 컨테이너 레지스트리 | 정리 정책 생성, 편집, 삭제 <br> 컨테이너 레지스트리에 이미지 푸시 |
| 머지 리퀘스트 | 머지 리퀘스트 생성 및 업데이트 |
| 패키지 레지스트리 | 패키지 게시 |
| CI/CD | 파이프라인 생성, 편집, 관리, 실행 <br>  빌드 생성, 편집, 관리, 실행 <br>  관리 환경 생성 및 편집 <br> 관리 배포 생성 및 편집 <br>  관리 클러스터 생성 및 편집 <br> 관리 릴리스 생성 및 편집 |
| 네임스페이스 | **For exceeded free user limits**: 새 사용자 초대 |

## 읽기 전용 프로젝트 {#read-only-projects}

{{< details >}}

- 티어:  Free, Premium, Ultimate

{{< /details >}}

프로젝트는 다음의 할당된 스토리지 제한을 초과할 때 읽기 전용 상태로 전환됩니다:

- Free 티어 - 네임스페이스의 모든 프로젝트가 [무료 제한](storage_usage_quotas.md#free-limit)을 초과할 때
- Premium 및 Ultimate 티어 - 네임스페이스의 모든 프로젝트가 [고정 프로젝트 제한](storage_usage_quotas.md#fixed-project-limit)을 초과할 때

### 제한된 작업 {#restricted-actions-1}

프로젝트가 스토리지 제한으로 인해 읽기 전용 상태일 때는 프로젝트 리포지토리에 대용량 파일(LFS)을 푸시하거나 추가할 수 없습니다. 프로젝트 또는 네임스페이스 페이지 상단의 배너에 읽기 전용 상태가 표시됩니다.

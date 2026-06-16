---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Praefect Rake 작업
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Rake 작업은 Praefect 스토리지에서 생성된 프로젝트에 사용할 수 있습니다. [Praefect 설명서](../gitaly/praefect/_index.md)에서 Praefect를 구성하는 방법에 대한 정보를 확인하세요.

## 복제본 체크섬 {#replica-checksums}

`gitlab:praefect:replicas`은(는) 다음에서 리포지토리의 체크섬을 출력합니다:

- 기본 Gitaly 노드
- 보조 내부 Gitaly 노드

특정 프로젝트 또는 모든 프로젝트에 대한 복제본을 확인할 수 있습니다.

이 Rake 작업을 GitLab이 설치된 노드에서 실행하고, Praefect가 설치된 노드에서는 실행하지 마세요.

### 특정 프로젝트에 대한 복제본 확인 {#check-replicas-for-a-specific-project}

- Linux 패키지 설치:

  ```shell
  sudo gitlab-rake "gitlab:praefect:replicas[project_id]"
  ```

- 자체 컴파일된 설치:

  ```shell
  sudo -u git -H bundle exec rake "gitlab:praefect:replicas[project_id]" RAILS_ENV=production
  ```

### 모든 프로젝트에 대한 복제본 확인 {#check-replicas-for-all-projects}

{{< history >}}

- GitLab 18.10에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219120).

{{< /history >}}

수천 개의 프로젝트가 있는 대규모 GitLab 인스턴스에서 모든 프로젝트에 대한 복제본을 확인하면 리소스 집약적일 수 있습니다. 각 프로젝트는 Gitaly 서비스에 대한 외부 호출이 필요하기 때문입니다. 이 작업을 피크 시간이 아닌 시간대에 실행하거나 프로덕션 성능에 영향을 주지 않는 일정으로 실행하세요.

- Linux 패키지 설치:

  ```shell
  sudo gitlab-rake gitlab:praefect:replicas
  ```

- 자체 컴파일된 설치:

  ```shell
  sudo -u git -H bundle exec rake gitlab:praefect:replicas RAILS_ENV=production
  ```

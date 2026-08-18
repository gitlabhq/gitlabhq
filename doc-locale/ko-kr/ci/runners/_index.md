---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 러너
description: 구성 및 작업 실행.
---

러너는 [러너](https://docs.gitlab.com/runner/) 애플리케이션을 실행하는 에이전트로, 파이프라인에서 GitLab CI/CD 작업을 실행합니다. 이들은 `.gitlab-ci.yml` 파일에 정의된 빌드, 테스트, 배포 및 기타 CI/CD 작업을 실행할 책임이 있습니다.

## 러너 실행 플로우 {#runner-execution-flow}

다음은 러너가 작동하는 방식의 기본 워크플로우입니다:

1. 러너를 먼저 GitLab에 [등록](https://docs.gitlab.com/runner/register/)해야 하며, 이렇게 하면 러너와 GitLab 간의 지속적인 연결이 설정됩니다.
1. 파이프라인이 트리거되면 GitLab은 등록된 러너에서 작업을 사용 가능하게 합니다.
1. 일치하는 러너는 작업을 선택하고, 러너당 하나의 작업을 실행합니다.
1. 결과는 실시간으로 GitLab에 보고됩니다.

자세한 내용은 [러너 실행 플로우](https://docs.gitlab.com/runner/#runner-execution-flow)를 참조하세요.

## 러너 작업 스케줄링 및 실행 {#runner-job-scheduling-and-execution}

CI/CD 작업을 실행해야 할 때 GitLab은 `.gitlab-ci.yml` 파일에 정의된 작업을 기반으로 작업을 생성합니다. 작업은 큐에 배치됩니다. GitLab은 일치하는 사용 가능한 러너를 확인합니다:

- 러너 태그
- 러너 유형(공유 또는 그룹과 같은)
- 러너 상태 및 용량
- 필요한 기능

할당된 러너는 작업 세부 정보를 받습니다. 러너는 환경을 준비하고 `.gitlab-ci.yml` 파일에 지정된 작업의 명령을 실행합니다.

## 러너 카테고리 {#runner-categories}

CI/CD 작업을 실행할 러너를 결정할 때 다음을 선택할 수 있습니다:

- GitLab.com 또는 GitLab Dedicated 사용자용 [GitLab 호스팅 러너](hosted_runners/_index.md).
- 모든 GitLab 설치용 [자체 관리 러너](https://docs.gitlab.com/runner/).

러너는 그룹, 프로젝트 또는 인스턴스 러너일 수 있습니다. GitLab 호스팅 러너는 인스턴스 러너입니다.

### GitLab 호스팅 러너 {#gitlab-hosted-runners}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Dedicated

{{< /details >}}

GitLab 호스팅 러너는 다음과 같습니다:

- GitLab에서 완벽하게 관리됩니다.
- 설정 없이 즉시 사용 가능합니다.
- 각 작업마다 새로운 VM에서 실행됩니다.
- Linux, Windows 및 macOS 옵션을 포함합니다.
- 수요에 따라 자동으로 확장됩니다.

다음과 같은 경우 GitLab 호스팅 러너를 선택합니다:

- 유지 보수가 필요 없는 CI/CD를 원합니다.
- 인프라 관리 없이 빠른 설정이 필요합니다.
- 작업이 실행 간 격리를 필요로 합니다.
- 표준 빌드 환경으로 작업 중입니다.
- GitLab.com 또는 GitLab Dedicated를 사용 중입니다.

### 자체 관리 러너 {#self-managed-runners}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

자체 관리 러너는 다음과 같습니다:

- 사용자가 설치하고 관리합니다.
- 자신의 인프라에서 실행됩니다.
- 사용자의 필요에 맞게 사용자 지정 가능합니다.
- 다양한 실행기(Shell, Docker 및 Kubernetes 포함)를 지원합니다.
- 특정 프로젝트 또는 그룹으로 공유하거나 설정할 수 있습니다.

다음과 같은 경우 자체 관리 러너를 선택합니다:

- 사용자 지정 구성이 필요합니다.
- 프라이빗 네트워크에서 작업을 실행하려고 합니다.
- 특정 보안 제어가 필요합니다.
- 프로젝트 또는 그룹 러너가 필요합니다.
- 러너 재사용으로 속도를 최적화해야 합니다.
- 자신의 인프라를 관리하려고 합니다.

## 관련 항목 {#related-topics}

- [러너 설치](https://docs.gitlab.com/runner/install/)
- [러너 구성](https://docs.gitlab.com/runner/configuration/)
- [러너 관리](https://docs.gitlab.com/runner/)
- [GitLab Dedicated용 호스팅 러너](../../administration/dedicated/hosted_runners.md)

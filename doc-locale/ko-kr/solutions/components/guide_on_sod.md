---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "역할 기반 액세스 제어를 사용하여 GitLab 업무 분리 솔루션의 개요(주요 구성 요소, 워크플로 및 감사 기능 포함)"
title: 업무 분리에 대한 GitLab 튜토리얼 가이드
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 문서는 역할 기반 액세스 제어(RBAC)를 통한 GitLab 업무 분리(SoD) 솔루션의 개요를 제공합니다. 솔루션은 소프트웨어 개발 생명 주기의 중요한 프로세스에 대한 완전한 제어를 개인이 갖지 않도록 방지하여 보안 원칙 준수를 보장합니다.

## 시작하기 {#getting-started}

### 솔루션 구성 요소 액세스 {#access-the-solution-component}

1. 계정 팀에서 초대 코드를 받습니다.
1. [솔루션 구성 요소 웹스토어](https://cloud.gitlab-accelerator-marketplace.com)에서 초대 코드를 사용하여 솔루션 구성 요소에 액세스합니다.

## 업무 분리란 무엇입니까 {#what-is-separation-of-duties}

업무 분리는 단일 개인이 중요한 프로세스에 대한 완전한 제어를 갖지 않도록 하는 기본적인 보안 원칙입니다. 소프트웨어 개발에서 SoD는 다양한 역할과 팀 간의 책임을 분산하여 승인되지 않은 또는 실수로 인한 코드를 프로덕션 환경으로 배포하는 것을 방지합니다.

역할 기반 액세스 제어(RBAC)를 통해 SoD를 구현하는 GitLab 방식은 다음을 제공합니다:

- 개발 및 배포 역할 간의 명확한 분리
- 보호 환경을 사용하여 배포 액세스 제어
- 브랜치 보호를 통한 무단 코드 수정 방지
- 머지 리퀘스트 승인 정책을 통한 코드 검토 시행
- 준수 확인을 위한 기본 제공 감사 기능

## GitLab SoD 솔루션의 핵심 구성 요소 {#key-components-of-gitlab-sod-solution}

### 역할 기반 액세스 제어(RBAC) {#role-based-access-control-rbac}

RBAC는 SoD를 구현하고 시행하기 위한 프레임워크를 형성합니다. 플랫폼 전체의 권한 및 책임을 관리하며 최소 권한의 원칙을 준수합니다. RBAC를 통해 조직은 다음을 수행할 수 있습니다:

- 세분화된 역할 기반 제어를 통해 전체적인 사용자 관리 구현
- 최소 권한 액세스 원칙으로 역할 할당
- 감사/보고를 통해 역할 및 권한의 가시성 유지

### 기능 브랜치 워크플로 {#feature-branch-workflow}

기능 브랜치 워크플로는 개발 활동과 프로덕션 배포 간의 명확한 경계를 정의하여 SoD를 지원합니다:

- 개발 팀은 기능 브랜치에서 코드를 수정하고 테스트 파이프라인을 트리거할 수 있습니다
- 보안 팀은 품질 게이트를 위한 승인 정책을 관리합니다
- 머지 리퀘스트는 작성자가 아닌 다른 사용자의 독립적인 검토가 필요합니다

### 브랜치 보호 및 환경 {#protected-branches--environments}

기본 브랜치는 SoD 시행에서 핵심적인 역할을 합니다:

- 보호 환경은 배포를 지정된 팀으로 제한합니다
- 배포 팀은 배포를 실행할 권한이 있지만 소스 코드를 수정할 수 없습니다
- 브랜치 보호는 무단 병합 및 푸시를 방지합니다

### 감사 및 준수 기능 {#audit--compliance-capabilities}

GitLab은 준수 요구 사항을 지원하기 위해 강력한 감사 기능을 제공합니다:

- 자동으로 생성된 릴리스 증거
- 기본 브랜치 활동에 대한 이벤트 로깅

### 전제 조건 {#prerequisites}

GitLab SoD 솔루션을 완전히 구현하기 위해 조직은 다음이 필요합니다:

- GitLab Ultimate 라이선스
- 적절히 구성된 CI/CD 파이프라인
- 개발 및 배포 역할 간의 명확한 분리가 있는 사용자 그룹

### 추가 리소스 {#additional-resources}

GitLab SoD 구현에 대한 자세한 내용은 다음을 참조하세요:

- [GitLab 역할 및 권한 설명서](../../user/permissions.md)
- [브랜치 보호 설명서](../../user/project/repository/branches/protected.md)
- [보호 환경 설명서](../../ci/environments/protected_environments.md)
- [머지 리퀘스트 승인 설명서](../../user/project/merge_requests/approvals/_index.md)

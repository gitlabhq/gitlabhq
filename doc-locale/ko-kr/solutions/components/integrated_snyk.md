---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Snyk와 GitLab CI/CD를 통합하여 애플리케이션 보안을 구현하는 방법에 관한 가이드입니다. 워크플로 설정, SARIF 스캔, 취약성 보고 등을 포함합니다."
title: Snyk와 통합된 GitLab 애플리케이션 보안 워크플로
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## 시작하기 {#getting-started}

### 솔루션 구성 요소 다운로드 {#download-the-solution-component}

1. 계정 팀으로부터 초대 코드를 입수합니다.
1. 초대 코드를 사용하여 [솔루션 구성 요소 웹스토어](https://cloud.gitlab-accelerator-marketplace.com)에서 솔루션 구성 요소를 다운로드합니다.

## Snyk 통합 {#snyk-integration}

이것은 Snyk와 GitLab CI 간의 GitLab CI/CD 구성 요소를 통한 통합입니다.

## Snyk 워크플로우 {#snyk-workflow}

이 프로젝트에는 Snyk CLI를 실행하고 SARIF 형식으로 스캔 보고서를 출력하는 구성 요소가 있습니다. 이것은 SARIF를 GitLab 취약성 레코드 형식으로 변환하는 구성 요소를 호출하며, semgrep 기본 이미지를 기반으로 하는 작업을 사용합니다.

컨테이너 레지스트리에는 Snyk CLI가 설치된 노드 기본 이미지가 있는 버전이 지정된 컨테이너가 있습니다. 이것은 Snyk 구성 요소 작업에서 사용되는 이미지입니다. `.gitlab-ci.yml` 파일은 컨테이너 이미지를 빌드하고, 테스트하고, 구성 요소를 버전 관리합니다.

### 버전 관리 {#versioning}

이 프로젝트는 시멘틱 버전 관리를 따릅니다.

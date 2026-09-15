---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 강화 - CI/CD 권장 사항
---

일반 강화 지침 및 철학은 [주요 강화 문서](hardening.md)에 요약되어 있습니다.

CI/CD의 강화 권장 사항 및 개념은 다음 섹션에서 설명합니다.

## 기본 권장 사항 {#basic-recommendations}

다양한 CI/CD 설정을 구성하는 방법은 CI/CD의 사용 방식에 따라 달라집니다. 예를 들어 패키지를 빌드하는 데 사용하는 경우 Docker 이미지나 외부 코드 리포지토리와 같은 외부 리소스에 실시간으로 액세스해야 하는 경우가 많습니다. 코드 기반 인프라(IaC)에 사용하는 경우 배포를 자동화하기 위해 외부 시스템의 자격 증명을 저장해야 하는 경우가 많습니다. 이러한 상황과 다른 여러 시나리오에서 CI/CD 작업 중에 사용할 잠재적으로 민감한 정보를 저장해야 합니다. 개별 시나리오가 매우 많으므로 CI/CD 프로세스를 강화하는 데 도움이 되도록 기본 정보를 요약했습니다.

일반적인 지침은 다음과 같습니다:

- 보안 정보를 보호합니다.
- 네트워크 통신이 암호화되었는지 확인합니다.
- 감사 및 문제 해결 목적으로 철저한 로깅을 사용합니다.

## 특정 권장 사항 {#specific-recommendations}

파이프라인은 프로젝트 사용자를 대신하여 작업을 자동화하기 위해 스테이지에서 작업을 실행하는 GitLab CI/CD의 핵심 구성 요소입니다. 파이프라인 처리에 대한 구체적인 지침을 보려면 [파이프라인 보안](../ci/pipeline_security/_index.md) 정보를 참조하세요.

배포는 주어진 환경과의 관계에서 파이프라인의 결과를 배포하는 CI/CD의 부분입니다. 기본 설정은 많은 제한을 적용하지 않으며, 서로 다른 역할과 책임을 가진 다양한 사용자가 해당 환경과 상호 작용할 수 있는 파이프라인을 트리거할 수 있으므로 이러한 환경을 제한해야 합니다. 자세한 내용을 보려면 [보호 환경](../ci/environments/protected_environments.md)을 참조하세요.

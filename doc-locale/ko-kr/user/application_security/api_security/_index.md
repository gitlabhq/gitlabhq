---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API 보안
description: "보호, 분석, 테스트, 스캔 및 발견."
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

API 보안은 웹 응용 프로그램 인터페이스(API)를 무단 액세스, 오용 및 공격으로부터 보호하기 위해 취해지는 조치를 말합니다. API는 현대 애플리케이션 개발의 중요한 구성 요소이며, 애플리케이션이 서로 상호 작용하고 데이터를 교환할 수 있도록 합니다. 하지만 이는 또한 공격자에게 매력적이며 제대로 보안되지 않으면 보안 위협에 취약합니다. 이 섹션에서는 애플리케이션의 웹 API 보안을 보장하는 데 사용할 수 있는 GitLab 기능을 설명합니다. 설명한 기능 중 일부는 웹 API에 특정하며, 다른 기능은 웹 API 애플리케이션과 함께 사용되는 더 일반적인 솔루션입니다.

- [SAST](../sast/_index.md)는 애플리케이션의 코드베이스를 분석하여 취약성을 식별합니다.
- [종속성 검사](../dependency_scanning/_index.md)는 프로젝트의 타사 종속성을 검토하여 알려진 취약성(예: CVE)을 찾습니다.
- [Container scanning](../container_scanning/_index.md)은 컨테이너 이미지를 분석하여 알려진 OS 패키지 취약성 및 설치된 언어 종속성을 식별합니다.
- [API Discovery](api_discovery/_index.md)는 REST API를 포함하는 애플리케이션을 검토하고 해당 API에 대한 OpenAPI 사양을 추론합니다. OpenAPI 사양 문서는 다른 GitLab 보안 도구에서 사용됩니다.
- [API security testing analyzer](../api_security_testing/_index.md)는 웹 API의 동적 분석 보안 테스트를 수행합니다. 이는 OWASP Top 10을 포함하여 애플리케이션의 다양한 보안 취약성을 식별할 수 있습니다.
- [API fuzzing](../api_fuzzing/_index.md)은 웹 API의 퍼지 테스트를 수행합니다. 퍼지 테스트는 이전에 알려지지 않았으며 SQL 주입과 같은 기존 취약성 유형에 매핑되지 않는 애플리케이션의 이슈를 찾습니다.

---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: DAST(동적 애플리케이션 보안 테스팅)
description: "자동화된 침투 테스팅, 취약성 감지, 웹 애플리케이션 스캔, 보안 평가 및 CI/CD 통합입니다."
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> DAST 프록시 기반 분석기는 GitLab 16.9에서 [더 이상 사용되지 않으며](https://gitlab.com/gitlab-org/gitlab/-/issues/430966) GitLab 17.3에서 [제거되었습니다](https://gitlab.com/groups/gitlab-org/-/epics/11986). 이것은 주요 변경 사항입니다. DAST 프록시 기반 분석기에서 DAST 버전 5로 마이그레이션하는 방법에 대한 지침은 [프록시 기반 마이그레이션 가이드](proxy_based_to_browser_based_migration_guide.md)를 참조하세요. DAST 버전 4 브라우저 기반 분석기에서 DAST 버전 5로 마이그레이션하는 방법에 대한 지침은 [브라우저 기반 마이그레이션 가이드](browser_based_4_to_5_migration_guide.md)를 참조하세요.

DAST는 자동화된 침투 테스트를 실행하여 실행 중인 웹 애플리케이션 및 API의 취약성을 찾습니다. DAST는 해커의 접근 방식을 자동화하고 교차 사이트 스크립팅(XSS), SQL 주입(SQLi) 및 교차 사이트 요청 위조(CSRF)와 같은 중요한 위협에 대한 실제 공격을 시뮬레이션하여 다른 보안 도구가 감지하지 못하는 취약성과 오구성을 드러냅니다.

DAST는 완전히 언어에 중립적이며 외부에서 안으로 애플리케이션을 검사합니다. DAST 스캔은 CI/CD 파이프라인에서 실행하거나, 일정에 따라 실행하거나, 요청 시 수동으로 실행할 수 있습니다. 소프트웨어 개발 수명 주기 중에 DAST를 사용하면 프로덕션에 배포하기 전에 애플리케이션의 취약성을 발견할 수 있습니다. DAST는 소프트웨어 보안의 기초 구성 요소이며 다른 GitLab 보안 도구와 함께 사용하여 애플리케이션의 포괄적인 보안 평가를 제공해야 합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요는 [DAST - 고급 보안 테스팅](https://www.youtube.com/watch?v=nbeDUoLZJTo)을 참조하세요.

## GitLab DAST {#gitlab-dast}

GitLab DAST 및 API 보안 분석기는 현대적 웹 애플리케이션 및 API에 광범위한 보안 범위를 제공하는 독점 런타임 도구입니다.

필요에 따라 DAST 분석기를 사용하세요:

- 알려진 취약성에 대해 단일 페이지 웹 애플리케이션을 포함한 웹 기반 애플리케이션을 스캔하려면 [DAST](browser/_index.md) 분석기를 사용하세요.
- 알려진 취약성에 대해 API를 스캔하려면 [API 보안](../api_security_testing/_index.md) 분석기를 사용하세요. GraphQL, REST 및 SOAP과 같은 기술이 지원됩니다.

분석기는 [애플리케이션 보안](../_index.md)에 설명된 아키텍처 패턴을 따릅니다. 각 분석기는 CI/CD 파이프라인 템플릿을 사용하여 파이프라인에서 구성할 수 있으며 Docker 컨테이너에서 스캔을 실행합니다. 스캔은 [DAST 보고서 아티팩트](../../../ci/yaml/artifacts_reports.md#artifactsreportsdast)를 출력하며, GitLab은 이를 사용하여 소스 및 대상 브랜치 간의 스캔 결과 차이를 기반으로 발견된 취약성을 결정합니다.

## 스캔 결과 보기 {#view-scan-results}

발견된 취약성은 [머지 리퀘스트](../detect/security_scanning_results.md), [파이프라인 보안 탭](../detect/security_scanning_results.md) 및 [취약성 보고서](../vulnerability_report/_index.md)에 나타납니다.

> [!note]
> 파이프라인은 SAST 및 DAST 스캔을 포함한 여러 작업으로 구성될 수 있습니다. 어떤 이유로 작업이 완료되지 못하면 보안 대시보드에 DAST 스캐너 출력이 표시되지 않습니다. 예를 들어 DAST 작업이 완료되지만 SAST 작업이 실패하면 보안 대시보드에 DAST 결과가 표시되지 않습니다. 실패 시 분석기는 종료 코드를 출력합니다.

### 스캔된 URL 목록 {#list-urls-scanned}

DAST 스캔이 완료되면 머지 리퀘스트 페이지에 스캔된 URL의 수가 표시됩니다. **상세 보기**를 선택하면 스캔된 URL 목록을 포함하는 웹 콘솔 출력을 볼 수 있습니다.

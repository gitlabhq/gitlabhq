---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab과 프로그래밍 방식으로 상호 작용합니다.
title: GitLab 확장 시작
---

GitLab과 프로그래밍 방식으로 상호 작용합니다. 작업을 자동화하고 다른 도구와 통합하며 사용자 지정 워크플로를 만듭니다. GitLab은 플러그인과 사용자 지정 훅도 지원합니다.

다음 단계를 따라 GitLab 확장에 대해 자세히 알아보세요.

## 1단계:  통합 설정 {#step-1-set-up-integrations}

GitLab은 개발 워크플로를 간소화하는 데 도움이 되는 주요 통합을 여러 개 제공합니다.

이러한 통합은 다음을 포함한 다양한 영역을 다룹니다:

- **인증**:  OAuth, SAML, LDAP
- **계획**:  Jira, Bugzilla, Redmine, Pivotal Tracker
- **커뮤니케이션**:  Slack, Microsoft Teams, Mattermost
- **보안**:  Checkmarx, Veracode, Fortify

자세한 정보는 다음을 참조하세요:

- [통합 목록](../../integration/_index.md)

## 2단계:  웹후크 설정 {#step-2-set-up-webhooks}

웹후크를 사용하여 GitLab 이벤트에 대해 외부 서비스에 알립니다.

웹후크는 푸시, 병합 및 커밋과 같은 특정 이벤트를 수신합니다. 이러한 이벤트 중 하나가 발생하면 GitLab은 HTTP POST 페이로드를 웹후크의 구성된 URL로 보냅니다. 웹후크에서 보낸 페이로드는 이벤트 이름, 프로젝트 ID, 사용자 및 커밋 세부 정보와 같은 이벤트에 대한 세부 정보를 제공합니다. 그러면 외부 시스템이 이벤트를 식별하고 처리합니다.

예를 들어, 코드가 GitLab으로 푸시될 때마다 새로운 Jenkins 빌드를 트리거하는 웹후크를 만들 수 있습니다.

프로젝트별 또는 전체 GitLab 인스턴스에 대해 웹후크를 구성할 수 있습니다. 프로젝트별 웹후크는 하나의 특정 프로젝트에 대한 이벤트를 수신합니다.

웹후크를 사용하여 GitLab을 CI/CD 시스템, 채팅 및 메시징 플랫폼, 모니터링 및 로깅 도구 등 다양한 외부 도구와 통합할 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [웹후크](../../user/project/integrations/webhooks.md)

## 3단계:  API 사용 {#step-3-use-the-apis}

REST API 또는 GraphQL API를 사용하여 GitLab과 프로그래밍 방식으로 상호 작용하고 사용자 지정 통합을 구축하거나 데이터를 검색하거나 프로세스를 자동화합니다. API는 프로젝트, 이슈, 머지 리퀘스트, 리포지토리를 포함한 GitLab의 다양한 측면을 다룹니다.

GitLab REST API는 RESTful 원칙을 따르고 요청 및 응답에 대한 데이터 형식으로 JSON을 사용합니다. 개인 액세스 토큰 또는 OAuth 2.0 토큰을 사용하여 이러한 요청 및 응답을 인증할 수 있습니다.

GitLab은 또한 데이터를 쿼리할 때 더 유연하고 효율적인 GraphQL API를 제공합니다.

cURL 또는 REST API 클라이언트로 API를 탐색하여 요청 및 응답을 이해해 보세요. 그런 다음 API를 사용하여 프로젝트 생성 및 그룹에 멤버 추가와 같은 작업을 자동화합니다.

자세한 정보는 다음을 참조하세요:

- [REST API](../api_resources.md)
- [GraphQL API](../graphql/reference/_index.md)

## 4단계:  GitLab CLI 사용 {#step-4-use-the-gitlab-cli}

GitLab CLI는 다양한 GitLab 작업을 완료하고 GitLab 인스턴스를 관리하는 데 도움이 될 수 있습니다.

GitLab CLI를 사용하여 다음과 같은 모든 종류의 대량 작업을 더 빠르게 수행할 수 있습니다:

- 새로운 프로젝트, 그룹 및 기타 GitLab 리소스 생성
- 사용자 및 권한 관리
- GitLab 인스턴스 간 프로젝트 가져오기 및 내보내기
- CI/CD 파이프라인 트리거

자세한 정보는 다음을 참조하세요:

- [GitLab CLI 설치](https://gitlab.com/gitlab-org/cli/#installation)

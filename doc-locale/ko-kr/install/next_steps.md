---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab을 설치한 후 이메일, 인증, CI/CD, GitLab Duo 및 기타 기능을 구성합니다."
title: GitLab 설치 후 단계
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

설치를 완료한 후 확인할 수 있는 몇 가지 리소스는 다음과 같습니다.

## 초기 로그인 {#initial-sign-in}

GitLab을 설치한 후 설치 중에 설정한 URL을 방문하여 `root` 사용자로 로그인할 수 있습니다.

설치 중에 자신의 비밀번호를 설정하지 않았다면 임의의 비밀번호가 할당됩니다. GitLab을 설치한 서버에서 `/etc/gitlab/initial_root_password` 아래에서 찾을 수 있습니다.

## 이메일 및 알림 {#email-and-notifications}

- [SMTP](https://docs.gitlab.com/omnibus/settings/smtp/): 적절한 이메일 알림 지원을 위해 SMTP를 구성합니다.
- [수신 이메일](../administration/incoming_email.md): 사용자가 이메일을 사용하여 의견에 답글을 달거나 새로운 이슈 및 머지 리퀘스트 등을 생성할 수 있도록 수신 이메일을 구성합니다.

## GitLab Duo {#gitlab-duo}

- [GitLab Duo](../user/gitlab_duo/_index.md): GitLab이 제공하는 AI 기반 기능과 활성화 방법을 알아봅니다.
- [GitLab Duo Self-Hosted](../administration/gitlab_duo_self_hosted/_index.md): GitLab Duo Self-Hosted를 배포하여 선호하는 GitLab 지원 LLM을 사용합니다.
- [GitLab Duo 데이터 사용](../user/gitlab_duo/data_usage.md): GitLab이 AI 데이터 개인정보를 어떻게 처리하는지 알아봅니다.

## CI/CD (러너) {#cicd-runner}

- [러너 설정](https://docs.gitlab.com/runner/): CI/CD 작업을 실행할 책임이 있는 하나 이상의 러너를 설정합니다.

## 컨테이너 레지스트리 {#container-registry}

- [컨테이너 레지스트리](../administration/packages/container_registry.md): 각 GitLab 프로젝트의 컨테이너 이미지를 저장할 수 있는 통합 컨테이너 레지스트리입니다.
- [종속성 프록시](../administration/packages/dependency_proxy.md): 종속성 프록시를 설정하여 Docker Hub에서 컨테이너 이미지를 캐시하여 더 빠르고 안정적인 빌드를 수행합니다.

## Pages {#pages}

- [GitLab Pages](../user/project/pages/_index.md): GitLab의 리포지토리에서 직접 정적 웹 사이트를 게시합니다

## 보안 {#security}

- [GitLab 보안](../security/_index.md): GitLab 인스턴스를 보안하기 위한 권장 방법입니다.
- GitLab [보안 뉴스레터](https://about.gitlab.com/company/preference-center/)를 구독하여 보안 업데이트 출시 시 알림을 받습니다.

## 인증 {#authentication}

- [LDAP](../administration/auth/ldap/_index.md): LDAP를 GitLab의 인증 메커니즘으로 사용하도록 구성합니다.
- [SAML 및 OAuth](../integration/omniauth.md): Okta, Google, Azure AD 등과 같은 온라인 서비스를 통해 인증합니다.

## 백업 및 업그레이드 {#backup-and-upgrade}

- [GitLab 백업 및 복원](../administration/backup_restore/_index.md): GitLab을 백업하거나 복원할 수 있는 여러 방법을 알아봅니다.
- [GitLab 업그레이드](../update/_index.md): 매월 새로운 기능이 풍부한 GitLab 버전이 출시됩니다. 업그레이드하는 방법 또는 보안 수정 사항을 포함하는 중간 버전으로 업그레이드하는 방법을 알아봅니다.
- [릴리스 및 유지 관리 정책](../policy/maintenance.md): 버전 명명을 제어하는 GitLab 정책은 물론 주요, 부분 및 패치 릴리스의 출시 속도에 대해 알아봅니다.

## 라이선스 {#license}

- [라이선스 추가](../administration/license.md) 또는 [무료 평가판 시작](https://about.gitlab.com/free-trial/): 라이선스를 사용하여 모든 GitLab Enterprise Edition 기능을 활성화합니다.
- [가격](https://about.gitlab.com/pricing/): 다양한 티어의 가격 정보입니다.

## 크로스 리포지토리 코드 검색 {#cross-repository-code-search}

- [고급 검색](../integration/advanced_search/elasticsearch.md): [Elasticsearch](https://www.elastic.co/) 또는 [OpenSearch](https://opensearch.org/)를 활용하여 전체 GitLab 인스턴스에서 더 빠르고 고급 코드 검색을 수행합니다.

## 확장 및 복제 {#scaling-and-replication}

- [GitLab 확장](../administration/reference_architectures/_index.md): GitLab은 여러 가지 유형의 클러스터링을 지원합니다.
- [Geo 복제](../administration/geo/_index.md): Geo는 광범위하게 분산된 개발 팀을 위한 솔루션입니다.

## 제품 설명서 설치 {#install-the-product-documentation}

선택 사항. 자신의 서버에서 설명서를 호스팅하려면 [제품 설명서 자체 호스팅](../administration/docs_self_host.md) 방법을 확인하세요.

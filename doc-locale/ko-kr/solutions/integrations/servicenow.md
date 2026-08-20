---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ServiceNow
description: "GitLab 워크플로우를 중앙에서 관리하고 자동화하도록 ServiceNow를 구성합니다."
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

ServiceNow는 GitLab 워크플로우 관리를 중앙에서 관리하고 자동화할 수 있도록 여러 통합을 제공합니다.

스택을 단순화하고 프로세스를 간소화하려면 가능한 한 GitLab [배포 승인](../../api/oauth2.md)을 사용해야 합니다.

## GitLab 스포크 {#gitlab-spoke}

ServiceNow의 GitLab 스포크를 사용하면 GitLab 프로젝트, 그룹, 사용자, 이슈, 머지 리퀘스트, 브랜치 및 리포지토리에 대한 작업을 자동화할 수 있습니다.

전체 기능 목록을 확인하려면 [GitLab 스포크 설명서(Xanadu 릴리스)](https://docs.servicenow.com/bundle/xanadu-integrate-applications/page/administer/integrationhub-store-spokes/concept/gitlab-spoke.html)를 참조하세요.

[GitLab을 OAuth 2.0 인증 서비스 제공자로 구성](../../integration/oauth_provider.md)해야 하며, 이는 애플리케이션을 만든 후 ServiceNow에서 애플리케이션 ID와 보안 암호를 제공하는 것을 포함합니다.

## GitLab SCM 및 DevOps용 지속적 통합 {#gitlab-scm-and-continuous-integration-for-devops}

ServiceNow DevOps에서 GitLab 리포지토리 및 GitLab CI/CD와 통합하여 GitLab 활동 및 변경 관리 프로세스에 대한 보기를 중앙에서 관리할 수 있습니다. 다음을 수행할 수 있습니다.

- GitLab 리포지토리 및 CI/CD 파이프라인의 활동에 대한 정보를 ServiceNow에서 추적합니다.
- GitLab CI/CD 파이프라인과 통합하여 변경 티켓 생성을 자동화하고 자동 승인할 변경 사항의 기준을 결정합니다.

자세한 내용은 다음 ServiceNow 리소스를 참조하세요:

- [ServiceNow DevOps 홈페이지](https://www.servicenow.com/products/devops.html)
- [ServiceNow DevOps 설명서](https://docs.servicenow.com/bundle/tokyo-devops/page/product/enterprise-dev-ops/concept/dev-ops-bundle-landing-page.html)
- [GitLab SCM 및 DevOps용 지속적 통합](https://store.servicenow.com/sn_appstore_store.do#!/store/application/54dc4eacdbc2dcd02805320b7c96191e/)

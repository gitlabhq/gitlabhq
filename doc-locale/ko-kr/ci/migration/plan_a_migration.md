---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 다른 도구에서 GitLab CI/CD로의 마이그레이션 계획
description: "Jenkins, GitHub Actions 등에서 마이그레이션합니다."
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

다른 도구에서 GitLab CI/CD로 마이그레이션을 시작하기 전에 먼저 마이그레이션 계획을 수립해야 합니다.

더 큰 규모의 마이그레이션을 위한 초기 단계에 대한 조언을 먼저 [조직 변화 관리](#manage-organizational-changes)에 대한 조언을 검토하세요.

마이그레이션에 참여하는 사용자는 예상을 설정하기 위한 중요한 기술적 단계로서 [마이그레이션을 시작하기 전에 확인할 질문](#technical-questions-to-ask-before-starting-a-migration)을 검토해야 합니다. CI/CD 도구는 접근 방식, 구조 및 기술 세부 사항이 다릅니다. 일부 개념은 일대일로 매핑되지만, 다른 개념은 대화형 변환이 필요합니다.

기존 도구의 동작을 엄격하게 변환하는 대신 원하는 최종 상태에 집중하는 것이 중요합니다.

## 조직 변화 관리 {#manage-organizational-changes}

GitLab CI/CD로의 전환에서 중요한 부분은 이동에 따른 문화적, 조직적 변화와 이를 성공적으로 관리하는 것입니다.

조직에서 도움이 되었다고 보고한 몇 가지 사항:

- 마이그레이션 목표에 대한 명확한 비전을 설정하고 전달하세요. 이는 사용자가 그 노력이 가치 있는 이유를 이해하는 데 도움이 됩니다. 작업이 완료되면 가치가 명확하지만, 진행 중일 때도 사람들이 인식해야 합니다.
- 관련 리더십 팀의 후원과 일치는 이전 사항을 돕습니다.
- 사용자에게 무엇이 다른지 교육하는 데 시간을 투자하고 이 가이드를 사용자와 공유하세요.
- 마이그레이션의 일부를 순서를 정하거나 지연시키는 방법을 찾으면 많은 도움이 될 수 있습니다. 중요한 것은 마이그레이션되지 않은(또는 부분적으로 마이그레이션된) 상태로 오래 방치하지 않는 것입니다.
- GitLab의 모든 이점을 얻으려면 기존 구성을 현재 상태 그대로 이동하는 것(현재의 모든 문제 포함)만으로는 충분하지 않습니다. GitLab CI/CD가 제공하는 개선 사항을 활용하고 전환 과정에서 구현을 업데이트하세요.

## 마이그레이션을 시작하기 전에 확인할 기술적 질문 {#technical-questions-to-ask-before-starting-a-migration}

CI/CD 요구 사항에 대한 초기 기술적 질문을 하면 마이그레이션 요구 사항을 빠르게 정의하는 데 도움이 됩니다:

- 이 파이프라인을 사용하는 프로젝트는 몇 개입니까?
- 어떤 분기 전략이 사용됩니까? 기능 브랜치? Mainline? 릴리스 브랜치?
- 코드를 빌드하는 데 어떤 도구를 사용합니까? 예를 들어, Maven, Gradle 또는 NPM입니까?
- 코드를 테스트하는 데 어떤 도구를 사용합니까? 예를 들어 JUnit, Pytest 또는 Jest입니까?
- 보안 스캐너를 사용합니까?
- 빌드된 패키지는 어디에 저장합니까?
- 코드를 어떻게 배포합니까?
- 코드는 어디에 배포합니까?

## 관련 항목 {#related-topics}

- Atlassian Bamboo Server의 CI/CD 인프라를 GitLab CI/CD로 마이그레이션하는 방법, [첫 번째 부분](https://about.gitlab.com/blog/migration-from-atlassian-bamboo-server-to-gitlab-ci/) 및 [두 번째 부분](https://about.gitlab.com/blog/how-to-migrate-atlassians-bamboo-servers-ci-cd-infrastructure-to-gitlab-ci-part-two/)

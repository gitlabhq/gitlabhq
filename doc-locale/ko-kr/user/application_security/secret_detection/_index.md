---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 시크릿 검색
description: "탐지, 방지, 모니터링, 저장, 취소, 그리고 보고."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

응용 프로그램은 CI/CD 서비스, 데이터베이스 또는 외부 저장소를 포함한 외부 리소스를 사용할 수 있습니다. 이러한 리소스에 대한 액세스에는 개인 키 및 토큰과 같은 정적 방법을 일반적으로 사용하여 인증이 필요합니다. 이러한 방법은 다른 사람과 공유하지 않아야 하기 때문에 "시크릿"이라고 불립니다.

시크릿 노출 위험을 최소화하려면 항상 [리포지토리 외부에 시크릿을 저장](../../../ci/secrets/_index.md)하세요. 그러나 시크릿은 때때로 실수로 Git 리포지토리에 커밋될 수 있습니다. 민감한 값이 원격 리포지토리로 푸시된 후 리포지토리에 액세스할 수 있는 모든 사용자는 시크릿을 사용하여 승인된 사용자를 가장할 수 있습니다.

시크릿 검색은 다음 두 가지를 위해 사용자의 활동을 모니터링합니다:

- 시크릿이 유출되는 것을 방지합니다.
- 시크릿이 유출된 경우 대응할 수 있도록 도와줍니다.

다층 방어 보안 접근 방식을 취하고 사용 가능한 모든 시크릿 검색 방법을 활성화해야 합니다:

- [시크릿 푸시 보호](secret_push_protection/_index.md)는 GitLab에 변경 사항을 푸시할 때 커밋에서 시크릿을 검색합니다. 시크릿이 감지되면 푸시가 차단됩니다. 시크릿 푸시 보호를 건너뛸 수 없는 경우는 제외합니다. 이 방법은 시크릿이 유출될 위험을 줄입니다.
- [파이프라인 시크릿 검색](pipeline/_index.md)은 프로젝트의 CI/CD 파이프라인의 일부로 실행됩니다. 리포지토리의 기본 브랜치에 대한 커밋이 시크릿을 검색합니다. 머지 리퀘스트 파이프라인에서 파이프라인 시크릿 검색을 활성화하면 개발 브랜치에 대한 커밋이 시크릿을 검색하므로 기본 브랜치에 커밋되기 전에 대응할 수 있습니다.
- [클라이언트 측 시크릿 검색](client/_index.md)은 GitLab에 저장되기 전에 이슈 및 머지 리퀘스트의 설명 및 주석에서 시크릿을 검색합니다. 시크릿이 감지되면 입력을 편집하고 시크릿을 제거하거나, 거짓 양성인 경우 설명 또는 주석을 저장할 수 있습니다.

시크릿이 리포지토리에 커밋되면 GitLab이 취약성 보고서에 노출을 기록합니다. 일부 시크릿 유형의 경우 GitLab이 노출된 시크릿을 자동으로 취소할 수 있습니다. 노출된 시크릿을 항상 가능한 한 빨리 취소하고 교체해야 합니다. 시크릿 관련 수정 지침은 취약성 보고서에 제공된 세부 정보를 검토하세요.

## GitLab Duo를 사용한 거짓 양성 감소 {#reducing-false-positives-with-gitlab-duo}

시크릿 검색 스캐너는 취약성 보고서에 노이즈를 생성하는 거짓 양성을 생성할 수 있습니다. [GitLab Duo 거짓 양성 검색](../vulnerabilities/secret_false_positive_detection.md) 기능은 자동으로 시크릿 검색 결과를 분석하여 가능성 있는 거짓 양성을 식별합니다. 이를 통해 보안 팀이 실제 시크릿에 집중하고 수동 심사에 소요되는 시간을 줄일 수 있습니다.

GitLab Duo 추가 기능이 있는 Ultimate 계층 고객의 경우, 거짓 양성 탐지가 각 보안 스캔 후에 자동으로 실행되며 각 평가에 대한 신뢰도 점수와 설명을 제공합니다.

## 관련 항목 {#related-topics}

- [시크릿 검색 제외](exclusions.md)
- [취약점 보고서](../vulnerability_report/_index.md)
- [유출된 시크릿에 대한 자동 대응](automatic_response.md)
- [푸시 규칙](../../project/repository/push_rules.md)
- [스크릿 거짓 양성 탐지](../vulnerabilities/secret_false_positive_detection.md)

---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 지원 세부 정보입니다.
title: 개발의 여러 스테이지에서 기능에 대한 지원
---

<!--
This page contains information targeting public users and customers of GitLab features.
The goal is to help users understand the risks of using features in various stages of development.

The user-targeted content has been approved by the GitLab legal team.
If you change this information, consider getting a legal team member to review it.

To add information about internal GitLab guidelines for developing and releasing features,
consider adding it to the handbook or to the '## Feature release requirements' section at the end of this page.
-->

GitLab은 때때로 실험적 또는 베타 등 다양한 개발 스테이지에서 기능을 릴리스합니다. 사용자는 옵트인하여 새로운 환경을 테스트할 수 있습니다. 이러한 종류의 기능 릴리스의 일부 이유는 다음과 같습니다:

- 모든 설계된 사용 사례에 대해 현재 형태의 기능의 확장, 지원 및 유지 관리 부담의 극단적인 경우를 검증합니다.
- 완전하지 않아 MVC로 간주되기에 충분하지 않지만 개발 프로세스의 일부로 코드베이스에 추가된 기능입니다.

일부 기능은 권장 사항이 마련되기 전에 개발되었거나 팀에서 대체 구현 방식이 필요하다고 판단한 경우 이러한 권장 사항에 맞지 않을 수 있습니다.

다른 모든 기능은 공개적으로 이용 가능한 것으로 간주됩니다.

## 실험 {#experiment}

실험적 기능:

- 프로덕션 사용을 위해 준비되지 않았습니다.
- [지원이 없습니다](https://support.gitlab.com/hc/en-us/articles/11625911285404-Statement-of-Support#experiment-&-beta-features). 이러한 기능과 관련된 이슈는 [GitLab 이슈 추적기](https://gitlab.com/gitlab-org/gitlab/-/issues)에서 열어야 합니다.
- 불안정할 수 있습니다.
- 언제든지 제거될 수 있습니다.
- 일반 공개로 발전하지 않을 수 있습니다.
- 데이터 손실의 위험이 있을 수 있습니다.
- 문서가 없거나 정보가 GitLab 이슈 또는 블로그로만 제한될 수 있습니다.
- 최종 사용자 환경이 없을 수 있으며 빠른 작업 또는 API 요청을 통해서만 액세스할 수 있습니다.

## 베타 {#beta}

베타 기능:

- 프로덕션 사용을 위해 준비되지 않을 수 있습니다.
- [상업적으로 합리적인 노력을 기반으로 지원](https://about.gitlab.com/support/statement-of-support/#experiment-beta-features)되지만 이슈를 해결하기 위해 개발로부터 추가 시간과 지원이 필요하다는 기대가 있습니다.
- 불안정할 수 있습니다.
- 변경될 가능성이 낮은 구성과 종속성이 있습니다.
- 변경될 가능성이 낮은 기능과 함수가 있습니다. 그러나 주요 릴리스 외에 또는 일반적으로 사용 가능한 기능보다 적은 공지를 통해 변경 사항이 발생할 수 있습니다.
- 데이터 손실의 위험이 낮습니다.
- 완전하거나 거의 완료된 사용자 환경이 있습니다.
- 파트너 "공개 미리보기" 상태와 동등할 수 있습니다.

## 공개 가용성 {#public-availability}

두 가지 유형의 공개 릴리스를 사용할 수 있습니다:

- 제한된 가용성
- 일반적으로 사용 가능

두 유형 모두 프로덕션 준비가 되어 있지만 범위가 다릅니다.

### 제한된 가용성 {#limited-availability}

제한된 가용성 기능은 일반적으로 사용 가능한 기능과 동일한 보안 요구 사항을 따르지만 초기 롤아웃 중에 플랫폼의 부분 집합에 배포되거나 확장 제한을 받을 수 있습니다.

제한된 가용성 기능:

- 축소된 규모에서 프로덕션 사용을 위해 준비됩니다.
- 하나 이상의 GitLab 플랫폼(GitLab.com, GitLab Self-Managed, GitLab Dedicated)에서 처음에 사용할 수 있습니다.
- 처음에는 무료이거나 일반적으로 사용 가능할 때 유료가 될 수 있습니다.
- 일반적으로 사용 가능해지기 전에 할인으로 제공될 수 있습니다.
- 일반적으로 사용 가능할 때 새 계약의 상업 조건이 변경될 수 있습니다.
- [완전히 지원](https://about.gitlab.com/support/statement-of-support/)되고 문서화되어 있습니다.
- GitLab 설계 표준에 맞춘 완전한 사용자 환경이 있습니다.

### 일반적으로 사용 가능 {#generally-available}

일반적으로 사용 가능한 기능:

- 모든 규모에서 프로덕션 사용을 위해 준비됩니다.
- [완전히 지원](https://about.gitlab.com/support/statement-of-support/)되고 문서화되어 있습니다.
- GitLab 설계 표준에 맞춘 완전한 사용자 환경이 있습니다.
- 모든 GitLab 제품(GitLab.com, GitLab.com Cells, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government)에서 사용 가능해야 합니다.
- GitLab Duo Agent Platform에서 일반적으로 사용 가능한 기능의 사용은 GitLab Credits를 사용합니다. 기능이 가장 최근 GitLab 버전에서 일반적으로 사용 가능해지면 기능 사용이 모든 버전 및 제품에서 크레딧을 사용하기 시작합니다. 베타 기능은 언제든지 사용 요금이 부과되는 일반 사용 가능으로 변경될 수 있습니다.

## 기능 릴리스 요구 사항 {#feature-release-requirements}

기능을 사용자에게 제공하기 전에 기능을 개발하는 GitLab 팀은 위의 상태 지침과 개발의 각 스테이지에 대한 요구 사항을 고려해야 합니다.

### 용어 {#terminology}

명확하게 하기 위해 이 지침은 다음 정의를 사용합니다:

- **Explicit opt-in**:  기능이 기본적으로 비활성화되어 있으며 인증된 사용자(예: 인스턴스 관리자, 그룹 소유자 또는 개별 사용자, 기능 범위에 따라)의 의도적인 활성화 작업이 필요합니다. 활성화할 수 있지만 활성화되지 않으면 비활성화된 상태로 유지되는 기능은 명시적 옵트인이 필요한 것으로 간주됩니다.
- **기본적으로 활성화됨**:  기능이 옵트인 작업을 요구하지 않고 사용자 또는 인스턴스에 대해 활성화됩니다. 기능은 실험적 또는 베타 스테이지 중에 기본적으로 활성화되면 안 됩니다.
- **Production use**:  다음을 모두 의미합니다:
  - 고객 프로덕션 워크로드(사용자가 비즈니스 운영에 의존하는 기능)
  - GitLab.com, Dedicated 및 Dedicated for Federal을 지원하는 GitLab 관리 프로덕션 인프라(플랫폼 안정성 또는 보안에 영향을 미치는 공유 서비스)
- **Internal testing**:  검증 목적으로 GitLab 팀 멤버의 GA 이전 기능 사용(Customer Zero라고도 함)입니다.

### 기능 성숙도 전환 원칙 {#feature-maturity-transition-principle}

기능이 성숙도 스테이지를 진행할 준비가 되었는지 평가할 때 **incident response test**를 적용합니다:

> "이 기능이 이미 목표 성숙도 수준에 있었고 이 위험이 나타났다면 인시던트를 선언하고 긴급 수정을 적용하겠습니까?"

기능은 GA 이후에 발생할 경우 인시던트 대응을 트리거할 위험과 함께 GA로 전환하면 안 되며 다음을 포함합니다:

- 중요(S1/S2) 보안 취약성
- SLA 약정을 위반하는 성능 저하
- 고객 알림이 필요한 데이터 무결성 이슈
- 플랫폼 안정성에 영향을 미치는 가용성 영향

이 원칙은 예측 가능한 향후 인시던트를 생성하기보다는 기능이 적절한 위험 태세로 프로덕션 성숙도에 도달하도록 보장합니다.

### 실험적 기능 {#experimental-features}

- 기본적으로 비활성화되어 있어야 하며 명시적 옵트인이 필요합니다. 고객 작업 없이 사용자 또는 인스턴스에 대해 자동으로 활성화될 수 없습니다.
- 다중 테넌트 플랫폼에서 옵트인한 사용자가 다른 테넌트에 대한 위험을 생성하지 않도록 테넌트 격리를 유지해야 합니다.
- 릴리스 성숙도의 현재 상태에 따라 표준(공개적으로)에서 보안 수정 사항이 릴리스될 수 있습니다. 표준 취약성 수정 SLO는 실험적 기능에 적용되지 않습니다.
- 명시된 베타 요구 사항을 충족하지 않고 베타로 이동하기 위한 예외에 대해 VP 승인이 필요합니다.

내부 테스트(Customer Zero)는 엔지니어링 검증을 위해 실험적 기능을 사용할 수 있습니다. 회사 전체 비즈니스 프로세스(예: 온보딩, 액세스 관리 또는 준수 워크플로우)에 영향을 미치는 기능은 엔지니어링 및 보안 리더십으로부터 문서화된 위험 수용이 필요합니다.

### 베타 기능 {#beta-features}

- 기본적으로 비활성화되어 있어야 하며 명시적 옵트인이 필요합니다. 고객 작업 없이 사용자 또는 인스턴스에 대해 자동으로 활성화될 수 없습니다.
- 다중 테넌트 플랫폼에서 옵트인한 사용자가 다른 테넌트에 대한 위험을 생성하지 않도록 테넌트 격리를 유지해야 합니다.
- 일반 공개 전에 보안 릴리스 프로세스를 설정하기 위한 문서화되고 이해관계자가 조율된 계획이 있어야 합니다. 이 프로세스는 취약성이 식별, 추적, 우선 순위 지정, 수정 및 조정된 공개를 통해 전달되는 방식을 포함하여 조기 공개 없이 안전한 취약성 수정을 가능하게 해야 합니다.
- 릴리스 성숙도의 현재 상태에 따라 표준(공개적으로)에서 보안 수정 사항이 릴리스될 수 있습니다. 표준 취약성 수정 SLO는 베타 기능에 적용되지 않습니다.
- 일반 공개 전에 감사 로깅 구현을 위한 문서화되고 이해관계자가 조율된 계획이 있어야 합니다. 이 계획은 어떤 이벤트가 로깅되는지, 로그 형식 및 보존, 보안 팀이 로그에 액세스하는 방법 및 기존 감사 시스템과의 통합 지점을 지정해야 합니다.
- 명시된 GA 요구 사항을 충족하지 않고 GA로 이동하기 위한 예외에 대해 e-group 승인이 필요합니다.

### 제한된 가용성 기능 {#limited-availability-features}

- 조기 공개 없이 안전한 취약성 수정을 가능하게 하는 운영 보안 릴리스 프로세스가 있어야 합니다.
- 보안 팀(내부 및 고객)이 비정상적인 동작을 감지하고 보안 인시던트를 조사하며 누가, 무엇을, 어디서, 언제에 대한 기본 질문에 답할 수 있는 운영 감사 로깅이 있어야 합니다. 감사 로깅은 세련된 UI 환경이 필요하지 않지만 보안 관련 이벤트에 대한 프로그래매틱 액세스를 제공해야 합니다.
- [운영 런북 문서](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs)가 있어야 합니다.

### 일반적으로 사용 가능한 기능 {#generally-available-features}

- GA로 이동하기 전에 완료된 보안 검토가 있어야 합니다. 보안 검토 범위는 기능 특성(고객 대면 기능, 인프라 영향, 데이터 액세스 패턴)에 의해 결정됩니다. 부분적으로 완료된 보안 검토를 통해 GA로 이동하는 기능은 E-Group 승인이 필요합니다.
- 취약성 수정 SLO를 준수하고 E-Group의 문서화된 위험 수용 없이 S1/S2 취약성과 함께 배포하지 마십시오. 인시던트 대응 테스트를 적용합니다: 기능은 GA 이후에 발견된 경우 긴급 패치를 트리거할 위험과 함께 배포하면 안 됩니다.
- 조기 공개 없이 안전한 취약성 수정을 가능하게 하는 운영 보안 릴리스 프로세스가 있어야 합니다.
- 보안 팀(내부 및 고객)이 비정상적인 동작을 감지하고 보안 인시던트를 조사하며 누가, 무엇을, 어디서, 언제에 대한 기본 질문에 답할 수 있는 운영 감사 로깅이 있어야 합니다. 감사 로깅은 세련된 UI 환경이 필요하지 않지만 보안 관련 이벤트에 대한 프로그래매틱 액세스를 제공해야 합니다.

## 예외 거버넌스 {#exception-governance}

비즈니스 요구가 이러한 요구 사항을 벗어나야 하는 예외적인 상황에서 GitLab은 경영진 승인 및 위험 수용이 포함된 문서화된 예외 프로세스를 따릅니다.

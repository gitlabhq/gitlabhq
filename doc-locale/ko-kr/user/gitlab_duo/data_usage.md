---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AI 기반 기능과 기능성
title: GitLab Duo 데이터 사용
---

GitLab Duo는 생성형 AI를 사용하여 속도를 높이고 생산성을 향상시킵니다. 각 AI 기반 기능은 독립적으로 작동하며 다른 기능이 작동하기 위해 필수 사항이 아닙니다.

GitLab은 특정 작업에 적합한 대규모 언어 모델(LLM)을 사용합니다. 이러한 LLM은 [Anthropic Claude](https://claude.com/product/overview), [Fireworks AI 호스팅 Codestral](https://mistral.ai/news/codestral/), [Gemini Enterprise Agent Platform 모델](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/beginners-guide), 및 [OpenAI 모델](https://platform.openai.com/docs/models)입니다.

## 점진적 개선 {#progressive-enhancement}

GitLab Duo AI 기반 기능은 DevSecOps 플랫폼 전반에 걸친 기존 GitLab 기능의 점진적 개선으로 설계되었습니다. 이러한 기능은 우아하게 실패하도록 설계되었으며 기본 기능의 핵심 기능을 방해하지 않아야 합니다. 각 기능은 관련 [기능 지원 정책](../../policy/development_stages_support.md)에서 정의한 예상 기능에 따릅니다.

## 안정성과 성능 {#stability-and-performance}

GitLab Duo AI 기반 기능은 다양한 [기능 지원 수준](../../policy/development_stages_support.md#beta)에 있습니다. 이러한 기능의 특성상 사용에 대한 높은 수요가 있을 수 있으므로 성능 저하 또는 기능의 예상치 못한 다운타임이 발생할 수 있습니다. 이러한 기능이 우아하게 성능을 저하하도록 구축했으며 악용이나 오용을 완화하기 위한 제어 장치가 마련되어 있습니다. GitLab은 베타 및 실험 기능을 언제든지 당사 재량에 따라 일부 또는 모든 고객에 대해 비활성화할 수 있습니다.

## 데이터 개인정보 보호 {#data-privacy}

GitLab Duo AI 기반 기능은 생성형 AI 모델로 구동됩니다. GitLab은 [GitLab 개인정보 보호 정책](https://about.gitlab.com/privacy/)에 따라 모든 개인 데이터를 처리합니다.

이러한 기능을 제공하기 위해 GitLab이 사용하는 AI 모델 서브프로세서 목록은 [타사 서브프로세서](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors)를 참조하세요.

## 데이터 보존 {#data-retention}

### 모델 서브프로세서 {#model-sub-processors}

GitLab Duo 요청의 경우 GitLab은 Fireworks AI와 함께 제로 데이터 보존 정책을 가지고 있습니다. Fireworks AI는 출력이 제공된 후 즉시 모델 입력 및 출력 데이터를 삭제하며 악용 모니터링을 위해 입력 및 출력 데이터를 저장하지 않습니다. GitLab Duo Code Suggestions 및 GitLab Duo Agentic Chat에 대해 프롬프트 캐싱이 켜지는 경우를 제외합니다. OpenAI 모델의 경우 프롬프트 캐싱을 끌 수 없습니다.

Amazon Bedrock 및 Gemini Enterprise Agent Platform에 호스팅되는 경우를 포함하여 특정 Anthropic 및 OpenAI 모델은 제한된 벤더 측 데이터 보존의 적용을 받습니다. 이러한 모델에 대한 자세한 내용은 [GitLab Duo Agent Platform 지원 AI 모델](../duo_agent_platform/model_selection.md#supported-models)을 참조하세요.

### GitLab {#gitlab}

GitLab Duo Chat 및 GitLab Duo Agent Platform은 이전에 논의한 주제로 빠르게 돌아갈 수 있도록 채팅 및 워크플로우 기록을 유지합니다. GitLab Duo Chat 인터페이스에서 채팅을 삭제할 수 있습니다. GitLab.com에서 GitLab은 악용 방지를 위해 채팅 및 워크플로우 기록을 유지합니다. GitLab은 고객이 [GitLab Support 티켓](https://about.gitlab.com/support/portal/)을 통해 동의를 제공하지 않는 한 입력 및 출력 데이터를 유지하지 않습니다.

GitLab Duo Agent Platform에 대해 확장 로깅을 활성화하면 GitLab이 추적 데이터를 유지합니다. AI 기능과 관련된 로깅 정보는 GitLab AI 모델 서브프로세서와의 모든 제로 데이터 보존 정책과 별개입니다. 자세한 내용은 [GitLab 로그 시스템](../../administration/logs/_index.md)을 참조하세요.

## 모델 학습 {#model-training}

GitLab은 생성형 AI 모델을 학습시키지 않습니다.

모든 GitLab AI 모델 서브프로세서는 모델 입력 및 출력을 사용하여 모델을 학습시키는 것이 제한됩니다. 이러한 서브프로세서는 GitLab과의 데이터 보호 계약에 따라 자신의 목적으로 고객 콘텐츠 사용을 금지하며, 독립적인 법적 의무를 수행하는 경우는 예외입니다.

## 원격 분석 {#telemetry}

GitLab Duo는 Snowplow 수집기를 통해 집계된 또는 익명화된 자사 사용량 데이터를 수집합니다. 이 사용량 데이터에는 다음 메트릭이 포함됩니다:

- 고유 사용자 수
- 고유 인스턴스 수
- 프롬프트 및 접미사 길이
- 사용된 모델
- 상태 코드 응답
- API 응답 시간
- Code Suggestions도 다음을 수집합니다:
  - 제안이 있는 언어 (예: Python)
  - 사용 중인 편집기 (예: VS Code)
  - 표시되거나, 수락되거나, 거부되거나, 오류가 있었던 제안 수
  - 제안이 표시된 기간

## GitLab Model Context Protocol 서버 {#gitlab-model-context-protocol-server}

다음 정보는 GitLab Self-Managed 인스턴스에서 [GitLab Model Context Protocol (MCP) 서버](../model_context_protocol/mcp_server.md) 사용에 적용됩니다.

GitLab MCP 서버를 사용할 때 GitLab은 데이터를 전송하거나, 저장하거나, 보존하거나, 처리하지 않습니다. 모든 통신은 MCP 클라이언트와 사용자 환경의 GitLab MCP 서버 간에 직접 발생합니다.

리포지토리 데이터 및 메타데이터는 GitLab으로 전송되지 않습니다.

MCP 클라이언트가 인스턴스에 연결되는지 제어합니다. 각 클라이언트의 자체 개인정보 보호 및 데이터 보존 정책이 적용됩니다.

## 모델 정확도 및 품질 {#model-accuracy-and-quality}

생성형 AI는 다음과 같을 수 있는 예상치 못한 결과를 생성할 수 있습니다:

- 낮은 품질
- 일관성 없음
- 불완전함
- 실패한 파이프라인
- 안전하지 않은 코드
- 모욕적이거나 무분별함
- 오래된 정보

GitLab은 생성된 콘텐츠의 품질을 개선하기 위해 모든 AI 기반 기능을 적극적으로 반복하고 있습니다. 프롬프트 엔지니어링, 이러한 기능을 강화하는 새로운 AI/ML 모델 평가, 그리고 이러한 기능에 직접 내장된 새로운 휴리스틱을 통해 품질을 개선합니다.

## 시크릿 검색 및 교정 {#secret-detection-and-redaction}

{{< history >}}

- GitLab 17.9에서 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/632)되었습니다.

{{< /history >}}

GitLab Duo는 플로우 실행 중 [시크릿 검색 및 교정](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/docs/developer/secret-redaction.md)을 포함합니다. 시나리오에 따라 GitLab Duo는 API 키, 자격 증명 및 토큰과 같은 민감한 정보를 자동으로 감지하고 대규모 언어 모델로 처리하기 전에 코드에서 제거합니다.

GitLab Duo를 사용할 때 코드는 사전 스캔 보안 워크플로우를 거칩니다:

1. Gitleaks를 사용하여 민감한 정보에 대해 코드를 스캔합니다.
1. 감지된 시크릿은 요청에서 자동으로 제거됩니다.

시크릿 스캔은 다음 시나리오에서 실행됩니다:

- 코드 완성 컨텍스트 변환 (AI로 컨텍스트가 전송되기 전)
- AI 컨텍스트 변환
- 워크플로우 도구 결과
- Agentic Chat 사용자 입력
- Git 명령 로깅
- CLI 구성 로깅

> [!note]
> 웹 인터페이스를 통해 GitLab Duo Chat과 상호작용할 때 시크릿 스캔이 발생하지 않습니다.

### 예외: 시크릿 오탐 탐지 {#exception-secret-false-positive-detection}

[스크릿 오탐 탐지](../application_security/vulnerabilities/secret_false_positive_detection.md)는 opt-in 기능으로, 감지된 시크릿 주변의 코드 컨텍스트를 포함한 취약성 정보를 분석을 위해 LLM으로 전송합니다. 이것은 [시크릿 검색 및 교정](#secret-detection-and-redaction) 동작에 대한 의도적인 예외입니다.

이 기능이 opt-in이므로 취약성 데이터가 LLM으로 전송되기 전에 그룹 및 프로젝트 수준 모두에서 명시적으로 활성화해야 합니다. 이 기능을 활성화하기 전에 조직의 데이터 정책을 검토하세요.

## GitLab과 그룹 사용량 데이터 공유 {#share-group-usage-data-with-gitlab}

{{< history >}}

- GitLab 18.9.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/587976)되었습니다.

{{< /history >}}

서비스 품질을 개선하기 위해 GitLab Duo Agent Platform 기능에 대한 사용량 데이터를 GitLab과 공유할 수 있습니다.

데이터 수집을 켠 후 네임스페이스의 모든 프로젝트 및 서브그룹의 AI 상호작용이 GitLab과 함께 로깅됩니다. 이 데이터는 서비스 개선 및 디버깅에만 사용되며 AI 모델 학습에는 사용되지 않습니다.

또한 [인스턴스](../../administration/gitlab_duo/configure/_index.md#share-usage-data-with-gitlab)에 대해 사용량 데이터 수집을 켤 수 있습니다.

사전 요구 사항:

- GitLab 18.9.1 이상이 필요합니다.
- 최상위 그룹의 소유자 역할이 필요합니다.
- GitLab.com에서 그룹은 [GitLab Duo가 활성화](turn_on_off.md#turn-gitlab-duo-on-or-off)되어야 합니다.

그룹에 대한 데이터 수집을 켜려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **수집 데이터**에서 **사용량 데이터 수집** 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### Agent Platform 사용량 데이터 {#agent-platform-usage-data}

데이터 수집을 켜면 다음 데이터가 로깅됩니다:

- GitLab Duo와의 상호작용에서 얻은 완전한 프롬프트 및 응답 텍스트
- 설정이 활성화될 때 진행 중이던 세션을 포함한 세션 컨텍스트
- 모델 메타데이터 (모델 버전, 토큰 수, 대기 시간)
- 도구 호출 및 해당 결과
- 사용자 피드백과 연관시킬 세션 ID

다음 정보는 사용자가 자신의 프롬프트에 포함하지 않는 한 로그에 포함되지 않습니다:

- 사용자 ID 또는 사용자 이름
- 이메일 주소 또는 개인 식별자
- 프로젝트 또는 네임스페이스 식별자

GitLab은 사용자가 프롬프트에 포함한 식별자를 제거하지 않습니다.

## 프롬프트 캐싱 {#prompt-caching}

프롬프트 캐싱은 캐시된 프롬프트 및 입력 데이터의 재처리를 방지하여 대기 시간을 개선합니다. 프롬프트 캐싱을 켜면 모델 벤더가 프롬프트 데이터를 메모리에 임시로 저장합니다. 캐시된 데이터는 영구 저장소에 로깅되지 않습니다.

프롬프트 레지스트리와 Code Suggestions를 사용하는 Agent Platform 기능 모두에 대해 토큰 캐싱이 지원되는 모델에 대해 자동으로 켜집니다.

### 프롬프트 캐싱 끄기 {#turn-off-prompt-caching}

기본적으로 프롬프트 캐싱이 켜집니다. 최상위 그룹 또는 인스턴스에 대해 프롬프트 캐싱을 끌 수 있습니다.

{{< tabs >}}

{{< tab title="최상위 그룹" >}}

사전 요구 사항:

- 최상위 그룹의 소유자 역할이 있습니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **데이터와 개인정보 보호** 섹션의 **프롬프트 캐싱** 아래에서 **프롬프트 캐싱 켜기** 체크박스를 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< tab title="인스턴스" >}}

사전 요구 사항:

- 관리자 액세스 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **관리자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **데이터와 개인정보 보호** 섹션의 **프롬프트 캐싱** 아래에서 **프롬프트 캐싱 켜기** 체크박스를 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< /tabs >}}

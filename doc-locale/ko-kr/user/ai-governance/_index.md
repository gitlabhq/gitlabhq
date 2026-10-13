---
stage: Software Supply Chain Security
group: AI Governance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "조직 전체에서 AI 에이전트 활동을 모니터링, 감사 및 제어합니다."
title: AI Governance
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

AI Governance 기능은 보안 및 규정 준수 팀이 조직 전체에서 AI 에이전트 활동을 모니터링, 감사 및 제어하는 데 도움이 됩니다.

이 기능은 GitLab Duo Agent Platform 에이전트와 GitLab MCP 서버를 통해 연결되는 Claude Code 및 Cursor와 같은 외부 에이전트 모두에 적용됩니다.

## 기능 {#features}

| 기능 | 설명 |
|:--------|:------------|
| [AI Governance Dashboard](governance-dashboard.md) | 그룹 전체에서 AI 에이전트 세션, 감사 로그 및 개발자 노출을 모니터링합니다. |
| [AI audit events](ai-audit-events.md) | 규정 준수 및 거버넌스 목적으로 에이전트 활동의 통합 기록을 찾아보고 필터링합니다. |
| [Tool governance](tool-governance.md) | 에이전트 도구에 대한 Allow, Ask 및 Deny 정책을 구성하고 모든 연결 클라이언트에 대해 실행 시점에 적용합니다. |

각 기능은 서로 다른 티어 및 가용성 요구 사항이 있습니다. 자세한 내용은 개별 기능 페이지를 확인하세요.

## 관련 항목 {#related-topics}

- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)
- [Compliance features](../compliance/_index.md)
- [감사 이벤트](../compliance/audit_events.md)

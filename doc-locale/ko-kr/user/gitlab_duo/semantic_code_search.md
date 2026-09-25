---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 의미 기반의 코드 검색으로 리포지토리에서 키워드 매칭이 아닌 의미에 따라 관련 코드 스니펫을 찾습니다.
title: 의미 기반의 코드 검색
---

{{< details >}}

- 티어:  Premium, Ultimate
- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 18.7에서 [베타](../../policy/development_stages_support.md#beta)로 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/16910)되었습니다.
- GitLab 18.8에서 GitLab Duo Core에 [추가](https://gitlab.com/gitlab-org/gitlab/-/work_items/588259)되었습니다.
- GitLab 18.9에서 GitLab Premium에 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/590394)되었습니다.

{{< /history >}}

> [!note]
> 관리자 문서는 [의미 기반의 코드 검색 관리](../../administration/semantic_code_search.md)를 참조하세요.

의미 기반의 코드 검색으로 리포지토리에서 키워드 매칭이 아닌 의미에 따라 관련 코드 스니펫을 찾습니다.

의미 기반의 코드 검색은 코드베이스를 벡터 데이터베이스에 저장된 벡터 임베딩으로 변환합니다. 검색할 때 쿼리가 임베딩으로 변환되고 의미적으로 유사한 결과를 찾기 위해 코드 임베딩과 비교됩니다. 이 방식은 키워드가 일치하지 않을 때도 관련 코드를 찾습니다.

## 사전 요구 사항 {#prerequisites}

- GitLab Self-Managed에서 [인스턴스](../../administration/semantic_code_search.md)에 대해 의미 기반의 코드 검색을 켭니다. GitLab.com에서 의미 기반의 코드 검색은 기본적으로 켜져 있습니다.
- 베타 및 실험 기능을 켭니다:
  - GitLab.com에서 [최상위 그룹에 대해](../duo_agent_platform/turn_on_off.md#on-gitlabcom-3) 설정합니다.
  - GitLab Self-Managed에서 [인스턴스](../duo_agent_platform/turn_on_off.md#on-gitlab-self-managed-3)에 대해.
- GitLab Duo를 [프로젝트](../duo_agent_platform/turn_on_off.md)에 대해 켭니다.

## 의미 기반의 코드 검색 사용 {#use-semantic-code-search}

의미 기반의 코드 검색은 여러 인터페이스를 통해 사용할 수 있습니다:

- REST API: [`GET /api/v4/projects/:id/search/semantic` 엔드포인트](../../api/search.md#semantic-search)를 사용하여 코드베이스를 프로그래밍 방식으로 검색합니다.
- MCP 서버 도구: 에이전트 워크플로우에서 [`semantic_code_search`](../model_context_protocol/mcp_server_tools.md#semantic_search) 도구를 사용합니다.
- CLI: 명령줄 액세스를 위해 [`glab search semantic`](https://docs.gitlab.com/cli/search/semantic/) 명령을 사용합니다.

## 임시 초기 인덱싱 {#ad-hoc-initial-indexing}

GitLab 프로젝트에서 의미 기반의 코드 검색을 처음 사용할 때:

- 리포지토리 코드가 인덱싱되고 벡터 임베딩으로 변환됩니다.
- 이러한 임베딩은 구성된 벡터 저장소에 저장됩니다.
- 코드가 기본 브랜치에 푸시될 때 업데이트가 증분으로 처리됩니다.

초기 인덱싱은 큰 리포지토리의 경우 시간이 걸릴 수 있습니다.

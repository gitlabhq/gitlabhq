---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AI를 사용하여 취약성 설명
---

{{< details >}}

- 티어:  Ultimate
- 추가 기능: GitLab Duo Enterprise, GitLab Duo with Amazon Q
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- [기본 LLM](../../gitlab_duo/model_selection.md#default-models)
- Amazon Q용 LLM: Amazon Q Developer
- [자가 호스팅 모델이 포함된 GitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)에서 사용 가능

{{< /collapsible >}}

{{< history >}}

- GitLab 16.0에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/10368)되었으며 GitLab.com에서 [실험](../../../policy/development_stages_support.md#experiment)으로 제공됩니다.
- GitLab 16.2에서 [베타](../../../policy/development_stages_support.md#beta) 상태로 승격되었습니다.
- GitLab 17.2에서 [일반 공급](https://gitlab.com/groups/gitlab-org/-/epics/10642)합니다.
- GitLab 17.6 이상에서 GitLab Duo 추가 기능이 필요하도록 변경되었습니다.

{{< /history >}}

GitLab Duo 취약성 설명은 대규모 언어 모델을 사용하여 다음을 수행하는 데 도움이 될 수 있습니다:

- 취약성을 요약합니다.
- 개발자와 보안 분석가가 취약성, 악용될 수 있는 방식 및 해결 방법을 이해하도록 돕습니다.
- 제안된 완화 방법을 제공합니다.

GitLab Duo는 중요하고 높은 심각도의 SAST 취약성을 자동으로 분석하여 잠재적 거짓 양성을 식별할 수 있습니다. 자세한 내용은 [SAST 거짓 양성 탐지](../vulnerabilities/false_positive_detection.md)를 참조하세요.

<i class="fa-youtube-play" aria-hidden="true"></i> [개요 시청](https://www.youtube.com/watch?v=MMVFvGrmMzw&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- [GitLab Duo](../../gitlab_duo/turn_on_off.md)를 그룹 또는 인스턴스에 대해 활성화해야 합니다.
- 프로젝트의 멤버여야 합니다.
- 취약성은 SAST 스캐너에서 나온 것이어야 합니다.

취약성을 설명하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **취약성 보고서**를 선택합니다.
1. 선택 사항. 기본 필터를 제거하려면 **지우기**({{< icon name="clear" >}})를 선택합니다.
1. 취약성 목록 위의 필터 막대를 선택합니다.
1. 표시되는 드롭다운 목록에서 **도구**를 선택하고 **SAST** 범주의 모든 값을 선택합니다.
1. 필터 필드 외부를 선택합니다. 취약성 심각도 합계 및 일치하는 취약성 목록이 업데이트됩니다.
1. 설명하려는 SAST 취약성을 선택합니다.
1. 다음 중 하나를 수행합니다:

   - _GitLab Duo Chat에 요청하여 이 취약성과 제안된 해결책을 설명하도록 AI를 사용할 수도 있습니다_라고 표시된 취약성 설명 아래의 텍스트를 선택합니다.
   - 오른쪽 상단에서 **머지 리퀘스트를 통해 해결** 드롭다운 목록에서 **취약성 설명**을 선택한 후 **취약성 설명**을 선택합니다.
   - GitLab Duo Chat을 열고 [취약성 설명](../../gitlab_duo_chat/examples.md#explain-a-vulnerability) 명령을 사용하여 `/vulnerability_explain`을 입력합니다.

응답은 페이지 오른쪽에 표시됩니다.

GitLab.com에서 이 기능을 사용할 수 있습니다. 기본적으로 Anthropic [`claude-3-haiku`](https://docs.anthropic.com/en/docs/about-claude/models#claude-3-a-new-generation-of-ai) 모델로 지원됩니다. GitLab은 대형 언어 모델이 정확한 결과를 생성한다는 것을 보장할 수 없습니다. 설명을 주의해서 사용하세요.

## 취약성 설명과 공유되는 제3자 AI API 데이터 {#data-shared-with-third-party-ai-apis-for-vulnerability-explanation}

다음 데이터는 타사 AI API와 공유됩니다.

- 취약성 제목(사용하는 스캐너에 따라 파일 이름이 포함될 수 있음).
- 취약성 식별자.
- 파일 이름.

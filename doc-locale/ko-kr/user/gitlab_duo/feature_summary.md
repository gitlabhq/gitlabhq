---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AI 기반 기능 및 기능.
title: GitLab Duo Non-Agentic 기능
---

{{< details >}}

- 티어:  Premium, Ultimate
- 추가 기능: GitLab Duo Pro 또는 Enterprise
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

다음 기능은 GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 일반적으로 사용할 수 있습니다. Premium 또는 Ultimate 구독 및 사용 가능한 추가 기능 중 하나가 필요합니다.

GitLab Duo with Amazon Q 기능은 별도의 추가 기능으로 제공되며 GitLab Self-Managed에서만 사용할 수 있습니다.

| 기능 | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q |
|---------|----------------|----------------------|--------------------------|
| [코드 제안](../project/repository/code_suggestions/_index.md) <sup>1</sup> | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [GitLab Duo Non-Agentic Chat](../gitlab_duo_chat/_index.md) | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [코드 설명](../gitlab_duo_chat/examples.md#explain-selected-code) in IDEs | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [코드 리팩터링](../gitlab_duo_chat/examples.md#refactor-code-in-the-ide) in IDEs | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [코드 수정](../gitlab_duo_chat/examples.md#fix-code-in-the-ide) in IDEs | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [테스트 생성](../gitlab_duo_chat/examples.md#write-tests-in-the-ide) in IDEs | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [코드 설명](../project/repository/code_explain.md) in GitLab UI | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [토론 요약](../discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat) | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [코드 검토](code_review.md) <sup>2</sup> | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [근본 원인 분석](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [취약성 설명](../application_security/analyze/duo.md) | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [취약성 해결](../application_security/remediate/duo.md) | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [머지 커밋 메시지 생성](../project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message) | {{< no >}} | {{< yes >}} | {{< yes >}} |

**각주**:

1. 코드 제안은 GitLab Duo Agent Platform의 일부로도 사용할 수 있으며, 추가 기능이 필요하지 않습니다.
1. Amazon Q는 이 기능의 다른 버전을 지원합니다. [Amazon Q를 사용하여 코드를 검토하는 방법 보기](../duo_amazon_q/_index.md#review-a-merge-request).

## 베타 및 실험 기능 {#beta-and-experimental-features}

다음 기능은 아직 일반적으로 사용할 수 없습니다.

Premium 또는 Ultimate 구독 및 GitLab Duo Enterprise 추가 기능이 필요합니다.

| 기능 | GitLab Duo Pro | GitLab Duo Enterprise | GitLab Duo with Amazon Q |
|---------|----------------|----------------------|--------------------------|
| [머지 리퀘스트 요약](../project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes) | {{< no >}} | {{< yes >}} | {{< no >}} |
| [코드 검토 요약](../project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review) | {{< no >}} | {{< yes >}} | {{< no >}} |
| [이슈 설명 생성](../project/issues/managing_issues.md#populate-an-issue-with-issue-description-generation) | {{< no >}} | {{< yes >}} | {{< no >}} |

## GitLab Duo Self-Hosted에서 사용 가능한 기능 {#features-available-in-gitlab-duo-self-hosted}

조직에서 언어 모델을 자체적으로 호스팅할 수 있습니다.

GitLab Duo Self-Hosted에서 사용할 수 있는 GitLab Duo 기능을 알아보려면 [지원되는 기능 목록](../../administration/gitlab_duo_self_hosted/_index.md#feature-versions-and-status)을 참조하세요.

## GitLab Duo with Amazon Q에 포함된 Amazon Q Developer Pro {#amazon-q-developer-pro-included-with-gitlab-duo-with-amazon-q}

[Amazon Q Developer Pro](https://aws.amazon.com/q/developer/)에 대한 라이선스 크레딧은 GitLab Duo with Amazon Q 구독에 포함됩니다.

이 구독에는 다음을 포함한 에이전트 채팅 및 명령줄 도구에 대한 액세스가 포함됩니다:

- [IDE의 Amazon Q Developer](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/q-in-IDE.html), Visual Studio, VS Code, JetBrains 및 Eclipse 포함.
- [명령줄의 Amazon Q Developer](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line.html).
- [AWS Management Console의 Amazon Q Developer](https://aws.amazon.com/q/developer/operate/).

Amazon Q Developer의 기능에 대한 자세한 내용은 [AWS 웹 사이트](https://aws.amazon.com/q/developer/)를 참조하세요.

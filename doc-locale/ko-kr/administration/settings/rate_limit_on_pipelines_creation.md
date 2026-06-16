---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 파이프라인 생성 시 속도 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/362475) 되었으며, [플래그](../feature_flags/_index.md)명은 `ci_enforce_throttle_pipelines_creation`입니다. 기본적으로 비활성화됨. GitLab.com에서 사용 설정됨
- 18.3에서 [기본적으로 사용 설정](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196545)됨

{{< /history >}}

사용자와 프로세스가 매분 일정 수 이상의 파이프라인을 요청하지 못하도록 제한을 설정할 수 있습니다. 이러한 제한은 리소스를 절약하고 안정성을 개선하는 데 도움이 됩니다.

GitLab은 파이프라인 생성을 위해 두 가지 유형의 속도 제한을 적용합니다:

- **Per project, commit, and user**:  동일한 프로젝트, 커밋 SHA, 사용자 조합으로 생성된 파이프라인을 제한합니다. 기본적으로 비활성화됨.
- **Per user**:  모든 프로젝트에서 사용자가 생성한 총 파이프라인을 제한합니다. 기본적으로 비활성화됨.

예를 들어 사용자 당 제한을 `100`로 설정하고 사용자가 서로 다른 프로젝트에서 1분 내에 [트리거 API](../../ci/triggers/_index.md)에 `101` 파이프라인 생성 요청을 보낸 경우, 101번째 요청이 차단됩니다. 1분 후 엔드포인트에 다시 액세스할 수 있습니다.

이러한 제한은 IP 주소별로 적용되지 않습니다.

제한을 초과하는 요청은 `application_json.log` 파일에 기록됩니다.

## 파이프라인 요청 제한 설정 {#set-pipeline-request-limits}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

파이프라인 요청 수를 제한하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **Pipelines Rate Limits**을 확장합니다.
1. **Max requests per minute per project, user, and commit** 아래에서 `0`보다 큰 값을 입력하여 동일한 프로젝트, 커밋, 사용자 조합의 파이프라인을 제한합니다.
1. **Max requests per minute per user** 아래에서 `0`보다 큰 값을 입력하여 각 사용자가 생성한 총 파이프라인을 제한합니다. 분당 무제한 요청의 경우 0으로 설정합니다.
1. **변경 사항 저장**을 선택합니다.

## 제한이 함께 작동하는 방식 {#how-the-limits-work-together}

두 속도 제한은 독립적으로 평가됩니다:

- 프로젝트에서 동일한 커밋 SHA에 대해 여러 파이프라인을 생성하는 사용자는 **per project, user, and commit** 제한의 대상이 됩니다.
- 서로 다른 프로젝트 또는 커밋에 걸쳐 파이프라인을 생성하는 사용자는 **사용자 당** 제한의 대상이 됩니다.
- 제한 중 하나라도 초과되면 파이프라인 생성 요청이 차단됩니다.

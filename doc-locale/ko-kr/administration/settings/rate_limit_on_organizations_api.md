---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 조직 API의 속도 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태:  실험

{{< /details >}}

{{< history >}}

- [GitLab 17.5에서 도입되었으며](https://gitlab.com/gitlab-org/gitlab/-/issues/470613) [기능 플래그](../feature_flags/_index.md) `allow_organization_creation`로 제공됩니다. 기본적으로 비활성화됨. 이 기능은 [실험](../../policy/development_stages_support.md) 단계입니다.
- GitLab 18.4에서 [변경되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/549062). 속도 제한 `allow_organization_creation` 기능 플래그가 통합되어 `organization_switching`로 이름이 변경되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능 여부는 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요.

속도 제한을 초과한 요청은 `auth.log` 파일에 기록됩니다.

예를 들어, `POST /organizations`에 대한 제한을 400으로 설정하면 1분 이내에 400을 초과하는 속도로 API 엔드포인트에 요청하는 경우 차단됩니다. 1분 후 엔드포인트에 대한 액세스가 복구됩니다.

[POST /organizations API](../../api/organizations.md#create-an-organization)에 요청하기 위해 사용자별 분당 속도 제한을 구성할 수 있습니다. 기본값은 10입니다.

## 속도 제한 변경 {#change-the-rate-limit}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

속도 제한을 변경하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **조직 API 속도 제한**을 확장합니다.
1. 모든 속도 제한의 값을 변경합니다. 속도 제한은 사용자별 분당 설정됩니다. 속도 제한을 비활성화하려면 값을 `0`로 설정합니다.
1. **변경 사항 저장**을 선택합니다.

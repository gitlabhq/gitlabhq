---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: REST API 지원 중단
description: "GitLab REST API에서 지원이 중단된 필드 및 예정된 주요 변경 사항 목록입니다."
---

다음 지원 중단 사항을 정기적으로 검토하고 권장 변경 사항을 적용해야 합니다. 이러한 지원 중단 사항은 개선된 API 기능을 나타내며 새 필드 또는 엔드포인트를 사용할 것을 권장합니다.

일부 지원 중단 사항에서 v5 를 언급하지만 v5 REST API 개발은 활발하지 않습니다. GitLab은 v4 내에서 이러한 변경 사항을 적용하지 않으며 [에 대한 시멘틱 버전 관리를 따릅니다](_index.md#versioning-and-deprecations).

## `geo_nodes` API 엔드포인트 {#geo_nodes-api-endpoints}

주요 변경 사항입니다. [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/369140)입니다.

[`geo_nodes` API 엔드포인트](../geo_nodes.md) 는 지원이 중단되었으며 [`geo_sites`](../geo_sites.md)로 대체됩니다. 이는 [Geo 배포를 참조하는 방식](../../administration/geo/glossary.md)에 대한 전역 변경의 일부입니다. 노드는 애플리케이션 전체에서 사이트로 이름이 변경됩니다. 두 엔드포인트의 기능은 동일하게 유지됩니다.

## `merged_by` API 필드 {#merged_by-api-field}

주요 변경 사항입니다. [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/350534)입니다.

[API](../merge_requests.md#list-merge-requests)의 `merged_by` 필드는 지원이 중단되었으며, 단순 병합이 아닌 다른 작업(자동 병합으로 설정, 병합 트레인에 추가)을 수행할 때 를 병합한 사람을 더 정확하게 식별하는 `merge_user` 필드로 대체됩니다.

API 사용자는 새로운 `merge_user` 필드를 대신 사용하도록 권장됩니다. `merged_by` 필드는 GitLab v5에서 제거될 것입니다.

## `merge_status` API 필드 {#merge_status-api-field}

주요 변경 사항입니다. [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/382032)입니다.

[API](../merge_requests.md#merge-status)의 `merge_status` 필드는 지원이 중단되었으며, 가 있을 수 있는 모든 잠재적 상태를 더 정확하게 식별하는 `detailed_merge_status` 필드로 대체됩니다. API 사용자는 새로운 `detailed_merge_status` 필드를 대신 사용하도록 권장됩니다. `merge_status` 필드는 GitLab v5에서 제거될 것입니다.

### User API의 `private_profile` 속성에 대한 Null 값 {#null-value-for-private_profile-attribute-in-user-api}

주요 변경 사항입니다. [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/387005)입니다.

API를 통해 사용자를 생성하고 업데이트할 때 `null`은 `private_profile` 속성의 유효한 값이었으며, 내부적으로 기본값으로 변환됩니다. GitLab v5에서 `null`은 더 이상 이 매개변수의 유효한 값이 아니며, 사용될 경우 응답은 400이 됩니다. 이 변경 후에는 유효한 값은 `true` 및 `false`뿐입니다.

## 단일 변경 사항 API 엔드포인트 {#single-merge-request-changes-api-endpoint}

주요 변경 사항입니다. [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/322117)입니다.

[단일 의 변경 사항](../merge_requests.md#retrieve-merge-request-changes) 을 가져오는 엔드포인트는 지원이 중단되었으며 [diff 목록](../merge_requests.md#list-merge-request-diffs) 엔드포인트로 대체됩니다. API 사용자는 새로운 diffs 엔드포인트로 전환하도록 권장됩니다.

`changes from a single merge request` 엔드포인트는 GitLab v5에서 제거될 것입니다.

## 관리되는 라이센스 API 엔드포인트 {#managed-licenses-api-endpoint}

주요 변경 사항입니다. [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/397067)입니다.

주어진 프로젝트의 모든 관리되는 라이센스를 가져오는 엔드포인트는 지원이 중단되었으며 [라이센스 정책](../../user/compliance/license_approval_policies.md) 기능으로 대체됩니다.

감지된 라이센스를 기반으로 을 계속 적용하려는 사용자는 새로운 [라이센스 정책](../../user/compliance/license_approval_policies.md)을 대신 생성하도록 권장됩니다.

`managed licenses` 엔드포인트는 GitLab v5에서 제거될 것입니다.

## API의 Approvers 및 Approver Group 필드 {#approvers-and-approver-group-fields-in-merge-request-approval-api}

주요 변경 사항입니다. [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/353097)입니다.

프로젝트의 구성을 가져오는 엔드포인트는 `approvers` 및 `approval_groups`에 대해 빈 배열을 반환합니다. 이러한 필드는 의 [모든 규칙 목록](../merge_request_approvals.md#list-all-approval-rules-for-a-merge-request)을 지원하는 엔드포인트로 대체되었습니다. API 사용자는 이 엔드포인트로 전환하도록 권장됩니다.

이러한 필드는 `get configuration` 엔드포인트에서 GitLab v5로 제거될 것입니다.

## 사용 `active` `paused`로 대체됨 {#runner-usage-of-active-replaced-by-paused}

주요 변경 사항입니다. [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)입니다.

GitLab GraphQL API 엔드포인트의 `active` 식별자는 GitLab 16.0에서 `paused`로 이름이 변경됩니다.

- v4에서는 `active` 대신 `paused` 속성을 사용할 수 있습니다.
- v5에서 이 변경은 `active` 속성을 취하거나 반환하는 엔드포인트에 영향을 미칩니다. 예를 들면:
  - `GET /runners`
  - `GET /runners/all`
  - `GET /runners/:id` / `PUT /runners/:id`
  - `PUT --form "active=false" /runners/:runner_id`
  - `GET /projects/:id/runners` / `POST /projects/:id/runners`
  - `GET /groups/:id/runners`

GitLab 16.0 릴리스는 를 등록할 때 `paused` 속성을 사용하기 시작합니다.

## 상태가 `paused`을 반환하지 않음 {#runner-status-will-not-return-paused}

주요 변경 사항입니다. [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/344648)입니다.

향후 v5에서 GitLab 의 엔드포인트는 `paused` 또는 `active`를 반환하지 않습니다.

의 상태는 연결 상태에만 관련됩니다. 예: `online`, `offline`, 또는 `not_connected`. 상태 `paused` 또는 `active`는 더 이상 나타나지 않습니다.

가 `paused`인지 확인할 때 API 사용자는 부울 속성 `paused`이 `true`인지 확인하도록 권장됩니다. 가 `active`인지 확인할 때는 `paused`이 `false`인지 확인하세요.

## 가 `ip_address`을 반환하지 않음 {#runner-will-not-return-ip_address}

주요 변경 사항입니다. [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/415159)입니다.

GitLab 17.0에서 [API](../runners.md)는 의 경우 `ip_address` 대신 `""`를 반환합니다. v5에서는 필드가 제거됩니다.

## `default_branch_protection` API 필드 {#default_branch_protection-api-field}

주요 변경 사항입니다. [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/408315)입니다.

`default_branch_protection` 필드는 GitLab 17.0에서 다음 API에 대해 지원이 중단됩니다:

- [새 그룹 API](../groups.md#create-a-group).
- [그룹 업데이트 API](../groups.md#update-group-attributes).
- [애플리케이션 설정 API](../settings.md#update-application-settings)

`default_branch_protection_defaults` 필드를 대신 사용해야 하며, 이는 기본 보호에 대한 더 세밀한 제어를 제공합니다.

`default_branch_protection` 필드는 GitLab v5에서 제거될 것입니다.

## `require_password_to_approve` API 필드 {#require_password_to_approve-api-field}

`require_password_to_approve`는 GitLab 16.9에서 지원이 중단되었습니다. `require_reauthentication_to_approve` 필드를 대신 사용하세요. 두 필드에 모두 값을 제공하면 `require_reauthentication_to_approve` 필드가 우선합니다.

`require_password_to_approve` 필드는 GitLab v5에서 제거될 것입니다.

## 프로젝트 API 엔드포인트를 사용한 Pull 미러링 구성 {#pull-mirroring-configuration-with-the-projects-api-endpoint}

주요 변경 사항입니다. [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/494294)입니다.

GitLab 17.6에서 [프로젝트 API를 사용한 pull 미러링 구성](../project_pull_mirroring.md#update-pull-mirroring-for-a-project-deprecated)은 지원이 중단됩니다. 새로운 구성 및 엔드포인트인 [`projects/:id/mirror/pull`](../project_pull_mirroring.md#update-project-pull-mirroring-settings)로 대체됩니다.

프로젝트 API를 사용한 이전 구성은 GitLab v5에서 제거될 것입니다.

## 프로젝트 API 엔드포인트를 사용한 `restrict_user_defined_variables` 매개변수 {#restrict_user_defined_variables-parameter-with-the-projects-api-endpoint}

GitLab 17.7에서는 프로젝트 API의 [`restrict_user_defined_variables` 매개변수](../projects.md#update-a-project)가 `ci_pipeline_variables_minimum_override_role`만 사용하기 위해 지원이 중단됩니다.

`restrict_user_defined_variables: false`와 동일한 동작을 하려면 `ci_pipeline_variables_minimum_override_role`를 `developer`로 설정하세요.

## 프로젝트 가져오기 API 엔드포인트의 `namespace` 매개변수 {#namespace-parameter-in-project-import-api-endpoints}

주요 변경 사항입니다. [관련 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/511053)입니다.

GitLab 18.7에서 [프로젝트 가져오기 및 내보내기 API](../project_import_export.md)의 `namespace` 매개변수는 `namespace_id` 및 `namespace_path` 매개변수로 지원이 중단됩니다. `namespace` 매개변수는 ID 또는 경로를 모두 허용하여 경로에 숫자만 포함되어 있을 때 모호함을 유발했습니다.

대신 다음을 사용해야 합니다:

- `namespace_id` 숫자 ID로 를 지정할 때 사용합니다.
- `namespace_path` 경로로 를 지정할 때 사용합니다.

`namespace` 매개변수는 GitLab v5에서 제거될 것입니다.

---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 액세스 토큰 범위
description: "개인, 그룹 및 프로젝트 액세스 토큰에 대해 각 범위로 부여되는 권한입니다."
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `read_service_ping` [GitLab 17.1에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/42692#note_1222832412). 개인 액세스 토큰만 해당합니다.
- `manage_runner` [GitLab 17.1에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/460721).
- `self_rotate` [GitLab 17.9에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178111). 기본적으로 활성화되었습니다.

{{< /history >}}

범위는 액세스 토큰이 특정 조직 수준에서 할 수 있는 작업을 정의합니다. 각 범위는 특정 권한 집합을 부여합니다.

토큰 유형은 토큰의 도달 범위를 결정합니다:

- 개인 액세스 토큰은 사용자가 사용할 수 있는 모든 그룹 및 프로젝트에 액세스할 수 있습니다.
- 그룹 액세스 토큰은 해당 그룹의 하위 그룹 및 프로젝트에 액세스할 수 있습니다.
- 프로젝트 액세스 토큰은 자신의 프로젝트에만 액세스할 수 있습니다.

개인 액세스 토큰을 특정 리소스 및 권한으로 제한하려면 [세분화된 개인 액세스 토큰](../../auth/tokens/fine_grained_access_tokens.md)을 참조하세요.

| 범위 | 토큰 가용성 | 설명 |
|-------|------------|-------------|
| `api` | 개인, 그룹, 프로젝트 | 토큰 범위에 대해 API에 대한 완전한 읽기 및 쓰기 액세스를 부여합니다. [컨테이너 레지스트리](../../user/packages/container_registry/_index.md), [종속성 프록시](../../user/packages/dependency_proxy/_index.md), 및 [패키지 레지스트리](../../user/packages/package_registry/_index.md)를 포함합니다. <sup>1</sup> |
| `read_api` | 개인, 그룹, 프로젝트 | 토큰 범위에 대해 API에 대한 읽기 액세스를 부여합니다. 개인 액세스 토큰의 경우 컨테이너 레지스트리와 패키지 레지스트리를 포함하며, 그룹 및 프로젝트 액세스 토큰의 경우 패키지 레지스트리만 포함합니다. |
| `read_repository` | 개인, 그룹, 프로젝트 | 토큰 범위에 대한 리포지토리로의 읽기 액세스(끌어오기)를 부여합니다: 개인 액세스 토큰의 경우 비공개 프로젝트, 그룹 액세스 토큰의 경우 그룹의 모든 리포지토리, 또는 프로젝트 액세스 토큰의 경우 프로젝트의 리포지토리. Git-over-HTTP 또는 [리포지토리 파일 API](../../api/repository_files.md)를 사용합니다. |
| `write_repository` | 개인, 그룹, 프로젝트 | 토큰 범위에 대한 리포지토리로의 읽기 및 쓰기 액세스(끌어오기 및 밀어넣기)를 부여합니다: 개인 액세스 토큰의 경우 비공개 프로젝트, 그룹 액세스 토큰의 경우 그룹의 모든 리포지토리, 또는 프로젝트 액세스 토큰의 경우 프로젝트의 리포지토리. Git-over-HTTP를 사용합니다. API 인증을 지원하지 않습니다. |
| `read_registry` | 개인, 그룹, 프로젝트 | 인증이 필요할 때 [컨테이너 레지스트리](../../user/packages/container_registry/_index.md) 이미지로의 읽기 액세스(끌어오기)를 부여합니다. 컨테이너 레지스트리가 활성화되어 있을 때만 사용 가능합니다. 개인정보 보호 조건은 토큰 유형에 따라 다릅니다: 개인 액세스 토큰이 비공개일 때, 그룹의 모든 프로젝트가 비공개일 때 그룹 액세스 토큰에, 프로젝트가 비공개일 때 프로젝트 액세스 토큰에 적용됩니다. |
| `write_registry` | 개인, 그룹, 프로젝트 | [컨테이너 레지스트리](../../user/packages/container_registry/_index.md) 이미지로의 쓰기 액세스(밀어넣기)를 부여합니다. 컨테이너 레지스트리가 활성화되어 있을 때만 사용 가능합니다. 그룹 및 프로젝트 액세스 토큰의 경우 이미지를 밀어넣기 위해 `read_registry` 범위도 포함해야 합니다. |
| `self_rotate` | 개인, 그룹, 프로젝트 | 이 토큰을 회전할 수 있는 권한을 부여합니다. 다른 토큰을 회전할 수 없습니다. 개인 액세스 토큰을 회전하려면 [개인 액세스 토큰 API](../../api/personal_access_tokens.md#rotate-a-personal-access-token)를 참조하세요. |
| `read_virtual_registry` | 개인, 그룹 | [종속성 프록시](../../user/packages/dependency_proxy/_index.md)를 통해 컨테이너 이미지로의 읽기 액세스(끌어오기)를 부여합니다. 종속성 프록시가 활성화되어 있을 때만 사용 가능합니다. <sup>2</sup> |
| `write_virtual_registry` | 개인, 그룹 | [종속성 프록시](../../user/packages/dependency_proxy/_index.md)를 통해 컨테이너 이미지로의 읽기 및 쓰기 액세스(끌어오기, 밀어넣기 및 삭제)를 부여합니다. 종속성 프록시가 활성화되어 있을 때만 사용 가능합니다. <sup>2</sup> |
| `create_runner` | 개인, 그룹, 프로젝트 | 토큰 범위에 대한 러너를 만들 수 있는 권한을 부여합니다. |
| `manage_runner` | 개인, 그룹, 프로젝트 | 토큰 범위에 대한 러너를 관리할 수 있는 권한을 부여합니다. |
| `ai_features` | 개인, 그룹, 프로젝트 | GitLab Duo, Code Suggestions API 및 GitLab Duo Chat API에 대한 API 작업을 수행할 수 있는 권한을 부여합니다. GitLab Duo Plugin for JetBrains와 함께 작동하도록 설계되었습니다. 다른 모든 확장 프로그램의 경우 개별 확장 프로그램 설명서를 참조하세요. GitLab Self-Managed 버전 16.5, 16.6 및 16.7에서는 작동하지 않습니다. GitLab Self-Managed 및 GitLab Dedicated에서 이 범위는 GitLab Duo가 활성화되어 있을 때만 사용 가능합니다. |
| `k8s_proxy` | 개인, 그룹, 프로젝트 | Kubernetes용 에이전트를 통해 Kubernetes API 호출을 수행할 수 있는 권한을 부여합니다. |
| `admin_mode` | 개인 | [Admin Mode](../../administration/settings/sign_in_restrictions.md#admin-mode)가 활성화되어 있을 때 API 작업을 수행할 수 있는 권한을 부여합니다. GitLab Self-Managed 인스턴스의 관리자에게만 사용 가능합니다. |
| `read_service_ping` | 개인 | 관리자로 인증될 때 API를 통해 Service Ping 페이로드를 다운로드할 수 있는 액세스를 부여합니다. |
| `sudo` | 개인 | 관리자로 인증될 때 시스템의 모든 사용자로서 API 작업을 수행할 수 있는 권한을 부여합니다. |
| `read_user` | 개인 | `/user` API 엔드포인트를 통해 인증된 사용자의 프로필에 대한 읽기 전용 액세스를 부여하며, 여기에는 사용자 이름, 공개 이메일 및 전체 이름이 포함됩니다. [`/users`](../../api/users.md) 아래의 읽기 전용 API 엔드포인트에 대한 액세스도 부여합니다. |

> [!warning]
> [외부 인증](../../administration/settings/external_authorization.md)을 켜신 경우, 개인 액세스 토큰 및 프로젝트 액세스 토큰은 컨테이너 또는 패키지 레지스트리에 액세스할 수 없습니다. 액세스를 복원하려면 외부 인증을 끄세요.

**각주**:

1. 개인 액세스 토큰의 경우 `api` 또한 Git-over-HTTP를 통해 레지스트리 및 리포지토리로의 완전한 읽기 및 쓰기 액세스를 부여합니다. 그룹 및 프로젝트 액세스 토큰은 이 Git-over-HTTP 절을 포함하지 않습니다.
1. 개인 액세스 토큰의 경우 가상 레지스트리 범위는 프로젝트가 비공개이고 인증이 필요할 때만 적용됩니다. 그룹 액세스 토큰은 이러한 조건을 가지지 않습니다.

## 관련 항목 {#related-topics}

- [개인 액세스 토큰](../../user/profile/personal_access_tokens.md)
- [그룹 액세스 토큰](../../user/group/settings/group_access_tokens.md)
- [프로젝트 액세스 토큰](../../user/project/settings/project_access_tokens.md)
- [토큰 개요](../../security/tokens/_index.md)

---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 속도 제한
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> GitLab.com의 경우 [GitLab.com 특정 속도 제한](../user/gitlab_com/_index.md#rate-limits-on-gitlabcom)을 참조하세요.
>
> GitLab Dedicated의 경우 [인증된 사용자 속도 제한](../administration/dedicated/user_rate_limits.md)을 참조하세요.

속도 제한은 웹 애플리케이션의 보안과 내구성을 개선하는 데 사용되는 일반적인 기술입니다.

예를 들어 간단한 스크립트는 초당 수천 개의 웹 요청을 수행할 수 있습니다. 요청은 다음 중 하나일 수 있습니다:

- 악의적인 요청.
- 무심한 요청.
- 단순한 버그.

애플리케이션과 인프라가 부하를 감당하지 못할 수 있습니다. 자세한 내용은 [서비스 거부 공격](https://en.wikipedia.org/wiki/Denial-of-service_attack)을 참조하세요. 대부분의 경우 단일 IP 주소의 요청 속도를 제한하여 완화할 수 있습니다.

대부분의 [무차별 대입 공격](https://en.wikipedia.org/wiki/Brute-force_attack)도 속도 제한으로 유사하게 완화됩니다.

> [!note]
> API 요청에 대한 속도 제한은 프론트엔드에서 수행된 요청에 영향을 주지 않습니다. 이러한 요청은 항상 웹 트래픽으로 계산되기 때문입니다.

## 구성 가능한 제한 {#configurable-limits}

인스턴스의 **운영자** 영역에서 이러한 속도 제한을 설정할 수 있습니다:

- [가져오기/내보내기 속도 제한](../administration/settings/import_export_rate_limits.md)
- [이슈 속도 제한](../administration/settings/rate_limit_on_issues_creation.md)
- [노트 속도 제한](../administration/settings/rate_limit_on_notes_creation.md)
- [보호된 경로](../administration/settings/protected_paths.md)
- [원본 엔드포인트 속도 제한](../administration/settings/rate_limits_on_raw_endpoints.md)
- [사용자 및 IP 속도 제한](../administration/settings/user_and_ip_rate_limits.md)
- [패키지 레지스트리 속도 제한](../administration/settings/package_registry_rate_limits.md)
- [Git LFS 속도 제한](../administration/settings/git_lfs_rate_limits.md)
- [Git SSH 작업 속도 제한](../administration/settings/rate_limits_on_git_ssh_operations.md)
- [파일 API 속도 제한](../administration/settings/files_api_rate_limits.md)
- [더 이상 사용되지 않는 API 속도 제한](../administration/settings/deprecated_api_rate_limits.md)
- [GitLab Pages 속도 제한](../administration/pages/_index.md#rate-limits)
- [파이프라인 속도 제한](../administration/settings/rate_limit_on_pipelines_creation.md)
- [인시던트 관리 속도 제한](../administration/settings/incident_management_rate_limits.md)
- [프로젝트 API 속도 제한](../administration/settings/rate_limit_on_projects_api.md)
- [그룹 API 속도 제한](../administration/settings/rate_limit_on_groups_api.md)
- [사용자 API 속도 제한](../administration/settings/rate_limit_on_users_api.md)
- [조직 API 속도 제한](../administration/settings/rate_limit_on_organizations_api.md)
- [웹후크 작업 속도 제한](../administration/settings/rate-limit-on-webhook-operations.md)

[ApplicationSettings API](../api/settings.md)를 사용하여 이러한 속도 제한을 설정할 수 있습니다:

- [자동 완성 사용자 속도 제한](../administration/instance_limits.md#autocomplete-users-rate-limit)

Rails 콘솔을 사용하여 이러한 속도 제한을 설정할 수 있습니다:

- [웹후크 속도 제한](../administration/instance_limits.md#webhook-rate-limit)

## Git 및 컨테이너 레지스트리 실패한 인증 금지 {#failed-authentication-ban-for-git-and-container-registry}

단일 IP 주소에서 3분 이내에 30개의 실패한 인증 요청을 받은 경우 GitLab은 1시간 동안 HTTP 상태 코드 `403`를 반환합니다. 이는 다음의 결합에만 적용됩니다:

- 커밋 요청.
- 컨테이너 레지스트리 (`/jwt/auth`) 요청.

이 제한:

- 성공적으로 인증한 요청으로 재설정됩니다. 예를 들어, 29개의 실패한 인증 요청 다음에 1개의 성공한 요청, 그 다음에 29개의 추가 실패한 인증 요청이 금지를 트리거하지 않습니다.
- `gitlab-ci-token`로 인증된 JWT 요청에는 적용되지 않습니다.
- 기본적으로 비활성화됩니다.

응답 헤더가 제공되지 않습니다.

속도 제한을 피하려면 다음을 수행할 수 있습니다:

- 자동화된 파이프라인의 실행을 엇갈리게 합니다.
- 실패한 인증 시도를 위해 [지수 백오프 및 재시도](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html)를 구성합니다.
- 토큰 만료를 관리하기 위해 문서화된 프로세스 및 [모범 사례](https://about.gitlab.com/blog/access-token-lifetime-limits/#how-to-minimize-the-impact)를 사용합니다.

구성 정보는 [Linux 패키지 구성 옵션](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-failed-authentication-ban)을 참조하세요.

## 구성 불가능한 제한 {#non-configurable-limits}

### 리포지토리 아카이브 {#repository-archives}

[리포지토리 아카이브 다운로드](../api/repositories.md#retrieve-file-archive-from-a-repository)에 대한 속도 제한을 사용할 수 있습니다. 제한은 프로젝트 및 UI 또는 API를 통해 다운로드를 시작하는 사용자에게 적용됩니다.

속도 제한은 사용자당 분당 5개 요청입니다.

### 사용자 가입 {#users-sign-up}

`/users/sign_up` 엔드포인트에서 IP 주소당 속도 제한이 있습니다. 이는 엔드포인트의 오용 시도를 완화하기 위한 것입니다. 예를 들어 사용 중인 사용자 이름이나 이메일 주소를 대량 발견하기 위해.

속도 제한은 IP 주소당 분당 20개 호출입니다.

### 사용자 이름 업데이트 {#update-username}

사용자 이름을 얼마나 자주 변경할 수 있는지에 대한 속도 제한이 있습니다. 이는 기능의 오용을 완화하기 위해 시행됩니다. 예를 들어 사용 중인 사용자 이름을 대량 발견하기 위해.

속도 제한은 인증된 사용자당 분당 10개 호출입니다.

### 사용자 이름 존재 {#username-exists}

내부 엔드포인트 `/users/:username/exists`에 대한 속도 제한이 있으며, 가입 시 선택한 사용자 이름이 이미 사용되었는지 확인하는 데 사용됩니다. 이는 대량 사용자 이름 발견과 같은 오용 위험을 완화하기 위한 것입니다.

속도 제한은 IP 주소당 분당 20개 호출입니다.

### 프로젝트 작업 API 엔드포인트 {#project-jobs-api-endpoint}

엔드포인트 `project/:id/jobs`에 대한 속도 제한이 있으며, 작업을 검색할 때 타임아웃을 줄이기 위해 시행됩니다.

속도 제한은 인증된 사용자당 600개 호출로 기본 설정됩니다. [속도 제한 구성](../administration/settings/user_and_ip_rate_limits.md)할 수 있습니다.

### AI 작업 {#ai-action}

GraphQL `aiAction` 변이에 대한 속도 제한이 있으며, 이 엔드포인트의 오용을 방지하기 위해 시행됩니다.

속도 제한은 인증된 사용자당 8시간마다 160개 호출입니다.

### API를 사용하여 멤버 삭제 {#delete-a-member-using-the-api}

[API 엔드포인트를 사용하여 프로젝트 또는 그룹 멤버 제거](../api/group_members.md#remove-a-group-member)에 대한 속도 제한이 있습니다 `/groups/:id/members` 또는 `/project/:id/members`.

속도 제한은 분당 60개 삭제입니다.

### API를 사용하여 프로젝트 멤버 나열 {#list-project-members-using-the-api}

{{< history >}}

- GitLab 18.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211239)되었습니다.

{{< /history >}}

그룹 또는 프로젝트의 모든 프로젝트 멤버를 나열하기 위한 속도 제한을 설정합니다. 다음 엔드포인트에서 분당 200개 요청으로 기본 설정됩니다:

```plaintext
GET /groups/:id/members/all
GET /projects/:id/members/all
```

관리자는 프로젝트 엔드포인트에 대해 [속도 제한 구성](../administration/settings/rate_limit_on_groups_api.md)할 수 있습니다.

### 리포지토리 Blob 및 파일 액세스 {#repository-blob-and-file-access}

{{< history >}}

- GitLab 18.1에서 [도입](https://gitlab.com/gitlab-org/security/gitlab/-/issues/1302)되었습니다.

{{< /history >}}

속도 제한은 특정 리포지토리 API 엔드포인트를 통해 큰 파일에 액세스할 때 적용됩니다. 10MB보다 큰 파일의 경우 속도 제한은 다음에 대해 프로젝트당 오브젝트당 분당 5개 호출입니다:

- [리포지토리 Blob 엔드포인트](../api/repositories.md#retrieve-a-blob-from-a-repository): `/projects/:id/repository/blobs/:sha`
- [리포지토리 파일 엔드포인트](../api/repository_files.md#retrieve-a-file-from-a-repository): `/projects/:id/repository/files/:file_path`

이러한 제한은 API를 통해 큰 리포지토리 파일에 액세스할 때 과도한 리소스 사용을 방지하는 데 도움이 됩니다.

### 알림 이메일 {#notification-emails}

{{< history >}}

- GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/439101)되었으며 [기능 플래그](../administration/feature_flags/_index.md) 이름이 `rate_limit_notification_emails`입니다. 기본적으로 사용 중지되어 있습니다.
- GitLab 17.2에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/439101)합니다. `rate_limit_notification_emails` 기능 플래그가 제거되었습니다.

{{< /history >}}

프로젝트 또는 그룹과 관련된 알림 이메일에 대한 속도 제한이 있습니다.

속도 제한은 프로젝트 또는 그룹당 사용자당 24시간마다 1,000개 알림입니다.

### GitHub 가져오기 {#github-import}

GitHub에서 프로젝트 가져오기를 트리거하기 위한 속도 제한이 있습니다.

속도 제한은 사용자당 분당 6개 트리거된 가져오기입니다.

### FogBugz 가져오기 {#fogbugz-import}

{{< history >}}

- GitLab 17.6에서 도입되었습니다.

{{< /history >}}

FogBugz에서 프로젝트 가져오기를 트리거하기 위한 속도 제한이 있습니다.

속도 제한은 사용자당 분당 1개 트리거된 가져오기입니다.

### 커밋 Diff 파일 {#commit-diff-files}

이는 확장된 커밋 Diff 파일 (`/[group]/[project]/-/commit/[:sha]/diff_files?expanded=1`)에 대한 속도 제한이며, 이 엔드포인트의 오용을 방지하기 위해 시행됩니다.

속도 제한은 인증된 사용자당 분당 6개 요청 또는 인증되지 않은 IP 주소당 6개 요청입니다.

### 변경 로그 생성 {#changelog-generation}

`:id/repository/changelog` 엔드포인트에서 사용자당 프로젝트당 속도 제한이 있습니다. 이는 엔드포인트의 오용 시도를 완화하기 위한 것입니다. 속도 제한은 GET 및 POST 작업 간에 공유됩니다.

속도 제한은 사용자당 프로젝트당 분당 5개 호출입니다.

### 배포 삭제 {#delete-a-deployment}

{{< history >}}

- GitLab 19.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/243738)되었습니다.

{{< /history >}}

[배포 삭제](../api/deployments.md#delete-a-deployment)에 속도 제한이 `DELETE /projects/:id/deployments/:deployment_id` 엔드포인트를 통해 적용됩니다. 이 제한은 대량 배포 삭제의 인프라 영향을 줄입니다.

속도 제한은 인증된 사용자당 분당 500개 요청입니다.

## 문제 해결 {#troubleshooting}

### Rack Attack이 로드 밸런서를 거부 목록에 등재 {#rack-attack-is-denylisting-the-load-balancer}

모든 트래픽이 로드 밸런서에서 오는 것으로 보이면 Rack Attack이 로드 밸런서를 차단할 수 있습니다. 이 경우 다음을 수행해야 합니다:

1. [`nginx[real_ip_trusted_addresses]` 구성](https://docs.gitlab.com/omnibus/settings/nginx/#configure-gitlab-trusted-proxies-and-nginx-real_ip-module)합니다. 이는 사용자의 IP가 로드 밸런서 IP로 나열되는 것을 방지합니다.
1. 로드 밸런서의 IP 주소를 허용 목록에 추가합니다.
1. GitLab을 재구성합니다.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Redis에서 Rack Attack으로 차단된 IP 제거 {#remove-blocked-ips-from-rack-attack-with-redis}

차단된 IP를 제거하려면:

1. 프로덕션 로그에서 차단된 IP를 찾습니다:

   ```shell
   grep "Rack_Attack" /var/log/gitlab/gitlab-rails/auth.log
   ```

1. 거부 목록이 Redis에 저장되므로 `redis-cli`을 열어야 합니다:

   ```shell
   /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
   ```

1. 다음 구문을 사용하여 블록을 제거할 수 있습니다. `<ip>`을 거부 목록에 등재된 실제 IP로 바꿉니다:

   ```plaintext
   del cache:gitlab:rack::attack:allow2ban:ban:<ip>
   ```

1. IP가 있는 키가 더 이상 표시되지 않는지 확인합니다:

   ```plaintext
   keys *rack::attack*
   ```

   기본적으로 [`keys` 명령이 비활성화](https://docs.gitlab.com/omnibus/settings/redis/#renamed-commands)됩니다.

1. 선택적으로 [IP를 허용 목록에 추가](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-failed-authentication-ban)하여 다시 거부 목록에 등재되는 것을 방지합니다.

---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: REST API 리소스
description: "컨텍스트(프로젝트, 그룹, 독립형, 템플릿)별로 구성된 GitLab REST API 리소스 및 엔드포인트 경로입니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab REST API는 GitLab 리소스에 대한 프로그래밍 방식의 제어를 제공합니다. 기존 도구와의 통합을 구축하고, 반복적인 작업을 자동화하며, 사용자 지정 보고서를 위한 데이터를 추출합니다. 웹 인터페이스를 사용하지 않고 프로젝트, 그룹, 이슈, 머지 리퀘스트에 액세스하고 조작합니다.

REST API를 사용하여 다음을 수행할 수 있습니다:

- 프로젝트 생성 및 사용자 관리를 자동화합니다.
- 외부 시스템에서 CI/CD 파이프라인을 트리거합니다.
- 이슈 및 머지 리퀘스트 데이터를 사용자 지정 대시보드용으로 추출합니다.
- GitLab을 타사 애플리케이션과 통합합니다.
- 여러 리포지토리에 걸쳐 사용자 지정 워크플로우를 구현합니다.

REST API 리소스는 다음과 같이 구성됩니다:

- [프로젝트 리소스](#project-resources)
- [그룹 리소스](#group-resources)
- [독립형 리소스](#standalone-resources)
- [템플릿 리소스](#template-resources)

## 프로젝트 리소스 {#project-resources}

다음 API 리소스는 프로젝트 컨텍스트에서 사용 가능합니다:

| 리소스                                                                       | 사용 가능한 엔드포인트 |
|--------------------------------------------------------------------------------|---------------------|
| [액세스 요청](access_requests.md)                                          | `/projects/:id/access_requests` (그룹에서도 사용 가능) |
| [액세스 토큰](project_access_tokens.md)                                      | `/projects/:id/access_tokens` (그룹에서도 사용 가능) |
| [에이전트](cluster_agents.md)                                                    | `/projects/:id/cluster_agents` |
| [브랜치](branches.md)                                                        | `/projects/:id/repository/branches/`, `/projects/:id/repository/merged_branches` |
| [커밋](commits.md)                                                          | `/projects/:id/repository/commits`, `/projects/:id/statuses` |
| [컨테이너 레지스트리](container_registry.md)                                    | `/projects/:id/registry/repositories` |
| [컨테이너 리포지토리 보호 규칙](container_repository_protection_rules.md)  | `/projects/:id/registry/protection/repository/rules` |
| [컨테이너 레지스트리 보호 태그 규칙](container_registry_protection_tag_rules.md) | `/projects/:id/registry/protection/tag/rules` |
| [사용자 지정 속성](custom_attributes.md)                                      | `/projects/:id/custom_attributes` (그룹 및 사용자에서도 사용 가능) |
| [Composer 배포](packages/composer.md)                                 | `/projects/:id/packages/composer` (그룹에서도 사용 가능) |
| [Conan v1 배포](packages/conan_v1.md)                                       | `/projects/:id/packages/conan` (독립형으로도 사용 가능) |
| [Conan v2 배포](packages/conan_v2.md)                                       | `/projects/:id/packages/conan` (독립형으로도 사용 가능) |
| [Debian 배포](packages/debian_project_distributions.md)               | `/projects/:id/debian_distributions` (그룹에서도 사용 가능) |
| [Debian 패키지](packages/debian.md)                                          | `/projects/:id/packages/debian` (그룹에서도 사용 가능) |
| [종속성](dependencies.md)                                                | `/projects/:id/dependencies` |
| [배포 키](deploy_keys.md)                                                  | `/projects/:id/deploy_keys` (독립형으로도 사용 가능) |
| [배포 토큰](deploy_tokens.md)                                              | `/projects/:id/deploy_tokens` (그룹 및 독립형으로도 사용 가능) |
| [배포](deployments.md)                                                  | `/projects/:id/deployments` |
| [토론](discussions.md) (스레드 댓글)                              | `/projects/:id/issues/.../discussions`, `/projects/:id/snippets/.../discussions`, `/projects/:id/merge_requests/.../discussions`, `/projects/:id/commits/.../discussions` (그룹에서도 사용 가능) |
| [임시 노트](draft_notes.md) (댓글)                                       | `/projects/:id/merge_requests/.../draft_notes` |
| [이모지 반응](emoji_reactions.md)                                          | `/projects/:id/issues/.../award_emoji`, `/projects/:id/merge_requests/.../award_emoji`, `/projects/:id/snippets/.../award_emoji` |
| [환경](environments.md)                                                | `/projects/:id/environments` |
| [오류 추적](error_tracking.md)                                            | `/projects/:id/error_tracking/settings` |
| [이벤트](events.md)                                                            | `/projects/:id/events` (사용자 및 독립형으로도 사용 가능) |
| [외부 상태 확인](status_checks.md)                                     | `/projects/:id/external_status_checks` |
| [기능 플래그 사용자 목록](feature_flag_user_lists.md)                          | `/projects/:id/feature_flags_user_lists` |
| [기능 플래그](feature_flags.md)                                              | `/projects/:id/feature_flags` |
| [동결 기간](freeze_periods.md)                                            | `/projects/:id/freeze_periods` |
| [Go 프록시](packages/go_proxy.md)                                               | `/projects/:id/packages/go` |
| [Helm 리포지토리](packages/helm.md)                                            | `/projects/:id/packages/helm_repository` |
| [통합](project_integrations.md) (이전명: "서비스")                          | `/projects/:id/integrations` |
| [초대](invitations.md)                                                  | `/projects/:id/invitations` (그룹에서도 사용 가능) |
| [이슈 보드](boards.md)                                                      | `/projects/:id/boards` |
| [이슈 링크](issue_links.md)                                                  | `/projects/:id/issues/.../links` |
| [이슈 통계](issues_statistics.md)                                      | `/projects/:id/issues_statistics` (그룹 및 독립형으로도 사용 가능) |
| [이슈](issues.md)                                                            | `/projects/:id/issues` (그룹 및 독립형으로도 사용 가능) |
| [반복](iterations.md)                                                    | `/projects/:id/iterations` (그룹에서도 사용 가능) |
| [프로젝트 CI/CD 작업 토큰 범위](project_job_token_scopes.md)                   | `/projects/:id/job_token_scope` |
| [작업](jobs.md)                                                                | `/projects/:id/jobs`, `/projects/:id/pipelines/.../jobs` |
| [작업 아티팩트](job_artifacts.md)                                             | `/projects/:id/jobs/:job_id/artifacts` |
| [레이블](labels.md)                                                            | `/projects/:id/labels` |
| [Maven 리포지토리](packages/maven.md)                                          | `/projects/:id/packages/maven` (그룹 및 독립형으로도 사용 가능) |
| [멤버](project_members.md)                                                  | `/projects/:id/members` (그룹에서도 사용 가능) |
| [머지 리퀘스트 승인](merge_request_approvals.md)                          | `/projects/:id/approvals`, `/projects/:id/merge_requests/.../approvals` |
| [머지 리퀘스트](merge_requests.md)                                            | `/projects/:id/merge_requests` (그룹 및 독립형으로도 사용 가능) |
| [머지 트레인](merge_trains.md)                                                | `/projects/:id/merge_trains` |
| [메타데이터](metadata.md)                                                        | `/metadata` |
| [모델 레지스트리](model_registry.md)                                            | `/projects/:id/packages/ml_models/` |
| [노트](notes.md) (댓글)                                                   | `/projects/:id/issues/.../notes`, `/projects/:id/snippets/.../notes`, `/projects/:id/merge_requests/.../notes` (그룹에서도 사용 가능) |
| [알림 설정](notification_settings.md)                              | `/projects/:id/notification_settings` (그룹 및 독립형으로도 사용 가능) |
| [NPM 리포지토리](packages/npm.md)                                              | `/projects/:id/packages/npm` |
| [NuGet 패키지](packages/nuget.md)                                            | `/projects/:id/packages/nuget` (그룹에서도 사용 가능) |
| [패키지](packages.md)                                                        | `/projects/:id/packages` |
| [Pages 도메인](pages_domains.md)                                              | `/projects/:id/pages/domains` (독립형으로도 사용 가능) |
| [Pages 설정](pages.md)                                                     | `/projects/:id/pages` |
| [파이프라인 일정](pipeline_schedules.md)                                    | `/projects/:id/pipeline_schedules` |
| [파이프라인 트리거](pipeline_triggers.md)                                      | `/projects/:id/triggers` |
| [파이프라인](pipelines.md)                                                      | `/projects/:id/pipelines` |
| [프로젝트 배지](project_badges.md)                                            | `/projects/:id/badges` |
| [프로젝트 클러스터](project_clusters.md)                                        | `/projects/:id/clusters` |
| [프로젝트 가져오기/내보내기](project_import_export.md)                              | `/projects/:id/export`, `/projects/import`, `/projects/:id/import` |
| [프로젝트 마일스톤](milestones.md)                                            | `/projects/:id/milestones` |
| [프로젝트 스니펫](project_snippets.md)                                        | `/projects/:id/snippets` |
| [프로젝트 템플릿](project_templates.md)                                      | `/projects/:id/templates` |
| [프로젝트 취약성](project_vulnerabilities.md).                         | `/projects/:id/vulnerabilities` |
| [프로젝트 Wiki](wikis.md)                                                      | `/projects/:id/wikis` |
| [프로젝트 수준 변수](project_level_variables.md)                          | `/projects/:id/variables` |
| [프로젝트](projects.md) (웹후크 설정 포함)                             | `/projects`, `/projects/:id/hooks` (사용자에서도 사용 가능) |
| [보호된 브랜치](protected_branches.md)                                    | `/projects/:id/protected_branches` |
| [보호된 컨테이너 레지스트리](container_repository_protection_rules.md)       | `/projects/:id/registry/protection/rules` |
| [보호 환경](protected_environments.md)                            | `/projects/:id/protected_environments` |
| [보호된 패키지](project_packages_protection_rules.md)                     | `/projects/:id/packages/protection/rules` |
| [보호된 태그](protected_tags.md)                                            | `/projects/:id/protected_tags` |
| [PyPI 패키지](packages/pypi.md)                                              | `/projects/:id/packages/pypi` (그룹에서도 사용 가능) |
| [릴리스 링크](releases/links.md)                                             | `/projects/:id/releases/.../assets/links` |
| [릴리스](releases/_index.md)                                                 | `/projects/:id/releases` |
| [원격 미러](remote_mirrors.md)                                            | `/projects/:id/remote_mirrors` |
| [리포지토리](repositories.md)                                                | `/projects/:id/repository` |
| [리포지토리 파일](repository_files.md)                                        | `/projects/:id/repository/files` |
| [리포지토리 하위 모듈](repository_submodules.md)                              | `/projects/:id/repository/submodules` |
| [리소스 레이블 이벤트](resource_label_events.md)                              | `/projects/:id/issues/.../resource_label_events`, `/projects/:id/merge_requests/.../resource_label_events` (그룹에서도 사용 가능) |
| [Ruby gems](packages/rubygems.md)                                              | `/projects/:id/packages/rubygems` |
| [러너](runners.md)                                                          | `/projects/:id/runners` (독립형으로도 사용 가능) |
| [검색](search.md)                                                            | `/projects/:id/search` (그룹 및 독립형으로도 사용 가능) |
| [태그](tags.md)                                                                | `/projects/:id/repository/tags` |
| [Terraform 모듈](packages/terraform-modules.md)                             | `/projects/:id/packages/terraform/modules` (독립형으로도 사용 가능) |
| [`.gitlab-ci.yml` 파일 검증](lint.md)                                      | `/projects/:id/ci/lint` |
| [취약성](vulnerabilities.md)                                          | `/vulnerabilities/:id` |
| [취약성 내보내기](vulnerability_exports.md)                              | `/projects/:id/vulnerability_exports` |
| [취약성 결과](vulnerability_findings.md)                            | `/projects/:id/vulnerability_findings` |

## 그룹 리소스 {#group-resources}

다음 API 리소스는 그룹 컨텍스트에서 사용 가능합니다:

| 리소스                                                       | 사용 가능한 엔드포인트 |
|----------------------------------------------------------------|---------------------|
| [액세스 요청](access_requests.md)                          | `/groups/:id/access_requests/` (프로젝트에서도 사용 가능) |
| [액세스 토큰](group_access_tokens.md)                        | `/groups/:id/access_tokens` (프로젝트에서도 사용 가능) |
| [사용자 지정 속성](custom_attributes.md)                      | `/groups/:id/custom_attributes` (프로젝트 및 사용자에서도 사용 가능) |
| [Debian 배포](packages/debian_group_distributions.md) | `/groups/:id/-/packages/debian` (프로젝트에서도 사용 가능) |
| [배포 토큰](deploy_tokens.md)                              | `/groups/:id/deploy_tokens` (프로젝트 및 독립형으로도 사용 가능) |
| [토론](discussions.md) (댓글 및 스레드)           | `/groups/:id/epics/.../discussions` (프로젝트에서도 사용 가능) |
| [에픽 이슈](epic_issues.md)                                  | `/groups/:id/epics/.../issues` |
| [에픽 링크](epic_links.md)                                    | `/groups/:id/epics/.../epics` |
| [에픽](epics.md)                                              | `/groups/:id/epics` |
| [그룹](groups.md)                                            | `/groups`, `/groups/.../subgroups` |
| [그룹 배지](group_badges.md)                                | `/groups/:id/badges` |
| [그룹 이슈 보드](group_boards.md)                          | `/groups/:id/boards` |
| [그룹 반복](group_iterations.md)                        | `/groups/:id/iterations` (프로젝트에서도 사용 가능) |
| [그룹 레이블](group_labels.md)                                | `/groups/:id/labels` |
| [그룹 수준 변수](group_level_variables.md)              | `/groups/:id/variables` |
| [그룹 마일스톤](group_milestones.md)                        | `/groups/:id/milestones` |
| [그룹 릴리스](group_releases.md)                            | `/groups/:id/releases` |
| [그룹 SSH 인증서](group_ssh_certificates.md)            | `/groups/:id/ssh_certificates` |
| [그룹 Wiki](group_wikis.md)                                  | `/groups/:id/wikis` |
| [초대](invitations.md)                                  | `/groups/:id/invitations` (프로젝트에서도 사용 가능) |
| [이슈](issues.md)                                            | `/groups/:id/issues` (프로젝트 및 독립형으로도 사용 가능) |
| [이슈 통계](issues_statistics.md)                      | `/groups/:id/issues_statistics` (프로젝트 및 독립형으로도 사용 가능) |
| [연결된 에픽](linked_epics.md)                                | `/groups/:id/epics/.../related_epics` |
| [멤버 역할](member_roles.md)                                | `/groups/:id/member_roles` |
| [멤버](group_members.md)                                    | `/groups/:id/members` (프로젝트에서도 사용 가능) |
| [머지 리퀘스트](merge_requests.md)                            | `/groups/:id/merge_requests` (프로젝트 및 독립형으로도 사용 가능) |
| [노트](notes.md) (댓글)                                   | `/groups/:id/epics/.../notes` (프로젝트에서도 사용 가능) |
| [알림 설정](notification_settings.md)              | `/groups/:id/notification_settings` (프로젝트 및 독립형으로도 사용 가능) |
| [리소스 레이블 이벤트](resource_label_events.md)              | `/groups/:id/epics/.../resource_label_events` (프로젝트에서도 사용 가능) |
| [검색](search.md)                                            | `/groups/:id/search` (프로젝트 및 독립형으로도 사용 가능) |

## 독립형 리소스 {#standalone-resources}

다음 API 리소스는 프로젝트 및 그룹 컨텍스트 외부에서 사용 가능합니다(`/users` 포함):

| 리소스                                                                                     | 사용 가능한 엔드포인트 |
|----------------------------------------------------------------------------------------------|---------------------|
| [모양](appearance.md)                                                                  | `/application/appearance` |
| [애플리케이션](applications.md)                                                              | `/applications` |
| [감사 이벤트](audit_events.md)                                                              | `/audit_events` |
| [아바타](avatar.md)                                                                          | `/avatar` |
| [브로드캐스트 메시지](broadcast_messages.md)                                                  | `/broadcast_messages` |
| [코드 스니펫](snippets.md)                                                                 | `/snippets` |
| [Code Suggestions](code_suggestions.md)                                                      | `/code_suggestions` |
| [사용자 지정 속성](custom_attributes.md)                                                    | `/users/:id/custom_attributes` (그룹 및 프로젝트에서도 사용 가능) |
| [종속성 목록 내보내기](dependency_list_export.md)                                         | `/pipelines/:id/dependency_list_exports`, `/projects/:id/dependency_list_exports`, `/groups/:id/dependency_list_exports`, `/security/dependency_list_exports/:id`, `/security/dependency_list_exports/:id/download` |
| [배포 키](deploy_keys.md)                                                                | `/deploy_keys` (프로젝트에서도 사용 가능) |
| [배포 토큰](deploy_tokens.md)                                                            | `/deploy_tokens` (프로젝트 및 그룹에서도 사용 가능) |
| [GitLab Duo 에이전트 플랫폼 플로우](duo_agent_platform_flows.md)                                      | `/ai/duo_workflows` |
| [이벤트](events.md)                                                                          | `/events`, `/users/:id/events` (프로젝트에서도 사용 가능) |
| [기능 플래그](features.md)                                                                 | `/features` |
| [Geo 노드](geo_nodes.md)                                                                    | `/geo_nodes` |
| [GLQL](glql.md)                                                                              | `/glql` |
| [그룹 활동 분석](group_activity_analytics.md)                                      | `/analytics/group_activity/{issues_count}` |
| [그룹 리포지토리 저장소 이동](group_repository_storage_moves.md)                          | `/group_repository_storage_moves` |
| [GitHub에서 리포지토리 가져오기](import.md#import-repository-from-github)                     | `/import/github` |
| [Bitbucket Server에서 리포지토리 가져오기](import.md#import-repository-from-bitbucket-server) | `/import/bitbucket_server` |
| [인스턴스 클러스터](instance_clusters.md)                                                    | `/admin/clusters` |
| [인스턴스 수준 CI/CD 변수](instance_level_ci_variables.md)                             | `/admin/ci/variables` |
| [이슈 통계](issues_statistics.md)                                                    | `/issues_statistics` (그룹 및 프로젝트에서도 사용 가능) |
| [이슈](issues.md)                                                                          | `/issues` (그룹 및 프로젝트에서도 사용 가능) |
| [작업](jobs.md)                                                                              | `/job` |
| [키](keys.md)                                                                              | `/keys` |
| [라이선스](license.md)                                                                        | `/license` |
| [마크다운](markdown.md)                                                                      | `/markdown` |
| [머지 리퀘스트](merge_requests.md)                                                          | `/merge_requests` (그룹 및 프로젝트에서도 사용 가능) |
| [네임스페이스](namespaces.md)                                                                  | `/namespaces` |
| [알림 설정](notification_settings.md)                                            | `/notification_settings` (그룹 및 프로젝트에서도 사용 가능) |
| [규정 준수 및 정책 설정](compliance_policy_settings.md)         | `/admin/security/compliance_policy_settings` |
| [Pages 도메인](pages_domains.md)                                                            | `/pages/domains` (프로젝트에서도 사용 가능) |
| [개인 액세스 토큰](personal_access_tokens.md)                                          | `/personal_access_tokens` |
| [계획 제한](plan_limits.md)                                                                | `/application/plan_limits` |
| [프로젝트 리포지토리 저장소 이동](project_repository_storage_moves.md)                      | `/project_repository_storage_moves` |
| [프로젝트](projects.md)                                                                      | `/users/:id/projects` (프로젝트에서도 사용 가능) |
| [러너](runners.md)                                                                        | `/runners` (프로젝트에서도 사용 가능) |
| [검색](search.md)                                                                          | `/search` (그룹 및 프로젝트에서도 사용 가능) |
| [서비스 데이터](usage_data.md)                                                                | `/usage_data` (GitLab 인스턴스 [Administrator](../user/permissions.md) 사용자만) |
| [설정](settings.md)                                                                      | `/application/settings` |
| [Sidekiq 메트릭](sidekiq_metrics.md)                                                        | `/sidekiq` |
| [Sidekiq 대기열 관리](admin_sidekiq_queues.md)                                     | `/admin/sidekiq/queues/:queue_name` |
| [스니펫 리포지토리 저장소 이동](snippet_repository_storage_moves.md)                      | `/snippet_repository_storage_moves` |
| [통계](statistics.md)                                                                  | `/application/statistics` |
| [제안](suggestions.md)                                                                | `/suggestions` |
| [시스템 웹후크](system_hooks.md)                                                              | `/hooks` |
| [할 일](todos.md)                                                                           | `/todos` |
| [토큰 정보](admin/token.md)                                                          | `/admin/token` |
| [토픽](topics.md)                                                                          | `/topics` |
| [사용자 애플리케이션](user_applications.md)                                                    | `/user/applications` |
| [사용자](users.md)                                                                            | `/users` |
| [웹 커밋](web_commits.md)                                                                | `/web_commits/public_key` |

## 템플릿 리소스 {#template-resources}

다음에 대한 엔드포인트를 사용할 수 있습니다:

- [Dockerfile 템플릿](templates/dockerfiles.md)
- [`.gitignore` 템플릿](templates/gitignores.md)
- [GitLab CI/CD YAML 템플릿](templates/gitlab_ci_ymls.md)
- [오픈 소스 라이선스 템플릿](templates/licenses.md)

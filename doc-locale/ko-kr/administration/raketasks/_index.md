---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Rake 작업
description: 관리 및 운영 Rake 작업입니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 [Rake](https://ruby.github.io/rake/) 작업으로 일반적인 관리 및 운영 프로세스를 지원합니다.

모든 Rake 작업은 작업 설명서에서 명시하지 않는 한 Rails 노드에서 실행해야 합니다.

다음을 사용하여 GitLab Rake 작업을 수행할 수 있습니다:

- `gitlab-rake <raketask>` - [Linux 패키지](https://docs.gitlab.com/omnibus/) 및 [GitLab Helm 차트](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet/#gitlab-specific-kubernetes-information) 설치용입니다.
- `bundle exec rake <raketask>` - [직접 컴파일된](../../install/self_compiled/_index.md) 설치용입니다.

## 사용 가능한 Rake 작업 {#available-rake-tasks}

다음은 GitLab에서 사용할 수 있는 Rake 작업입니다:

| 태스크                                                                                                 | 설명 |
|:------------------------------------------------------------------------------------------------------|:------------|
| [액세스 토큰 만료 작업](tokens/_index.md)                                                     | 액세스 토큰의 만료 날짜를 일괄 연장하거나 제거합니다. |
| [AI 카탈로그 외부 에이전트](ai_catalog.md)                                                           | AI 카탈로그 외부 에이전트를 시드합니다. |
| [백업 및 복원](../backup_restore/_index.md)                                                    | GitLab 인스턴스를 백업, 복원 및 서버 간에 마이그레이션합니다. |
| [정리](cleanup.md)                                                                                | GitLab 인스턴스에서 불필요한 항목을 정리합니다. |
| 개발                                                                                           | GitLab 기여자를 위한 작업입니다. 자세한 내용은 개발 설명서를 참조하세요. |
| [Elasticsearch](../../integration/advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) | GitLab 인스턴스에서 Elasticsearch를 유지 관리합니다. |
| [일반 유지 관리](maintenance.md)                                                                 | 일반 유지 관리 및 자체 확인 작업입니다. |
| [GitHub 가져오기](../../user/project/import/github.md)                                                  | GitHub에서 저장소를 검색 및 가져옵니다. |
| [대규모 프로젝트 내보내기 가져오기](project_import_export.md#import-large-projects)                        | 대규모 GitLab [프로젝트 내보내기](../../user/project/settings/import_export.md)를 가져옵니다. |
| [수신 이메일](incoming_email.md)                                                                   | 수신 이메일 관련 작업입니다. |
| [무결성 확인](check.md)                                                                          | 저장소, 파일, LDAP 등의 무결성을 확인합니다. |
| [Keep-around 참조](keep_around.md)                                                              | 프로젝트에 대한 모든 고아 keep-around 참조를 찾습니다. |
| [LDAP 유지 관리](ldap.md)                                                                           | [LDAP](../auth/ldap/_index.md) 관련 작업입니다. |
| [비밀번호](password.md)                                                                               | 비밀번호 관리 작업입니다. |
| [Praefect Rake 작업](praefect.md)                                                                    | [Praefect](../gitaly/praefect/_index.md) 관련 작업입니다. |
| [프로젝트 가져오기/내보내기](project_import_export.md)                                                     | [프로젝트 내보내기 및 가져오기](../../user/project/settings/import_export.md)를 준비합니다. |
| [Sidekiq 작업 마이그레이션](../sidekiq/sidekiq_job_migration.md)                                          | 미래 날짜에 예약된 Sidekiq 작업을 새 큐로 마이그레이션합니다. |
| [Service Desk 이메일](service_desk_email.md)                                                           | Service Desk 이메일 관련 작업입니다. |
| [SMTP 유지 관리](smtp.md)                                                                           | SMTP 관련 작업입니다. |
| [SPDX 라이선스 목록 가져오기](spdx.md)                                                                   | [SPDX 라이선스 목록](https://spdx.org/licenses/) 의 로컬 복사본을 가져와서 [라이선스 승인 정책](../../user/compliance/license_approval_policies.md)과 일치시킵니다. |
| [사용자 비밀번호 재설정](../../security/reset_user_password.md#use-a-rake-task)                         | Rake를 사용하여 사용자 비밀번호를 재설정합니다. |
| [의미론적 코드 검색](../../user/gitlab_duo/semantic_code_search.md#check-semantic-code-search-status) | 의미론적 코드 검색 상태를 확인합니다. |
| [업로드 마이그레이션](uploads/migrate.md)                                                                 | 로컬 스토리지와 객체 스토리지 간에 업로드를 마이그레이션합니다. |
| [업로드 삭제](uploads/sanitize.md)                                                               | GitLab의 이전 버전에 업로드된 이미지에서 EXIF 데이터를 제거합니다. |
| 서비스 데이터                                                                                          | Service Ping를 생성하고 문제를 해결합니다. 자세한 내용은 Service Ping 개발 설명서를 참조하세요. |
| [사용자 관리](user_management.md)                                                                 | 사용자 관리 작업을 수행합니다. |
| [웹후크 관리](web_hooks.md)                                                                | 프로젝트 웹후크를 유지 관리합니다. |
| [X.509 서명](x509_signatures.md)                                                                | X.509 커밋 서명을 업데이트합니다. 이는 인증서 저장소가 변경된 경우 유용할 수 있습니다. |

사용 가능한 모든 Rake 작업을 나열하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake -vT
```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

```shell
gitlab-rake -vT
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake -vT RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

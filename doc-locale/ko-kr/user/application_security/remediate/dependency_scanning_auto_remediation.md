---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 종속성 검사 자동 수정
description: 취약한 종속성을 수정하기 위해 자동으로 머지 리퀘스트를 엽니다.
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- `dependency_management_auto_remediation`라는 이름의 [기능 플래그](../../../administration/feature_flags/_index.md)를 사용하는 [실험적 기능](../../../policy/development_stages_support.md#experiment)으로 GitLab 19.0에 [도입됨](https://gitlab.com/groups/gitlab-org/-/work_items/17403). 기본적으로 비활성화되었습니다.
- [GitLab 19.2로 이동](https://gitlab.com/groups/gitlab-org/-/work_items/604588)되어 [베타](../../../policy/development_stages_support.md#beta) 단계에 진입했습니다. `dependency_management_auto_remediation` 기능 플래그는 기본적으로 활성화됩니다.
- 에이전트 기반 주요 변경 해결 기능이 GitLab 19.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/603392)되었으며 [기능 플래그](../../../administration/feature_flags/_index.md)는 `enable_dependency_bump_breaking_changes`입니다. 기본적으로 비활성화되었습니다.

{{< /history >}}

종속성 검사 자동 수정은 취약한 종속성을 사용 가능한 비취약 버전으로 업그레이드하는 머지 리퀘스트를 엽니다. 서비스 계정이 사용자의 개입 없이 머지 리퀘스트를 생성하며, 이후 표준 검토 및 승인 프로세스를 거칩니다.

베타 단계에서 종속성 검사 자동 수정은 독립적으로 구성할 수 있는 두 가지 기능을 지원합니다:

- 종속성 버전 업그레이드: GitLab은 취약한 종속성을 업데이트하는 머지 리퀘스트를 엽니다.
- 에이전트 기반 주요 변경 해결: 버전 업그레이드로 인해 주요 변경으로 인한 파이프라인 실패가 발생하면 GitLab Duo가 자동으로 해결을 시도합니다. 자세한 내용은 [에이전트 기반 주요 변경 해결 활성화](#enable-agentic-breaking-change-resolution)를 참조하세요.

일반적으로 사용 가능한 로드맵은 [에픽 19244](https://gitlab.com/groups/gitlab-org/-/work_items/19244)를 참조하세요.

## 종속성 검사 자동 수정 활성화 {#turn-on-dependency-scanning-auto-remediation}

전제 조건:

- `dependency_management_auto_remediation` [기능 플래그](../../../administration/feature_flags/_index.md)는 프로젝트에서 활성화되어야 합니다. 이 플래그는 GitLab 19.2에서 기본적으로 활성화됩니다.
- [종속성 검사](../dependency_scanning/_index.md) 기능이 활성화되어 있고 결과를 생성하고 있어야 합니다.
- 프로젝트에서 [지원되는 패키지 관리자](#supported-package-managers)를 사용해야 합니다.
- 종속성 검사 자동 수정 프로필이 프로젝트에 연결되어야 합니다. 지침은 [종속성 검사 자동 수정 프로필](../configuration/security_configuration_profiles.md#dependency-scanning-auto-remediation-profile)을 참조하세요.

취약성 검사와 자동 수정을 트리거하려면 파이프라인을 실행합니다. 종속성 검사 자동 수정은 GitLab이 사용 가능한 수정이 있는 취약성을 감지할 때 자동으로 트리거됩니다.

## 종속성 버전 업그레이드 작동 방식 {#how-dependency-version-bumps-work}

종속성 검사 자동 수정 프로필이 이 동작을 제어합니다. 기본 프로필 사용:

- 심각도 임계값: GitLab은 심각도 `high` 이상의 취약성을 수정합니다.
- 휴지 기간: GitLab은 최근 7일 동안 릴리스된 수정 버전을 제외합니다.
- 업그레이드 정책: GitLab은 [에이전트 기반 주요 변경 해결](#enable-agentic-breaking-change-resolution)이 활성화되지 않은 한 패치 및 부 버전 업그레이드만 제안합니다.
- 머지 리퀘스트 열기 제한: 최대 10개의 자동 수정 머지 리퀘스트가 한 번에 프로젝트당 열린 상태로 있을 수 있습니다. GitLab은 기존 머지 리퀘스트가 병합되거나 닫힐 때까지 새 머지 리퀘스트를 생성하지 않습니다.

각 파이프라인이 실행된 후 GitLab은 종속성 스캔 결과를 이 값들과 비교합니다. 각 적격 취약성에 대해 다음을 수행합니다.

1. GitLab은 가장 가까운 주요 변경을 포함하지 않는 업그레이드 경로를 결정합니다.
1. 서비스 계정이 관련 매니페스트 파일을 업데이트하는 머지 리퀘스트를 엽니다.
1. GitLab은 프로젝트의 활성 유지 보수자를 검토자로 지정합니다. 활성 유지 보수자가 없으면 머지 리퀘스트가 검토자 없이 열린 상태로 유지됩니다.
1. 머지 리퀘스트는 프로젝트의 표준 승인 워크플로우를 거칩니다.

베타 단계 동안 GitLab은 가장 높은 심각도의 발견으로 시작하여 한 번에 세 개의 취약성을 처리합니다.

## 에이전트 기반 주요 변경 해결 활성화 {#enable-agentic-breaking-change-resolution}

버전 업그레이드로 인해 주요 변경으로 인한 파이프라인 실패가 발생하면 GitLab Duo가 주요 변경을 자동으로 해결할 수 있습니다. 이 기능은 종속성 버전 업그레이드 기능과 별도이며 자체 토글이 있습니다.

전제 조건:

- 프로젝트에서 [GitLab Duo](../../../user/gitlab_duo/_index.md)를 사용할 수 있어야 합니다.
- `enable_dependency_bump_breaking_changes` [기능 플래그](../../../administration/feature_flags/_index.md)는 프로젝트의 루트 네임스페이스에서 활성화되어야 합니다.

에이전트 기반 주요 변경 해결을 활성화하려면 [프로젝트 API](../../../api/projects.md#update-a-project)를 사용하여 프로젝트에 대해 `duo_dependency_bump_breaking_changes_enabled`을 `true`로 설정합니다.

## 스케줄러 동시성 구성 {#configure-scheduler-concurrency}

관리자는 Sidekiq 플릿 전체에서 동시에 실행되는 자동 수정 스케줄러 작업의 수를 제한할 수 있습니다. `security_update_scheduler_max_concurrency` [애플리케이션 설정](../../../api/settings.md)을 사용하여 상한을 설정합니다. 기본값은 `30`이며 값은 `200`로 제한됩니다. 스케줄링을 일시 중지하려면 값을 `0`으로 설정합니다.

## 지원되는 패키지 관리자 {#supported-package-managers}

종속성 검사 자동 수정은 다음 패키지 관리자를 지원합니다:

| 언어                | 패키지 관리자                     | 파일                                                                          |
| ----------------------- | ------------------------------------ | ------------------------------------------------------------------------------ |
| Ruby                    | Bundler                             | `Gemfile`, `Gemfile.lock`                                                      |
| Java                    | Maven                               | `pom.xml`                                                                      |
| Java                    | Gradle                              | `build.gradle`, `build.gradle.kts`                                             |
| Python                  | pip, pipenv, poetry, setuptools, uv | `requirements.txt`, `Pipfile`, `pyproject.toml`, `setup.py`, `uv.lock`         |
| JavaScript / TypeScript | npm, yarn, pnpm, bun                | `package.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lock` |

추가 생태계 지원은 [에픽 19244](https://gitlab.com/groups/gitlab-org/-/work_items/19244)에서 제안되고 있습니다.

## 알려진 이슈 {#known-issues}

베타 단계 동안:

- 휴지 기간: GitLab은 최근 7일 동안 릴리스된 수정 버전을 제안하지 않으며, 나중에 손상되었거나 악의적인 것으로 판명될 수 있는 버전으로 수정될 위험을 줄입니다.
- 버전 업그레이드 범위:  패치 및 마이너 버전 업그레이드만 제안됩니다. 주요 변경을 발생시킬 가능성이 더 높은 주 버전 업그레이드는 에이전트 기반 주요 변경 해결이 활성화되지 않은 한 시도되지 않습니다.
- 파이프라인 실행당 1개 취약성:  각 파이프라인 실행은 사용 가능한 수정 사항이 있는 단일 취약성을 대상으로 합니다. 여러 수정 사항을 하나의 머지 리퀘스트로 일괄 처리하는 것은 [에픽 19244](https://gitlab.com/groups/gitlab-org/-/work_items/19244)에서 제안되고 있습니다.
- 사용 가능한 수정 사항 없음:  취약성에 대해 호환성을 깨지 않는(non-breaking) 수정 버전이 없으면 해당 발견 항목에 대한 머지 리퀘스트는 생성되지 않습니다.

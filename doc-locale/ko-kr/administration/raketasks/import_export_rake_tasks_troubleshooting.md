---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 가져오기 및 내보내기 문제 해결
---

가져오기 또는 내보내기에 문제가 있으면 Rake 작업을 사용하여 디버그 모드를 활성화합니다:

```shell
# Import
IMPORT_DEBUG=true gitlab-rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file_to_import.tar.gz]"

# Export
EXPORT_DEBUG=true gitlab-rake "gitlab:import_export:export[root, group/subgroup, projectnametoexport, /tmp/export_file.tar.gz]"
```

다음으로 특정 오류 메시지에 대한 세부 정보를 검토합니다.

## `Exception: undefined method 'name' for nil:NilClass` {#exception-undefined-method-name-for-nilnilclass}

`username`은(는) 유효하지 않습니다.

## `Exception: undefined method 'full_path' for nil:NilClass` {#exception-undefined-method-full_path-for-nilnilclass}

`namespace_path`이(가) 존재하지 않습니다. 예를 들어 그룹 또는 하위 그룹 중 하나의 이름이 잘못되었거나 누락되었거나, 경로에 프로젝트 이름을 지정했을 수 있습니다.

작업은 프로젝트만 생성합니다. 새 그룹 또는 하위 그룹으로 가져오려면 먼저 생성합니다.

## `Exception: No such file or directory @ rb_sysopen - (filename)` {#exception-no-such-file-or-directory--rb_sysopen---filename}

`archive_path`에서 지정한 프로젝트 내보내기 파일이 누락되었습니다.

## `Exception: Permission denied @ rb_sysopen - (filename)` {#exception-permission-denied--rb_sysopen---filename}

지정한 프로젝트 내보내기 파일에 `git` 사용자가 액세스할 수 없습니다.

문제를 해결하려면:

1. 파일 소유자를 `git:git`으로 설정합니다.
1. 파일 권한을 `0400`으로 변경합니다.
1. 파일을 공용 폴더(예: `/tmp/`)로 이동합니다.

## `Name can contain only letters, digits, emoji ...` {#name-can-contain-only-letters-digits-emoji-}

```plaintext
Name can contain only letters, digits, emoji, '_', '.', '+', dashes, or spaces. It must start with a letter,
digit, emoji, or '_', and Path can contain only letters, digits, '_', '-', or '.'. It cannot start
with '-', end in '.git', or end in '.atom'.
```

`project_path`에서 지정한 프로젝트 이름이 지정된 이유 중 하나로 유효하지 않습니다.

`project_path`에 프로젝트 이름만 입력합니다. 예를 들어 하위 그룹의 경로를 제공하면 `/`이(가) 프로젝트 이름의 유효한 문자가 아니므로 이 오류가 발생합니다.

## `Name has already been taken and Path has already been taken` {#name-has-already-been-taken-and-path-has-already-been-taken}

그 이름의 프로젝트가 이미 존재합니다.

## `Exception: Error importing repository into (namespace) - No space left on device` {#exception-error-importing-repository-into-namespace---no-space-left-on-device}

디스크 공간이 부족하여 가져오기를 완료할 수 없습니다.

가져오기 중에 tarball이 구성된 `shared_path` 디렉터리에 캐시됩니다. 디스크에 캐시된 tarball과 압축 해제된 프로젝트 파일을 모두 수용할 수 있는 충분한 여유 공간이 있는지 확인합니다.

## `Total number of not imported relations: XX` 메시지로 가져오기 성공 {#import-succeeds-with-total-number-of-not-imported-relations-xx-message}

`Total number of not imported relations: XX` 메시지를 수신했는데 가져오기 중에 이슈가 생성되지 않으면 [`exceptions_json.log`](../logs/_index.md#exceptions_jsonlog)를 확인합니다. `N is out of range for ActiveModel::Type::Integer with limit 4 bytes`과(와) 같은 오류가 표시될 수 있습니다. 여기서 `N`은(는) 4바이트 정수 제한을 초과하는 정수입니다. 그 경우 `relative_position` 필드의 이슈 재조정 문제가 발생할 가능성이 높습니다.

```ruby
# Check the current maximum value of relative_position
Issue.where(project_id: Project.find(ID).root_namespace.all_projects).maximum(:relative_position)

# Run the rebalancing process and check if the maximum value of relative_position has changed
Issues::RelativePositionRebalancingService.new(Project.find(ID).root_namespace.all_projects).execute
Issue.where(project_id: Project.find(ID).root_namespace.all_projects).maximum(:relative_position)
```

가져오기를 다시 시도하고 이슈가 성공적으로 가져와졌는지 확인합니다.

## 가져오기 시 Gitaly 호출 오류 {#gitaly-calls-error-when-importing}

대규모 프로젝트를 개발 환경으로 가져오려고 시도하는 경우 Gitaly에서 너무 많은 호출 또는 호출에 대한 오류를 발생시킬 수 있습니다. 예를 들어:

```plaintext
Error importing repository into qa-perf-testing/gitlabhq - GitalyClient#call called 31 times from single request. Potential n+1?
```

이 오류는 개발 설정의 n+1 호출 제한 때문입니다. 이 오류를 해결하려면 `GITALY_DISABLE_REQUEST_LIMITS=1`을(를) 환경 변수로 설정합니다. 그런 다음 개발 환경을 다시 시작하고 가져오기를 다시 합니다.

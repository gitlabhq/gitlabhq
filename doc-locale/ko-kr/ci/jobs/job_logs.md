---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD 작업 로그
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

작업 로그는 [작업](_index.md)의 전체 실행 기록을 표시합니다.

## 작업 로그 보기 {#view-job-logs}

작업 로그를 보려면:

1. 작업 로그를 보려는 프로젝트를 선택합니다.
1. 왼쪽 사이드바에서 **CI/CD** > **파이프라인**을 선택합니다.
1. 검사하려는 파이프라인을 선택합니다.
1. 파이프라인 보기에서 작업 목록에서 작업을 선택하여 작업 로그 페이지를 봅니다.

작업과 해당 로그 출력에 대한 자세한 정보를 보려면 작업 로그 페이지를 스크롤합니다.

## 전체 화면 모드에서 작업 로그 보기 {#view-job-logs-in-full-screen-mode}

**전체 화면 표시**를 클릭하여 전체 화면 모드에서 작업 로그의 내용을 볼 수 있습니다.

전체 화면 모드를 사용하려면 웹 브라우저도 이를 지원해야 합니다. 웹 브라우저가 전체 화면 모드를 지원하지 않으면 이 옵션을 사용할 수 없습니다.

## 작업 로그 섹션 확장 및 축소 {#expand-and-collapse-job-log-sections}

{{< history >}}

- bash 셸의 다중 라인 명령 출력이 GitLab 16.5에서 [도입](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3486)되었으며, [기능 플래그](https://docs.gitlab.com/runner/configuration/feature-flags/)는 `FF_SCRIPT_SECTIONS`입니다. 기본적으로 비활성화되어 있습니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

`FF_SCRIPT_SECTIONS`을 활성화하면 다중 라인 스크립트 명령이 작업 로그에 축소 가능한 섹션으로 나타납니다. 한 줄 명령은 `$` 접두사로 직접 인쇄됩니다. 지속 시간이 표시되지 않습니다.

`powershell` 및 `pwsh` 셸에서 `FF_SCRIPT_SECTIONS`은 축소 가능한 섹션을 생성하지 않습니다. 명령은 색상 출력으로만 인쇄됩니다.

### 사용자 정의 축소 가능한 섹션 생성 {#create-custom-collapsible-sections}

GitLab이 축소 가능한 섹션을 구분하는 데 사용하는 특수 코드를 수동으로 출력하여 작업 로그에 축소 가능한 섹션을 생성할 수 있습니다:

- 섹션 시작 마커: `\e[0Ksection_start:UNIX_TIMESTAMP:SECTION_NAME\r\e[0K` + `TEXT_OF_SECTION_HEADER`
- 섹션 끝 마커: `\e[0Ksection_end:UNIX_TIMESTAMP:SECTION_NAME\r\e[0K`

이 코드를 CI 구성의 스크립트 섹션에 추가해야 합니다. 예를 들어 `echo`을 사용합니다:

```yaml
job1:
  script:
    - echo -e "\e[0Ksection_start:`date +%s`:my_first_section\r\e[0KHeader of the 1st collapsible section"
    - echo 'this line should be hidden when collapsed'
    - echo -e "\e[0Ksection_end:`date +%s`:my_first_section\r\e[0K"
```

러너가 사용하는 셸에 따라 이스케이프 구문이 다를 수 있습니다. 예를 들어 Zsh를 사용하는 경우 특수 문자를 `\\e` 또는 `\\r`로 이스케이프해야 할 수 있습니다.

위의 예에서:

- `date +%s`: Unix 타임스탬프를 생성하는 명령(예: `1560896352`)입니다.
- `my_first_section`: 섹션에 제공된 이름입니다. 이름은 문자, 숫자 및 `_`, `.`, `-` 문자로만 구성될 수 있습니다.
- `\r\e[0K`: 렌더링된(색상이 지정된) 작업 로그에 섹션 마커가 표시되는 것을 방지하는 이스케이프 시퀀스입니다. 원본 작업 로그를 볼 때 작업 로그의 오른쪽 위 모서리에서 **전체 원본 표시**({{< icon name="doc-text" >}})를 선택하여 표시됩니다.
  - `\r`: 캐리지 리턴(커서를 라인의 시작 위치로 이동).
  - `\e[0K`: 커서 위치에서 라인 끝까지 라인을 지우는 ANSI 이스케이프 코드입니다. (`\e[K`만으로는 작동하지 않습니다. `0`을 포함해야 합니다).

원본 작업 로그 샘플:

```plaintext
\e[0Ksection_start:1560896352:my_first_section\r\e[0KHeader of the 1st collapsible section
this line should be hidden when collapsed
\e[0Ksection_end:1560896353:my_first_section\r\e[0K
```

작업 로그 콘솔 샘플:

![숨겨진 콘텐츠가 있는 축소된 섹션을 표시하는 작업 로그](img/collapsible_job_v16_10.png)

#### 스크립트를 사용하여 섹션 표시 개선 {#improve-section-display-with-a-script}

작업 로그 출력에서 섹션 마커를 생성하는 `echo` 문을 제거하려면 작업 내용을 스크립트 파일로 이동하고 작업에서 호출할 수 있습니다:

1. 섹션 헤더를 처리할 수 있는 스크립트를 만듭니다. 예를 들어:

   ```shell
   # function for starting the section
   function section_start () {
     local section_title="${1}"
     local section_description="${2:-$section_title}"

     echo -e "section_start:`date +%s`:${section_title}[collapsed=true]\r\e[0K${section_description}"
   }

   # Function for ending the section
   function section_end () {
     local section_title="${1}"

     echo -e "section_end:`date +%s`:${section_title}\r\e[0K"
   }

   # Create sections
   section_start "my_first_section" "Header of the 1st collapsible section"

   echo "this line should be hidden when collapsed"

   section_end "my_first_section"

   # Repeat as required
   ```

1. 스크립트를 `.gitlab-ci.yml` 파일에 추가합니다:

   ```yaml
   job:
     script:
       - source script.sh
   ```

### 기본적으로 섹션 축소 {#collapse-sections-by-default}

기본적으로 섹션을 축소하려면 `[collapsed=true]`을 섹션 시작 마커에 추가하고, 섹션 이름 뒤 및 `\r` 앞에 배치합니다:

- 섹션 시작 마커(포함 `[collapsed=true]`): `\e[0Ksection_start:UNIX_TIMESTAMP:SECTION_NAME[collapsed=true]\r\e[0K` + `TEXT_OF_SECTION_HEADER`
- 섹션 끝 마커(변경 없음): `\e[0Ksection_end:UNIX_TIMESTAMP:SECTION_NAME\r\e[0K`

업데이트된 섹션 시작 텍스트를 CI 구성에 추가합니다. 예를 들어 `echo`을 사용합니다:

```yaml
job1:
  script:
    - echo -e "\e[0Ksection_start:`date +%s`:my_first_section[collapsed=true]\r\e[0KHeader of the 1st collapsible section"
    - echo 'this line should be hidden automatically after loading the job log'
    - echo -e "\e[0Ksection_end:`date +%s`:my_first_section\r\e[0K"
```

## 작업 로그 삭제 {#delete-job-logs}

작업 로그를 삭제하면 [작업 전체를 지웁니다](../../api/jobs.md#erase-a-job).

자세한 내용은 [작업 로그 삭제](../../user/storage_management_automation.md#delete-job-logs)를 참조하세요.

## 타임스탬프 {#timestamps}

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `parse_ci_job_timestamps`이라는 이름의 [플래그와 함께](../../administration/feature_flags/_index.md) GitLab 17.1에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/455582). 기본적으로 비활성화되어 있습니다.
- 기능 플래그 `parse_ci_job_timestamps`이 GitLab 17.2에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/464785)되었습니다.
- GitLab 18.9에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/202293)합니다.

{{< /history >}}

기본적으로 작업 로그는 각 라인에 대해 [ISO 8601 형식](https://www.iso.org/iso-8601-date-and-time-format.html)의 타임스탬프를 포함합니다. 타임스탬프를 사용하여 성능 문제를 해결하고, 병목 지점을 식별하고, 특정 빌드 단계가 얼마나 오래 걸리는지 측정합니다.

타임스탬프가 활성화되면 작업 로그는 약 10% 더 많은 저장 공간을 사용합니다.

다음은 타임스탬프가 있는 작업 로그의 예입니다:

![각 라인의 UTC 타임스탬프가 있는 작업 로그](img/ci_log_timestamp_v17_6.png)

### 작업 로그의 타임스탬프 제어 {#control-timestamps-in-job-logs}

전제 조건:

- GitLab 러너 18.7 이상.

타임스탬프가 작업 로그에 나타나는지 제어하려면 `FF_TIMESTAMPS` CI/CD 변수를 사용합니다:

- `false`로 설정하여 타임스탬프를 비활성화합니다
- `true`로 설정하여 타임스탬프를 명시적으로 활성화합니다

예를 들어:

```yaml
variables:
  FF_TIMESTAMPS: false  # Disables timestamps

job:
  script:
    - echo "This job's log behavior depends on FF_TIMESTAMPS value"
```

자세한 내용은 [`.gitlab-ci.yml` 파일에서 CI/CD 변수 정의](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)를 참조하세요.

## 문제 해결 {#troubleshooting}

### 작업 로그 느리게 업데이트 {#job-log-slow-to-update}

실행 중인 작업에 대한 작업 로그 페이지를 방문할 때 로그 업데이트 전에 최대 60초의 지연이 있을 수 있습니다. 기본 새로 고침 시간은 60초이지만, 로그가 UI에서 한 번 표시된 후 로그 업데이트는 3초마다 발생해야 합니다.

### 오류: `This job does not have a trace` (GitLab 18.0 이상) {#error-this-job-does-not-have-a-trace-in-gitlab-180-or-later}

GitLab Self-Managed 인스턴스를 18.0 이상으로 업그레이드한 후 `This job does not have a trace` 오류가 표시될 수 있습니다. 이것은 다음 두 가지 모두가 있는 인스턴스에서 실패한 업그레이드 마이그레이션으로 인해 발생할 수 있습니다:

- 객체 저장소 활성화됨
- 제거된 기능 플래그 `ci_enable_live_trace`로 이전에 활성화된 증분 로깅입니다. 이 기능 플래그는 GitLab Environment Toolkit 또는 Helm Chart 배포에서 기본적으로 활성화되지만 수동으로도 활성화할 수 있습니다.

영향을 받는 작업 로그를 볼 수 있는 기능을 복구하려면 [증분 로깅 다시 활성화](../../administration/settings/continuous_integration.md#configure-incremental-logging)합니다

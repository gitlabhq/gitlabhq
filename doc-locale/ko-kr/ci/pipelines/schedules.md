---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 예약된 파이프라인
description: cron 패턴을 사용하여 CI/CD 파이프라인을 자동으로 실행하는 일정을 만들고 관리합니다.
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

파이프라인 일정을 만들어 cron 패턴을 기반으로 정기적인 간격으로 파이프라인을 실행합니다. 파이프라인 일정을 사용하여 코드 변경에 의해 트리거되지 않고 시간 기반 일정으로 실행해야 하는 작업에 사용합니다.

커밋 또는 머지 리퀘스트에 의해 트리거된 파이프라인과 달리, 예약된 파이프라인은 코드 변경과 독립적으로 실행됩니다. 이는 배포를 최신 상태로 유지하거나 정기적인 유지 보수를 실행하는 등 개발 활동과 관계없이 발생해야 하는 작업에 적합합니다.

예약된 파이프라인은 프로젝트 또는 그룹이 삭제로 표시되면 실행을 중지합니다.

## 파이프라인 일정 만들기 {#create-a-pipeline-schedule}

{{< history >}}

- 입력 옵션이 GitLab 17.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/525504)되었습니다.

{{< /history >}}

파이프라인 일정을 만들면 일정 소유자가 됩니다. 파이프라인은 사용자의 권한으로 실행되며 [보호 환경](../environments/protected_environments.md)에 액세스하고 액세스 수준에 따라 [CI/CD 작업 토큰](../jobs/ci_job_token.md)을 사용할 수 있습니다.

전제 조건:

- 프로젝트에 대한 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.
- 기본 이메일 주소를 확인해야 합니다.
- [보호된 브랜치](../../user/project/repository/branches/protected.md#protect-a-branch)를 대상으로 하는 일정의 경우 대상 브랜치에 병합 권한이 있어야 합니다.
- `.gitlab-ci.yml` 파일에 유효한 구문이 있어야 합니다. 일정을 예약하기 전에 [구성을 검증](../yaml/lint.md)할 수 있습니다.

파이프라인 일정을 만들려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인 일정**을 선택합니다.
1. **새 일정**을 선택합니다.
1. 필드를 완성하세요.
   - **간격 패턴**: 미리 구성된 간격 중 하나를 선택하거나 [cron 표기법](../../topics/cron/_index.md)으로 사용자 지정 간격을 입력합니다. 모든 cron 값을 사용할 수 있지만 예약된 파이프라인은 인스턴스의 [최대 예약된 파이프라인 빈도](../../administration/cicd/limits.md#maximum-scheduled-pipeline-frequency)보다 더 자주 실행할 수 없습니다.
   - **대상 브랜치 또는 태그**: 파이프라인의 브랜치 또는 태그를 선택합니다.
   - **입력**: 파이프라인의 `spec:inputs` 섹션에 정의된 [입력](../inputs/_index.md)의 값을 설정합니다. 이러한 입력 값은 예약된 파이프라인이 실행될 때마다 사용됩니다. 일정은 최대 20개의 입력을 포함할 수 있습니다.
   - **변수**: 일정에 [CI/CD 변수](../variables/_index.md)를 원하는 만큼 추가합니다. 이러한 변수는 예약된 파이프라인이 실행될 때만 사용 가능하며 다른 파이프라인 실행에서는 사용할 수 없습니다. 입력이 변수 대신 파이프라인 구성에 권장되는 이유는 향상된 보안과 유연성을 제공하기 때문입니다.

프로젝트가 [최대 파이프라인 일정 수](../../administration/cicd/limits.md#number-of-pipeline-schedules)에 도달한 경우 다른 일정을 추가하기 전에 사용하지 않는 일정을 삭제합니다.

## 파이프라인 일정 편집 {#edit-a-pipeline-schedule}

전제 조건:

- 일정 소유자이거나 일정의 소유권을 가져야 합니다.
- 프로젝트에 대한 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.
- [보호된 브랜치](../../user/project/repository/branches/protected.md#protect-a-branch)를 대상으로 하는 일정의 경우 대상 브랜치에 병합 권한이 있어야 합니다.
- [보호된 태그](../../user/project/protected_tags.md#configure-protected-tags)에서 실행되는 일정의 경우 보호된 태그를 만들 수 있어야 합니다.

파이프라인 일정을 편집하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인 일정**을 선택합니다.
1. 일정 옆에서 **편집**({{< icon name="pencil" >}})을 선택합니다.
1. 변경 사항을 적용한 후 **변경사항 저장**을 선택합니다.

## 수동으로 실행 {#run-manually}

예약된 파이프라인을 분당 한 번 수동으로 실행할 수 있습니다. 예약된 파이프라인을 수동으로 실행하면 일정 소유자의 권한 대신 사용자의 권한을 사용합니다.

다음으로 예약된 시간을 기다리지 않고 파이프라인 일정을 즉시 트리거하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인 일정**을 선택합니다.
1. 일정 옆에서 **실행**({{< icon name="play" >}})을 선택합니다.

## 소유권 가져 오기 {#take-ownership}

원래 소유자를 사용할 수 없어서 파이프라인 일정이 비활성화되면 소유권을 가져올 수 있습니다.

예약된 파이프라인은 일정을 소유한 사용자의 권한으로 실행됩니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.

일정의 소유권을 가져오려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인 일정**을 선택합니다.
1. 일정 옆에서 **소유권 가져 오기**를 선택합니다.

## 예약된 파이프라인 보기 {#view-your-scheduled-pipelines}

{{< history >}}

- GitLab 18.4에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/558979).

{{< /history >}}

모든 프로젝트에서 소유한 활성 파이프라인 일정을 보려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. **계정**을 선택합니다.
1. **당신이 소유한 예약된 파이프라인**으로 스크롤합니다.

## 관련 항목 {#related-topics}

- [CI/CD 파이프라인](_index.md)
- [예약된 파이프라인에 대한 작업 실행](../jobs/job_rules.md#run-jobs-for-scheduled-pipelines)
- [파이프라인 일정 API](../../api/pipeline_schedules.md)
- [파이프라인 효율](pipeline_efficiency.md#reduce-how-often-jobs-run)

## 문제 해결 {#troubleshooting}

파이프라인 일정으로 작업할 때 다음과 같은 이슈가 발생할 수 있습니다.

### 예약된 파이프라인이 비활성화됨 {#scheduled-pipeline-becomes-inactive}

예약된 파이프라인 상태가 예기치 않게 `Inactive`로 변경되면 일정 소유자가 차단되었거나 프로젝트에서 제거되었을 수 있습니다.

일정의 소유권을 가져와 다시 활성화합니다.

### 시스템 부하를 방지하기 위해 파이프라인 일정 배포 {#distribute-pipeline-schedules-to-prevent-system-load}

동시에 시작되는 너무 많은 파이프라인으로 인한 과도한 부하를 방지하려면 파이프라인 일정을 검토하고 배포합니다:

1. 이 명령을 실행하여 일정 데이터를 추출하고 형식화합니다:

   ```shell
   outfile=/tmp/gitlab_ci_schedules.tsv
   sudo gitlab-psql --command "
    COPY (SELECT
        ci_pipeline_schedules.cron,
        ci_pipeline_schedules.cron_timezone,
        namespaces.path AS group,
        projects.path   AS project,
        users.email
    FROM ci_pipeline_schedules
    JOIN projects ON projects.id = ci_pipeline_schedules.project_id
    JOIN namespaces ON namespaces.id = projects.namespace_id
    JOIN users    ON users.id    = ci_pipeline_schedules.owner_id
    WHERE ci_pipeline_schedules.active = 't'
    ) TO '$outfile' CSV HEADER DELIMITER E'\t' ;"
   sort  "$outfile" | uniq -c | sort -n
   ```

1. 출력을 검토하여 인기 있는 `cron` 패턴을 식별합니다. 예를 들어 많은 일정이 매시간 시작(`0 * * * *`)에 실행될 수 있습니다.
1. 특히 대규모 저장소의 경우 일정을 조정하여 계층화된 [`cron` 패턴](../../topics/cron/_index.md#cron-syntax)을 만듭니다. 예를 들어 매시간 시작에 실행되는 여러 일정 대신 시간 전체에 분산합니다(`5 * * * *`, `15 * * * *`, `25 * * * *`).

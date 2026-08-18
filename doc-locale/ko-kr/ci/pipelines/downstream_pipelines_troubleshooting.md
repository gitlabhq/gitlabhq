---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 다운스트림 파이프라인 문제 해결
---

## 트리거 작업이 실패하고 다중 프로젝트 파이프라인을 만들지 못함 {#trigger-job-fails-and-does-not-create-multi-project-pipeline}

다중 프로젝트 파이프라인에서 다음의 경우 트리거 작업이 실패하고 다운스트림 파이프라인을 만들지 못합니다:

- 다운스트림 프로젝트를 찾을 수 없습니다.
- 업스트림 파이프라인을 만드는 사용자가 다운스트림 프로젝트에서 파이프라인을 만들 수 있는 [권한](../../user/permissions.md)을 가지고 있지 않습니다.
- 다운스트림 파이프라인이 보호된 브랜치를 대상으로 하며 사용자가 보호된 브랜치에 대해 파이프라인을 실행할 수 있는 권한이 없습니다. 자세한 내용은 [보호된 브랜치에 대한 파이프라인 보안](_index.md#pipeline-security-on-protected-branches)을 참고하세요.

다운스트림 프로젝트에서 어떤 사용자가 권한 이슈를 겪고 있는지 확인하려면 [Rails 콘솔](../../administration/operations/rails_console.md)에서 다음 명령을 사용하여 트리거 작업을 확인하고 `user_id` 속성을 찾으세요.

```ruby
Ci::Bridge.find(<job_id>)
```

## 파이프라인이 실행될 때 자식 파이프라인에서 작업이 만들어지지 않음 {#job-in-child-pipeline-is-not-created-when-the-pipeline-runs}

상위 파이프라인이 [머지 리퀘스트 파이프라인](merge_request_pipelines.md)인 경우, 자식 파이프라인은 [`workflow:rules` 또는 `rules`을(를) 사용하여 작업이 실행되도록 해야 합니다](downstream_pipelines.md#run-child-pipelines-with-merge-request-pipelines).

자식 파이프라인의 작업이 누락되었거나 잘못된 `rules` 구성으로 인해 실행될 수 없는 경우:

- 자식 파이프라인이 시작에 실패합니다.
- 상위 파이프라인의 트리거 작업이 다음과 같이 실패합니다: `downstream pipeline can not be created, the resulting pipeline would have been empty. Review the`[`rules`](../yaml/_index.md#rules)`configuration for the relevant jobs.`

## `$` 문자가 다운스트림 파이프라인으로 제대로 전달되지 않음 {#variable-with--character-does-not-get-passed-to-a-downstream-pipeline-properly}

[다운스트림 파이프라인으로 CI/CD 변수를 전달할](downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline) 때 [`$$`를 사용하여 `$` 문자를 이스케이프할 수 없습니다.](../variables/job_scripts.md#use-the--character-in-cicd-variables) 다운스트림 파이프라인은 여전히 `$`을(를) 변수 참조의 시작으로 간주합니다.

UI에서 변수를 구성할 때 [CI/CD 변수 확장 방지](../variables/_index.md#allow-cicd-variable-expansion)하거나 [`variables:expand` 키워드](../yaml/_index.md#variablesexpand)를 사용하여 변수 값이 확장되지 않도록 설정할 수 있습니다. 이 변수를 다운스트림 파이프라인으로 전달할 수 있으며 `$`가 변수 참조로 해석되지 않습니다.

## `Ref is ambiguous` {#ref-is-ambiguous}

동일한 이름의 브랜치가 존재할 때 태그를 사용하여 다중 프로젝트 파이프라인을 트리거할 수 없습니다. 다운스트림 파이프라인이 다음 오류로 생성에 실패합니다: `downstream pipeline can not be created, Ref is ambiguous`.

브랜치 이름과 일치하지 않는 태그 이름으로만 다중 프로젝트 파이프라인을 트리거합니다.

## 트리거 작업이 `data integrity failure`로 실패 {#trigger-job-fails-with-data-integrity-failure}

이 오류는 작업 처리 중 예상치 못한 예외를 나타냅니다. 원인 및 해결 단계는 [오류: `data integrity failure`](../jobs/job_troubleshooting.md#error-data-integrity-failure)를 참고하세요.

## 업스트림 파이프라인에서 작업 아티팩트를 다운로드할 때 `403 Forbidden` 오류 {#403-forbidden-error-when-downloading-a-job-artifact-from-an-upstream-pipeline}

CI/CD 작업 토큰은 파이프라인이 실행되는 프로젝트로 범위가 지정됩니다. 따라서 다운스트림 파이프라인의 작업 토큰은 기본적으로 업스트림 프로젝트에 액세스하는 데 사용할 수 없습니다.

이를 해결하려면 [다운스트림 프로젝트를 작업 토큰 범위 허용 목록에 추가](../jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)합니다.

## 오류: `needs:need pipeline should be a string` {#error-needsneed-pipeline-should-be-a-string}

동적 자식 파이프라인에서 [`needs:pipeline:job`](../yaml/_index.md#needspipelinejob)를 사용할 때 다음 오류가 표시될 수 있습니다:

```plaintext
Unable to run pipeline
- jobs:<job_name>:needs:need pipeline should be a string
```

이 오류는 파이프라인 ID가 문자열 대신 정수로 파싱될 때 발생합니다. 이를 해결하려면 파이프라인 ID를 따옴표로 묶으세요:

```yaml
rspec:
  needs:
    - pipeline: "$UPSTREAM_PIPELINE_ID"
      job: dependency-job
      artifacts: true
```

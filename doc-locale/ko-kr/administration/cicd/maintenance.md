---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD 유지 보수 콘솔 명령
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

다음 명령은 [Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)에서 실행됩니다.

> [!warning]
> 데이터를 직접 변경하는 모든 명령은 올바르게 실행되지 않거나 적절한 조건에서 실행되지 않으면 손상될 수 있습니다. 테스트 환경에서 복원할 준비가 된 인스턴스 백업과 함께 실행하는 것을 강력히 권장합니다.

## 실행 중인 모든 파이프라인 및 해당 작업 취소 {#cancel-all-running-pipelines-and-their-jobs}

```ruby
admin = User.find(user_id) # replace user_id with the id of the admin you want to cancel the pipeline
# Iterate over each cancelable pipeline
Ci::Pipeline.cancelable.find_each do |pipeline|
  Ci::CancelPipelineService.new(
    pipeline: pipeline,
    current_user: user,
    cascade_to_children: false # the children are included in the outer loop
  )
end
```

## 중단된 대기 파이프라인 취소 {#cancel-stuck-pending-pipelines}

```ruby
project = Project.find_by_full_path('<project_path>')
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').count
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').each {|p| p.cancel if p.stuck?}
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').count
```

## 머지 리퀘스트 통합 시도 {#try-merge-request-integration}

```ruby
project = Project.find_by_full_path('<project_path>')
mr = project.merge_requests.find_by(iid: <merge_request_iid>)
mr.project.try(:ci_integration)
```

## `.gitlab-ci.yml` 파일 검증 {#validate-the-gitlab-ciyml-file}

```ruby
project = Project.find_by_full_path('<project_path>')
content = project.ci_config_for(project.repository.root_ref_sha)
Gitlab::Ci::Lint.new(project: project, current_user: User.first).validate(content)
```

## 기존 프로젝트에서 AutoDevOps 비활성화 {#disable-autodevops-on-existing-projects}

```ruby
Project.all.each do |p|
  p.auto_devops_attributes={"enabled"=>"0"}
  p.save
end
```

## 파이프라인 일정 수동 실행 {#run-pipeline-schedules-manually}

Rails 콘솔을 통해 파이프라인 일정을 수동으로 실행하여 일반적으로 표시되지 않는 오류를 찾을 수 있습니다.

```ruby
# schedule_id can be obtained from Edit Pipeline Schedule page
schedule = Ci::PipelineSchedule.find_by(id: <schedule_id>)

# Select the user that you want to run the schedule for
user = User.find_by_username('<username>')

# Run the schedule
ps = Ci::CreatePipelineService.new(schedule.project, user, ref: schedule.ref).execute!(:schedule, ignore_skip_ci: true, save_on_errors: false, schedule: schedule)
```

<!--- start_remove The following content will be removed on remove_date: '2027-08-15' -->

## 러너 등록 토큰 얻기(지원 중단됨) {#obtain-runners-registration-token-deprecated}

> [!warning]
> 러너 등록 토큰을 전달하는 옵션 및 특정 구성 인수 지원은 기존 기능으로 간주되며 권장되지 않습니다. [러너 생성 워크플로우](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)를 사용하여 러너를 등록하기 위한 인증 토큰을 생성합니다. 이 프로세스는 러너 소유권의 완전한 추적성을 제공하고 러너 플릿의 보안을 강화합니다. 자세한 내용은 [새로운 러너 등록 워크플로우로 마이그레이션](../../ci/runners/new_creation_workflow.md)을(를) 참조하세요.

전제 조건:

- 러너 등록 토큰은 [enabled](../settings/continuous_integration.md#control-runner-registration) 상태여야 하며 **운영자** 영역에서 설정됩니다.

```ruby
Gitlab::CurrentSettings.current_application_settings.runners_registration_token
```

## 시드 러너 등록 토큰(지원 중단됨) {#seed-runners-registration-token-deprecated}

> [!warning]
> 러너 등록 토큰을 전달하는 옵션 및 특정 구성 인수 지원은 기존 기능으로 간주되며 권장되지 않습니다. [러너 생성 워크플로우](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)를 사용하여 러너를 등록하기 위한 인증 토큰을 생성합니다. 이 프로세스는 러너 소유권의 완전한 추적성을 제공하고 러너 플릿의 보안을 강화합니다. 자세한 내용은 [새로운 러너 등록 워크플로우로 마이그레이션](../../ci/runners/new_creation_workflow.md)을(를) 참조하세요.

```ruby
appSetting = Gitlab::CurrentSettings.current_application_settings
appSetting.set_runners_registration_token('<new-runners-registration-token>')
appSetting.save!
```

<!--- end_remove -->

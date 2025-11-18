---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDメンテナンスコンソールコマンド
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

以下のコマンドは、[Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)で実行します。

{{< alert type="warning" >}}

データを直接変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。念のため、インスタンスのバックアップを復元できるように準備し、Test環境で実行することを強くお勧めします。

{{< /alert >}}

## 実行中のすべてのパイプラインとそのジョブをキャンセルします {#cancel-all-running-pipelines-and-their-jobs}

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

## 停止している保留中のパイプラインをキャンセル {#cancel-stuck-pending-pipelines}

```ruby
project = Project.find_by_full_path('<project_path>')
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').count
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').each {|p| p.cancel if p.stuck?}
Ci::Pipeline.where(project_id: project.id).where(status: 'pending').count
```

## マージリクエストインテグレーションを試す {#try-merge-request-integration}

```ruby
project = Project.find_by_full_path('<project_path>')
mr = project.merge_requests.find_by(iid: <merge_request_iid>)
mr.project.try(:ci_integration)
```

## `.gitlab-ci.yml`ファイルを検証します {#validate-the-gitlab-ciyml-file}

```ruby
project = Project.find_by_full_path('<project_path>')
content = project.ci_config_for(project.repository.root_ref_sha)
Gitlab::Ci::Lint.new(project: project, current_user: User.first).validate(content)
```

## 既存のプロジェクトでAutoDevOpsを無効にする {#disable-autodevops-on-existing-projects}

```ruby
Project.all.each do |p|
  p.auto_devops_attributes={"enabled"=>"0"}
  p.save
end
```

## パイプラインパイプラインスケジュールを手動で実行する {#run-pipeline-schedules-manually}

パイプラインスケジュールをRailsコンソールから手動で実行して、通常は表示されないエラーを表示できます。

```ruby
# schedule_id can be obtained from Edit Pipeline Schedule page
schedule = Ci::PipelineSchedule.find_by(id: <schedule_id>)

# Select the user that you want to run the schedule for
user = User.find_by_username('<username>')

# Run the schedule
ps = Ci::CreatePipelineService.new(schedule.project, user, ref: schedule.ref).execute!(:schedule, ignore_skip_ci: true, save_on_errors: false, schedule: schedule)
```

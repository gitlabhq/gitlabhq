##
# This is a debug script to reproduce specific scenarios for scheduled jobs (https://gitlab.com/gitlab-org/gitlab-ce/issues/51352)
# By using this script, you don't need to setup GitLab runner.
# This script is specifically made for FE/UX engineers. They can quickly check how scheduled jobs behave.
#
# *** THIS IS NOT TO BE MERGED ***
#
# ### How to use ###
#
# ### Prerequisite
# 1. Create a project (for example with path `incremental-rollout`)
# 1. Create a .gitlab-ci.yml with the following content
#
=begin
stages:
- build
- test
- production
- rollout 10%
- rollout 50%
- rollout 100%
- cleanup

build:
  stage: build
  script: sleep 1s

test:
  stage: test
  script: sleep 3s

rollout 10%:
  stage: rollout 10%
  script: date
  when: delayed
  start_in: 10 seconds
  allow_failure: false

rollout 50%:
  stage: rollout 50%
  script: date
  when: delayed
  start_in: 10 seconds
  allow_failure: false

rollout 100%:
  stage: rollout 100%
  script: date
  when: delayed
  start_in: 10 seconds
  allow_failure: false

cleanup:
  stage: cleanup
  script: date
=end
#
# ### How to load this script
#
# ```
# bundle exec rails console                    # Login to rails console
# require '/path/to/scheduled_job_fixture.rb'  # Load this script
# ```
#
# ### Reproduce the scenario ~ when all stages succeeded ~
#
# 1. ScheduledJobFixture.new(16, 1).create_pipeline('master')
# 1. ScheduledJobFixture.new(16, 1).finish_stage_until('test')
# 1. Wait until rollout 10% job is triggered
# 1. ScheduledJobFixture.new(16, 1).finish_stage_until('rollout 10%')
# 1. Wait until rollout 50% job is triggered
# 1. ScheduledJobFixture.new(16, 1).finish_stage_until('rollout 50%')
# 1. Wait until rollout 100% job is triggered
# 1. ScheduledJobFixture.new(16, 1).finish_stage_until('rollout 100%')
# 1. ScheduledJobFixture.new(16, 1).finish_stage_until('cleanup')
#
# Expectation: Users see a succeccful pipeline
#
# ### Reproduce the scenario ~ when rollout 10% jobs failed ~
#
# 1. ScheduledJobFixture.new(29, 1).create_pipeline('master')
# 1. ScheduledJobFixture.new(29, 1).finish_stage_until('test')
# 1. Wait until rollout 10% job is triggered
# 1. ScheduledJobFixture.new(29, 1).drop_jobs('rollout 10%')
#
# Expectation: Following stages should be skipped.
#
# ### Reproduce the scenario ~ when user clicked cancel button before build job finished ~
#
# 1. ScheduledJobFixture.new(29, 1).create_pipeline('master')
# 1. ScheduledJobFixture.new(29, 1).cancel_pipeline
#
# Expectation: All stages should be canceled.
#
# ### Reproduce the scenario ~ when user canceled the pipeline after rollout 10% job is scheduled ~
#
# 1. ScheduledJobFixture.new(29, 1).create_pipeline('master')
# 1. ScheduledJobFixture.new(29, 1).finish_stage_until('test')
# 1. Run next command before rollout 10% job is triggered
# 1. ScheduledJobFixture.new(29, 1).cancel_pipeline
#
# Expectation: rollout 10% job will be canceled. Following stages will be skipped.
#
# ### Reproduce the scenario ~ when user canceled rollout 10% job after rollout 10% job is scheduled ~
#
# 1. ScheduledJobFixture.new(29, 1).create_pipeline('master')
# 1. ScheduledJobFixture.new(29, 1).finish_stage_until('test')
# 1. Run next command before rollout 10% job is triggered
# 1. ScheduledJobFixture.new(29, 1).cancel_jobs('rollout 10%')
#
# Expectation: rollout 10% job will be canceled. Following stages will be skipped.
#
# ### Reproduce the scenario ~ when user played rollout 10% job immidiately ~
#
# 1. ScheduledJobFixture.new(29, 1).create_pipeline('master')
# 1. ScheduledJobFixture.new(29, 1).finish_stage_until('test')
# 1. Play rollout 10% job before rollout 10% job is triggered
#
# Expectation: rollout 10% becomes pending immidiately
#
# ### Reproduce the scenario ~ when rollout 10% job is allowed to fail ~
#
# 1. Set `allow_failure: true` to rollout 10% job
# 1. ScheduledJobFixture.new(29, 1).create_pipeline('master')
# 1. ScheduledJobFixture.new(29, 1).finish_stage_until('test')
# 1. Wait until rollout 10% job is triggered
# 1. ScheduledJobFixture.new(29, 1).drop_jobs('rollout 10%')
#
# Expectation: rollout 50% job should be triggered
#

class ScheduledJobFixture
  attr_reader :project
  attr_reader :user

  include GitlabRoutingHelper

  def initialize(project_id, user_id)
    @project = Project.find_by_id(project_id)
    @user = User.find_by_id(user_id)
  end

  def create_pipeline(ref)
    pipeline = Ci::CreatePipelineService.new(project, user, ref: ref).execute(:web)
    Rails.application.routes.url_helpers.namespace_project_pipeline_url(project.namespace, project, pipeline)
  end

  def finish_stage_until(stage_name)
    pipeline = Ci::Pipeline.last
    pipeline.stages.order(:id).each do |stage|
      stage.builds.map(&:success)
      stage.update_status
      pipeline.update_status

      return if stage.name == stage_name
    end
  end

  def run_jobs(stage_name)
    pipeline = Ci::Pipeline.last
    stage = pipeline.stages.find_by_name(stage_name)
    stage.builds.map(&:run)
    stage.update_status
    pipeline.update_status
  end

  def drop_jobs(stage_name)
    pipeline = Ci::Pipeline.last
    stage = pipeline.stages.find_by_name(stage_name)
    stage.builds.map(&:drop)
    stage.update_status
    pipeline.update_status
  end

  def cancel_jobs(stage_name)
    pipeline = Ci::Pipeline.last
    stage = pipeline.stages.find_by_name(stage_name)
    stage.builds.map(&:cancel)
    stage.update_status
    pipeline.update_status
  end

  def cancel_pipeline
    Ci::Pipeline.last.cancel_running
  end
end

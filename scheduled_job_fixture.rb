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
# 1. Create a project
# 1. Create a .gitlab-ci.yml with the following content
#
# ```
# stages:
# - build
# - test
# - production
# - rollout 10%
# - rollout 50%
# - rollout 100%
# - cleanup
# 
# build:
# stage: build
# script: sleep 1s
# 
# test:
# stage: test
# script: sleep 3s
# 
# rollout 10%:
# stage: rollout 10%
# script: date
# when: delayed
# start_in: 10 seconds
# allow_failure: false
# 
# rollout 50%:
# stage: rollout 50%
# script: date
# when: delayed
# start_in: 10 seconds
# allow_failure: false
# 
# rollout 100%:
# stage: rollout 100%
# script: date
# when: delayed
# start_in: 10 seconds
# allow_failure: false
# 
# cleanup:
# stage: cleanup
# script: date
# ```
#
# ### How to load this script
#
# ```
# bundle exec rails console                    # Login to rails console
# require '/path/to/scheduled_job_fixture.rb'  # Load this script
# ```
#
# ### Reproduce the scenario A) ~ Succeccfull timed incremantal rollout ~
#
# ````
# ScheduledJobFixture.new(29, 1).create_pipeline('master')
# ScheduledJobFixture.new(29, 1).finish_stage_until('test')  # Succeed 'build' and 'test' jobs. 'rollout 10%' job will be scheduled. See the pipeline page
# ScheduledJobFixture.new(29, 1).finish_stage_until('rollout 10%')  # Succeed `rollout 10%` job. 'rollout 50%' job will be scheduled.
# ScheduledJobFixture.new(29, 1).finish_stage_until('rollout 50%')  # Succeed `rollout 50%` job. 'rollout 100%' job will be scheduled.
# ScheduledJobFixture.new(29, 1).finish_stage_until('rollout 100%')  # Succeed `rollout 100%` job. 'cleanup' job will be scheduled.
# ScheduledJobFixture.new(29, 1).finish_stage_until('cleanup')  # Succeed `cleanup` job. The pipeline becomes green.
# ```
class ScheduledJobFixture
  attr_reader :project
  attr_reader :user

  def initialize(project_id, user_id)
    @project = Project.find_by_id(project_id)
    @user = User.find_by_id(user_id)
  end

  def create_pipeline(ref)
    Ci::CreatePipelineService.new(project, user, ref: ref).execute(:web)
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
end

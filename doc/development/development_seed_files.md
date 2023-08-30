---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Development seed files

Development seed files are listed under `gitlab/db/fixtures/development/` and `gitlab/ee/db/fixtures/development/`
folders. These files are used to populate the database with records to help verifying if feature functionalities, like charts, are working as expected on local host.

The task `rake db:seed_fu` can be used to run all development seeds with the exception of the ones under a flag which is usually passed as an environment variable.

The following table summarizes the seeds and tasks that can be used to generate
data for features.

| Feature                                                                                                           | Command                                                                                                           | Seed                                                                                                                                                |
|-------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| DevOps Adoption                                                                                                   | `FILTER=devops_adoption bundle exec rake db:seed_fu`                                                          | [31_devops_adoption.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/db/fixtures/development/31_devops_adoption.rb)                        |
| Value Streams Dashboard                                                                                           | `FILTER=cycle_analytics SEED_VSA=1 bundle exec rake db:seed_fu`                                               | [17_cycle_analytics.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/fixtures/development/17_cycle_analytics.rb)                           |
| Value Stream Analytics                                                                                            | `FILTER=customizable_cycle_analytics SEED_CUSTOMIZABLE_CYCLE_ANALYTICS=1 bundle exec rake db:seed_fu` | [30_customizable_cycle_analytics](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/db/fixtures/development/30_customizable_cycle_analytics.rb) |
| CI/CD analytics                                                                                                   | `FILTER=ci_cd_analytics SEED_CI_CD_ANALYTICS=1 bundle exec rake db:seed_fu`                                   | [38_ci_cd_analytics](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/fixtures/development/38_ci_cd_analytics.rb?ref_type=heads)               |
| Contributions Analytics<br><br>Productivity Analytics<br><br>Code review Analytics<br><br>Merge Request Analytics | `FILTER=productivity_analytics SEED_PRODUCTIVITY_ANALYTICS=1 bundle exec rake db:seed_fu`             | [90_productivity_analytics](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/db/fixtures/development/90_productivity_analytics.rb)             |
| Repository Analytics                                                                                              | `FILTER=14_pipelines NEW_PROJECT=1 bundle exec rake db:seed_fu`                                       | [14_pipelines](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/fixtures/development/14_pipelines.rb?ref_type=heads)                           |
| Issue Analytics<br><br>Insights                                                                                   | `NEW_PROJECT=1 bin/rake gitlab:seed:insights:issues`                                                          | [insights Rake task](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/seed/insights.rake)                                     |
| DORA metrics                                                                                                      | `SEED_DORA=1 FILTER=dora_metrics bundle exec rake db:seed_fu`                                                 | [92_dora_metrics](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/db/fixtures/development/92_dora_metrics.rb)                                 |

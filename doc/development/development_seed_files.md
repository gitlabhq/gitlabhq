---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Development seed files
---

Development seed files are listed under `gitlab/db/fixtures/development/` and `gitlab/ee/db/fixtures/development/`
folders. These files are used to populate the database with records to help verifying if feature functionalities, like charts, are working as expected on local host.

The task `rake db:seed_fu` can be used to run all development seeds with the exception of the ones under a flag which is usually passed as an environment variable.

The following table summarizes the seeds and tasks that can be used to generate
data for features.

| Feature                                                                                                           | Command                                                                                                       | Seed                                                                                                                                                |
|-------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| DevOps Adoption                                                                                                   | `FILTER=devops_adoption bundle exec rake db:seed_fu`                                                          | [31_devops_adoption.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/db/fixtures/development/31_devops_adoption.rb)                        |
| Value Streams Dashboard                                                                                           | `FILTER=cycle_analytics SEED_VSA=1 bundle exec rake db:seed_fu`                                               | [17_cycle_analytics.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/fixtures/development/17_cycle_analytics.rb)                           |
| Value Streams Dashboard overview counts                                                                           | `FILTER=vsd_overview_counts SEED_VSD_COUNTS=1 bundle exec rake db:seed_fu`                                    | [93_vsd_overview_counts.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/db/fixtures/development/93_vsd_overview_counts.rb)                |
| Value Stream Analytics                                                                                            | `FILTER=customizable_cycle_analytics SEED_CUSTOMIZABLE_CYCLE_ANALYTICS=1 bundle exec rake db:seed_fu`         | [30_customizable_cycle_analytics](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/db/fixtures/development/30_customizable_cycle_analytics.rb) |
| CI/CD analytics                                                                                                   | `FILTER=ci_cd_analytics SEED_CI_CD_ANALYTICS=1 bundle exec rake db:seed_fu`                                   | [38_ci_cd_analytics](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/fixtures/development/38_ci_cd_analytics.rb?ref_type=heads)               |
| Contributions Analytics<br><br>Productivity Analytics<br><br>Code review Analytics<br><br>Merge Request Analytics | `FILTER=productivity_analytics SEED_PRODUCTIVITY_ANALYTICS=1 bundle exec rake db:seed_fu`                     | [90_productivity_analytics](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/db/fixtures/development/90_productivity_analytics.rb)             |
| Repository Analytics                                                                                              | `FILTER=14_pipelines NEW_PROJECT=1 bundle exec rake db:seed_fu`                                               | [14_pipelines](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/fixtures/development/14_pipelines.rb?ref_type=heads)                           |
| Issue Analytics<br><br>Insights                                                                                   | `NEW_PROJECT=1 bin/rake gitlab:seed:insights:issues`                                                          | [insights Rake task](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/seed/insights.rake)                                     |
| DORA metrics                                                                                                      | `SEED_DORA=1 FILTER=dora_metrics bundle exec rake db:seed_fu`                                                 | [92_dora_metrics](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/db/fixtures/development/92_dora_metrics.rb)                                 |
| Code Suggestion data in ClickHouse                                                                                | `FILTER=ai_usage_stats bundle exec rake db:seed_fu`                                                           | [94_ai_usage_stats](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/db/fixtures/development/94_ai_usage_stats.rb)                             |
| GitLab Duo                                                                                                        | `SEED_GITLAB_DUO=1 FILTER=gitlab_duo bundle exec rake db:seed_fu`                                                               | [95_gitlab_duo](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/db/fixtures/development/95_gitlab_duo.rb)                             |
| GitLab Duo: Seed failed CI jobs for Root Cause Analysis (`/troubleshoot`) evaluation                                                                                                  | `LANGCHAIN_API_KEY=$Key bundle exec rake gitlab:duo_chat:seed:failed_ci_jobs`                                                          | [seed_failed_ci_jobs](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/duo_chat/seed_failed_ci_jobs.rake)                        |
| Pipeline metrics                                                                                                  | `FILTER=pipeline_metrics SEED_PIPELINE_METRICS=1 bundle exec rake db:seed_fu`                                 | [98_pipeline_metrics.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/db/fixtures/development/98_pipeline_metrics.rb)                      |

## Seed project and group resources for GitLab Duo

The [`gitlab:duo:setup` setup script](ai_features/_index.md#run-gitlabduosetup-task) executes the development seed file for GitLab Duo project and group resources. In self-managed mode, the task is idempotent and skips reseeding if the `gitlab-duo` group already exists. To force reseeding from the setup task, set `GITLAB_DUO_RESEED=1`.

To run the seed directly (outside the setup task) and recreate all resources:

```shell
SEED_GITLAB_DUO=1 FILTER=gitlab_duo bundle exec rake db:seed_fu
```

### Configurable paths

By default, the seeder creates a group at `gitlab-duo` with a project at `gitlab-duo/test`, cloned from the
[test-repo](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/test-repo).
You can override these defaults with the following environment variables:

| Environment variable | Default | Description |
|---|---|---|
| `GITLAB_DUO_GROUP_PATH` | `gitlab-duo` | Path of the group to create. |
| `GITLAB_DUO_PROJECT_PATH` | `test` | Path of the project to create inside the group. |
| `GITLAB_DUO_PROJECT_CLONE_URL` | `https://gitlab.com/.../test-repo.git` | Git URL to clone as the project repository. |

For example, to seed into a custom group and project:

```shell
GITLAB_DUO_GROUP_PATH=my-duo-group GITLAB_DUO_PROJECT_PATH=my-project \
  SEED_GITLAB_DUO=1 FILTER=gitlab_duo bundle exec rake db:seed_fu
```

The same environment variables are respected by the `gitlab:duo:setup` Rake task.

### Fixed IDs and evaluation framework compatibility

GitLab Duo group and project resources are also used by the [Central Evaluation Framework](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library) for automated GitLab Duo evaluation.
Some evaluation datasets refer to group or project resources (for instance, `Summarize issue #123` requires a corresponding issue record in PostgreSQL).

Currently, this development seed file and evaluation datasets are managed separately.
To ensure that the integration keeps working, this seeder has to create the **same** group/project resources every time.
For example, ID and IID of the inserted PostgreSQL records must be the same every time we run this seeding process.

When using the **default** group and project paths (`gitlab-duo/test`), the seeder assigns a fixed base ID of `1_000_000`
to all seeded records (group, project, epic, issue, merge request, and so on). This guarantees deterministic IDs that
the evaluation datasets depend on.

When you provide **custom** paths through the environment variables above, fixed IDs are **not** applied and
PostgreSQL assigns IDs automatically.

> [!note]
> Custom-path seeds are fully functional for interactive use of GitLab Duo features
> (Duo Chat, code suggestions, and so on). The only limitation is that the
> [Central Evaluation Framework](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library)
> datasets expect the fixed IDs created by the default paths. If you need to run
> automated evaluations, use the default `gitlab-duo/test` paths.

These fixtures are depended by the following projects:

- [Central Evaluation Framework](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/prompt-library)
- [Evaluation Runner](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner)

See [this architecture doc](https://gitlab.com/gitlab-org/modelops/ai-model-validation-and-research/ai-evaluation/evaluation-runner/-/blob/main/docs/architecture.md) for more information.

---
stage: Create
group: Incubation
info: Machine Learning Experiment Tracking is a GitLab Incubation Engineering program. No technical writer assigned to this group.
---

# MLflow client compatibility **(FREE ALL)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8560) in GitLab 15.11 as an [Experiment](../../../../policy/experiment-beta-support.md#experiment) release [with a flag](../../../../administration/feature_flags.md) named `ml_experiment_tracking`. Disabled by default.

NOTE:
Model experiment tracking is an [experimental feature](../../../../policy/experiment-beta-support.md).
Refer to <https://gitlab.com/gitlab-org/gitlab/-/issues/381660> for feedback and feature requests.

[MLflow](https://mlflow.org/) is a popular open source tool for Machine Learning Experiment Tracking.
GitLab [Model experiment tracking](index.md) is compatible with MLflow Client,
[logging experiments](index.md). The setup requires minimal changes to existing code.

GitLab plays the role of a MLflow server. Running `mlflow server` is not necessary.

## Enable MLflow client integration

Prerequisites:

- A [personal](../../../../user/profile/personal_access_tokens.md), [project](../../../../user/project/settings/project_access_tokens.md), or [group](../../../../user/group/settings/group_access_tokens.md) access token with at least the Developer role and the `api` permission.
- The project ID. To find the project ID:
  1. On the left sidebar, select **Search or go to** and find your project.
  1. Select **Settings > General**.

To use MLflow client compatibility from a local environment:

1. Set the tracking URI and token environment variables on the host that runs the code.
   This can be your local environment, CI pipeline, or remote host. For example:

   ```shell
   export MLFLOW_TRACKING_URI="<your gitlab endpoint>/api/v4/projects/<your project id>/ml/mlflow"
   export MLFLOW_TRACKING_TOKEN="<your_access_token>"
   ```

1. If your training code contains the call to `mlflow.set_tracking_uri()`, remove it.

When running the training code, MLflow creates experiments, runs, log parameters, metrics, metadata
and artifacts on GitLab.

After experiments are logged, they are listed under `/<your project>/-/ml/experiments`.
Runs are registered as:

- Model Candidates, which can be explored by selecting an experiment.
- Tags, which are registered as metadata.

## Associating a candidate to a CI/CD job

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119454) in GitLab 16.1.

If your training code is being run from a CI/CD job, GitLab can use that information to enhance
candidate metadata. To associate a candidate to a CI/CD job:

1. In the [Project CI variables](../../../../ci/variables/index.md), include the following variables:
    - `MLFLOW_TRACKING_URI`: `"<your gitlab endpoint>/api/v4/projects/<your project id>/ml/mlflow"`
    - `MLFLOW_TRACKING_TOKEN`: `<your_access_token>`

1. In your training code within the run execution context, add the following code snippet:

    ```python
    with mlflow.start_run(run_name=f"Candidate {index}"):
      # Your training code

      # Start of snippet to be included
      if os.getenv('GITLAB_CI'):
        mlflow.set_tag('gitlab.CI_JOB_ID', os.getenv('CI_JOB_ID'))
      # End of snippet to be included
    ```

## Supported MLflow client methods and caveats

GitLab supports these methods from the MLflow client. Other methods might be supported but were not
tested. More information can be found in the [MLflow Documentation](https://www.mlflow.org/docs/1.28.0/python_api/mlflow.html).

| Method                   | Supported        | Version Added  | Comments                                                                            |
|--------------------------|------------------|----------------|-------------------------------------------------------------------------------------|
| `get_experiment`         | Yes              | 15.11          |                                                                                     |
| `get_experiment_by_name` | Yes              | 15.11          |                                                                                     |
| `set_experiment`         | Yes              | 15.11          |                                                                                     |
| `get_run`                | Yes              | 15.11          |                                                                                     |
| `start_run`              | Yes              | 15.11          | (16.3) If a name is not provided, the candidate receives a random nickname.         |
| `log_artifact`           | Yes with caveat  | 15.11          | (15.11) `artifact_path` must be empty. Does not support directories.                |
| `log_artifacts`          | Yes with caveat  | 15.11          | (15.11) `artifact_path` must be empty. Does not support directories.                |
| `log_batch`              | Yes              | 15.11          |                                                                                     |
| `log_metric`             | Yes              | 15.11          |                                                                                     |
| `log_metrics`            | Yes              | 15.11          |                                                                                     |
| `log_param`              | Yes              | 15.11          |                                                                                     |
| `log_params`             | Yes              | 15.11          |                                                                                     |
| `log_figure`             | Yes              | 15.11          |                                                                                     |
| `log_image`              | Yes              | 15.11          |                                                                                     |
| `log_text`               | Yes with caveat  | 15.11          | (15.11) Does not support directories.                                               |
| `log_dict`               | Yes with caveat  | 15.11          | (15.11) Does not support directories.                                               |
| `set_tag`                | Yes              | 15.11          |                                                                                     |
| `set_tags`               | Yes              | 15.11          |                                                                                     |
| `set_terminated`         | Yes              | 15.11          |                                                                                     |
| `end_run`                | Yes              | 15.11          |                                                                                     |
| `update_run`             | Yes              | 15.11          |                                                                                     |
| `log_model`              | Partial          | 15.11          | (15.11) Saves the artifacts, but not the model data. `artifact_path` must be empty. |

## Limitations

- The API GitLab supports is the one defined at MLflow version 1.28.0.
- API endpoints not listed above are not supported.
- During creation of experiments and runs, ExperimentTags are stored, even though they are not displayed.
- MLflow Model Registry is not supported.

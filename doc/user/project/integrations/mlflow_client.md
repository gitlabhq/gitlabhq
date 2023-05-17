---
stage: Create
group: Incubation
info: Machine Learning Experiment Tracking is a GitLab Incubation Engineering program. No technical writer assigned to this group.
---

# MLflow client integration **(FREE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8560) in GitLab 15.11 as an [Experiment](../../../policy/alpha-beta-support.md#experiment) release [with a flag](../../../administration/feature_flags.md) named `ml_experiment_tracking`. Disabled by default.

NOTE:
Model experiment tracking is an [experimental feature](../../../policy/alpha-beta-support.md).
Refer to <https://gitlab.com/gitlab-org/gitlab/-/issues/381660> for feedback and feature requests.

[MLflow](https://mlflow.org/) is a popular open source tool for Machine Learning Experiment Tracking.
GitLab works as a backend to the MLflow Client, [logging experiments](../ml/experiment_tracking/index.md).
Setting up your integrations requires minimal changes to existing code.

GitLab plays the role of a MLflow server. Running `mlflow server` is not necessary.

## Enable MLflow client integration

Prerequisites:

- A [personal access token](../../../user/profile/personal_access_tokens.md) for the project, with minimum access level of `api`.
- The project ID. To find the project ID, on the top bar, select **Main menu > Projects** and find your project. On the left sidebar, select **Settings > General**.

To enable MLflow client integration:

1. Set the tracking URI and token environment variables on the host that runs the code.
   This can be your local environment, CI pipeline, or remote host. For example:

   ```shell
   export MLFLOW_TRACKING_URI="http://<your gitlab endpoint>/api/v4/projects/<your project id>/ml/mlflow"
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
candidate metadata. To do so, add the following snippet to your training code within the run
execution context:

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

| Method                   | Supported        | Version Added  | Comments |
|--------------------------|------------------|----------------|----------|
| `get_experiment`         | Yes              | 15.11          |   |
| `get_experiment_by_name` | Yes              | 15.11          |   |
| `set_experiment`         | Yes              | 15.11          |   |
| `get_run`                | Yes              | 15.11          |   |
| `start_run`              | Yes              | 15.11          |   |
| `log_artifact`           | Yes with caveat  | 15.11          | (15.11) `artifact_path` must be empty string. Does not support directories.
| `log_artifacts`          | Yes with caveat  | 15.11          | (15.11) `artifact_path` must be empty string. Does not support directories.
| `log_batch`              | Yes              | 15.11          |   |
| `log_metric`             | Yes              | 15.11          |   |
| `log_metrics`            | Yes              | 15.11          |   |
| `log_param`              | Yes              | 15.11          |   |
| `log_params`             | Yes              | 15.11          |   |
| `log_figure`             | Yes              | 15.11          |   |
| `log_image`              | Yes              | 15.11          |   |
| `log_text`               | Yes with caveat  | 15.11          | (15.11) Does not support directories.
| `log_dict`               | Yes with caveat  | 15.11          | (15.11) Does not support directories.
| `set_tag`                | Yes              | 15.11          |   |
| `set_tags`               | Yes              | 15.11          |   |
| `set_terminated`         | Yes              | 15.11          |   |
| `end_run`                | Yes              | 15.11          |   |
| `update_run`             | Yes              | 15.11          |   |
| `log_model`              | Partial          | 15.11          | (15.11) Saves the artifacts, but not the model data. `artifact_path` must be empty.

## Limitations

- The API GitLab supports is the one defined at MLflow version 1.28.0.
- API endpoints not listed above are not supported.
- During creation of experiments and runs, ExperimentTags are stored, even though they are not displayed.
- MLflow Model Registry is not supported.

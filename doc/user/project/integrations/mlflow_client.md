---
stage: Create
group: Incubation
info: Machine Learning Experiment Tracking is a GitLab Incubation Engineering program. No technical writer assigned to this group.
---

# MLFlow client integration **(FREE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8560) in GitLab 15.11 as an [Experiment](../../../policy/alpha-beta-support.md#experiment) release [with a flag](../../../administration/feature_flags.md) named `ml_experiment_tracking`. Disabled by default.

NOTE:
Model experiment tracking is an [experimental feature](../../../policy/alpha-beta-support.md).
Refer to <https://gitlab.com/gitlab-org/gitlab/-/issues/381660> for feedback and feature requests.

[MLFlow](https://mlflow.org/) is one of the most popular open source tools for Machine Learning Experiment Tracking.
GitLab works as a backend to the MLFlow Client, [logging experiments](../ml/experiment_tracking/index.md).
Setting up your integrations requires minimal changes to existing code.

GitLab plays the role of proxy server, both for artifact storage and tracking data. It reflects the
MLFlow [Scenario 5](https://www.mlflow.org/docs/latest/tracking.html#scenario-5-mlflow-tracking-server-enabled-with-proxied-artifact-storage-access).

## Enable MLFlow client integration

Prerequisites:

- A [personal access token](../../../user/profile/personal_access_tokens.md) for the project, with minimum access level of `api`.
- The project ID. To find the project ID, on the top bar, select **Main menu > Projects** and find your project. On the left sidebar, select **Settings > General**.

To enable MLFlow client integration:

1. Set the tracking URI and token environment variables on the host that runs the code.
   This can be your local environment, CI pipeline, or remote host. For example:

   ```shell
   export MLFLOW_TRACKING_URI="http://<your gitlab endpoint>/api/v4/projects/<your project id>/ml/mlflow"
   export MLFLOW_TRACKING_TOKEN="<your_access_token>"
   ```

1. If your training code contains the call to `mlflow.set_tracking_uri()`, remove it.

When running the training code, MLFlow creates experiments, runs, log parameters, metrics, metadata
and artifacts on GitLab.

After experiments are logged, they are listed under `/<your project>/-/ml/experiments`.
Runs are registered as:

- Model Candidates, which can be explored by selecting an experiment.
- Tags, which are registered as metadata.

## Supported MlFlow client methods and caveats

GitLab supports these methods from the MLFlow client. Other methods might be supported but were not
tested. More information can be found in the [MLFlow Documentation](https://www.mlflow.org/docs/1.28.0/python_api/mlflow.html).

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

- The API GitLab supports is the one defined at MLFlow version 1.28.0.
- API endpoints not listed above are not supported.
- During creation of experiments and runs, ExperimentTags are stored, even though they are not displayed.
- MLFlow Model Registry is not supported.

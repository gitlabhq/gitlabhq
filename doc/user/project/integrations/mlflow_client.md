---
stage: Create
group: Incubation
info: Machine Learning Experiment Tracking is a GitLab Incubation Engineering program. No technical writer assigned to this group.
---

# MLFlow Client Integration **(FREE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8560) in GitLab 15.6 as an [Alpha](../../../policy/alpha-beta-support.md#alpha-features) release [with a flag](../../../administration/feature_flags.md) named `ml_experiment_tracking`. Disabled by default.

DISCLAIMER:
MLFlow Client Integration is an experimental feature being developed by the Incubation Engineering Department,
and will receive significant changes over time.

[MLFlow](https://mlflow.org/) is one of the most popular open source tools for Machine Learning Experiment Tracking.
GitLabs works as a backend to the MLFlow Client, [logging experiments](../ml/experiment_tracking/index.md).
Setting up your integrations requires minimal changes to existing code.

GitLab plays the role of proxy server, both for artifact storage and tracking data. It reflects the
MLFlow [Scenario 5](https://www.mlflow.org/docs/latest/tracking.html#scenario-5-mlflow-tracking-server-enabled-with-proxied-artifact-storage-access).

## Enable MFlow Client Integration

Complete this task to enable MFlow Client Integration.

Prerequisites:

- A [personal access token](../../../user/profile/personal_access_tokens.md) for the project, with minimum access level of `api`.
- The project ID. To find the project ID, on the top bar, select **Main menu > Projects** and find your project. On the left sidebar, select **Settings > General**.

1. Set the tracking URI and token environment variables on the host that runs the code (your local environment, CI pipeline, or remote host).

   For example:

   ```shell
   export MLFLOW_TRACKING_URI="http://<your gitlab endpoint>/api/v4/projects/<your project id>/ml/mlflow"
   export MLFLOW_TRACKING_TOKEN="<your_access_token>"
   ```

1. If your training code contains the call to `mlflow.set_tracking_uri()`, remove it.

When running the training code, MLFlow will create experiments, runs, log parameters, metrics,
and artifacts on GitLab.

After experiments are logged, they are listed under `/<your project>/-/ml/experiments`. Runs are registered as Model Candidates,
that can be explored by selecting an experiment.

## Limitations

- The API GitLab supports is the one defined at MLFlow version 1.28.0.
- API endpoints not listed above are not supported.
- During creation of experiments and runs, tags are ExperimentTags and RunTags are ignored.
- MLFLow Model Registry is not supported.

## Supported methods and caveats

This is a list of methods we support from the MLFlow client. Other methods might be supported but were not
tested. More information can be found in the [MLFlow Documentation](https://www.mlflow.org/docs/1.28.0/python_api/mlflow.html).

### `set_experiment`

Accepts both experiment_name and experiment_id

### `start_run()`

- Nested runs have not been tested.
- `run_name` is not supported

### `log_param()`, `log_params()`, `log_metric()`, `log_metrics()`

Work as defined by the documentation

### `log_artifact()`, `log_artifacts()`

`artifact_path` must be empty string.

### `log_model()`

This is an experimental method in MLFlow, and partial support is offered. It stores the model artifacts, but does
not log the model information. The `artifact_path` parameter must be set to `''`, because Generic Packages do not support folder
structure.

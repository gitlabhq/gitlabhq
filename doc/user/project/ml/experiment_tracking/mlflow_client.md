---
stage: ModelOps
group: MLOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: MLflow client compatibility
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/8560) in GitLab 15.11.
> - [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/9341) in GitLab 17.8.

[MLflow](https://mlflow.org/) is a popular open source tool for Machine Learning experiment tracking.
GitLab [Model experiment tracking](_index.md) and GitLab
[Model registry](../model_registry/_index.md) are compatible with the MLflow client. The setup requires minimal changes to existing code.

GitLab plays the role of a MLflow server. Running `mlflow server` is not necessary.

## Enable MLflow client integration

Prerequisites:

- A [personal](../../../profile/personal_access_tokens.md), [project](../../settings/project_access_tokens.md), or [group](../../../group/settings/group_access_tokens.md) access token with at least the Developer role and the `api` scope.
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

1. If the training code contains the call to `mlflow.set_tracking_uri()`, remove it.

In the model registry, you can copy the tracking URI from the overflow menu in the top right
by selecting the vertical ellipsis (**{ellipsis_v}**).

## Model experiments

When running the training code, MLflow client can be used to create experiments, runs,
models, model versions, log parameters, metrics, metadata, and artifacts on GitLab.

After experiments are logged, they are listed under `/<your project>/-/ml/experiments`.

Runs are registered and can be explored by selecting an experiment, model, or model version.

### Creating an experiment

```python
import mlflow

# Create a new experiment
experiment_id = mlflow.create_experiment(name="<your_experiment>")

# Setting the active experiment also creates a new experiment if it doesn't exist.
mlflow.set_experiment(experiment_name="<your_experiment>")
```

### Creating a run

```python
import mlflow

# Creating a run requires an experiment ID or an active experiment
mlflow.set_experiment(experiment_name="<your_experiment>")

# Runs can be created with or without a context manager
with mlflow.start_run() as run:
    print(run.info.run_id)
    # Your training code

with mlflow.start_run():
    # Your training code
```

### Logging parameters and metrics

```python
import mlflow

mlflow.set_experiment(experiment_name="<your_experiment>")

with mlflow.start_run():
    # Parameter keys need to be unique in the scope of the run
    mlflow.log_param(key="param_1", value=1)

    # Metrics can be updated throughout the run
    mlflow.log_metric(key="metrics_1", value=1)
    mlflow.log_metric(key="metrics_1", value=2)
```

### Logging artifacts

```python
import mlflow

mlflow.set_experiment(experiment_name="<your_experiment>")

with mlflow.start_run():
    # Plaintext text files can be logged as artifacts using `log_text`
    mlflow.log_text('Hello, World!', artifact_file='hello.txt')

    mlflow.log_artifact(
        local_path='<local/path/to/file.txt>',
        artifact_path='<optional relative path to log the artifact at>'
    )
```

### Logging models

Models can be logged using one of the supported [MLflow Model flavors](https://mlflow.org/docs/latest/models.html#built-in-model-flavors).
Logging with a model flavor records the metadata, making it easier to manage, load, and deploy models across different tools and environments.

```python
import mlflow
from sklearn.ensemble import RandomForestClassifier

mlflow.set_experiment(experiment_name="<your_experiment>")

with mlflow.start_run():
    # Create and train a simple model
    model = RandomForestClassifier(n_estimators=10, random_state=42)
    model.fit(X_train, y_train)

    # Log the model using MLflow sklearn mode flavour
    mlflow.sklearn.log_model(model, artifact_path="model")
```

### Associating a run to a CI/CD job

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119454) in GitLab 16.1.
> - [Changed](https://gitlab.com/groups/gitlab-org/-/epics/9423) to beta in GitLab 17.1.

If your training code is being run from a CI/CD job, GitLab can use that information to enhance
run metadata. To associate a run to a CI/CD job:

1. In the [Project CI variables](../../../../ci/variables/_index.md), include the following variables:
   - `MLFLOW_TRACKING_URI`: `"<your gitlab endpoint>/api/v4/projects/<your project id>/ml/mlflow"`
   - `MLFLOW_TRACKING_TOKEN`: `<your_access_token>`

1. In your training code within the run execution context, add the following code snippet:

   ```python
   import os
   import mlflow

   with mlflow.start_run(run_name=f"Run {index}"):
     # Your training code

     # Start of snippet to be included
     if os.getenv('GITLAB_CI'):
       mlflow.set_tag('gitlab.CI_JOB_ID', os.getenv('CI_JOB_ID'))
     # End of snippet to be included
   ```

## Model registry

You can also manage models and model versions by using the MLflow
client. Models are registered under `/<your project>/-/ml/models`.

### Models

#### Creating a model

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
description = 'Model description'
model = client.create_registered_model(model_name, description=description)
```

**Notes**

- `create_registered_model` argument `tags` is ignored.
- `name` must be unique within the project.
- `name` cannot be the name of an existing experiment.

#### Fetching a model

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
model = client.get_registered_model(model_name)
```

#### Updating a model

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
description = 'New description'
client.update_registered_model(model_name, description=description)
```

#### Deleting a model

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
client.delete_registered_model(model_name)
```

### Logging runs to a model

Every model has an associated experiment with the same name prefixed by `[model]`.
To log a run to the model, use the experiment passing the correct name:

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
exp = client.get_experiment_by_name(f"[model]{model_name}")
run = client.create_run(exp.experiment_id)
```

### Model version

#### Creating a model version

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
description = 'Model version description'
model_version = client.create_model_version(model_name, source="", description=description)
```

If the version parameter is not passed, it will be auto-incremented from the latest uploaded
version. You can set the version by passing a tag during model version creation. The version
must follow [SemVer](https://semver.org/) format.

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
version = '<your_version>'
tags = { "gitlab.version": version }
client.create_model_version(model_name, version, description=description, tags=tags)
```

**Notes**

- Argument `run_id` is ignored. Every model version behaves as a run. Creating a mode version from a run is not yet supported.
- Argument `source` is ignored. GitLab will create a package location for the model version files.
- Argument `run_link` is ignored.
- Argument `await_creation_for` is ignored.

#### Updating a model

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
version = '<your_version>'
description = 'New description'
client.update_model_version(model_name, version, description=description)
```

#### Fetching a model version

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
version = '<your_version>'
client.get_model_version(model_name, version)
```

#### Getting latest versions of a model

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
client.get_latest_versions(model_name)
```

**Notes**

- Argument `stages` is ignored.
- Versions are ordered by highest semantic version.

#### Loading a model version

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
version = '<your_version'  # e.g. '1.0.0'

# Alternatively search the version
version = mlflow.search_registered_models(filter_string="name='{model_name}'")[0].latest_versions[0].version

model = mlflow.pyfunc.load_model(f"models:/{model_name}/{latest_version}")

# Or load the latest version
model = mlflow.pyfunc.load_model(f"models:/{model_name}/latest")
```

#### Logging metrics and parameters to a model version

Every model version is also a run, allowing users to log parameters
and metrics. The run ID can either be found at the Model version page in GitLab,
or by using the MLflow client:

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
version = '<your_version>'
model_version = client.get_model_version(model_name, version)
run_id = model_version.run_id

# Your training code

client.log_metric(run_id, '<metric_name>', '<metric_value>')
client.log_param(run_id, '<param_name>', '<param_value>')
client.log_batch(run_id, metric_list, param_list, tag_list)
```

#### Logging artifacts to a model version

GitLab creates a package that can be used by the MLflow client to upload files.

```python
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
version = '<your_version>'
model_version = client.get_model_version(model_name, version)
run_id = model_version.run_id

# Your training code

client.log_artifact(run_id, '<local/path/to/file.txt>', artifact_path="")
client.log_figure(run_id, figure, artifact_file="my_plot.png")
client.log_dict(run_id, my_dict, artifact_file="my_dict.json")
client.log_image(run_id, image, artifact_file="image.png")
```

Artifacts will then be available under `https/<your project>/-/ml/models/<model_id>/versions/<version_id>`.

#### Linking a model version to a CI/CD job

Similar to runs, it is also possible to link a model version to a CI/CD job:

```python
import os
from mlflow import MlflowClient

client = MlflowClient()
model_name = '<your_model_name>'
version = '<your_version>'
model_version = client.get_model_version(model_name, version)
run_id = model_version.run_id

# Your training code

if os.getenv('GITLAB_CI'):
    client.set_tag(model_version.run_id, 'gitlab.CI_JOB_ID', os.getenv('CI_JOB_ID'))
```

## Supported MLflow client methods and caveats

GitLab supports these methods from the MLflow client. Other methods might be supported but were not
tested. More information can be found in the [MLflow Documentation](https://www.mlflow.org/docs/1.28.0/python_api/mlflow.html). The MlflowClient counterparts
of the methods below are also supported with the same caveats.

| Method                   | Supported       | Version Added | Comments                                                                                     |
|--------------------------|-----------------|---------------|----------------------------------------------------------------------------------------------|
| `create_experiment`      | Yes             | 15.11         |                                                                                              |
| `get_experiment`         | Yes             | 15.11         |                                                                                              |
| `get_experiment_by_name` | Yes             | 15.11         |                                                                                              |
| `delete_experiment`      | Yes             | 17.5          |                                                                                              |
| `set_experiment`         | Yes             | 15.11         |                                                                                              |
| `get_run`                | Yes             | 15.11         |                                                                                              |
| `delete_run`             | Yes             | 17.5          |                                                                                              |
| `start_run`              | Yes             | 15.11         | (16.3) If a name is not provided, the run receives a random nickname.                        |
| `search_runs`            | Yes             | 15.11         | (16.4) `experiment_ids` supports only a single experiment ID with order by column or metric. |
| `log_artifact`           | Yes with caveat | 15.11         | (15.11) `artifact_path` must be empty. Does not support directories.                         |
| `log_artifacts`          | Yes with caveat | 15.11         | (15.11) `artifact_path` must be empty. Does not support directories.                         |
| `log_batch`              | Yes             | 15.11         |                                                                                              |
| `log_metric`             | Yes             | 15.11         |                                                                                              |
| `log_metrics`            | Yes             | 15.11         |                                                                                              |
| `log_param`              | Yes             | 15.11         |                                                                                              |
| `log_params`             | Yes             | 15.11         |                                                                                              |
| `log_figure`             | Yes             | 15.11         |                                                                                              |
| `log_image`              | Yes             | 15.11         |                                                                                              |
| `log_text`               | Yes with caveat | 15.11         | (15.11) Does not support directories.                                                        |
| `log_dict`               | Yes with caveat | 15.11         | (15.11) Does not support directories.                                                        |
| `set_tag`                | Yes             | 15.11         |                                                                                              |
| `set_tags`               | Yes             | 15.11         |                                                                                              |
| `set_terminated`         | Yes             | 15.11         |                                                                                              |
| `end_run`                | Yes             | 15.11         |                                                                                              |
| `update_run`             | Yes             | 15.11         |                                                                                              |
| `log_model`              | Partial         | 15.11         | (15.11) Saves the artifacts, but not the model data. `artifact_path` must be empty.          |
| `load_model`             | Yes             | 17.5          |                                                                                              |

Other MLflowClient methods:

| Method                    | Supported        | Version added | Comments                                         |
|---------------------------|------------------|---------------|--------------------------------------------------|
| `create_registered_model` | Yes with caveats | 16.8          | [See notes](#creating-a-model)                   |
| `get_registered_model`    | Yes              | 16.8          |                                                  |
| `delete_registered_model` | Yes              | 16.8          |                                                  |
| `update_registered_model` | Yes              | 16.8          |                                                  |
| `create_model_version`    | Yes with caveats | 16.8          | [See notes](#creating-a-model-version)           |
| `get_model_version`       | Yes              | 16.8          |                                                  |
| `get_latest_versions`     | Yes with caveats | 16.8          | [See notes](#getting-latest-versions-of-a-model) |
| `update_model_version`    | Yes              | 16.8          |                                                  |
| `create_registered_model` | Yes              | 16.8          |                                                  |
| `create_registered_model` | Yes              | 16.8          |                                                  |

## Known issues

- The API GitLab supports is the one defined at MLflow version 2.7.1.
- MLflow client methods not listed above are not supported.
- During creation of experiments and runs, ExperimentTags are stored, even though they are not displayed.

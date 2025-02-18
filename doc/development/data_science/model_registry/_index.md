---
stage: ModelOps
group: MLOps
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Model Registry
---

Model registry is the component in the MLOps lifecycle responsible for managing
model versions. Beyond tracking just artifacts, it is responsible to track the
metadata associated to each model, like:

- Performance
- Parameters
- Data lineage

## Data topology

All entities belong to a project, and only users with access to the project can
interact with the entities.

### `Ml::Model`

- Holds general information about a model, like name and description.
- Each model as a default `Ml::Experiment` with the same name where candidates are logged to.
- Has many `Ml::ModelVersion`.

#### `Ml::ModelVersion`

- Is a version of the model.
- Links to a `Packages::Package` with the same project, name, and version.
- Version must use semantic versioning.

#### `Ml::Experiment`

- Collection of comparable `Ml::Candidates`.

#### `Ml::Candidate`

- A candidate to a model version.
- Can have many parameters (`Ml::CandidateParams`), which are usually configuration variables passed to the training code.
- Can have many performance indicators (`Ml::CandidateMetrics`).
- Can have many user defined metadata (`Ml::CandidateMetadata`).

## MLflow compatibility layer

To make it easier for Data Scientists with GitLab Model registry, we provided a
compatibility layer to [MLflow client](https://mlflow.org/docs/latest/python_api/mlflow.client.html).
We do not provide an MLflow instance with GitLab. Instead, GitLab itself acts as
an instance of MLflow. This method stores data on the GitLab database, which
improves user reliability and functionality. See the user documentation about
[the compatibility layer](../../../user/project/ml/experiment_tracking/mlflow_client.md).

The compatibility layer is implemented by replicating the [MLflow rest API](https://mlflow.org/docs/latest/rest-api.html)
in [`lib/api/ml/mlflow`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/api/ml/mlflow).

Some terms on MLflow are named differently in GitLab:

- An MLflow `Run` is a GitLab `Candidate`.
- An MLflow `Registered model` is a GitLab `Model`.

### Setting up for testing

To test the an script with MLflow with GitLab as the backend:

1. Install MLflow:

   ```shell
   mkdir mlflow-compatibility
   cd mlflow-compatibility
   pip install mlflow jupyterlab
   ```

1. In the directory, create a Python file named `mlflow_test.py` with the following code:

   ```python3
   import mlflow
   import os
   from mlflow.tracking import MlflowClient

   os.environ["MLFLOW_TRACKING_TOKEN"]='<TOKEN>'
   os.environ["MLFLOW_TRACKING_URI"]='<your gitlab endpoint>/api/v4/projects/<your project id>/ml/mlflow'

   client = MlflowClient()
   client.create_experiment("My first experiment")
   ```

1. Run the script:

   ```shell
   python mlflow_test.py
   ```

1. Go to the project `/-/ml/experiments`. An experiment should have been created.

You can edit the script to call the client methods we are trying to implement. See
[GitLab Model experiments example](https://gitlab.com/gitlab-org/incubation-engineering/mlops/model_experiment_example)
for a more complete example.

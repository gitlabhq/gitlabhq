---
stage: ModelOps
group: MLOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Model registry
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9423) in GitLab 16.8 as an [experiment](../../../../policy/development_stages_support.md#experiment) release [with a flag](../../../../administration/feature_flags.md) named `model_registry`. Disabled by default. To enable the feature, an administrator can [enable the feature flag](../../../../administration/feature_flags.md) named `model_registry`.
> - [Changed](https://gitlab.com/groups/gitlab-org/-/epics/9423) to beta in GitLab 17.1.
> - [Changed](https://gitlab.com/groups/gitlab-org/-/epics/14998) to general availability in GitLab 17.6.

Model registry allows data scientists and developers to manage their machine learning
models, along with all metadata associated with their creation: parameters, performance
metrics, artifacts, logs, and more. For the full list of supported features,
see [epic 9423](https://gitlab.com/groups/gitlab-org/-/epics/9423).

## Access the model registry

To access the model registry, on the left sidebar, select **Deploy > Model registry**.

If **Model registry** is not available, ensure that it has been enabled.

To enable the model registry or set the [visibility level](../../../public_access.md) to public or private:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Under **Model registry**, ensure the toggle is on and select who you want to have access.
   Users must have
at least the [Reporter role](../../../permissions.md#roles) to modify or delete models and model versions.

## Create machine learning models by using the UI

To create a new machine learning model by using the GitLab UI:

1. On the left sidebar, select **Deploy > Model registry**.
1. On the **Model registry** page, select **Create/Import**.
1. In the dropdown, select **Create new model**.
1. Complete the fields:
   - Enter a unique name for your model name.
   - Optional. Provide a description for the model.
1. Select **Create**.

You can now view the newly created model in the model registry.

## Create a model version by using the UI

To create a new model version:

1. On the model details page, select **Create new version**.
1. Complete the fields:
   - Enter a unique version number following semantic versioning.
   - Optional. Provide a description for the model version.
   - Upload any files, logs, metrics, or parameters associated with the model version.
1. Select on **Create & import**.

The new model version is now available in the model registry.

### Delete a model

To delete a model and all its associated versions:

1. On the left sidebar, select **Deploy > Model registry**.
1. Find the model you want to delete.
1. In the most right column, select the vertical ellipsis (**{ellipsis_v}**) and **Delete model**.

Alternatively you can delete models from the model details page:

1. On the left sidebar, select **Deploy > Model registry**.
1. Find the model you want to delete.
1. Select the model name to view its details.
1. Select the vertical ellipsis (**{ellipsis_v}**) and **Delete model**.
1. Confirm the deletion.

### Delete a model version

To delete a model version:

1. On the left sidebar, select **Deploy > Model registry**.
1. Find the model with a version you want to delete.
1. Select the model name to view its details.
1. Select the **Versions** tab.
1. Find the model version you want to delete
1. In the most right column, select the vertical ellipsis (**{ellipsis_v}**) and **Delete model version**.

Alternatively you can delete models from the model version details page:

1. On the left sidebar, select **Deploy > Model registry**.
1. Find the model with a version you want to delete.
1. Select the model name to view its details.
1. Select the **Versions** tab.
1. Select the version name to view its details.
1. Select the vertical ellipsis (**{ellipsis_v}**) and **Delete model version**.
1. Confirm the deletion.

### Add artifacts to a model version

To add artifacts to a model version:

1. On the left sidebar, select **Deploy > Model registry**.
1. Find the model.
1. Select the model name to view its details.
1. Select the **Versions** tab.
1. Select the version name to view its details.
1. Select the **Artifacts** tab.
1. Optional. Specify a subfolder path for the files to be uploaded to. For example `config`.
1. Use **select** to choose the files to upload.
1. Select **Upload**.

Alternatively, you can drag and drop files in the drop area. The artifacts are automatically uploaded.

### Delete artifacts from a model version

To delete artifacts of a version:

1. On the left sidebar, select **Deploy > Model registry**.
1. Find the model.
1. Select the model name to view its details.
1. Select the **Versions** tab.
1. Select the version name to view its details.
1. Select the **Artifacts** tab.
1. Select the box next to each artifact you want to delete.
1. Select **Delete**.
1. Confirm the deletion.

## Create machine learning models and model versions by using MLflow

Models and model versions can be created using the [MLflow](https://www.mlflow.org/docs/latest/tracking.html) client compatibility.
For more information about how to create and manage models and model versions, see [MLflow client compatibility](../experiment_tracking/mlflow_client.md#model-registry).
You can also create models directly on GitLab by selecting **Create Model**
on the Model registry page.

### Add artifacts, metrics, and parameters to a model version by using MLflow

Files can either be uploaded to a model version using:

- The package registry, where a model version is associated to a package of name `<model_name>/<model_version>`.
- The MLflow client compatibility. [View details](../experiment_tracking/mlflow_client.md#logging-artifacts-to-a-model-version).

Users can log metrics and a parameters of a model version through the MLflow client compatibility, [see details](../experiment_tracking/mlflow_client.md#logging-metrics-and-parameters-to-a-model-version)

## Link a model version to a CI/CD job

When creating a model version through a GitLab CI/CD job, you can link the model
version to the job, giving convenient access to the job's logs, merge request, and pipeline.
This can be done through the MLflow client compatibility. [View details](../experiment_tracking/mlflow_client.md#linking-a-model-version-to-a-cicd-job).

## Model versions and semantic versioning

The version of a model version in GitLab must follow [Semantic Version specification](https://semver.org/).
Using semantic versioning facilitates model deployment, by communicating which
if a new version can be deployed without changes to the application:

- **Major (integer):** A change in the major component signifies a breaking change in the model, and that the application
  that consumes the model must be updated to properly use this new version.
  A new algorithm or the addition of a mandatory feature column are examples of breaking
  changes that would require a bump at the major component.

- **Minor (integer):** A change in the minor component signifies a non-breaking change, and that the
  consumer can safely use the new version without breaking, although the consumer might
  need to be updated to use its new functionality. For example, adding a non-mandatory
  feature column with a default value to the model is a minor bump, because when a value for
  the added column is not passed, inference still works.

- **Patch (integer):** A change in the patch component means that a new version is out that does not
  require any action by the application. For example, a daily retrain of the
  model does not change the feature set or how the application consumes the
  model version. Auto updating to a new patch is a safe update.

- **Prerelease (text):** Represents a version that is not yet ready for production use.
  Used to identify alpha, beta, or release candidate versions of the model.

### Model version examples

- Initial Release: 1.0.0 - The first release of the model, with no changes or patches.
- New Feature: 1.1.0 - A new non-breaking feature has been added to the model, incrementing the minor version.
- Bug Fix: 1.1.1 - A bug has been fixed in the model, incrementing the patch version.
- Breaking Change: 2.0.0 - A breaking change has been made to the model, incrementing the major version.
- Patch Release: 2.0.1 - A bug has been fixed in the model, incrementing the patch version.
- Prerelease: 2.0.1-alpha1 - A prerelease version of the model, with an alpha release.
- Prerelease: 2.0.1-rc2 - A release candidate version of the model.
- New Feature: 2.1.0 - A new feature has been added to the model, so the minor version is incremented.

---
stage: ModelOps
group: MLOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Model registry

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9423) in GitLab 16.8 as an [experiment](../../../../policy/experiment-beta-support.md#experiment) release [with a flag](../../../../administration/feature_flags.md) named `model_registry`. Disabled by default. To enable the feature, an administrator can [enable the feature flag](../../../../administration/feature_flags.md) named `model_registry`.
> - [Changed](https://gitlab.com/groups/gitlab-org/-/epics/9423) to beta in GitLab 17.1.

NOTE:
Model registry is in [beta](../../../../policy/experiment-beta-support.md). [Provide feedback](https://gitlab.com/groups/gitlab-org/-/epics/9423).

Model registry allows data scientists and developers to manage their machine learning
models, along with all metadata associated with their creation: parameters, performance
metrics, artifacts, logs and more. For the full list of currently supported features,
see [epic 9423](https://gitlab.com/groups/gitlab-org/-/epics/9423).

## Access the model registry

To set the model registry [visibility level](../../../public_access.md) to public, private or disabled:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Under **Model registry**, ensure the toggle is on and select who you want to have access.
   Users must have
at least the [Reporter role](../../../permissions.md#roles) to modify or delete models and model versions.

## Exploring models, model versions and model candidates

To access the model registry, from the left sidebar, select **Deploy > Model registry**.

## Creating machine learning models and model versions

Models and model versions can be created using the [MLflow](https://www.mlflow.org/docs/latest/tracking.html) client compatibility.
For more information about how to create and manage models and model versions, see [MLflow client compatibility](../experiment_tracking/mlflow_client.md#model-registry).
You can also create models directly on GitLab by selecting **Create Model**
on the Model registry page.

## Upload files, log metrics, log parameters to a model version

Files can either be uploaded to a model version using:

- The package registry, where a model version is associated to a package of name `<model_name>/<model_version>`.
- The MLflow client compatibility. [View details](../experiment_tracking/mlflow_client.md#logging-artifacts-to-a-model-version).

Users can log metrics and a parameters of a model version through the MLflow client compatibility, [see details](../experiment_tracking/mlflow_client.md#logging-metrics-and-parameters-to-a-model-version)

## Link a model version to a CI/CD job

When creating a model version through a GitLab CI/CD job, you can link the model
version to the job, giving easy access to the job's logs, merge request, and pipeline.
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
  the added column is not passed, inference will still work.

- **Patch (integer):** A change in the patch component means that a new version is out that does not
  require any action by the application. For example, a daily retrain of the
  model does not change the feature set or how the application consumes the
  model version. Auto updating to a new patch is a safe update.

- **Prerelease (text):**  Represents a version that is not yet ready for production use.
  Used to identify alpha, beta, or release candidate versions of the model.

### Model version examples

- Initial Release: 1.0.0 - This is the first release of the model, with no changes or patches.
- New Feature: 1.1.0 - A new non-breaking feature has been added to the model, incrementing the minor version.
- Bug Fix: 1.1.1 - A bug has been fixed in the model, incrementing the patch version.
- Breaking Change: 2.0.0 - A breaking change has been made to the model, incrementing the major version.
- Patch Release: 2.0.1 - A bug has been fixed in the model, incrementing the patch version.
- Prerelease: 2.0.1-alpha1 - This is a prerelease version of the model, with an alpha release.
- Prerelease: 2.0.1-rc2 - This is a release candidate version of the model.
- New Feature: 2.1.0 - A new feature has been added to the model, so the minor version is incremented.

## Related topics

- Development details, feedback, and feature requests in [epic 9423](https://gitlab.com/groups/gitlab-org/-/epics/9423).

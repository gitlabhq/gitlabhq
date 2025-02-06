---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Automatically build and publish packages with CI/CD'
---

You can use CI/CD to build and publish your PyPI packages. Automatic builds can help you keep your packages
up to date and available to others.

In this tutorial, you'll create a new CI/CD configuration to build, test, and publish a sample PyPI package.
When you finish, you should better understand how each step in the pipeline works, and feel comfortable integrating CI/CD
into your own package registry workflow.

To automatically build and publish packages with CI/CD:

1. [Create a `.gitlab-ci.yml` file](#create-a-gitlab-ciyml-file)
   1. Optional. [Authenticate without a CI/CD variable](#authenticate-without-a-cicd-variable)
1. [Check the pipeline](#check-the-pipeline)

## Before you begin

Before you complete this tutorial, make sure you have the following:

- A test project. You can use any Python project you like, but consider creating a project specifically for this tutorial.
- Familiarity with PyPI and the GitLab package registry.

## Create a `.gitlab-ci.yml` file

Every CI/CD configuration needs a `.gitlab-ci.yml`. This file defines each stage in the CI/CD pipeline. In this case,
the stages are:

- `build` - Build a PyPI package.
- `test` - Validate the package with the testing framework `pytest`.
- `publish` - Publish the package to the package registry.

To create a `.gitlab-ci.yml` file:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Repository**.
1. Above the file list, select the branch you want to commit to.
1. Select **Create new** (**{plus}**) and **New file**.
1. Name the file `.gitlab-ci.yml`. In the larger window, paste this sample configuration:

   ```yaml
   default:
     image: python:3.9
     cache:
       paths:
         - .pip-cache/
     before_script:
       - python --version
       - pip install --upgrade pip
       - pip install build twine

   stages:
     - build
     - test
     - publish

   variables:
     PIP_CACHE_DIR: "$CI_PROJECT_DIR/.pip-cache"

   build:
     stage: build
     script:
       - python -m build
     artifacts:
       paths:
         - dist/

   test:
     stage: test
     script:
       - pip install pytest
       - pip install dist/*.whl
       - pytest

   publish:
     stage: publish
     script:
       - TWINE_PASSWORD=${CI_JOB_TOKEN} TWINE_USERNAME=gitlab-ci-token python -m twine upload --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi dist/*
     rules:
       - if: $CI_COMMIT_TAG
   ```

1. Select **Commit changes**.

Here's a quick explanation of the code we committed:

- `image` - Specifies which Docker image to use.
- `stages` - Defines the three stages for this pipeline.
- `variables` and `cache` - Configures PIP to use caching. This can make subsequent pipelines run a bit faster.
- `before_script` - Installs the tools required to complete the three stages.
- `build` - Build the packages and store the results as an artifact.
- `test` - Install and run pytest to validate the package.
- `publish` - Upload the package to the package registry with twine, only if a new tag is pushed.
  Authenticate with the package registry using the `CI_JOB_TOKEN`.

### Authenticate without a CI/CD variable

To authenticate with the package registry, the example configuration uses the `CI_JOB_TOKEN`, which is automatically provided by GitLab CI/CD.
To publish to external PyPI registries, you must configure a secret variable in your project settings:

1. On the left sidebar, select **Settings > CI/CD > Variables**.
1. Add a new variable named `PYPI_TOKEN` with your PyPI API token as the value.
1. In your `.gitlab-ci.yml` file, replace the `publish:script` with:

   ```yaml
   script:
   - TWINE_PASSWORD=${PYPI_TOKEN} TWINE_USERNAME=__token__ python -m twine upload dist/*
   ```

## Check the pipeline

When you commit your changes, you should check to make sure the pipeline runs correctly:

- On the left sidebar, select **Build > Pipelines**. The most recent pipeline should have the three stages we defined earlier.

If the pipeline hasn't run, manually run a fresh pipeline and make sure it completes successfully.

## Best practices

To ensure the security and stability of your packages, you should follow best practices for publishing to the package registry.
The configuration we added:

- Implements caching to speed up your pipeline.
- Uses artifacts to pass the built package between stages.
- Includes a test stage to validate the package before publishing.
- Uses GitLab CI/CD variables for sensitive information like authentication tokens.
- Publishes only when a new Git tag is pushed. This ensures only properly versioned releases are published.

Congratulations! You've successfully built, tested, and published a package with GitLab CI/CD. You should be able to
use a similar configuration to streamline your own development processes.

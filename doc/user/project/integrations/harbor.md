---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Harbor
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can use Harbor as the container registry for your GitLab project.

[Harbor](https://goharbor.io/) is an open-source registry that can help you manage artifacts across cloud-native compute platforms like Kubernetes and Docker.

The Harbor integration can help you if you need GitLab CI/CD and a container image repository.

## Prerequisites

In the Harbor instance, ensure that:

- The project to be integrated has been created.
- The authenticated user has permission to pull, push, and edit images in the Harbor project.

## Configure GitLab

GitLab supports integrating Harbor projects at the group or project level. Complete these steps in GitLab:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Integrations**.
1. Select **Harbor**.
1. Under **Enable integration**, select the **Active** checkbox.
1. Provide the Harbor configuration information:
   - **Harbor URL**: The base URL of Harbor instance which is being linked to this GitLab project. For example, `https://harbor.example.net`.
   - **Harbor project name**: The project name in the Harbor instance. For example, `testproject`.
   - **Username**: Your username in the Harbor instance, which should meet the requirements in [prerequisites](#prerequisites).
   - **Password**: Password of your username.

1. Select **Save changes**.

After the Harbor integration is activated:

- The global variables `$HARBOR_USERNAME`, `$HARBOR_HOST`, `$HARBOR_OCI`, `$HARBOR_PASSWORD`, `$HARBOR_URL`, and `$HARBOR_PROJECT` are created for CI/CD use.
- The project-level integration settings override the group-level integration settings.

## Security considerations

### Secure your requests to the Harbor APIs

For each API request through the Harbor integration, the credentials for your connection to the Harbor API use
the `username:password` combination. The following are suggestions for safe use:

- Use TLS on the Harbor APIs you connect to.
- Follow the principle of least privilege (for access on Harbor) with your credentials.
- Have a rotation policy on your credentials.

### CI/CD variable security

Malicious code pushed to your `.gitlab-ci.yml` file could compromise your variables, including
`$HARBOR_PASSWORD`, and send them to a third-party server. For more details, see
[CI/CD variable security](../../../ci/variables/_index.md#cicd-variable-security).

## Examples of Harbor variables in CI/CD

### Push a Docker image with kaniko

For more information, see [Use kaniko to build Docker images](../../../ci/docker/using_kaniko.md).

```yaml
docker:
  stage: docker
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: ['']
  script:
    - mkdir -p /kaniko/.docker
    - echo "{\"auths\":{\"${HARBOR_HOST}\":{\"auth\":\"$(echo -n ${HARBOR_USERNAME}:${HARBOR_PASSWORD} | base64 -w 0)\"}}}" > /kaniko/.docker/config.json
    - >-
      /kaniko/executor
      --context "${CI_PROJECT_DIR}"
      --dockerfile "${CI_PROJECT_DIR}/Dockerfile"
      --destination "${HARBOR_HOST}/${HARBOR_PROJECT}/${CI_PROJECT_NAME}:${CI_COMMIT_TAG}"
  rules:
  - if: $CI_COMMIT_TAG
```

### Push a Helm chart with an OCI registry

Helm supports OCI registries by default. OCI is supported in [Harbor 2.0](https://github.com/goharbor/harbor/releases/tag/v2.0.0) and later.
Read more about OCI in Helm's [blog](https://helm.sh/blog/storing-charts-in-oci/) and [documentation](https://helm.sh/docs/topics/registries/#enabling-oci-support).

```yaml
helm:
  stage: helm
  image:
    name: dtzar/helm-kubectl:latest
    entrypoint: ['']
  variables:
    # Enable OCI support (not required since Helm v3.8.0)
    HELM_EXPERIMENTAL_OCI: 1
  script:
    # Log in to the Helm registry
    - helm registry login "${HARBOR_URL}" -u "${HARBOR_USERNAME}" -p "${HARBOR_PASSWORD}"
    # Package your Helm chart, which is in the `test` directory
    - helm package test
    # Your helm chart is created with <chart name>-<chart release>.tgz
    # You can push all building charts to your Harbor repository
    - helm push test-*.tgz ${HARBOR_OCI}/${HARBOR_PROJECT}
```

---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Multi-container scanning
description: Image vulnerability scanning, configuration, customization, and reporting.
---

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3139) as an [experiment](../../../policy/development_stages_support.md) in GitLab 18.7.

Use multi-container scanning to scan multiple container images in a single pipeline.
This feature enables you to:

- Scan multiple images in parallel.
- Configure scanning targets in a single configuration file.
- Integrate with existing container scanning workflows.

Multi-container scanning uses
[dynamic child pipelines](../../../ci/pipelines/downstream_pipelines.md#dynamic-child-pipelines) to
run scans concurrently, reducing overall pipeline execution time.

## Supported images

Multi-container scanning supports:

- Images from public registries (Docker Hub, GitLab Container Registry, and others)
- Images from private registries (with authentication configured)
- Multi-architecture images

## Enable multi-container scanning

Prerequisites:

- GitLab Runner with Docker executor.
- A `.gitlab-multi-image.yml` configuration file in your repository root.
- At least one container image to scan.

To enable multi-container scanning:

1. Create a `.gitlab-multi-image.yml` file in your repository root:

   ```yaml
      scanTargets:
        - name: alpine
          tag: latest
        - name: python
          tag: 3.9-slim
   ```

1. Include the template in your `.gitlab-ci.yml`:

   ```yaml
      include:
        - template: Jobs/Multi-Container-Scanning.latest.gitlab-ci.yml
   ```

1. Commit and push your changes. The pipeline runs the scans automatically.

## Configuration

Configure multi-container scanning by editing the `.gitlab-multi-image.yml` file.

### Basic configuration example

```yaml
scanTargets:
  - name: alpine
    tag: "3.19"
  - name: ubuntu
    tag: "22.04"
```

### Complete configuration example

```yaml
# Include license information in reports
includeLicenses: true

# Configure registry authentication
auths:
  registry.example.com:
    username: ${REGISTRY_USER}
    password: ${REGISTRY_PASSWORD}

# Allow insecure connections (not recommended for production)
allowInsecure: false

# Additional CA certificates for custom registries
additionalCaCertificateBundle: |
  -----BEGIN CERTIFICATE-----
  ...
  -----END CERTIFICATE-----

# Images to scan
scanTargets:
  - name: registry.example.com/myapp
    tag: "v1.2.3"
  - name: postgres
    tag: "15-alpine"
```

### Configuration options

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `scanTargets` | Array | Yes | List of container images to scan |
| `scanTargets[].name` | String | Yes | Image name (with optional registry) |
| `scanTargets[].tag` | String | No | Image tag (default: `latest`) |
| `scanTargets[].registry` | String | No | Registry override |
| `includeLicenses` | Boolean | No | Include license information in reports |
| `auths` | Object | No | Registry authentication credentials |
| `allowInsecure` | Boolean | No | Allow insecure HTTPS connections |
| `additionalCaCertificateBundle` | String | No | Additional CA certificates in PEM format |

## Common scenarios

The following sections describe some example scenarios that you can adapt to suit your needs.

### Scan images from different registries

```yaml
scanTargets:
  - name: docker.io/library/nginx
    tag: "1.25"
  - name: registry.gitlab.com/mygroup/myapp
    tag: "main"
  - name: gcr.io/myproject/service
    tag: "prod"
```

### Use private registry authentication

```yaml
auths:
  registry.gitlab.com:
    username: ${CI_REGISTRY_USER}
    password: ${CI_REGISTRY_PASSWORD}
  docker.io:
    username: ${DOCKERHUB_USER}
    password: ${DOCKERHUB_TOKEN}

scanTargets:
  - name: registry.gitlab.com/private/image
    tag: latest
```

### Scan specific versions for compliance

```yaml
scanTargets:
  - name: postgres
    tag: "14.10"
  - name: redis
    tag: "7.2.3"
  - name: nginx
    tag: "1.25.3"
```

## CI/CD variables

You can customize multi-container scanning behavior by using CI/CD variables.

| Variable | Default | Description |
|----------|---------|-------------|
| `CONTAINER_SCANNING_DISABLED` | - | Set to `true` or `1` to disable scanning |
| `AST_ENABLE_MR_PIPELINES` | `true` | Enable scanning in merge request pipelines |
| `CS_SCANNER_IMAGE` | `registry.gitlab.com/.../multiple-container-scanner:0` | Scanner image to use |

### Disable multi-container scanning

To disable scanning temporarily:

```yaml
variables:
  CONTAINER_SCANNING_DISABLED: "true"
```

### Disable MR pipeline scanning

```yaml
variables:
  AST_ENABLE_MR_PIPELINES: "false"
```

## View scan results

After the pipeline completes:

1. On the top bar, select **Search or go to** and find your project.
1. Go to your merge request or pipeline details page.
1. Select the **Security** tab.
1. View detected vulnerabilities from all scanned images.

Each scanned image generates:

- A container scanning report.
- A CycloneDX SBOM (Software Bill of Materials).
- License information (if `includeLicenses: true`).

### Pipeline structure

Multi-container scanning creates two jobs:

- `multi-cs::generate-scan`: Generates the scanning configuration
- `multi-cs::trigger-scan`: Triggers a child pipeline with parallel scan jobs

The child pipeline contains one job per image in `scanTargets`.

## Troubleshooting

When working with multi-container scanning, you might encounter the following issues.

### Pipeline fails with "configuration file not found"

Cause: The `.gitlab-multi-image.yml` file is missing or in the wrong location.

Solution: Ensure `.gitlab-multi-image.yml` exists in your repository root.

### Authentication fails for private registry

Cause: Invalid credentials or missing authentication configuration.

Solution:

1. Verify that credentials are correct and configured correctly.

   ```yaml
      auths:
        registry.example.com:
          username: ${REGISTRY_USER}
          password: ${REGISTRY_PASSWORD}
   ```

1. Define variables in **Settings** > **CI/CD > **Variables**.

### Scan takes too long

Cause: Multiple large images being scanned sequentially.

Solution: Multi-container scanning already runs scans in parallel.

Consider:

- Using smaller base images
- Scanning only specific image versions
- Adjusting GitLab Runner concurrency settings

### Child pipeline doesn't show reports

Cause: Missing `strategy: mirror` in trigger configuration.

Solution: This is configured by default in the template. If you've customized
the template, ensure the trigger job includes `strategy: mirror`.

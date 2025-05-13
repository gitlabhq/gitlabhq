---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Build and sign Python packages with GitLab CI/CD'
---

This tutorial shows you how to implement a secure pipeline for Python packages. The pipeline includes stages that cryptographically sign and verify Python packages using GitLab CI/CD and [Sigstore Cosign](https://docs.sigstore.dev/).

By the end, you'll learn how to:

- Build and sign Python packages using GitLab CI/CD.
- Store and manage package signatures using the generic package registry.
- Verify package signatures as an end user.

## What are the benefits of package signing?

Package signing provides several crucial security benefits:

- **Authenticity**: Users can verify that packages come from trusted sources.
- **Data integrity**: If a package is tampered with during distribution, it will be detected.
- **Non-repudiation**: The origin of a package can be cryptographically proven.
- **Supply chain security**: Package signing protects against supply chain attacks and compromised repositories.

## Before you begin

To complete this tutorial, you need:

- A GitLab account and test project.
- Basic familiarity with Python packaging, GitLab CI/CD, and package registry concepts.

## Steps

Here's an overview of what you're going to do:

1. [Set up a Python project.](#set-up-a-python-project)
1. [Add a base configuration.](#add-base-configuration)
1. [Configure the build stage.](#configure-the-build-stage)
1. [Configure the sign stage.](#configure-the-sign-stage)
1. [Configure the verify stage.](#configure-the-verify-stage)
1. [Configure the publish stage.](#configure-the-publish-stage)
1. [Configure the publish signatures stage.](#configure-the-publish-signatures-stage)
1. [Configure the consumer verification stage.](#configure-the-consumer-verification-stage)
1. [Verify packages as a user.](#verify-packages-as-a-user)

### Set up a Python project

First, create a test project. Add a `pyproject.toml` file in your project root:

```toml
[build-system]
requires = ["setuptools>=45", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "<my_package>"  # Will be dynamically replaced by CI/CD pipeline
version = "<1.0.0>"    # Will be dynamically replaced by CI/CD pipeline
description = "<Your package description>"
readme = "README.md"
requires-python = ">=3.7"
authors = [
    {name = "<Your Name>", email = "<your.email@example.com>"},
]

[project.urls]
"Homepage" = "<https://gitlab.com/my_package>"  # Will be replaced with actual project URL
```

Make sure you replace `Your Name` and `your.email@example.com` with your own personal details.

When you finish building your CI/CD pipeline in the following steps, the pipeline automatically:

- Replaces `my_package` with a normalized version of your project name.
- Changes the `version` to match the pipeline version.
- Changes the `Homepage` URL to match your GitLab project URL.

#### Add base configuration

In your project root, add a `.gitlab-ci.yml` file. Add the following configuration:

```yaml
variables:
  # Base Python version for all jobs
  PYTHON_VERSION: '3.10'
  # Package names and versions
  PACKAGE_NAME: ${CI_PROJECT_NAME}
  PACKAGE_VERSION: "1.0.0"  # Use semantic versioning
  # Sigstore service URLs
  FULCIO_URL: 'https://fulcio.sigstore.dev'
  REKOR_URL: 'https://rekor.sigstore.dev'
  # Identity for Sigstore verification
  CERTIFICATE_IDENTITY: 'https://gitlab.com/${CI_PROJECT_PATH}//.gitlab-ci.yml@refs/heads/${CI_DEFAULT_BRANCH}'
  CERTIFICATE_OIDC_ISSUER: 'https://gitlab.com'
  # Pip cache directory for faster builds
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.pip-cache"
  # Auto-accept prompts from Cosign
  COSIGN_YES: "true"
  # Base URL for generic package registry
  GENERIC_PACKAGE_BASE_URL: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/${PACKAGE_NAME}/${PACKAGE_VERSION}"

default:
  before_script:
    # Normalize package name once at the start of any job
    - export NORMALIZED_NAME=$(echo "${CI_PROJECT_NAME}" | tr '-' '_')

# Template for Python-based jobs
.python-job:
  image: python:${PYTHON_VERSION}
  before_script:
    # First normalize package name
    - export NORMALIZED_NAME=$(echo "${CI_PROJECT_NAME}" | tr '-' '_')
    # Then install Python dependencies
    - pip install --upgrade pip
    - pip install build twine setuptools wheel
  cache:
    paths:
      - ${PIP_CACHE_DIR}

# Template for Python + Cosign jobs
.python+cosign-job:
  extends: .python-job
  before_script:
    # First normalize package name
    - export NORMALIZED_NAME=$(echo "${CI_PROJECT_NAME}" | tr '-' '_')
    # Then install dependencies
    - apt-get update && apt-get install -y curl wget
    - wget -O cosign https://github.com/sigstore/cosign/releases/download/v2.2.3/cosign-linux-amd64
    - chmod +x cosign && mv cosign /usr/local/bin/
    - export COSIGN_EXPERIMENTAL=1
    - pip install --upgrade pip
    - pip install build twine setuptools wheel
stages:
  - build
  - sign
  - verify
  - publish
  - publish_signatures
  - consumer_verification
```

This base configuration:

- Instructs the pipeline to use Python `3.10` as the base image for consistency
- Sets up two reusable templates: `.python-job` for basic Python operations and `.python+cosign-job` for signing operations
- Implements pip caching to speed up builds
- Normalizes package names by converting hyphens to underscores for Python compatibility
- Defines all key variables at the pipeline level for easy management

### Configure the build stage

The build stage builds Python distribution packages.

In your `.gitlab-ci.yml` file, add the following configuration:

```yaml
build:
  extends: .python-job
  stage: build
  script:
    # Initialize git repo with actual content
    - git init
    - git config --global init.defaultBranch main
    - git config --global user.email "ci@example.com"
    - git config --global user.name "CI"
    - git add .
    - git commit -m "Initial commit"

    # Update package name, version, and homepage URL in pyproject.toml
    - sed -i "s/name = \".*\"/name = \"${NORMALIZED_NAME}\"/" pyproject.toml
    - sed -i "s/version = \".*\"/version = \"${PACKAGE_VERSION}\"/" pyproject.toml
    - sed -i "s|\"Homepage\" = \".*\"|\"Homepage\" = \"https://gitlab.com/${CI_PROJECT_PATH}\"|" pyproject.toml

    # Debug: show updated file
    - echo "Updated pyproject.toml contents:"
    - cat pyproject.toml

    # Build package
    - python -m build
  artifacts:
    paths:
      - dist/
      - pyproject.toml
```

The build stage configuration:

- Initializes a Git repository for build context
- Dynamically updates package metadata in `pyproject.toml`
- Adds both wheel (`.whl`) and source distribution (`.tar.gz`) packages
- Preserves build artifacts for subsequent stages
- Provides a debug output for troubleshooting

### Configure the sign stage

The sign stage signs packages using Sigstore Cosign.

In your `.gitlab-ci.yml` file, add the following configuration:

```yaml
sign:
  extends: .python+cosign-job
  stage: sign
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  script:
    - |
      for file in dist/*.whl dist/*.tar.gz; do
        if [ -f "$file" ]; then
          filename=$(basename "$file")

          cosign sign-blob --yes \
            --fulcio-url=${FULCIO_URL} \
            --rekor-url=${REKOR_URL} \
            --oidc-issuer $CI_SERVER_URL \
            --identity-token $SIGSTORE_ID_TOKEN \
            --output-signature "dist/${filename}.sig" \
            --output-certificate "dist/${filename}.crt" \
            "$file"

          # Debug: Verify files were created
          echo "Checking generated signature and certificate:"
          ls -l "dist/${filename}.sig" "dist/${filename}.crt"
        fi
      done
  artifacts:
    paths:
      - dist/
```

The sign stage configuration:

- Uses [keyless signing](https://docs.sigstore.dev/cosign/signing/overview/) from Sigstore for enhanced security
- Signs both wheel and source distribution packages
- Creates separate signature (`.sig`) and certificate (`.crt`) files
- Uses an OIDC integration for authentication
- Includes detailed logging for signature generation

### Configure the verify stage

The verify stage validates signatures locally.

In your `.gitlab-ci.yml` file, add the following configuration:

```yaml
verify:
  extends: .python+cosign-job
  stage: verify
  script:
    - |
      failed=0

      for file in dist/*.whl dist/*.tar.gz; do
        if [ -f "$file" ]; then
          filename=$(basename "$file")

          echo "Verifying file: $file"
          echo "Using signature: dist/${filename}.sig"
          echo "Using certificate: dist/${filename}.crt"

          if ! cosign verify-blob \
            --signature "dist/${filename}.sig" \
            --certificate "dist/${filename}.crt" \
            --certificate-identity "${CERTIFICATE_IDENTITY}" \
            --certificate-oidc-issuer "${CERTIFICATE_OIDC_ISSUER}" \
            "$file"; then
            echo "Verification failed for $filename"
            failed=1
          fi
        fi
      done

      if [ $failed -eq 1 ]; then
        exit 1
      fi
```

The verify stage configuration:

- Verifies signatures immediately after signing
- Checks both wheel and source distribution packages
- Validates the certificate identity and the OIDC issuer
- Fails fast if any verification fails
- Provides detailed verification logs

### Configure the publish stage

The publish stage uploads packages to the GitLab PyPI package registry.

In your `.gitlab-ci.yml` file, add the following configuration:

```yaml
publish:
  extends: .python-job
  stage: publish
  script:
    - |
      # Configure PyPI settings for GitLab package registry
      cat << EOF > ~/.pypirc
      [distutils]
      index-servers = gitlab
      [gitlab]
      repository = ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi
      username = gitlab-ci-token
      password = ${CI_JOB_TOKEN}
      EOF

      # Upload packages using twine
      TWINE_PASSWORD=${CI_JOB_TOKEN} TWINE_USERNAME=gitlab-ci-token \
        twine upload --repository-url ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/pypi \
        dist/*.whl dist/*.tar.gz
```

The publish stage configuration:

- Configures PyPI registry authentication
- Uses the GitLab built-in package registry
- Publishes both wheel and source distributions
- Uses job tokens for secure authentication
- Creates a reusable `.pypirc` configuration

### Configure the publish signatures stage

The publish signatures stage stores signatures in the GitLab generic package registry.

In your `.gitlab-ci.yml` file, add the following configuration:

```yaml
publish_signatures:
  extends: .python+cosign-job
  stage: publish_signatures
  script:
    - |
      for file in dist/*.whl dist/*.tar.gz; do
        if [ -f "$file" ]; then
          filename=$(basename "$file")

          ls -l "dist/${filename}.sig" "dist/${filename}.crt"

          echo "Publishing signatures for $filename"
          echo "Publishing to: ${GENERIC_PACKAGE_BASE_URL}/${filename}.sig"

          # Upload signature and certificate
          curl --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
               --fail \
               --upload-file "dist/${filename}.sig" \
               "${GENERIC_PACKAGE_BASE_URL}/${filename}.sig"

          curl --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
               --fail \
               --upload-file "dist/${filename}.crt" \
               "${GENERIC_PACKAGE_BASE_URL}/${filename}.crt"
        fi
      done
```

The publish signatures stage configuration:

- Stores signatures in the generic package registry
- Maintains signature-to-package mapping
- Uses consistent naming conventions for artifacts
- Includes size verification for signatures
- Provides detailed upload logs

### Configure the consumer verification stage

The consumer verification stage simulates end-user package verification.

In your `.gitlab-ci.yml` file, add the following configuration:

```yaml
consumer_verification:
  extends: .python+cosign-job
  stage: consumer_verification
  script:
    - |
      # Initialize git repo for setuptools_scm
      git init
      git config --global init.defaultBranch main

      # Create directory for downloading packages
      mkdir -p pkg signatures

      # Download the specific wheel version
      pip download --index-url "https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/api/v4/projects/${CI_PROJECT_ID}/packages/pypi/simple" \
          "${NORMALIZED_NAME}==${PACKAGE_VERSION}" --no-deps -d ./pkg --verbose

      # Download the specific source distribution version
      pip download --no-binary :all: \
          --index-url "https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/api/v4/projects/${CI_PROJECT_ID}/packages/pypi/simple" \
          "${NORMALIZED_NAME}==${PACKAGE_VERSION}" --no-deps -d ./pkg --verbose

      failed=0
      for file in pkg/*.whl pkg/*.tar.gz; do
        if [ -f "$file" ]; then
          filename=$(basename "$file")

          sig_url="${GENERIC_PACKAGE_BASE_URL}/${filename}.sig"
          cert_url="${GENERIC_PACKAGE_BASE_URL}/${filename}.crt"

          echo "Downloading signatures for $filename"
          echo "Signature URL: $sig_url"
          echo "Certificate URL: $cert_url"

          # Download signatures
          curl --fail --silent --show-error \
               --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
               --output "signatures/${filename}.sig" \
               "$sig_url"

          curl --fail --silent --show-error \
               --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
               --output "signatures/${filename}.crt" \
               "$cert_url"

          # Verify signature
          if ! cosign verify-blob \
            --signature "signatures/${filename}.sig" \
            --certificate "signatures/${filename}.crt" \
            --certificate-identity "${CERTIFICATE_IDENTITY}" \
            --certificate-oidc-issuer "${CERTIFICATE_OIDC_ISSUER}" \
            "$file"; then
            echo "Signature verification failed"
            failed=1
          fi
        fi
      done

      if [ $failed -eq 1 ]; then
        echo "Verification failed for one or more packages"
        exit 1
      fi
```

The consumer verification stage configuration:

- Simulates real-world package installation
- Downloads and verifies both package formats
- Uses the exact version matching for consistency
- Implements comprehensive error handling
- Tests the complete verification workflow

### Verify packages as a user

As an end user, you can verify package signatures with the following steps:

1. Install Cosign:

   ```shell
   wget -O cosign https://github.com/sigstore/cosign/releases/download/v2.2.3/cosign-linux-amd64
   chmod +x cosign && sudo mv cosign /usr/local/bin/
   ```

   Cosign requires special permissions for global installations. Use `sudo` to bypass permissions issues.

1. Download the package and its signatures:

   ```shell
   # You can find your PROJECT_ID in your GitLab project's home page under the project name

   # Download the specific version of the package
   pip download your-package-name==1.0.0 --no-deps

   # The FILENAME will be the output from the pip download command
   # For example: your-package-name-1.0.0.tar.gz or your-package-name-1.0.0-py3-none-any.whl

   # Download signatures from GitLab's generic package registry
   # Replace these values with your project's details:
   # GITLAB_URL: Your GitLab instance URL (for example, https://gitlab.com)
   # PROJECT_ID: Your project's ID number
   # PACKAGE_NAME: Your package name
   # VERSION: Package version (for example, 1.0.0)
   # FILENAME: The exact filename of your downloaded package

   curl --output "${FILENAME}.sig" \
     "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/packages/generic/${PACKAGE_NAME}/${VERSION}/${FILENAME}.sig"

   curl --output "${FILENAME}.crt" \
     "${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/packages/generic/${PACKAGE_NAME}/${VERSION}/${FILENAME}.crt"
   ```

1. Verify the signatures:

   ```shell
   # Replace CERTIFICATE_IDENTITY and CERTIFICATE_OIDC_ISSUER with the values from the project's pipeline
   export CERTIFICATE_IDENTITY="https://gitlab.com/your-group/your-project//.gitlab-ci.yml@refs/heads/main"
   export CERTIFICATE_OIDC_ISSUER="https://gitlab.com"

   # Verify wheel package
   FILENAME="your-package-name-1.0.0-py3-none-any.whl"
   COSIGN_EXPERIMENTAL=1 cosign verify-blob \
     --signature "${FILENAME}.sig" \
     --certificate "${FILENAME}.crt" \
     --certificate-identity "${CERTIFICATE_IDENTITY}" \
     --certificate-oidc-issuer "${CERTIFICATE_OIDC_ISSUER}" \
     "${FILENAME}"

   # Verify source distribution
   FILENAME="your-package-name-1.0.0.tar.gz"
   COSIGN_EXPERIMENTAL=1 cosign verify-blob \
     --signature "${FILENAME}.sig" \
     --certificate "${FILENAME}.crt" \
     --certificate-identity "${CERTIFICATE_IDENTITY}" \
     --certificate-oidc-issuer "${CERTIFICATE_OIDC_ISSUER}" \
     "${FILENAME}"
   ```

When verifying packages as an end user:

- Make sure package downloads match the exact version you want to verify.
- Verify each package type (wheel and source distribution) separately.
- Make sure the certificate identity exactly matches what was used to sign the package.
- Check that all URL components are correctly set. For example, the `GITLAB_URL` or `PROJECT_ID`.
- Check that package filenames match exactly what was uploaded to the registry.
- Use the `COSIGN_EXPERIMENTAL=1` feature flag for keyless verification. This flag is required.
- Understand that failed verifications might indicate tampering or incorrect certificate and signature pairs.
- Keep track of the certificate identity and issuer values from your project's pipeline.

## Troubleshooting

When completing this tutorial, you might encounter the following errors:

### Error: `404 Not Found`

If you encounter a `404 Not Found` error page:

- Double-check all URL components.
- Verify the package version exists in the registry.
- Ensure filenames match exactly, including the version and platform tags.

### Verification failed

If signature verification fails, make sure:

- The `CERTIFICATE_IDENTITY` matches the signing pipeline.
- The `CERTIFICATE_OIDC_ISSUER` is correct.
- The signature and certificate pair is correct for the package.

### Permission denied

If you encounter permissions issues:

- Check if you have access to the package registry.
- Verify authentication if the registry is private.
- Use the correct file permissions when installing Cosign.

### Authentication issues

If you encounter authentication issues:

- Check the `CI_JOB_TOKEN` permissions.
- Verify the registry authentication configuration.
- Validate the project's access settings.

### Verify package configuration and pipeline settings

Check the package configuration. Make sure:

- Package names use underscores (`_`), not hyphens (`-`).
- Version strings use valid [PEP 440](https://peps.python.org/pep-0440/).
- The `pyproject.toml` file is properly formatted.

Check the pipeline settings. Make sure:

- OIDC is configured correctly.
- Job dependencies are properly set.
- Required permissions are in place.

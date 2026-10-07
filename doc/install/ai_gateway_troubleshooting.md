---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Troubleshoot issues with the AI Gateway.
title: Troubleshooting the AI Gateway
---

When working with the [AI Gateway](install_ai_gateway.md), you might encounter the following issues.

## OpenShift permission issues

When deploying the AI Gateway on OpenShift, you might encounter permission errors due to the OpenShift security model.

### Read-only file system at `/tmp`

The AI Gateway writes to `/tmp`. However, based on the OpenShift environment, which is security-restricted, `/tmp` might be read-only.

To resolve this issue, create a new `EmptyDir` volume and mount it at `/tmp`
in either of the following ways:

- From the command line:

  ```shell
  oc set volume <object_type>/<name> --add --name=tmpVol --type=emptyDir --mountPoint=/tmp
  ```

- In your `values.yaml`:

  ```yaml
  volumes:
  - name: tmp-volume
    emptyDir: {}

  volumeMounts:
  - name: tmp-volume
    mountPath: "/tmp"
  ```

### HuggingFace models

By default, the AI Gateway uses `/home/aigateway/.hf` for caching HuggingFace models, which might not be writable in OpenShift's
security-restricted environment. Permission errors like the following might occur:

```shell
[Errno 13] Permission denied: '/home/aigateway/.hf/...'
```

To resolve this issue, set the `HF_HOME` environment variable to a writable location. You can use `/var/tmp/huggingface` or any other directory that is writable by the container in either of the following ways:

- In your `values.yaml`:

  ```yaml
  extraEnvironmentVariables:
    - name: HF_HOME
      value: /var/tmp/huggingface  # Use any writable directory
  ```

- In your Helm upgrade command:

  ```shell
  --set "extraEnvironmentVariables[0].name=HF_HOME" \
  --set "extraEnvironmentVariables[0].value=/var/tmp/huggingface"  # Use any writable directory
  ```

This configuration ensures the AI Gateway can properly cache HuggingFace models while respecting the OpenShift security constraints. The exact directory you choose might depend on your specific OpenShift configuration and security policies.

## Tokenizer cache shadowed by a volume mount

The pre-cached tokenizer files in the AI Gateway image
might be shadowed by a volume mount if:

- Code completion requests return a `500` error.
- AI Gateway logs show an `OSError` from `transformers/utils/hub.py`
  attempting to download `Salesforce/codegen2-16B` from `huggingface.co`.

The self-hosted AI Gateway image (`self-hosted-vX.Y.Z-ee`) sets
`HF_HUB_OFFLINE=true` and pre-caches the tokenizer at build time,
so no network access to `huggingface.co` should occur at runtime.
If network access occurs, an empty directory in your Helm values
might be mounted over `/home/aigateway/.hf`, overwriting the cached files.

Do not try to resolve this issue by granting egress access to `huggingface.co`.
Instead, to diagnose the issue, run the following in the AI Gateway pod:

```shell
ls -la /home/aigateway/.hf/hub/ 2>/dev/null || echo "NO_CACHE_DIR"
env | grep -E '^(HF_|TRANSFORMERS_)'
```

If the cache directory is missing or empty, do the following:

1. Check your `values.yaml` for any `volumeMounts` that target
   `/home/aigateway/.hf` or the path set by `HF_HOME`.
1. Remove or remap the mount to a directory that does not overlap
   with the image's built-in cache.

## Self-signed certificate error

When the AI Gateway tries to connect to a GitLab instance or model endpoint with a certificate signed by a custom certificate authority (CA) or a self-signed certificate, the following error might occur:

```plaintext
[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: self-signed certificate in certificate chain
```

To resolve this issue, see [connect to a GitLab instance or model endpoint with a self-signed SSL certificate](install_ai_gateway.md#connect-to-a-gitlab-instance-or-model-endpoint-with-a-self-signed-ssl-certificate).

## Token creation failed

If you encounter a `Token creation failed` error when you use features like GitLab Duo Chat,
the `AIGW_SELF_SIGNED_JWT__SIGNING_KEY` and `AIGW_SELF_SIGNED_JWT__VALIDATION_KEY`
environment variables might not be set on the AI Gateway.

These keys are required for the AI Gateway to issue short-lived user JWTs.
Without these keys, the AI Gateway cannot sign tokens, which causes a JWK
deserialization failure.

To resolve this issue:

1. Generate the required keys:

   ```shell
   openssl genrsa -out aigw_signing.key 2048
   openssl genrsa -out aigw_validation.key 2048
   ```

1. Add the keys to your AI Gateway container by passing them as environment variables:

   ```shell
   -e AIGW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat aigw_signing.key)" \
   -e AIGW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat aigw_validation.key)"
   ```

1. Restart the AI Gateway container.

## SSL certificate errors when loading PEM files

If you get an error that says `JWKError` while loading the PEM file into the Docker container,
you might need to resolve an SSL certificate error.

To resolve this issue, use the following environment variables to set the appropriate
certificate bundle path in the Docker container:

- `SSL_CERT_FILE=/path/to/ca-bundle.pem`
- `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

Replace `/path/to/ca-bundle.pem` with the path to your certificate bundle.

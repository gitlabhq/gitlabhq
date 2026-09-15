---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Sign CI/CD artifacts and container images with a self-hosted Sigstore stack, including Fulcio configuration and troubleshooting.
title: Sign artifacts and container images with self-hosted Sigstore
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

If you run GitLab Self-Managed, you can't use the public [Sigstore service](signing_examples.md)
to sign your CI/CD artifacts and container images.
The service only trusts GitLab.com pipelines, not pipelines from your own instance.
Instead, you can connect your own Sigstore infrastructure (Fulcio, Rekor, and a
Certificate Transparency log) to your GitLab instance, so you can sign and verify artifacts with
Cosign without depending on GitLab.com or the internet.

The GitLab OpenID Connect (OIDC) provider proves your identity,
Cosign throws away the signing key right after it's used,
and Rekor records every signing event in its transparency log.

The certificate Fulcio issues gets embedded in the signature, along with details about exactly
which pipeline created it, including the project path, commit SHA, pipeline source, runner environment,
and job URL.

Prerequisites:

- Access to configure your Sigstore infrastructure (Fulcio, Rekor) and your GitLab CI/CD runners.
- A self-hosted Sigstore stack running in your network, including Fulcio, Rekor, and a Certificate
  Transparency log. The Certificate Transparency log is required.
  Cosign verifies a signed certificate timestamp during verification, so a Fulcio deployed
  without a Certificate Transparency log issues certificates that Cosign cannot verify.
  For deployment instructions, see:
  - [Sigstore transparency log installation guide](https://docs.sigstore.dev/logging/installation/)
    for Rekor and its Trillian backend
  - [Fulcio repository](https://github.com/sigstore/fulcio) for Fulcio and the Certificate
    Transparency log
- Rekor configured with a persistent signing key.
- If your GitLab instance uses HTTPS with a private certificate authority, that certificate
  authority must be trusted by both Fulcio and your CI/CD runners:
  - The certificate authority certificate mounted into the Fulcio container, with `SSL_CERT_FILE`
    set to its path.
  - The certificate authority certificate installed into the operating system trust store on
    each runner.
- [Cosign](https://docs.sigstore.dev/cosign/system_config/installation/) v2.x or later installed
  on your CI/CD runners.
- The trust material files from your Sigstore stack, placed on your runners in a shared location
  such as `/etc/sigstore/`:
  - Fulcio root CA certificate (`fulcio-root.pem`)
  - Rekor transparency log public key (`rekor-pub.pem`)
  - Certificate Transparency log public key (`ctfe-pub.pem`)

## Configure Fulcio to trust your GitLab instance

Configure Fulcio to trust your GitLab instance so it can verify OIDC tokens
from GitLab CI/CD jobs during keyless signing. Fulcio maps the token's claims to fields in the
signing certificate. The configuration file requires both an `oidc-issuers` section and a
`ci-issuer-metadata` section.

To configure Fulcio:

1. Retrieve the exact OIDC issuer URL with the following command.
   Replace `https://gitlab.example.com` with your GitLab instance's URL.
   Fulcio requires an exact match.
   The scheme and the presence or absence of a trailing slash both matter.

   ```shell
   curl --silent "https://gitlab.example.com/.well-known/openid-configuration" | jq --raw-output .issuer
   ```

1. Create a Fulcio OIDC configuration file with an `oidc-issuers` entry for your GitLab instance.
   Replace `<gitlab_issuer_url>` with the output from the previous step:

   ```yaml
   oidc-issuers:
     <gitlab_issuer_url>:
       issuer-url: <gitlab_issuer_url>
       client-id: sigstore
       type: ci-provider
       ci-provider: gitlab-pipeline
       contact: admin@example.com
       description: "GitLab Self-Managed OIDC"
   ```

1. In the same file, add a `ci-issuer-metadata` section with the GitLab claim templates, copied
   from the [upstream Fulcio configuration](https://github.com/sigstore/fulcio/blob/main/config/identity/config.yaml).
   Replace `<gitlab_issuer_url>` with the same value you used in the previous step.

   For what each claim maps to, see the GitLab column of
   [mapping OIDC token claims to Fulcio OIDs](https://github.com/sigstore/fulcio/blob/main/docs/oid-info.md#mapping-oidc-token-claims-to-fulcio-oids).

   ```yaml
   ci-issuer-metadata:
     gitlab-pipeline:
       default-template-values:
         url: "<gitlab_issuer_url>"
         environment: ""
       extension-templates:
         build-signer-uri: "https://{{ .ci_config_ref_uri }}"
         build-signer-digest: "ci_config_sha"
         runner-environment: "runner_environment"
         source-repository-uri: "{{ .url }}/{{ .project_path }}"
         source-repository-digest: "sha"
         source-repository-ref: >-
           refs/{{if eq .ref_type "branch"}}heads/{{ else }}tags/{{end}}{{ .ref }}
         source-repository-identifier: "project_id"
         source-repository-owner-uri: "{{ .url }}/{{ .namespace_path }}"
         source-repository-owner-identifier: "namespace_id"
         build-config-uri: "https://{{ .ci_config_ref_uri }}"
         build-config-digest: "ci_config_sha"
         build-trigger: "pipeline_source"
         run-invocation-uri: >-
           {{ .url }}/{{ .project_path }}/-/jobs/{{ .job_id }}
         source-repository-visibility-at-signing: "project_visibility"
         deployment-environment: "environment"
       subject-alternative-name-template: "https://{{ .ci_config_ref_uri }}"
   ```

   > [!note]
   > This section is maintained by the Sigstore project, not GitLab. Periodically check the
   > upstream file for changes, and update your copy to match.

## Sign artifacts and container images

Use the `id_tokens` keyword to generate an OIDC token for the job.
Cosign presents this token to Fulcio, which issues an ephemeral signing certificate.

Cosign v3 uses signing configuration files to specify your Sigstore service endpoints and
trust material. Generate these files once and distribute them to runners, or generate them
in each job as shown in the following example.

```yaml
sign-artifact:
  stage: sign
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  variables:
    COSIGN_YES: "true"
  script:
    - cosign signing-config create
        --fulcio="url=http://<sigstore-host>:5555,api-version=1,start-time=2024-01-01T00:00:00Z,operator=my-org"
        --rekor="url=http://<sigstore-host>:3000,api-version=1,start-time=2024-01-01T00:00:00Z,operator=my-org"
        --rekor-config="ANY"
        --oidc-provider="url=https://gitlab.example.com,api-version=1,start-time=2024-01-01T00:00:00Z,operator=my-org"
        --out signing-config.json
    - cosign trusted-root create
        --fulcio="url=http://<sigstore-host>:5555,certificate-chain=/etc/sigstore/fulcio-root.pem,start-time=2024-01-01T00:00:00Z"
        --rekor="url=http://<sigstore-host>:3000,public-key=/etc/sigstore/rekor-pub.pem,start-time=2024-01-01T00:00:00Z"
        --ctfe="url=http://<sigstore-host>:6962,public-key=/etc/sigstore/ctfe-pub.pem,start-time=2024-01-01T00:00:00Z"
        --out trusted-root.json
    - cosign sign-blob
        --signing-config=signing-config.json
        --trusted-root=trusted-root.json
        --oidc-client-id=sigstore
        --identity-token=$SIGSTORE_ID_TOKEN
        --bundle=artifact.bundle
        artifact.txt
```

The `start-time` value is the earliest time the service endpoint is considered valid, as defined
in the [Sigstore protobuf specification](https://github.com/sigstore/protobuf-specs).
Use the date your Sigstore stack was deployed.

Replace `sigstore` in `--oidc-client-id` with the client ID configured in your Fulcio OIDC
issuer entry.

Use the same issuer URL for `--oidc-provider` that you registered in the Fulcio `oidc-issuers`
configuration.

### Sign container images

To sign a container image, use `cosign sign` with the image reference in place of the file path.
The signing configuration is the same.

The container registry must be reachable over HTTPS on a resolvable hostname.
The registry advertises an authentication realm at its own external URL.
Cosign rejects a realm whose host is a literal private or link-local address.
An instance whose `registry_external_url` is a bare IP address can sign files but cannot
sign container images.

### For Cosign v2.x

If you use Cosign v2.x, use URL flags and environment variables in place of configuration files:

```yaml
sign-artifact:
  stage: sign
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  variables:
    COSIGN_YES: "true"
    SIGSTORE_ROOT_FILE: /etc/sigstore/fulcio-root.pem
    SIGSTORE_REKOR_PUBLIC_KEY: /etc/sigstore/rekor-pub.pem
    SIGSTORE_CT_LOG_PUBLIC_KEY_FILE: /etc/sigstore/ctfe-pub.pem
  script:
    - cosign sign-blob
        --fulcio-url=http://<sigstore-host>:5555
        --rekor-url=http://<sigstore-host>:3000
        --oidc-issuer=https://gitlab.example.com
        --identity-token=$SIGSTORE_ID_TOKEN
        --output-signature=artifact.sig
        --output-certificate=artifact.crt
        artifact.txt
```

For container images, use Cosign v3 as described in [Sign container images](#sign-container-images).

Cosign v2 writes the certificate as base64-encoded PEM.
Decode it before passing it to another tool.

Use the same issuer URL for `--oidc-issuer` that you registered in the Fulcio `oidc-issuers`
configuration.

## Verify signatures

Verification with a Cosign v3 bundle uses the trust material and the expected signer identity:

```shell
cosign verify-blob \
  --trusted-root=trusted-root.json \
  --bundle=artifact.bundle \
  --certificate-oidc-issuer=https://gitlab.example.com \
  --certificate-identity=https://gitlab.example.com/my-group/my-project//.gitlab-ci.yml@refs/heads/main \
  artifact.txt
```

The `--certificate-identity` value is the Subject Alternative Name of the signing certificate,
and it's built from the CI/CD configuration path:

```plaintext
https://<CI_SERVER_HOST>/<CI_PROJECT_PATH>//.gitlab-ci.yml@<full ref>
```

Three details in that pattern matter:

- The scheme is always `https://`, because the `subject-alternative-name-template` in the
  Fulcio configuration sets it.
  This holds even when your instance is reachable over HTTP.
- The double slash before `.gitlab-ci.yml` is correct.
  The path segment before it is the project, and the empty segment that follows carries the
  default CI/CD configuration location.
- The full ref is `refs/heads/<branch>` for a branch pipeline and `refs/tags/<tag>` for a
  tag pipeline.

To verify artifacts signed with Cosign v2, pass the detached signature and certificate:

```shell
cosign verify-blob \
  --signature=artifact.sig \
  --certificate=artifact.crt \
  --certificate-oidc-issuer=https://gitlab.example.com \
  --certificate-identity=https://gitlab.example.com/my-group/my-project//.gitlab-ci.yml@refs/heads/main \
  artifact.txt
```

## Related topics

- [Signing examples](signing_examples.md) for GitLab.com with the public Sigstore instance
- [CI/CD OIDC ID tokens](../secrets/id_token_authentication.md)
- [Sigstore: Custom components](https://docs.sigstore.dev/cosign/system_config/custom_components/)

## Troubleshooting

When signing artifacts with self-hosted Sigstore infrastructure, you might encounter the following issues.

### Error: `metadata not found for ci provider gitlab-pipeline`

This error occurs when the `ci-issuer-metadata` section is missing from your Fulcio
configuration.

To resolve this issue, add the full `ci-issuer-metadata` block as documented in
[configure Fulcio to trust your GitLab instance](#configure-fulcio-to-trust-your-gitlab-instance).

### Error: `ctfe public key not found for payload`

This error occurs when Cosign cannot find the Certificate Transparency log public key for
your self-hosted stack.

To resolve this issue, include `--ctfe` in your `cosign trusted-root create` command for
Cosign v3, or set the `SIGSTORE_CT_LOG_PUBLIC_KEY_FILE` environment variable for Cosign v2.

### Error: `not enough verified log entries from transparency log`

This error occurs when the Rekor public key in `trusted-root.json` no longer matches the
key the Rekor instance is using.
An in-memory signer generates a new key and a new empty Merkle tree (Rekor's tamper-evident log structure) on every restart.
Any restart therefore invalidates the trust material, and signing fails for every job until
it is rebuilt.

To resolve this issue, read the current key from the running instance and regenerate the
trusted root:

```shell
curl --silent --fail "http://<sigstore-host>:3000/api/v1/log/publicKey" --output /etc/sigstore/rekor-pub.pem
cosign trusted-root create \
  --fulcio="url=http://<sigstore-host>:5555,certificate-chain=/etc/sigstore/fulcio-root.pem,start-time=2024-01-01T00:00:00Z" \
  --rekor="url=http://<sigstore-host>:3000,public-key=/etc/sigstore/rekor-pub.pem,start-time=2024-01-01T00:00:00Z" \
  --ctfe="url=http://<sigstore-host>:6962,public-key=/etc/sigstore/ctfe-pub.pem,start-time=2024-01-01T00:00:00Z" \
  --out trusted-root.json
```

Distribute the regenerated `trusted-root.json` to every runner.

To prevent this issue, configure Rekor with a persistent signing key and a fixed tree
identifier.

### Error: `failed to verify signed certificate timestamp`

This error occurs when the certificate carries no signed certificate timestamp, which
happens when Fulcio runs without a Certificate Transparency log.
Signing succeeds in this configuration, and only verification fails.

To resolve this issue, configure Fulcio with `--ct-log-url` pointing at your Certificate
Transparency log, and include `--ctfe` when you create the trusted root.

### Error: `x509: certificate signed by unknown authority`

This error occurs when Fulcio cannot validate the TLS certificate your GitLab instance
presents.

To resolve this issue, mount your private certificate authority certificate into the
Fulcio container and set `SSL_CERT_FILE` to its path.

The Fulcio `/healthz` endpoint reports `SERVING` even when OIDC provider initialization
has failed. Use the container log to confirm the provider loaded.

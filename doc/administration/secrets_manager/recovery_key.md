---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Recovery key management
---

The recovery key is an emergency credential for OpenBao. Use it to generate a temporary root
token when the primary JWT authentication method becomes unavailable.

The recovery key is not used in standard operations such as secret fetches or namespace
provisioning. Treat it as a high-privilege credential and store it securely.

> [!warning]
> The recovery key cannot decrypt data stored in the OpenBao database. All OpenBao data is
> protected by the configured unseal mechanism, either a static key stored in the
> `gitlab-openbao-unseal` Kubernetes secret or an external KMS.
> Back up your unseal mechanism separately from the recovery key.

To run the commands on this page, you need the name of your toolbox pod. To find it, run:

```shell
kubectl get pods -n gitlab -lapp=toolbox
```

Use the pod name in place of `<toolbox-pod-name>` in the following commands.

## Store the recovery key

Run this command once during initial setup, before an incident occurs:

```shell
kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
  gitlab-rake "gitlab:secrets_management:openbao:recovery_key:store"
```

The command generates the recovery key in OpenBao and stores it encrypted in the GitLab database.

> [!warning]
> The recovery key can only be generated once.
> You can't run `recovery_key:store` a second time
> or after running `recovery_key:fetch`.

Until you run this command, OpenBao logs a warning on every pod restart:
`[WARN]  core: post-unseal upgrade seal keys failed: error="no recovery key found"`.
The warning stops after you store the key.

## View the stored recovery key

To fetch and view the recovery key from the GitLab database, run:

```shell
kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
  gitlab-rake "gitlab:secrets_management:openbao:recovery_key:show"
```

> [!warning]
> The command asks for confirmation before displaying the key in plaintext.
> Store the output securely. Do not log it or share it outside a secure channel.

## Fetch the recovery key without storing it

Use `recovery_key:fetch` to generate and display the recovery key in the terminal without storing it
in the GitLab database. Use this task when you store the key in an external system,
for example a password manager or hardware security module.

> [!warning]
> The recovery key can only be generated once.
> You can't run `recovery_key:fetch` a second time
> or after running `recovery_key:store`.

```shell
kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
  gitlab-rake "gitlab:secrets_management:openbao:recovery_key:fetch"
```

The task asks for confirmation before generating and displaying the key. The key appears in plaintext.

## Generate a root token from the recovery key

Use the recovery key to generate a temporary root token when you need to perform privileged
OpenBao operations such as reconfiguring JWT authentication or migrating the seal. For example,
when you fail over to a Geo secondary site with a different domain. For more information, see
[Configure JWT authentication](../geo/disaster_recovery/_index.md#optional-configure-jwt-authentication).

> [!warning]
> Revoke the root token immediately after you complete the required operations.
> A root token has unrestricted access to all OpenBao operations and namespaces.

The `bao` binary is available inside the OpenBao pod. Run all commands with `kubectl exec`.
No port-forward is required.

1. Retrieve your recovery key:

   ```shell
   kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
     gitlab-rake "gitlab:secrets_management:openbao:recovery_key:show"
   ```

   If you used `recovery_key:fetch` and stored the key externally, retrieve it from that location instead.

1. Get the OpenBao pod name:

   ```shell
   kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name
   ```

   Replace `<openbao-pod-name>` in the following steps with the output from this command. For example, `pod/gitlab-openbao-0`.

1. Generate an OTP:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -generate-otp"
   ```

   Replace `<otp>` in the following commands with this output.

1. Initialize root generation:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -init -otp=<otp>"
   ```

   A successful response includes `Started: true` and a `Nonce` value.
   Replace `<nonce>` in the following steps with this `Nonce` value.

1. Submit the recovery key:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "echo '<recovery_key>' | BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -nonce=<nonce>"
   ```

   OpenBao is configured with a single recovery key share, so the operation completes
   immediately. A successful response includes `Complete: true` and an `Encoded Token` value.
   Replace `<encoded_token>` in the next step with this token value.

1. Decode the root token:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao operator generate-root -decode=<encoded_token> -otp=<otp>"
   ```

   Replace `<root_token>` in the following steps with the decoded root token.

1. Verify the root token works:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao token lookup"
   ```

   A successful response includes `policies  [root]`.

1. Perform the required privileged operations.

1. Revoke the root token:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao token revoke -self"
   ```

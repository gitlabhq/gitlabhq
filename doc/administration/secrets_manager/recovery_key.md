---
stage: Security Platform
group: Secrets Manager OpenBao
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Recovery key management
---

The recovery key is an emergency credential for OpenBao. Use it to generate a root token for
privileged OpenBao operations.

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

Generate a root token when you need to perform a privileged OpenBao operation that GitLab cannot
perform for you. A root token has unrestricted access to all OpenBao operations and namespaces.

Prerequisites:

- Permission to run `kubectl exec` in the toolbox pod and the OpenBao pod.
- A recovery key that you stored with `recovery_key:store`, or saved after you ran
  `recovery_key:fetch`.
- Working authentication from GitLab to OpenBao. If authentication fails, see
  [JWT authentication fails](troubleshooting.md#jwt-authentication-fails).

To generate a root token:

1. Run the Rake task:

   ```shell
   kubectl exec -n gitlab -it -c toolbox <toolbox-pod-name> -- \
     gitlab-rake "gitlab:secrets_management:openbao:root_token:generate"
   ```

1. When the task asks for confirmation, enter `y`. If you stored the recovery key with
   `recovery_key:store`, the task uses the stored key. Otherwise, enter the recovery key. The task
   does not display the key as you enter the key.

   If another root token generation is already in progress, the task asks whether to cancel the
   existing generation and start a new generation. To continue, enter `y`.

   The task displays the root token. Replace `<root_token>` in the following steps with this value.

1. Get the OpenBao pod name:

   ```shell
   kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1
   ```

   Replace `<openbao-pod-name>` in the following steps with the output from this command.
   For example, `pod/gitlab-openbao-5c6dfc987d-b2wtb`.

1. Verify the root token works:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao token lookup"
   ```

   A successful response includes `policies  [root]`.

1. Perform the required privileged operations.
   For example, to change an ACL policy, save the policy to a file, edit the file, and then write
   the file back to OpenBao:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao policy read <policy-name>" \
     > <policy-name>.hcl
   kubectl exec -i -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao policy write <policy-name> -" \
     < <policy-name>.hcl
   ```

   The `-i` flag passes the edited file to `bao policy write` through standard input.

1. Revoke the root token, because root tokens do not expire:

   ```shell
   kubectl exec -n gitlab <openbao-pod-name> -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao token revoke -self"
   ```

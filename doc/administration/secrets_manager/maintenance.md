---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Maintain OpenBao
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Beta

{{< /details >}}

For Geo failover, see
[Geo disaster recovery](../geo/disaster_recovery/_index.md#step-4-optional-promote-the-openbao-ha-cluster).

## Back up and restore OpenBao

OpenBao stores data in a separate logical database on PostgreSQL. Back up this database alongside your
regular GitLab backup so you can restore secrets after a failure.

For detailed backup and restore procedures specific to OpenBao, see the
[OpenBao backup documentation](https://docs.gitlab.com/charts/charts/openbao/#back-up-openbao).

## Recovery key management

For information about managing the OpenBao recovery key, including storing, viewing, and using it to
generate a root token, see [recovery key management](recovery_key.md).

## Recover OpenBao authentication

You might need to recover OpenBao authentication if the JWT `aud` (audience) claim and the stored
`bound_audiences` value drift apart.

Reconfigure authentication with a recovery key first, because it preserves stored secrets.
Reset OpenBao data only as a last resort, because it deletes all stored secrets.

### Reconfigure authentication with a recovery key

This method preserves all stored secrets, but requires a recovery key.

1. Generate a temporary root token from the recovery key. For the procedure, see
   [Generate a root token from the recovery key](recovery_key.md#generate-a-root-token-from-the-recovery-key).

1. Read the current authentication role so you have its full configuration:

   ```shell
   OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
   kubectl exec -n gitlab "$OPENBAO_POD" -c openbao-server -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao read auth/gitlab_rails_jwt/role/app"
   ```

1. Re-apply the role with the corrected `bound_audiences` and every other field from the previous
   step. On update, OpenBao resets omitted fields to their defaults, so the request must include the
   full configuration. Importantly:

   - The `role_type` field defaults to `oidc`, so you must include `role_type=jwt` or the role
     breaks.
   - The `claim_mappings` field resets to empty if omitted, which breaks authorization. Include the
     same mappings the previous step returned.

   `bound_claims` and `claim_mappings` are maps, so supply the configuration as JSON on standard
   input with `bao write <path> -`. Replace `<your-domain>` with your OpenBao domain, and replace
   the `claim_mappings` and other values with the ones the previous step returned:

   ```shell
   kubectl exec -i -n gitlab "$OPENBAO_POD" -c openbao-server -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao write auth/gitlab_rails_jwt/role/app -" <<'JSON'
   {
     "role_type": "jwt",
     "user_claim": "user_id",
     "bound_subject": "gitlab_secrets_manager",
     "bound_audiences": ["https://openbao.<your-domain>"],
     "token_policies": ["secrets_manager"],
     "bound_claims": {"secrets_manager_scope": "privileged"},
     "claim_mappings": {
       "user_id": "user_id",
       "project_id": "project_id",
       "group_id": "group_id",
       "namespace_id": "namespace_id",
       "correlation_id": "correlation_id"
     }
   }
   JSON
   ```

1. Revoke the root token. The procedure in the first step includes the revoke command.

This procedure corrects the root-level audience only. Geo failover to a secondary site with a
different domain is not supported, because it also requires re-provisioning JWT authentication for
every project and group. Instead, update DNS so the primary domain points to the promoted secondary.
For more information, see [Geo deployment](_index.md#geo-deployment).

### Reset OpenBao data

> [!warning]
> This procedure permanently deletes all secrets stored in OpenBao. Re-create all Secrets Manager
> secrets after you finish.

Reset OpenBao data when you do not have a recovery key and `bound_audiences` is out of sync with the
JWT `aud` claim, and authentication fails. A mismatch can happen when OpenBao was initialized with
the wrong URL. The reset wipes the OpenBao database so that OpenBao self-initializes with the correct
configuration.

If you have a recovery key, [reconfigure authentication with a recovery key](#reconfigure-authentication-with-a-recovery-key)
instead. That method preserves stored secrets.

Before you start, set the correct audience in your configuration:

- For GitLab 18.10 and later, set `global.openbao.jwt_audience` to the audience you want.
- For earlier versions, set the OpenBao external URL. OpenBao derives `bound_audiences` from this
  URL during self-initialization.

To reset OpenBao data:

1. Scale OpenBao to zero replicas:

   ```shell
   kubectl -n gitlab scale deployment gitlab-openbao --replicas=0
   kubectl -n gitlab rollout status deployment gitlab-openbao --timeout=60s
   ```

1. Get the toolbox pod name:

   ```shell
   kubectl -n gitlab get pods -l app=toolbox -o jsonpath='{.items[0].metadata.name}'
   ```

1. Wipe the OpenBao storage tables. Replace the placeholders with your OpenBao database password and
   host:

   ```shell
   kubectl -n gitlab exec -ti <toolbox-pod-name> -- \
     env PGPASSWORD='<openbao_database_password>' \
     psql -h <postgres_host> -U openbao -d openbao \
     -c "TRUNCATE TABLE openbao_kv_store; TRUNCATE TABLE openbao_ha_locks;"
   ```

1. Redeploy OpenBao with the corrected configuration:

   ```shell
   helm upgrade --install --version <chart-version> gitlab gitlab/gitlab \
     -n gitlab -f gitlab.yaml
   ```

1. Scale OpenBao back up. A chart redeploy does not restore a deployment that you scaled down
   manually:

   ```shell
   kubectl -n gitlab scale deployment gitlab-openbao --replicas=2
   kubectl -n gitlab rollout status deployment gitlab-openbao --timeout=120s
   ```

1. Verify that OpenBao is initialized, unsealed, and uses the correct audience:

   ```shell
   OPENBAO_POD=$(kubectl -n gitlab get pods -l app.kubernetes.io/name=openbao \
     -l openbao-active=true -o jsonpath='{.items[0].metadata.name}')
   kubectl -n gitlab exec -ti "$OPENBAO_POD" -c openbao-server -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao status"
   kubectl -n gitlab get configmap gitlab-openbao-config -o yaml | grep bound_audiences
   ```

   The status shows `Initialized   true` and `Sealed   false`, and the `bound_audiences` value
   matches the audience GitLab sends.

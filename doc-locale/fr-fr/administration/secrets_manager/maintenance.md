---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Maintenir OpenBao
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Statut : Version bêta

{{< /details >}}

Pour le basculement Geo, consultez [Reprise de Geo après sinistre](../geo/disaster_recovery/_index.md#step-4-optional-promote-the-openbao-ha-cluster).

## Sauvegarder et restaurer OpenBao {#back-up-and-restore-openbao}

OpenBao stocke les données dans une base de données logique distincte sur PostgreSQL. Sauvegardez cette base de données avec votre sauvegarde GitLab habituelle afin de pouvoir restaurer les secrets après une défaillance.

Pour des procédures détaillées de sauvegarde et de restauration spécifiques à OpenBao, consultez la [documentation de sauvegarde OpenBao](https://docs.gitlab.com/charts/charts/openbao/#back-up-openbao).

## Gestion de la clé de récupération {#recovery-key-management}

Pour des informations sur la gestion de la clé de récupération OpenBao, notamment son stockage, sa consultation et son utilisation pour générer un jeton root, consultez la [gestion de la clé de récupération](recovery_key.md).

## Récupérer l'authentification OpenBao {#recover-openbao-authentication}

Vous pourriez avoir besoin de récupérer l'authentification OpenBao si la revendication JWT `aud` (audience) et la valeur stockée `bound_audiences` divergent.

Reconfigurez l'authentification avec une clé de récupération en premier, car elle préserve les secrets stockés. Réinitialisez les données OpenBao uniquement en dernier recours, car cette opération supprime tous les secrets stockés.

### Reconfigurer l'authentification avec une clé de récupération {#reconfigure-authentication-with-a-recovery-key}

Cette méthode préserve tous les secrets stockés, mais nécessite une clé de récupération.

1. Générez un jeton root temporaire à partir de la clé de récupération. Pour la procédure, consultez [Générer un jeton root à partir de la clé de récupération](recovery_key.md#generate-a-root-token-from-the-recovery-key).

1. Lisez le rôle d'authentification actuel afin de disposer de sa configuration complète :

   ```shell
   OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
   kubectl exec -n gitlab "$OPENBAO_POD" -c openbao-server -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=<root_token> bao read auth/gitlab_rails_jwt/role/app"
   ```

1. Réappliquez le rôle avec le `bound_audiences` corrigé et tous les autres champs de l'étape précédente. Lors d'une mise à jour, OpenBao réinitialise les champs omis à leurs valeurs par défaut. La requête doit donc inclure la configuration complète. Important :

   - Le champ `role_type` est défini par défaut sur `oidc`, vous devez donc inclure `role_type=jwt` ou le rôle cessera de fonctionner.
   - Le champ `claim_mappings` est réinitialisé à vide s'il est omis, ce qui bloque l'autorisation. Incluez les mêmes mappages que ceux retournés par l'étape précédente.

   `bound_claims` et `claim_mappings` sont des maps. Fournissez donc la configuration en JSON sur l'entrée standard avec `bao write <path> -`. Remplacez `<your-domain>` par votre domaine OpenBao, et remplacez les `claim_mappings` et autres valeurs par ceux retournés à l'étape précédente :

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

1. Révoquez le jeton root. La procédure de la première étape inclut la commande de révocation.

Cette procédure corrige uniquement l'audience au niveau root. Le basculement Geo vers un site secondaire avec un domaine différent n'est pas pris en charge, car il nécessite également le re-provisionnement de l'authentification JWT pour chaque projet et groupe. Mettez plutôt à jour le DNS afin que le domaine principal pointe vers le secondaire promu. Pour plus d'informations, consultez [Déploiement Geo](_index.md#geo-deployment).

### Réinitialiser les données OpenBao {#reset-openbao-data}

> [!warning]
> Cette procédure supprime définitivement tous les secrets stockés dans OpenBao. Recréez tous les secrets du Secrets Manager une fois l'opération terminée.

Réinitialisez les données OpenBao lorsque vous ne disposez pas d'une clé de récupération et que `bound_audiences` n'est pas synchronisé avec la revendication JWT `aud`, et que l'authentification échoue. Un décalage peut survenir lorsqu'OpenBao a été initialisé avec la mauvaise URL. La réinitialisation efface la base de données OpenBao afin qu'OpenBao se réinitialise automatiquement avec la configuration correcte.

Si vous disposez d'une clé de récupération, [reconfigurez l'authentification avec une clé de récupération](#reconfigure-authentication-with-a-recovery-key) à la place. Cette méthode préserve les secrets stockés.

Avant de commencer, définissez l'audience correcte dans votre configuration :

- Pour GitLab 18.10 et versions ultérieures, définissez `global.openbao.jwt_audience` sur l'audience souhaitée.
- Pour les versions antérieures, définissez l'URL externe d'OpenBao. OpenBao dérive `bound_audiences` à partir de cette URL lors de l'auto-initialisation.

Pour réinitialiser les données OpenBao :

1. Réduisez OpenBao à zéro réplicas :

   ```shell
   kubectl -n gitlab scale deployment gitlab-openbao --replicas=0
   kubectl -n gitlab rollout status deployment gitlab-openbao --timeout=60s
   ```

1. Obtenez le nom du pod toolbox :

   ```shell
   kubectl -n gitlab get pods -l app=toolbox -o jsonpath='{.items[0].metadata.name}'
   ```

1. Effacez les tables de stockage OpenBao. Remplacez les espaces réservés par le mot de passe et l'hôte de votre base de données OpenBao :

   ```shell
   kubectl -n gitlab exec -ti <toolbox-pod-name> -- \
     env PGPASSWORD='<openbao_database_password>' \
     psql -h <postgres_host> -U openbao -d openbao \
     -c "TRUNCATE TABLE openbao_kv_store; TRUNCATE TABLE openbao_ha_locks;"
   ```

1. Redéployez OpenBao avec la configuration corrigée :

   ```shell
   helm upgrade --install --version <chart-version> gitlab gitlab/gitlab \
     -n gitlab -f gitlab.yaml
   ```

1. Faites remonter OpenBao. Un redéploiement de chart ne restaure pas un déploiement que vous avez réduit manuellement :

   ```shell
   kubectl -n gitlab scale deployment gitlab-openbao --replicas=2
   kubectl -n gitlab rollout status deployment gitlab-openbao --timeout=120s
   ```

1. Vérifiez qu'OpenBao est initialisé, non scellé et utilise l'audience correcte :

   ```shell
   OPENBAO_POD=$(kubectl -n gitlab get pods -l app.kubernetes.io/name=openbao \
     -l openbao-active=true -o jsonpath='{.items[0].metadata.name}')
   kubectl -n gitlab exec -ti "$OPENBAO_POD" -c openbao-server -- \
     sh -c "BAO_ADDR=http://127.0.0.1:8200 bao status"
   kubectl -n gitlab get configmap gitlab-openbao-config -o yaml | grep bound_audiences
   ```

   Le statut affiche `Initialized   true` et `Sealed   false`, et la valeur `bound_audiences` correspond à l'audience envoyée par GitLab.

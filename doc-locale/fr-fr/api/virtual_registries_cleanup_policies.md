---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des politiques de nettoyage des registres virtuels
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut :  Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) dans GitLab 18.6 [avec un indicateur](../administration/feature_flags/_index.md) nommé `maven_virtual_registry`. Activé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de ces endpoints est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Consultez attentivement la documentation avant de les utiliser.

Utilisez cette API pour :

- Créer et gérer des politiques de nettoyage des registres virtuels.
- Configurer des planifications de nettoyage et des paramètres de rétention.
- Nettoyer automatiquement les entrées de cache inutilisées.

## Gérer les politiques de nettoyage {#manage-cleanup-policies}

Utilisez les endpoints suivants pour créer et gérer des politiques de nettoyage des registres virtuels. Chaque groupe ne peut avoir qu'une seule politique de nettoyage.

### Récupérer la politique de nettoyage d'un groupe {#retrieve-the-cleanup-policy-for-a-group}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) dans GitLab 18.6 [avec un indicateur](../administration/feature_flags/_index.md) nommé `maven_virtual_registry`. Activé par défaut.

{{< /history >}}

Récupère la politique de nettoyage pour un groupe spécifié. Chaque groupe ne peut avoir qu'une seule politique de nettoyage.

```plaintext
GET /groups/:id/-/virtual_registries/cleanup/policy
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|:----------|:-----|:---------|:------------|
| `id` | chaîne ou entier | Oui | L'ID du groupe ou le chemin complet du groupe. Doit être un groupe principal. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

Exemple de réponse :

```json
{
  "group_id": 5,
  "next_run_at": "2024-06-06T12:28:27.855Z",
  "last_run_at": "2024-05-30T12:28:27.855Z",
  "last_run_deleted_size": 1048576,
  "last_run_deleted_entries_count": 25,
  "keep_n_days_after_download": 30,
  "status": "scheduled",
  "cadence": 7,
  "enabled": true,
  "notify_on_success": false,
  "notify_on_failure": false,
  "failure_message": null,
  "last_run_detailed_metrics": {
    "maven": {
      "deleted_entries_count": 25,
      "deleted_size": 1048576
    }
  },
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### Créer une politique de nettoyage {#create-a-cleanup-policy}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) dans GitLab 18.6 [avec un indicateur](../administration/feature_flags/_index.md) nommé `maven_virtual_registry`. Activé par défaut.

{{< /history >}}

Crée une politique de nettoyage pour un groupe spécifié. Chaque groupe ne peut avoir qu'une seule politique de nettoyage.

```plaintext
POST /groups/:id/-/virtual_registries/cleanup/policy
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | chaîne ou entier | Oui | L'ID du groupe ou le chemin complet du groupe. Doit être un groupe principal. |
| `cadence` | entier | Non | Fréquence d'exécution de la politique de nettoyage. Doit être l'une des valeurs suivantes : `1` (quotidien), `7` (hebdomadaire), `14` (bihebdomadaire), `30` (mensuel), `90` (trimestriel). |
| `enabled` | boolean | Non | Activer ou désactiver la politique de nettoyage. |
| `keep_n_days_after_download` | entier | Non | Nombre de jours après lesquels les entrées de cache inutilisées doivent être nettoyées. Doit être compris entre 1 et 365. |
| `notify_on_success` | boolean | Non | Notifier les propriétaires du groupe en cas d'exécutions de nettoyage réussies. |
| `notify_on_failure` | boolean | Non | Notifier les propriétaires du groupe en cas d'exécutions de nettoyage échouées. |

Exemple de requête :

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --header "Accept: application/json" \
     --data '{"enabled": true, "keep_n_days_after_download": 30, "cadence": 7}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

Exemple de réponse :

```json
{
  "group_id": 5,
  "next_run_at": "2024-06-06T12:28:27.855Z",
  "last_run_at": null,
  "last_run_deleted_size": 0,
  "last_run_deleted_entries_count": 0,
  "keep_n_days_after_download": 30,
  "status": "scheduled",
  "cadence": 7,
  "enabled": true,
  "notify_on_success": false,
  "notify_on_failure": false,
  "failure_message": null,
  "last_run_detailed_metrics": {},
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### Mettre à jour une politique de nettoyage {#update-a-cleanup-policy}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) dans GitLab 18.6 [avec un indicateur](../administration/feature_flags/_index.md) nommé `maven_virtual_registry`. Activé par défaut.

{{< /history >}}

Met à jour la politique de nettoyage pour un groupe spécifié.

```plaintext
PATCH /groups/:id/-/virtual_registries/cleanup/policy
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | chaîne ou entier | Oui | L'ID du groupe ou le chemin complet du groupe. Doit être un groupe principal. |
| `cadence` | entier | Non | Fréquence d'exécution de la politique de nettoyage. Doit être l'une des valeurs suivantes : `1` (quotidien), `7` (hebdomadaire), `14` (bihebdomadaire), `30` (mensuel), `90` (trimestriel). |
| `enabled` | boolean | Non | Booléen pour activer/désactiver la politique. |
| `keep_n_days_after_download` | entier | Non | Nombre de jours après lesquels les entrées de cache inutilisées doivent être nettoyées. Doit être compris entre 1 et 365. |
| `notify_on_success` | boolean | Non | Notifier les propriétaires du groupe en cas d'exécutions de nettoyage réussies. |
| `notify_on_failure` | boolean | Non | Notifier les propriétaires du groupe en cas d'exécutions de nettoyage échouées. |

> [!note]
> Vous devez fournir au moins l'un des paramètres optionnels dans votre requête.

Exemple de requête :

```shell
curl --request PATCH \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"keep_n_days_after_download": 60}' \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

Exemple de réponse :

```json
{
  "group_id": 5,
  "next_run_at": "2024-06-06T12:28:27.855Z",
  "last_run_at": "2024-05-30T12:28:27.855Z",
  "last_run_deleted_size": 1048576,
  "last_run_deleted_entries_count": 25,
  "keep_n_days_after_download": 60,
  "status": "scheduled",
  "cadence": 7,
  "enabled": true,
  "notify_on_success": false,
  "notify_on_failure": false,
  "failure_message": null,
  "last_run_detailed_metrics": {
    "maven": {
      "deleted_entries_count": 25,
      "deleted_size": 1048576
    }
  },
  "created_at": "2024-05-30T12:28:27.855Z",
  "updated_at": "2024-05-30T12:28:27.855Z"
}
```

### Supprimer une politique de nettoyage {#delete-a-cleanup-policy}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/572839) dans GitLab 18.6 [avec un indicateur](../administration/feature_flags/_index.md) nommé `maven_virtual_registry`. Activé par défaut.

{{< /history >}}

Supprime la politique de nettoyage pour un groupe spécifié.

```plaintext
DELETE /groups/:id/-/virtual_registries/cleanup/policy
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | chaîne ou entier | Oui | L'ID du groupe ou le chemin complet du groupe. Doit être un groupe principal. |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Accept: application/json" \
     --url "https://gitlab.example.com/api/v4/groups/5/-/virtual_registries/cleanup/policy"
```

En cas de succès, renvoie un code de statut [`204 No Content`](rest/troubleshooting.md#status-codes).

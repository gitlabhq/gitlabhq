---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des contrôles externes
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez l'API des contrôles externes pour définir le statut d'une vérification qui utilise un service externe.

Vous pouvez configurer des contrôles externes avec une fonctionnalité de ping périodique. Lorsque le ping est activé (par défaut), GitLab réinitialise automatiquement le statut du contrôle à `pending` toutes les 12 heures. Lorsque le ping est désactivé, le statut du contrôle est mis à jour uniquement via des appels API.

## Définir le statut d'un contrôle externe {#set-status-of-an-external-control}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/13658) dans GitLab 17.11.

{{< /history >}}

Définit le statut d'un contrôle externe spécifié. Utilisez cette opération pour informer GitLab qu'un contrôle a réussi ou échoué une vérification par un service externe.

Prérequis

- Doit utiliser l'authentification HMAC, Timestamp et Nonce pour la sécurité.

```plaintext
PATCH /api/v4/projects/:id/compliance_external_controls/:external_control_id/status
```

En-têtes HTTP :

| En-tête                |  Type   | Obligatoire | Description                                                                                   |
| --------------------- | ------- | -------- | --------------------------------------------------------------------------------------------- |
| `X-Gitlab-Timestamp`  | string  | oui      | Horodatage Unix actuel.                                                                       |
| `X-Gitlab-Nonce`      | string  | oui      | Chaîne ou jeton aléatoire pour prévenir les attaques par rejeu.                                             |
| `X-Gitlab-Hmac-Sha256`| string  | oui      | Signature HMAC-SHA256 de la requête.                                                         |

Pour calculer la signature HMAC-SHA256 :

1. Concaténez ces valeurs dans l'ordre suivant :
   - `X-Gitlab-Timestamp`
   - `X-Gitlab-Nonce`
   - Le chemin complet de la requête
   - La valeur de l'attribut `status`, formatée comme `status=<status>`
1. Calculez le HMAC-SHA256 de la chaîne concaténée à l'aide de votre clé secrète.

Attributs pris en charge :

| Attribut                | Type    | Obligatoire | Description                                                                                       |
| ------------------------ | ------- | -------- |---------------------------------------------------------------------------------------------------|
| `id`                     | integer | oui      | ID d'un projet.                                                                                  |
| `external_control_id`    | integer | oui      | ID d'un contrôle externe.                                                                        |
| `status`                 | string  | oui      | Définissez sur `pass` pour marquer le contrôle comme réussi, ou sur `fail` pour le faire échouer.                                |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                | Type     | Description                                   |
|--------------------------|----------|-----------------------------------------------|
| `status`                 | string   | Le statut qui a été défini pour le contrôle. |

Exemple de requête :

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "X-Gitlab-Timestamp: <X-Gitlab-Timestamp>" \
  --header "X-Gitlab-Nonce: <X-Gitlab-Nonce>" \
  --header "X-Gitlab-Hmac-Sha256: <X-Gitlab-Hmac-Sha256>" \
  --header "Content-Type: application/json" \
  --data '{"status": "pass"}' \
  --url "https://gitlab.example.com/api/v4/projects/<id>/compliance_external_controls/<external_control_id>/status"
```

Exemple de réponse :

```json
{
    "status":"pass"
}
```

## Sujets connexes {#related-topics}

- [Frameworks de conformité](../user/compliance/compliance_frameworks/_index.md)

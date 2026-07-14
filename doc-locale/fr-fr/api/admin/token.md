---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST qui expose les informations sur les jetons."
title: "API d'informations sur les jetons"
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed
- Statut :  Expérience

{{< /details >}}

Utilisez cette API pour récupérer des détails sur des jetons arbitraires et pour les révoquer. Contrairement à d'autres API qui exposent les informations sur les jetons, cette API vous permet de récupérer des détails ou de révoquer des jetons sans connaître le type spécifique du jeton.

## Préfixes de jetons {#token-prefixes}

Lors d'une requête, les jetons `personal`, `project` ou `group access` doivent commencer par `glpat` ou le [préfixe personnalisé](../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix) actuel. Si le jeton commence par un préfixe personnalisé précédent, l'opération échoue. L'intérêt pour la prise en charge des préfixes personnalisés précédents est suivi dans le [ticket 165663](https://gitlab.com/gitlab-org/gitlab/-/issues/165663).

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

## Récupérer les informations sur un jeton {#retrieve-token-information}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165157) dans GitLab 17.5 [avec un flag](../../administration/feature_flags/_index.md) nommé `admin_agnostic_token_finder`. Désactivé par défaut.
- [Disponible de façon générale](https://gitlab.com/gitlab-org/gitlab/-/issues/490572) dans GitLab 17.8. L'indicateur de fonctionnalité `admin_agnostic_token_finder` a été supprimé.
- [Jetons de flux ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169821) dans GitLab 17.6.
- [Secrets d'application OAuth ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172985) dans GitLab 17.7.
- [Jetons d'agent de cluster ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172932) dans GitLab 17.7.
- [Jetons d'authentification de runner ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173987) dans GitLab 17.7.
- [Jetons de déclenchement de pipeline ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174030) dans GitLab 17.7.
- [Jetons de job CI/CD ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175234) dans GitLab 17.9.
- [Jetons clients de feature flag ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177431) dans GitLab 17.9.
- [Cookies de session GitLab ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178022) dans GitLab 17.9.
- [Jetons d'e-mail entrant ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177077) dans GitLab 17.9.

{{< /history >}}

Récupère les informations d'un jeton spécifié. Cet endpoint prend en charge les jetons suivants :

- [Jetons d'accès personnels](../../user/profile/personal_access_tokens.md)
- [Jetons d'emprunt d'identité](../rest/authentication.md#impersonation-tokens)
- [Jetons de déploiement](../../user/project/deploy_tokens/_index.md)
- [Jetons de flux](../../security/tokens/_index.md#feed-token)
- [Secrets d'application OAuth](../../integration/oauth_provider.md)
- [Jetons d'agent de cluster](../../security/tokens/_index.md#gitlab-cluster-agent-tokens)
- [Jetons d'authentification de runner](../../security/tokens/_index.md#runner-authentication-tokens)
- [Jetons de déclenchement de pipeline](../../ci/triggers/_index.md#create-a-pipeline-trigger-token)
- [Jetons de job CI/CD](../../security/tokens/_index.md#cicd-job-tokens)
- [Jetons clients de feature flag](../../operations/feature_flags.md#get-access-credentials)
- [Cookies de session GitLab](../../user/profile/active_sessions.md)
- [Jetons d'e-mail entrant](../../security/tokens/_index.md#incoming-email-token)

```plaintext
POST /api/v4/admin/token
```

Attributs pris en charge :

| Attribut    | Type    | Obligatoire | Description                |
|--------------|---------|----------|----------------------------|
| `token`      | string  | Oui      | Jeton existant à identifier. Les jetons `Personal`, `project` ou `group access` doivent commencer par `glpat` ou le [préfixe personnalisé](../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix) actuel. |

En cas de succès, renvoie [`200`](../rest/troubleshooting.md#status-codes) et des informations sur le jeton.

Peut renvoyer les codes de statut suivants :

- `200 OK` :  Informations sur le jeton.
- `401 Unauthorized` :  L'utilisateur n'est pas autorisé.
- `403 Forbidden` :  L'utilisateur n'est pas un administrateur.
- `404 Not Found` :  Le jeton est introuvable.
- `422 Unprocessable` :  Le type de jeton n'est pas pris en charge.

Exemple de requête :

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/admin/token" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"token": "glpat-<example-token>"}'
```

Exemple de réponse :

```json
{
 "id": 1,
 "user_id": 70,
 "name": "project-access-token",
 "revoked": false,
 "expires_at": "2024-10-04",
 "created_at": "2024-09-04T07:19:18.652Z",
 "updated_at": "2024-09-04T07:19:18.652Z",
 "scopes": [
  "api",
  "read_api"
 ],
 "impersonation": false,
 "expire_notification_delivered": false,
 "last_used_at": null,
 "after_expiry_notification_delivered": false,
 "previous_personal_access_token_id": null,
 "advanced_scopes": null,
 "organization_id": 1
}
```

## Révoquer un jeton {#revoke-a-token}

{{< history >}}

- [Jetons d'agent de cluster ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178211) dans GitLab 17.9.
- [Jetons d'authentification de runner ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179066) dans GitLab 17.9.
- [Secrets d'application OAuth ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179035) dans GitLab 17.9.
- [Jetons d'e-mail entrant ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180763) dans GitLab 17.9.
- [Jetons clients de feature flag ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181096) dans GitLab 17.9.
- [Jetons de déclenchement de pipeline ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181598) dans GitLab 17.10 [avec un flag](../../administration/feature_flags/_index.md) nommé `token_api_expire_pipeline_triggers`. Désactivé par défaut.
- [Sessions GitLab ajoutées](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184047) dans GitLab 17.11.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

Révoque, réinitialise ou supprime un jeton spécifié en fonction du type de jeton. Cet endpoint prend en charge les types de jetons suivants :

| Type de jeton                                                                                   | Action prise en charge   |
|----------------------------------------------------------------------------------------------|--------------------|
| [Jetons d'accès personnels](../../user/profile/personal_access_tokens.md)                       | Révoquer             |
| [Jetons d'emprunt d'identité](../../user/profile/personal_access_tokens.md)                         | Révoquer             |
| [Jetons d'accès au projet](../../security/tokens/_index.md#project-access-tokens)               | Révoquer             |
| [Jetons d'accès de groupe](../../security/tokens/_index.md#group-access-tokens)                   | Révoquer             |
| [Jetons de déploiement](../../user/project/deploy_tokens/_index.md)                                   | Révoquer             |
| [Jetons d'agent de cluster](../../security/tokens/_index.md#gitlab-cluster-agent-tokens)          | Révoquer             |
| [Jetons de déclenchement de pipeline](../../ci/triggers/_index.md#create-a-pipeline-trigger-token)       | Révoquer             |
| [Jetons de flux](../../security/tokens/_index.md#feed-token)                                    | Réinitialiser              |
| [Jetons d'authentification de runner](../../security/tokens/_index.md#runner-authentication-tokens) | Réinitialiser              |
| [Secrets d'application OAuth](../../integration/oauth_provider.md)                             | Réinitialiser              |
| [Jetons d'e-mail entrant](../../security/tokens/_index.md#incoming-email-token)                | Réinitialiser              |
| [Jetons clients de feature flag](../../operations/feature_flags.md#get-access-credentials)      | Réinitialiser              |
| [Cookies de session GitLab](../../user/profile/active_sessions.md)                              | Supprimer             |

```plaintext
DELETE /api/v4/admin/token
```

Attributs pris en charge :

| Attribut    | Type    | Obligatoire | Description              |
|--------------|---------|----------|--------------------------|
| `token`      | string  | Oui      | Jeton existant à révoquer. Les jetons `Personal`, `project` ou `group access` doivent commencer par `glpat` ou le [préfixe personnalisé](../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix) actuel. |

En cas de succès, renvoie [`204`](../rest/troubleshooting.md#status-codes) sans contenu.

Peut renvoyer les codes de statut suivants :

- `204 No content` :  Le jeton a été révoqué.
- `401 Unauthorized` :  L'utilisateur n'est pas autorisé.
- `403 Forbidden` :  L'utilisateur n'est pas un administrateur.
- `404 Not Found` :  Le jeton est introuvable.
- `422 Unprocessable` :  Le type de jeton n'est pas pris en charge.

Exemple de requête :

```shell
curl --request DELETE \
  --url "https://gitlab.example.com/api/v4/admin/token" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"token": "glpat-<example-token>"}'
```

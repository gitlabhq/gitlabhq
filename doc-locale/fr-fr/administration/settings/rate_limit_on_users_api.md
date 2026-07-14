---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Limites de débit sur l'API Users"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Les limites de débit pour l'API Users ont été [introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/452349) dans GitLab 17.1 avec un [flag](../feature_flags/_index.md) nommé `rate_limiting_user_endpoints`. Désactivé par défaut.
- [Ajout](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) de limites de débit personnalisables dans GitLab 17.10.
- [Disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/524831) dans GitLab 18.1. Indicateur de feature flag `rate_limiting_user_endpoints` supprimé.

{{< /history >}}

> [!note]
> Lors de la mise à niveau vers GitLab 18.0 ou une version ultérieure, les limites de débit configurables pour cette API sont définies sur `0`. Les administrateurs peuvent ajuster les limites de débit selon leurs besoins. Pour savoir quelles limites de débit sont concernées, consultez [Rate limitations announced for Projects, Groups, and Users APIs](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/#rate-limitation-details).

Vous pouvez configurer la limite de débit par minute et par adresse IP et par utilisateur pour les requêtes vers l'[API Users](../../api/users.md) suivante.

| Limite                                                           | Valeur par défaut |
|-----------------------------------------------------------------|---------|
| [`GET /users/:id/followers`](../../api/user_follow_unfollow.md#list-all-accounts-that-follow-a-user) | 100 par minute |
| [`GET /users/:id/following`](../../api/user_follow_unfollow.md#list-all-accounts-followed-by-a-user) | 100 par minute |
| [`GET /users/:id/status`](../../api/users.md#retrieve-the-status-of-a-user)                               | 240 par minute |
| [`GET /users/:id/keys`](../../api/user_keys.md#list-all-ssh-keys-for-a-user)                         | 120 par minute |
| [`GET /users/:id/keys/:key_id`](../../api/user_keys.md#retrieve-an-ssh-key-for-a-user)                               | 120 par minute |
| [`GET /users/:id/gpg_keys`](../../api/user_keys.md#list-all-gpg-keys-for-a-user)                     | 120 par minute |
| [`GET /users/:id/gpg_keys/:key_id`](../../api/user_keys.md#retrieve-a-gpg-key-for-a-user)                 | 120 par minute |

Prérequis :

- Accès administrateur.

Pour modifier la limite de débit :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Users API rate limit**.
1. Définissez des valeurs pour toute limite de débit disponible. Les limites de débit sont par minute, par utilisateur pour les requêtes authentifiées et par adresse IP pour les requêtes non authentifiées. Saisissez `0` pour désactiver une limite de débit.
1. Sélectionnez **Sauvegarder les modifications**.

Chaque limite de débit :

- S'applique par utilisateur si la requête est authentifiée.
- S'applique par adresse IP si la requête n'est pas authentifiée.
- Peut être définie sur `0` pour désactiver les limites de débit.

Journaux :

- Les requêtes qui dépassent la limite de débit sont consignées dans le fichier `auth.log`.
- Les modifications de limite de débit sont consignées dans le fichier `audit_json.log`.

Exemple :

Si vous définissez une limite de débit de 150 pour `GET /users/:id/followers` et envoyez 155 requêtes en une minute, les cinq dernières requêtes sont bloquées. Après une minute, vous pouvez continuer à envoyer des requêtes jusqu'à ce que vous dépassiez à nouveau la limite de débit.

---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurer des limites de débit sur les requêtes HTTP Git vers GitLab Self-Managed.
title: Limites de débit sur HTTP Git
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147112) dans GitLab 17.0.

{{< /history >}}

Si vous utilisez HTTP Git dans votre dépôt, les opérations Git courantes peuvent générer de nombreuses requêtes HTTP Git. GitLab peut appliquer des limites de débit sur les requêtes HTTP Git authentifiées et non authentifiées pour améliorer la sécurité et la durabilité de votre application web.

> [!note]
> [Les limites de débit générales des utilisateurs et des adresses IP](user_and_ip_rate_limits.md) ne s'appliquent pas aux requêtes HTTP Git.

## Prérequis {#prerequisites}

Vous devez disposer d'un accès administrateur.

## Configurer les limites de débit HTTP Git non authentifiées {#configure-unauthenticated-git-http-rate-limits}

GitLab désactive par défaut les limites de débit sur les requêtes HTTP Git non authentifiées.

Pour appliquer des limites de débit aux requêtes HTTP Git qui ne contiennent pas de paramètres d'authentification, activez et configurez ces limites :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Limites de débit HTTP Git**.
1. Sélectionnez **Activer la limite de débit des requêtes HTTP Git non authentifiées**.
1. Saisissez une valeur pour **Max unauthenticated Git HTTP requests per period per user**.
1. Saisissez une valeur pour **Limite de débit des requêtes HTTP Git non authentifiées en secondes**.
1. Sélectionnez **Sauvegarder les modifications**.

## Configurer les limites de débit HTTP Git authentifiées {#configure-authenticated-git-http-rate-limits}

{{< history >}}

- Les limites de débit HTTP Git authentifiées [introduites](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191552) dans GitLab 18.1 [avec un indicateur](../feature_flags/_index.md) nommé `git_authenticated_http_limit`. Désactivé par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/543768) dans GitLab 18.3.
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/issues/561577) dans GitLab 18.4. Indicateur de feature flag `git_authenticated_http_limit` supprimé.

{{< /history >}}

GitLab désactive par défaut les limites de débit sur les requêtes HTTP Git authentifiées.

Pour appliquer des limites de débit aux requêtes HTTP Git qui contiennent des paramètres d'authentification, activez et configurez ces limites :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Limites de débit HTTP Git**.
1. Sélectionnez **Activer la limite de débit des requêtes HTTP Git authentifiées**.
1. Saisissez une valeur pour **Max authenticated Git HTTP requests per period per user**.
1. Saisissez une valeur pour **Limite de débit des requêtes HTTP Git authentifiées en secondes**.
1. Sélectionnez **Sauvegarder les modifications**.

Si nécessaire, vous pouvez [autoriser des utilisateurs spécifiques à contourner la limite de débit des requêtes authentifiées](user_and_ip_rate_limits.md#allow-specific-users-to-bypass-authenticated-request-rate-limiting).

## Sur GitLab.com {#on-gitlabcom}

Sur GitLab.com, les requêtes HTTP Git sont soumises aux [limites de débit des requêtes Git HTTPS](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom) :

- 10 000 requêtes par minute pour un utilisateur authentifié.
- 15 000 requêtes par minute depuis une adresse IP non authentifiée.

## Sujets connexes {#related-topics}

- [Limitation de débit](../../security/rate_limits.md)
- [Limites de débit des utilisateurs et des adresses IP](user_and_ip_rate_limits.md)

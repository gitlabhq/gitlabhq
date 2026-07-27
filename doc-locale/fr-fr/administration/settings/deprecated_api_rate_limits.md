---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Définir des limites de débit pour les API obsolètes sur GitLab.
gitlab_dedicated: yes
title: Limites de débit des API obsolètes
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les points de terminaison d'API obsolètes ont été remplacés par des fonctionnalités alternatives, mais ils ne peuvent pas être supprimés sans rompre la compatibilité ascendante. Pour encourager les utilisateurs à passer à l'alternative, définissez une limite de débit restrictive sur les points de terminaison obsolètes.

## Points de terminaison d'API obsolètes {#deprecated-api-endpoints}

Cette limite de débit n'inclut pas tous les points de terminaison d'API obsolètes, seulement ceux susceptibles d'affecter les performances :

- [`GET /groups/:id`](../../api/groups.md#retrieve-a-group) sans le paramètre de requête `with_projects=0`.

## Définir des limites de débit des API obsolètes {#define-deprecated-api-rate-limits}

Les limites de débit pour les points de terminaison d'API obsolètes sont désactivées par défaut. Lorsqu'elles sont activées, elles remplacent les limites de débit générales pour les utilisateurs et les adresses IP pour les requêtes vers les points de terminaison obsolètes. Vous pouvez conserver toutes les limites de débit générales pour les utilisateurs et les adresses IP déjà en place, et augmenter ou diminuer les limites de débit pour les points de terminaison d'API obsolètes. Aucune autre nouvelle fonctionnalité n'est fournie par cette substitution.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour remplacer les limites de débit générales pour les utilisateurs et les adresses IP pour les requêtes vers les points de terminaison d'API obsolètes :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Deprecated API Rate Limits**.
1. Cochez les cases correspondant aux types de limites de débit que vous souhaitez activer :
   - **Unauthenticated API request rate limit**
   - **Authenticated API request rate limit**
1. Si vous avez sélectionné **unauthenticated** :
   1. Sélectionnez le **Maximum unauthenticated API requests per period per IP**.
   1. Sélectionnez la **Durée de la limitation de fréquence des requêtes d'API non authentifiées en secondes**.
1. Si vous avez sélectionné **authenticated** :
   1. Sélectionnez le **Maximum authenticated API requests per period per user**.
   1. Sélectionnez la **Limitation de fréquence des requêtes d'API authentifiées en secondes**.

## Sujets connexes {#related-topics}

- [Limites de débit](../../security/rate_limits.md)
- [Limites de débit pour les utilisateurs et les adresses IP](user_and_ip_rate_limits.md)

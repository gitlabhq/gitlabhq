---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: "Configurer les limites de débit pour l'API de fichiers du dépôt."
title: "Limites de débit sur l'API de fichiers du dépôt"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

L'[API de fichiers du dépôt](../../api/repository_files.md) vous permet de récupérer, créer, mettre à jour et supprimer des fichiers dans votre dépôt. Pour améliorer la sécurité et la durabilité de votre application web, vous pouvez appliquer des [limites de débit](../../security/rate_limits.md) sur cette API. Toutes les limites de débit que vous créez pour l'API de fichiers remplacent les [limites de débit générales par utilisateur et par IP](user_and_ip_rate_limits.md).

## Définir les limites de débit de l'API de fichiers {#define-files-api-rate-limits}

Les limites de débit pour l'API de fichiers sont désactivées par défaut. Lorsqu'elles sont activées, elles remplacent les limites de débit générales par utilisateur et par IP pour les requêtes adressées à l'[API de fichiers du dépôt](../../api/repository_files.md). Vous pouvez conserver les limites de débit générales par utilisateur et par IP déjà en place, et augmenter ou diminuer les limites de débit pour l'API de fichiers. Aucune autre nouvelle fonctionnalité n'est fournie par ce remplacement.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

Pour remplacer les limites de débit générales par utilisateur et par IP pour les requêtes adressées à l'API de fichiers du dépôt :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Files API Rate Limits**.
1. Cochez les cases correspondant aux types de limites de débit que vous souhaitez activer :
   - **Unauthenticated API request rate limit**
   - **Authenticated API request rate limit**
1. Si vous avez sélectionné **unauthenticated** :
   1. Sélectionnez le **Max unauthenticated API requests per period per IP**.
   1. Sélectionnez la **Durée de la limitation de fréquence des requêtes d'API non authentifiées en secondes**.
1. Si vous avez sélectionné **authenticated** :
   1. Sélectionnez le **Max authenticated API requests per period per user**.
   1. Sélectionnez la **Limitation de fréquence des requêtes d'API authentifiées en secondes**.

## Sujets connexes {#related-topics}

- [Limites de débit](../../security/rate_limits.md)
- [API de fichiers du dépôt](../../api/repository_files.md)
- [Limites de débit par utilisateur et par IP](user_and_ip_rate_limits.md)

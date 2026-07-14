---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: Configurer les limites de débit pour Git LFS sur GitLab.
title: Limites de débit sur Git LFS
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Git Large File Storage (LFS)](../../topics/git/lfs/_index.md) est une extension Git pour la gestion des fichiers volumineux. Si vous utilisez Git LFS dans votre dépôt, les opérations Git courantes peuvent générer de nombreuses requêtes Git LFS. Vous pouvez appliquer des [limites de débit générales pour les utilisateurs et les adresses IP](user_and_ip_rate_limits.md), mais vous pouvez également remplacer le paramètre général pour appliquer des limites supplémentaires aux requêtes Git LFS. Ce remplacement peut améliorer la sécurité et la durabilité de votre application web.

## Sur GitLab.com {#on-gitlabcom}

Sur GitLab.com, les requêtes Git LFS sont soumises aux [limites de débit des requêtes web authentifiées](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom). Ces limites sont définies à 1 000 requêtes par minute et par utilisateur.

Chaque objet Git LFS téléversé ou téléchargé génère une requête HTTP qui est comptabilisée dans cette limite.

> [!note]
> Les projets contenant plusieurs fichiers volumineux peuvent rencontrer une erreur de limite de débit HTTP. Cette erreur se produit lors d'un clonage ou d'un tirage, lorsqu'ils sont effectués depuis une seule adresse IP dans des environnements automatisés tels que les pipelines CI/CD.

## Sur GitLab Self-Managed {#on-gitlab-self-managed}

Les limites de débit Git LFS sont désactivées par défaut sur les instances GitLab Self-Managed. Les administrateurs peuvent configurer des limites de débit dédiées spécifiquement pour le trafic Git LFS. Lorsqu'elles sont activées, ces limites de débit LFS dédiées remplacent les [limites de débit par défaut pour les utilisateurs et les adresses IP](user_and_ip_rate_limits.md).

### Configurer les limites de débit Git LFS {#configure-git-lfs-rate-limits}

Prérequis :

- Vous devez être administrateur de l'instance.

Pour configurer les limites de débit Git LFS :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Git LFS Rate Limits**.
1. Sélectionnez **Activer la limite de fréquence des requêtes Git LFS authentifiées**.
1. Saisissez une valeur pour **Nombre maximal de requêtes Git LFS authentifiées par période et par utilisateur**.
1. Saisissez une valeur pour **Durée de la limitation des requêtes Git LFS authentifiées en secondes**.
1. Sélectionnez **Sauvegarder les modifications**.

## Sujets connexes {#related-topics}

- [Limitation de débit](../../security/rate_limits.md)
- [Limites de débit pour les utilisateurs et les adresses IP](user_and_ip_rate_limits.md)

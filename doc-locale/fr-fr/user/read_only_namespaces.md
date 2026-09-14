---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Espaces de nommage et projets en lecture seule
---

## Espaces de nommage en lecture seule {#read-only-namespaces}

{{< details >}}

- Édition : Gratuite
- Offre : GitLab.com

{{< /details >}}

Un espace de nommage est placé en état de lecture seule lorsqu'il dépasse la [limite du nombre d'utilisateurs gratuits](free_user_limit.md) et lorsque la visibilité de l'espace de nommage est privée.

Pour supprimer l'état de lecture seule d'un espace de nommage et de ses projets, vous pouvez :

- [Réduire le nombre de membres](free_user_limit.md#manage-members-in-your-group-namespace) dans votre espace de nommage.
- [Démarrer un essai gratuit](https://gitlab.com/-/trial_registrations/new), qui inclut un nombre illimité de membres.
- [Acheter une édition payante](https://about.gitlab.com/pricing/).

### Actions restreintes {#restricted-actions}

Lorsqu'un espace de nommage est en état de lecture seule, vous ne pouvez pas exécuter les actions répertoriées dans le tableau suivant. Si vous essayez d'exécuter une action restreinte, vous pourriez obtenir une erreur `404`.

| Fonctionnalité | Action restreinte |
|---------|-------------------|
| Registre de conteneurs | Créer, modifier et supprimer des politiques de nettoyage. <br> Envoyer une image vers le registre de conteneurs. |
| Les merge requests | Créer et mettre à jour une merge request. |
| Registre de paquets | Publier un package. |
| CI/CD | Créer, modifier, administrer et exécuter des pipelines. <br>  Créer, modifier, administrer et exécuter des builds. <br>  Créer et modifier des environnements d'administration. <br> Créer et modifier des déploiements d'administration. <br>  Créer et modifier des clusters d'administration. <br> Créer et modifier des releases d'administration. |
| Espaces de nommage | **En cas de dépassement des limites d'utilisateurs gratuites** : inviter de nouveaux utilisateurs. |

## Projets en lecture seule {#read-only-projects}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate

{{< /details >}}

Un projet est placé en état de lecture seule lorsqu'il dépasse la limite de stockage allouée sur :

- L'édition Gratuite, lorsqu'un projet de l'espace de nommage dépasse la [limite gratuite](storage_usage_quotas.md#free-limit).
- Les éditions GitLab Premium et GitLab Ultimate, lorsqu'un projet de l'espace de nommage dépasse la [limite fixe du projet](storage_usage_quotas.md#fixed-project-limit).

### Actions restreintes {#restricted-actions-1}

Lorsqu'un projet est en lecture seule en raison de limites de stockage, vous ne pouvez pas envoyer vers le dépôt du projet ou y ajouter de fichiers volumineux (LFS). Une bannière en haut de la page du projet ou de l'espace de nommage indique le statut de lecture seule.

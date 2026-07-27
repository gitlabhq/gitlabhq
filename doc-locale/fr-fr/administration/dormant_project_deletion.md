---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Suppression des projets inactifs
description: Configurer la suppression des projets inactifs.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689) dans GitLab 15.0 [avec un flag](feature_flags/_index.md) nommé `inactive_projects_deletion`. Désactivé par défaut.
- [Feature flag `inactive_projects_deletion`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96803) supprimé dans GitLab 15.4.
- Configuration via l'interface utilisateur GitLab [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85575) dans GitLab 15.1.
- [Renommé](https://gitlab.com/gitlab-org/gitlab/-/work_items/533275) depuis la suppression de projet inactif dans GitLab 18.1.

{{< /history >}}

Au fil du temps, les projets dans les grandes instances GitLab peuvent devenir inactifs et utiliser de l'espace disque inutile.

Vous pouvez configurer GitLab pour supprimer automatiquement les projets inactifs après une période d'inactivité spécifique. Lorsqu'un projet n'a aucune activité dans cette période définie :

- Les responsables reçoivent des notifications les avertissant de la suppression planifiée.
- Si aucune activité ne se produit dans le projet, GitLab le supprime à l'expiration du délai.
- Lorsque la suppression se produit, GitLab génère un événement d'audit indiquant que @GitLab-Admin-Bot a effectué la suppression.

Pour le paramètre par défaut sur GitLab.com, consultez [les paramètres de GitLab.com](../user/gitlab_com/_index.md#dormant-project-deletion).

## Configurer la suppression des projets inactifs {#configure-dormant-project-deletion}

Prérequis :

- Accès administrateur.

Pour configurer la suppression des projets inactifs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Dépôt**.
1. Développez **Maintenance du dépôt**.
1. Dans la section **Suppression des projets inactifs**, sélectionnez **Supprimer les projets inactifs**.
1. Configurez les paramètres.
   - L'e-mail d'avertissement est envoyé aux utilisateurs ayant le rôle Propriétaire et Responsable pour le projet inactif.
   - La durée de l'e-mail doit être inférieure à la durée de **Supprimer le projet après**.
1. Sélectionnez **Sauvegarder les modifications**.

Les projets inactifs qui remplissent les critères sont programmés pour la suppression et un e-mail d'avertissement est envoyé. Si les projets restent inactifs, ils sont supprimés après la durée spécifiée. Ces projets sont supprimés même si [le projet est archivé](../user/project/working_with_projects.md#archive-a-project).

### Exemple de configuration {#configuration-example}

#### Exemple 1 {#example-1}

Si vous utilisez ces paramètres :

- **Supprimer les projets inactifs** activé.
- **Supprimer les projets inactifs qui dépassent** défini sur `50`.
- **Supprimer le projet après** défini sur `12`.
- **Envoyer un courriel d'avertissement** défini sur `6`.

Si un projet fait moins de 50 Mo, il n'est pas considéré comme inactif.

Si un projet fait plus de 50 Mo et qu'il est inactif depuis :

- Plus de 6 mois : Un e-mail d'avertissement de suppression est envoyé. Cet e-mail inclut la date à laquelle le projet sera programmé pour la suppression.
- Plus de 12 mois : Le projet est programmé pour la suppression.

#### Exemple 2 {#example-2}

Si vous utilisez ces paramètres :

- **Supprimer les projets inactifs** activé.
- **Supprimer les projets inactifs qui dépassent** défini sur `0`.
- **Supprimer le projet après** défini sur `12`.
- **Envoyer un courriel d'avertissement** défini sur `11`.

Étant donné que la limite de taille a été définie sur 0 Mo, tous les projets d'une instance sont concernés. Si un projet est inactif depuis :

- Plus de 11 mois : Un e-mail d'avertissement de suppression est envoyé. Cet e-mail inclut la date à laquelle le projet sera programmé pour la suppression.
- Plus de 12 mois : Le projet est programmé pour la suppression.

Si un projet existe et qu'il est déjà inactif depuis plus de 12 mois lorsque vous configurez ces paramètres :

- Un e-mail d'avertissement de suppression est envoyé immédiatement. Cet e-mail inclut la date à laquelle le projet sera programmé pour la suppression.
- Le projet est programmé pour la suppression 1 mois (12 mois - 11 mois) après l'envoi de l'e-mail d'avertissement.

## Déterminer quand un projet a été actif pour la dernière fois {#determine-when-a-project-was-last-active}

Vous pouvez consulter les activités d'un projet et déterminer quand le projet a été actif pour la dernière fois de plusieurs façons :

- Accédez à la [page d'activité](../user/project/working_with_projects.md#view-project-activity) du projet et consultez la date du dernier événement.
- Consultez l'attribut `last_activity_at` du projet à l'aide de l'[API Projects](../api/projects.md).
- Répertoriez les événements visibles du projet à l'aide de l'[API Events](../api/events.md#list-all-visible-events-for-a-project). Consultez l'attribut `created_at` du dernier événement.

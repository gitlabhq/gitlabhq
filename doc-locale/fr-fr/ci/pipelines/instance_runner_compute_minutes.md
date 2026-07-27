---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Minutes de calcul, achats, suivi de l'utilisation et gestion des quotas pour les runners d'instance sur GitLab.com et GitLab Self-Managed."
title: "Utilisation du calcul pour les runners d'instance"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

La quantité de minutes de calcul que les projets peuvent consommer pour exécuter des jobs sur les runners d'instance gérés par l'administrateur est limitée [runners d'instance](../runners/runners_scope.md#instance-runners). Cette limite est suivie à l'aide d'un quota de calcul du runner d'instance sur le serveur GitLab. Lorsqu'un espace de nommage dépasse le quota, le [quota est appliqué](#enforcement).

Les runners d'instance gérés par l'administrateur sont ceux [gérés par l'administrateur de l'instance GitLab](../../administration/cicd/compute_minutes.md).

> [!note]
> Sur GitLab.com, les runners d'instance sont à la fois gérés par l'administrateur et hébergés par GitLab, car l'instance est gérée par GitLab.

## Application du quota de calcul {#compute-quota-enforcement}

### Réinitialisation mensuelle {#monthly-reset}

L'utilisation des minutes de calcul est réinitialisée à `0` chaque mois. Le quota de calcul est [réinitialisé à l'allocation mensuelle](https://about.gitlab.com/pricing/).

Par exemple, si vous disposez d'un quota mensuel de 10 000 minutes de calcul :

1. Le 1er avril, vous disposez de 10 000 minutes de calcul.
1. Au cours du mois d'avril, vous utilisez 6 000 des 10 000 minutes de calcul disponibles dans le quota.
1. Le 1er mai, l'utilisation cumulée du calcul est réinitialisée à 0, et vous disposez de 10 000 minutes de calcul pour le mois de mai.

Les données d'utilisation du mois précédent sont conservées afin d'afficher un historique de la consommation au fil du temps.

### Notifications {#notifications}

Une bannière in-app s'affiche et une notification par e-mail est envoyée aux propriétaires de l'espace de nommage lorsque les minutes de calcul restantes sont :

- Inférieures à 25 % du quota.
- Inférieures à 5 % du quota.
- Entièrement utilisées (zéro minute restante).

### Application {#enforcement}

Lorsque le quota de calcul est épuisé pour le mois en cours, les runners d'instance cessent de traiter les nouveaux jobs. Dans les pipelines déjà démarrés :

- Tout job en attente (pas encore démarré) ou job réessayé devant être traité par des runners d'instance est abandonné.
- Les jobs s'exécutant sur des runners d'instance peuvent continuer à s'exécuter jusqu'à ce que l'utilisation globale de l'espace de nommage dépasse le quota de 1 000 minutes de calcul. Après la période de grâce de 1 000 minutes de calcul, les jobs encore en cours d'exécution sont également abandonnés.

Les runners de projet et les runners de groupe ne sont pas affectés par le quota de calcul et continuent à traiter les jobs.

## Afficher l'utilisation {#view-usage}

Vous pouvez afficher l'utilisation du calcul (y compris les [minutes supplémentaires](../../subscriptions/gitlab_com/compute_minutes.md)) pour un groupe ou un espace de nommage personnel afin de comprendre les tendances d'utilisation du calcul et le nombre de minutes de calcul restantes.

Dans certains cas, la limite du quota est remplacée par l'un des labels suivants :

- **Illimité** : Pour les espaces de nommage disposant d'un quota de calcul illimité.
- **Non pris en charge** : Pour les espaces de nommage où les runners d'instance ne sont pas activés.

### Afficher l'utilisation pour un groupe {#view-usage-for-a-group}

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Pour afficher l'utilisation du calcul pour votre groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe. Le groupe ne doit pas être un sous-groupe.
1. Sélectionnez **Paramètres** > **Quotas d'utilisation**.
1. Sélectionnez l'onglet **Pipelines**.

La liste des projets affiche uniquement les projets ayant une utilisation du calcul ou une utilisation des runners d'instance au cours du mois en cours. La liste inclut tous les projets de l'espace de nommage et de ses sous-groupes, triés par ordre décroissant d'utilisation du calcul.

### Afficher l'utilisation pour un espace de nommage personnel {#view-usage-for-a-personal-namespace}

Vous pouvez afficher l'utilisation du calcul pour votre espace de nommage personnel :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Quotas d'utilisation**.

La liste des projets affiche les [projets personnels](../../user/project/working_with_projects.md) ayant une utilisation du calcul ou une utilisation des runners d'instance au cours du mois en cours uniquement.

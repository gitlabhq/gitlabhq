---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Surveillez l'adoption de DevSecOps dans votre instance GitLab, suivez l'utilisation des fonctionnalités et obtenez des informations sur les performances de l'équipe."
title: Adoption de DevOps par instance
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

L'adoption de DevOps vous donne un aperçu de l'adoption des fonctionnalités de développement, de sécurité et d'exploitation de l'ensemble de votre instance, ainsi qu'un score DevOps.

Pour plus d'informations sur cette fonctionnalité, consultez également [Adoption de DevOps par groupe](../../user/group/devops_adoption/_index.md).

## Score DevOps {#devops-score}

> [!note]
> Pour afficher le score DevOps, vous devez activer le [Service Ping](../settings/usage_statistics.md#service-ping) de votre instance GitLab. Le Score DevOps est un outil comparatif, de sorte que les données de votre score doivent d'abord être traitées de manière centralisée par GitLab Inc. Si le Service Ping n'est pas activé, la valeur du score DevOps est 0.

Vous pouvez utiliser le score DevOps pour comparer votre statut DevOps à celui d'autres organisations.

Le **Score DevOps** affiche l'utilisation des principales fonctionnalités de GitLab sur votre instance au cours des 30 derniers jours, en moyenne sur le nombre d'utilisateurs facturables au cours de cette période.

- **Votre score** représente la moyenne de vos scores de fonctionnalités.
- **Votre utilisation** représente l'utilisation moyenne d'une fonctionnalité par utilisateur facturable au cours des 30 derniers jours.
- Le **Score d'utilisation du chef de projet** est calculé à partir des instances les plus performantes sur la base des [données du Service Ping](../settings/usage_statistics.md#service-ping) collectées par GitLab.

Les données du Service Ping sont agrégées sur les serveurs GitLab à des fins d'analyse. Vos informations d'utilisation ne sont **not sent** à d'autres instances GitLab. Si vous venez de commencer à utiliser GitLab, quelques semaines peuvent être nécessaires pour que les données soient collectées avant que cette fonctionnalité ne soit disponible.

## Afficher l'adoption de DevOps {#view-devops-adoption}

Prérequis :

- Accès administrateur.

Pour afficher l'adoption de DevOps pour votre instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Données d'analyse** > **Adoption de DevOps**.

## Ajouter un groupe à l'adoption de DevOps {#add-a-group-to-devops-adoption}

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner pour le groupe.

Pour ajouter un groupe à l'adoption de DevOps :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Données d'analyse** > **Adoption de DevOps**.
1. Dans la liste déroulante **Ajouter ou supprimer des groupes**, sélectionnez le groupe que vous souhaitez ajouter.

## Supprimer un groupe de l'adoption de DevOps {#remove-a-group-from-devops-adoption}

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner pour le groupe.

Pour supprimer un groupe de l'adoption de DevOps :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Données d'analyse** > **Adoption de DevOps**.
1. Soit :

- Dans la liste déroulante **Ajouter ou supprimer des groupes**, désélectionnez le groupe que vous souhaitez supprimer.
- Dans le tableau **Adoption par groupe**, dans la ligne du groupe que vous souhaitez supprimer, sélectionnez **Remove Group from the table** ({{< icon name="remove" >}}).

---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Exiger des approbations avant le déploiement dans un environnement protégé
title: Approbations de déploiement
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez exiger des approbations supplémentaires pour les déploiements dans des environnements protégés. Les déploiements sont bloqués jusqu'à ce que toutes les approbations requises soient accordées.

Utilisez les approbations de déploiement pour répondre aux processus de test, de sécurité ou de conformité. Par exemple, vous pouvez souhaiter exiger des approbations pour les déploiements dans des environnements de production.

## Configurer les approbations de déploiement {#configure-deployment-approvals}

Vous pouvez exiger des approbations pour les déploiements dans des environnements protégés dans un projet.

Prérequis :

- Pour mettre à jour un environnement, vous devez disposer du rôle Maintainer ou Owner.

Pour configurer les approbations de déploiement pour un projet :

1. Créez un job de déploiement dans le fichier `.gitlab-ci.yml` de votre projet :

   ```yaml
   stages:
     - deploy

   production:
     stage: deploy
     script:
       - 'echo "Deploying to ${CI_ENVIRONMENT_NAME}"'
     environment:
       name: ${CI_JOB_NAME}
       action: start
   ```

   Le job n'a pas besoin d'être manuel (`when: manual`).

1. Ajoutez les [règles d'approbation](#add-multiple-approval-rules) requises.

Les environnements de votre projet nécessitent une approbation avant le déploiement.

### Ajouter plusieurs règles d'approbation {#add-multiple-approval-rules}

{{< history >}}

- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/345678) dans GitLab 15.0. [Feature flag `deployment_approval_rules`](https://gitlab.com/gitlab-org/gitlab/-/issues/345678) supprimé.
- Configuration de l'interface utilisateur [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/378445) dans GitLab 15.11.

{{< /history >}}

Ajoutez plusieurs règles d'approbation pour contrôler qui peut approuver et exécuter des jobs de déploiement.

Pour ajouter plusieurs règles d'approbation, vous devez disposer du rôle Developer pour le projet. Pour ajouter un groupe en tant qu'approbateur, vous devez [inviter le groupe dans le projet](../../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project). Seuls les groupes invités apparaissent dans la liste des approbateurs.

Pour configurer plusieurs règles d'approbation, utilisez les [paramètres CI/CD](protected_environments.md#protecting-environments). Vous pouvez [également utiliser l'API](../../api/group_protected_environments.md#protect-a-single-environment).

Tous les jobs déployant dans l'environnement sont bloqués et attendent les approbations avant de s'exécuter. Assurez-vous que le nombre d'approbations requises est inférieur au nombre d'utilisateurs autorisés à déployer.

Un utilisateur ne peut donner qu'une seule approbation par déploiement, même s'il est membre de plusieurs groupes d'approbateurs. [L'issue 457541](https://gitlab.com/gitlab-org/gitlab/-/issues/457541) propose de modifier ce comportement afin que le même utilisateur puisse donner plusieurs approbations par déploiement depuis différents groupes d'approbateurs.

Une fois qu'un job de déploiement est approuvé, vous devez [exécuter le job manuellement](../jobs/job_control.md#run-a-manual-job).

### Autoriser l'auto-approbation {#allow-self-approval}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/381418) dans GitLab 15.8.
- L'approbation automatique a été [supprimée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124638) dans GitLab 16.2 en raison de [problèmes d'ergonomie](https://gitlab.com/gitlab-org/gitlab/-/issues/391258).

{{< /history >}}

Par défaut, l'utilisateur qui déclenche un pipeline de déploiement ne peut pas également approuver le job de déploiement.

Un administrateur GitLab peut approuver ou rejeter tous les déploiements.

Pour autoriser l'auto-approbation d'un job de déploiement :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Environnements protégés**.
1. Dans les **Options d'approbation**, cochez la case **Allow pipeline triggerer to approve deployment**.

## Approuver ou rejeter un déploiement {#approve-or-reject-a-deployment}

Dans un environnement avec plusieurs règles d'approbation, vous pouvez :

- Approuver un déploiement pour lui permettre de continuer.
- Rejeter un déploiement pour l'empêcher.

Prérequis :

- Vous avez la permission de déployer dans l'environnement protégé.

Pour approuver ou rejeter un déploiement :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. Sélectionnez le nom de l'environnement.
1. Trouvez le déploiement et sélectionnez son **Status badge**.
1. Facultatif. Ajoutez un commentaire décrivant la raison pour laquelle vous approuvez ou rejetez le déploiement.
1. Sélectionnez **Approuver** ou **Rejeter**.

Vous pouvez également [utiliser l'API](../../api/deployments.md#approve-or-reject-a-deployment).

Vous ne pouvez donner qu'une seule approbation par déploiement, même si vous êtes membre de plusieurs groupes d'approbateurs. [L'issue 457541](https://gitlab.com/gitlab-org/gitlab/-/issues/457541) propose de modifier ce comportement afin que le même utilisateur puisse donner plusieurs approbations par déploiement depuis différents groupes d'approbateurs.

L'approbation de déploiement ne démarre pas automatiquement le job de déploiement correspondant. Vous devez [exécuter le job manuellement](../jobs/job_control.md#run-a-manual-job).

### Afficher les détails d'approbation d'un déploiement {#view-the-approval-details-of-a-deployment}

Prérequis :

- Vous avez la permission de déployer dans l'environnement protégé.

Un déploiement dans un environnement protégé ne peut se poursuivre qu'après l'octroi de toutes les approbations requises.

Pour afficher les détails d'approbation d'un déploiement :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. Sélectionnez le nom de l'environnement.
1. Trouvez le déploiement et sélectionnez son **Status badge**.

Les détails du statut d'approbation sont affichés :

- Approbateurs éligibles
- Nombre d'approbations accordées et nombre d'approbations requises
- Utilisateurs ayant accordé leur approbation
- Historique des approbations ou des rejets

## Afficher les déploiements bloqués {#view-blocked-deployments}

Examinez le statut de vos déploiements, notamment si un déploiement est bloqué.

Pour afficher vos déploiements :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Opération** > **Environnements**.
1. Sélectionnez l'environnement cible du déploiement.

Un déploiement portant le label **blocked** est bloqué.

Pour obtenir le statut d'approbation d'un déploiement, vous pouvez également [utiliser l'API](../../api/deployments.md#retrieve-a-deployment). Le champ `status` indique si un déploiement est bloqué.

## Sujets connexes {#related-topics}

- [Epic de la fonctionnalité d'approbations de déploiement](https://gitlab.com/groups/gitlab-org/-/epics/6832)

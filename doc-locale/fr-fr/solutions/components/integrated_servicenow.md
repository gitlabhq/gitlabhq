---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: Gestion intégrée des changements - ServiceNow
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Version de ServiceNow : dernière version, Xanadu et compatibilité ascendante avec les versions précédentes

{{< /details >}}

Ce document fournit les instructions et les détails fonctionnels permettant à GitLab d'orchestrer la gestion des changements avec la solution ServiceNow intégrée à l'aide de ServiceNow DevOps Change Velocity.

Grâce à l'intégration de ServiceNow DevOps Change Velocity, il est possible de suivre les informations relatives à l'activité dans les dépôts GitLab et les pipelines CI/CD dans ServiceNow.

Cette solution automatise la création des demandes de changement et les approuve automatiquement selon les critères de politique définis lorsqu'elle est intégrée aux pipelines CI/CD GitLab.

Ce document vous explique comment

1. Intégrer ServiceNow à GitLab avec Change Velocity pour la gestion des changements,
1. Créer automatiquement la demande de changement dans ServiceNow via le pipeline CI/CD GitLab,
1. Approuver la demande de changement dans ServiceNow si elle nécessite une révision et une approbation du CAB,
1. Démarrer le déploiement en production sur la base de l'approbation de la demande de changement.

## Premiers pas {#getting-started}

### Télécharger le composant de solution {#download-the-solution-component}

1. Obtenez le code d'invitation auprès de votre équipe de compte.
1. Téléchargez le composant de solution depuis [la boutique de composants de solution](https://cloud.gitlab-accelerator-marketplace.com) en utilisant votre code d'invitation.

## Options d'intégration pour la gestion des changements {#integration-options-for-change-management}

Il existe plusieurs façons d'intégrer GitLab à ServiceNow. Les options suivantes sont disponibles dans ce composant de solution :

1. ServiceNow DevOps Change Velocity pour le processus de demande de changement intégré
1. ServiceNow DevOps Change Velocity avec demande de changement personnalisée et Velocity Container Image
1. API REST ServiceNow pour un processus de demande de changement personnalisé

## ServiceNow DevOps Change Velocity {#servicenow-devops-change-velocity}

Après avoir installé et configuré DevOps Change Velocity depuis la boutique ServiceNow, activez le contrôle des changements via la création automatisée de changements directement dans le DevOps Change Workspace.

### Processus de demande de changement intégré {#built-in-change-request-process}

ServiceNow DevOps Change Velocity fournit un modèle de demande de changement intégré pour le processus de changement normal, et la demande de changement créée automatiquement suit une convention de nommage par défaut.

Le processus de changement normal exige que la demande de changement soit approuvée avant que le job de pipeline de déploiement en production puisse être exécuté.

#### Configurer le pipeline et les jobs de demande de changement {#setup-the-pipeline-and-change-request-jobs}

Utilisez le pipeline d'exemple `gitlab-ci-workflow1.yml` dans le dépôt de la solution comme point de départ. Consultez les étapes ci-dessous pour activer la création automatique de changements et transmettre les attributs de changement via le pipeline.

> [!note]
> Pour des instructions plus détaillées, consultez [Automate DevOps change request creation](https://www.servicenow.com/docs/bundle/yokohama-it-service-management/page/product/enterprise-dev-ops/task/automate-devops-change-request.html).

Voici les étapes de haut niveau :

1. Dans le DevOps Change Workspace, accédez à l'onglet Change, puis sélectionnez Automate change.

   ![DevOps Change Workspace avec l'option Automate change sélectionnée.](img/snow_automate_cr_creation_v17_9.png)
1. Dans le champ Application, sélectionnez l'application que vous souhaitez associer au pipeline pour lequel vous souhaitez automatiser la création de demandes de changement, puis sélectionnez Next.
1. Sélectionnez le pipeline qui contient l'étape (stage) à partir de laquelle vous souhaitez déclencher la création automatisée des demandes de changement. Par exemple, l'étape de création de la demande de changement.
1. Sélectionnez l'étape dans le pipeline à partir de laquelle vous souhaitez déclencher la création automatisée d'une demande de changement.
1. Spécifiez les attributs de changement dans les champs de changement et activez la réception du changement en sélectionnant l'option Change receipt.
1. Modifiez votre pipeline et utilisez l'extrait de code correspondant pour activer le contrôle des changements et spécifier les attributs de changement. Par exemple, en ajoutant les deux configurations suivantes au job pour lequel le contrôle des changements est activé :

   ```yaml
      when: manual
      allow_failure: false
   ```

   ![Job du pipeline CI/CD GitLab mis à jour pour prendre en charge le contrôle des changements.](img/snow_automated_cr_pipeline_update_v17_9.png)

#### Exécuter le pipeline avec la gestion des changements {#run-pipeline-with-change-management}

Une fois les étapes précédentes terminées, le pipeline CD du projet peut intégrer les jobs illustrés dans le pipeline d'exemple `gitlab-ci-workflow1.yml`.

Pour exécuter un pipeline avec la gestion des changements :

1. Dans ServiceNow, le contrôle des changements est activé pour l'une des étapes du pipeline.

   ![Étape ServiceNow avec le contrôle des changements activé dans le pipeline.](img/snow_change_control_enabled_v17_9.png)
1. Dans GitLab, le job de pipeline avec la fonction de contrôle des changements s'exécute.

   ![Pipeline GitLab mis en pause en attente d'approbation du changement.](img/snow_pipeline_pause_for_approval_v17_9.png)
1. Dans ServiceNow, une demande de changement est automatiquement créée dans ServiceNow.

   ![Demande de changement ServiceNow en attente d'approbation.](img/snow_cr_waiting_for_approval_v17_9.png)
1. Dans ServiceNow, approuvez la demande de changement

   ![Demande de changement ServiceNow marquée comme approuvée.](img/snow_cr_approved_v17_9.png)
1. Le pipeline reprend et démarre le job suivant pour le déploiement dans l'environnement de production après l'approbation de la demande de changement.

   ![Pipeline GitLab qui reprend après l'approbation du changement.](img/snow_pipeline_resumes_v17_9.png)

### Actions personnalisées avec Velocity Container Image {#custom-actions-with-velocity-container-image}

Utilisez les actions personnalisées ServiceNow via l'image Docker DevOps Change Velocity pour définir le titre, la description, le plan de changement, le plan de retour arrière et les données relatives aux artefacts à déployer, ainsi que l'enregistrement des packages de la demande de changement. Cela vous permet de personnaliser les descriptions des demandes de changement au lieu de transmettre les métadonnées du pipeline comme description de la demande de changement.

#### Configurer le pipeline et les jobs de demande de changement {#setup-the-pipeline-and-change-request-jobs-1}

Il s'agit d'un module complémentaire à ServiceNow DevOps Change Velocity ; les étapes de configuration précédentes restent donc identiques. Vous devez simplement inclure l'image Docker dans la définition du pipeline.

Utilisez le pipeline d'exemple `gitlab-ci-workflow2.yml` dans ce dépôt comme référence.

1. Spécifiez l'image à utiliser dans le job. Mettez à jour la version de l'image selon vos besoins.

   ```yaml
      image: servicenowdocker/sndevops:5.0.0
   ```

1. Utilisez la CLI pour des actions spécifiques. Par exemple, pour utiliser la CLI sndevops afin de créer une demande de changement

   ```yaml
   sndevopscli create change -p {
        "changeStepDetails": {
          "timeout": 3600,
          "interval": 100
        },
        "autoCloseChange": true,
        "attributes": {
          "short_description": "'"${CHANGE_REQUEST_SHORT_DESCRIPTION}"'",
          "description": "'"${CHANGE_REQUEST_DESCRIPTION}"'",
          "assignment_group": "'"${ASSIGNMENT_GROUP_ID}"'",
          "implementation_plan": "'"${CR_IMPLEMENTATION_PLAN}"'",
          "backout_plan": "'"${CR_BACKOUT_PLAN}"'",
          "test_plan": "'"${CR_TEST_PLAN}"'"
        }
      }

   ```

#### Exécuter le pipeline avec la gestion des changements personnalisée {#run-pipeline-with-custom-change-management}

Utilisez le pipeline d'exemple `gitlab-ci-workflow2.yml` comme point de départ. Une fois les étapes précédentes terminées, le pipeline CD du projet peut intégrer les jobs illustrés dans le pipeline d'exemple `gitlab-ci-workflow2.yml`.

Pour exécuter un pipeline avec la gestion des changements personnalisée :

1. Dans ServiceNow, le contrôle des changements est activé pour l'une des étapes du pipeline.

   ![Étape ServiceNow avec le contrôle des changements activé en utilisant un flow de changement personnalisé.](img/snow_change_control_enabled_v17_9.png)
1. Dans GitLab, le job de pipeline avec la fonction de contrôle des changements s'exécute.

   ![Workflow de création de demande de changement 2](img/snow_cr_creation_workflow2_v17_9.png)
1. Dans ServiceNow, une demande de changement est créée avec un titre personnalisé, une description et tout autre champ fourni par les valeurs de variables du pipeline en utilisant l'image `servicenowdocker/sndevops`.

   ![Demande de changement ServiceNow créée avec des valeurs personnalisées issues du pipeline.](img/snow_pipeline_workflow2_v17_9.png)
1. Dans GitLab, le numéro de la demande de changement et d'autres informations sont disponibles dans les détails du pipeline. Le job du pipeline reste en cours d'exécution jusqu'à ce que la demande de changement soit approuvée, puis passe au job suivant.

   ![Détails du changement dans le pipeline après approbation - workflow 2](img/snow_pipeline_details_workflow2_v17_9.png)
1. Dans ServiceNow, approuvez la demande de changement.

   ![Détails du pipeline - workflow 2](img/snow_pipeline_cr_details_workflow2_v17_9.png)
1. Dans GitLab, le job du pipeline reprend et démarre le job suivant, qui est le déploiement dans l'environnement de production après l'approbation de la demande de changement.

   ![Reprise du pipeline - workflow 2](img/snow_pipeline_resumes_workflow2_v17_9.png)

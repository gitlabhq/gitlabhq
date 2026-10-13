---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutoriel : protégez votre projet grâce à la détection des secrets dans les pipelines'
---

<!-- vale gitlab_base.FutureTense = NO -->

Si votre application utilise des ressources externes, vous devez généralement authentifier votre application avec un secret, tel qu'un jeton ou une clé. Si un secret est poussé vers un dépôt distant, toute personne ayant accès au dépôt peut usurper votre identité ou celle de votre application.

La détection des secrets dans les pipelines utilise un job CI/CD pour vérifier la présence de secrets dans votre projet GitLab. Dans ce tutoriel, vous allez créer un projet, configurer la détection des secrets dans les pipelines et apprendre à analyser ses résultats :

1. [Créer un projet](#create-a-project)
1. [Vérifier la sortie du job](#check-the-job-output)
1. [Activer les pipelines de merge request](#enable-merge-request-pipelines)
1. [Ajouter un faux secret](#add-a-fake-secret)
1. [Trier le secret](#triage-the-secret)
1. [Remédier à une fuite](#remediate-a-leak)

## Avant de commencer {#before-you-begin}

Avant de commencer ce tutoriel, assurez-vous de disposer des éléments suivants :

- Un compte GitLab.com. Pour tirer pleinement parti de toutes les fonctionnalités de la détection des secrets dans les pipelines, vous devez utiliser un compte GitLab Ultimate si vous en avez un.
- Une certaine familiarité avec CI/CD.

## créer un projet {#create-a-project}

Commencez par créer un projet et activer la détection des secrets :

1. Dans le coin supérieur droit, sélectionnez **Créer un nouveau** ({{< icon name="plus" >}}) et **Nouveau projet/dépôt**.
1. Sélectionnez **Créer un projet vide**.
1. Saisissez les détails du projet :
   1. Saisissez un nom et un slug de projet.
   1. Dans la liste déroulante **Cible du déploiement du projet (facultatif)**, sélectionnez **Aucun déploiement planifié**.
   1. Cochez la case **Initialiser le dépôt avec un README**. Cela vous donnera un emplacement pour ajouter du contenu au projet ultérieurement.
   1. Cochez la case **Activer la détection de secret**.
1. Sélectionnez **Créer le projet**.

Un nouveau projet est créé et initialisé avec un fichier README et `.gitlab-ci.yml`. La configuration CI/CD inclut le template `Security/Secret-Detection.gitlab-ci.yml`, qui active la détection des secrets dans les pipelines du projet.

## Vérifier la sortie du job {#check-the-job-output}

La détection des secrets dans les pipelines s'exécute dans un job CI/CD appelé `secret_detection`. Les résultats de l'analyse sont écrits dans le job log CI/CD. Chaque analyse produit également un rapport complet sous forme d'artefact de job.

Pour vérifier les résultats de la dernière analyse :

1. Dans la barre latérale gauche, sélectionnez **Version** > **Jobs**.
1. Sélectionnez le job `secret_detection` le plus récent. Si vous n'avez pas exécuté de nouveau pipeline, il ne devrait y avoir qu'un seul job.
1. Vérifiez la sortie du log pour les éléments suivants :
   - Des informations sur l'analyse, notamment la version de l'analyseur et l'ensemble de règles. Votre projet utilise l'ensemble de règles par défaut car vous avez activé la détection des secrets automatiquement.
   - Si des secrets ont été détectés. Vous devriez voir `no leaks found`.
1. Pour télécharger le rapport complet, sous **Artéfacts de job**, sélectionnez **Téléchargement**.

## Activer les pipelines de merge request {#enable-merge-request-pipelines}

Jusqu'à présent, vous avez utilisé la détection des secrets dans les pipelines pour analyser les commits de la branche par défaut. Mais pour analyser les commits dans les merge requests avant de les fusionner dans la branche par défaut, vous devez activer les pipelines de merge request.

Pour cela :

1. Ajoutez les lignes suivantes à votre fichier `.gitlab-ci.yml` :

   ```yaml
   variables:
     AST_ENABLE_MR_PIPELINES: "true"
   ```

1. Enregistrez les modifications et commitez-les dans la branche `main` de votre projet.

## Ajouter un faux secret {#add-a-fake-secret}

Ensuite, compliquons la sortie du job en « faisant fuiter » un faux secret dans une merge request :

1. Extrayez une nouvelle branche :

   ```shell
   git checkout -b pipeline-sd-tutorial
   ```

1. Modifiez le README de votre projet et ajoutez les lignes suivantes. Veillez à supprimer les espaces avant et après le `-` pour correspondre au format exact d'un jeton d'accès personnel :

   ```markdown
   # To make the example work, remove
   # the spaces before and after the dash:
   glpat - 12345678901234567890
   ```

1. Commitez et poussez vos modifications, puis ouvrez une merge request pour les fusionner dans la branche par défaut.

   Un pipeline de merge request est automatiquement exécuté.
1. Attendez que le pipeline se termine, puis vérifiez le job log. Vous devriez voir `WRN leaks found: 1`.
1. Téléchargez l'artefact de job et vérifiez qu'il contient les informations suivantes :
   - Le type de secret. Dans cet exemple, le type est `"GitLab personal access token"`.
   - Une description de l'utilisation du secret, accompagnée de quelques étapes pour remédier à la fuite.
   - La gravité de la fuite. Étant donné que les jetons d'accès personnels peuvent être utilisés pour usurper l'identité d'utilisateurs sur GitLab.com, cette fuite est `Critical`.
   - Le texte brut du secret.
   - Des informations sur l'emplacement du secret :

     ```json
     "file": "README.md",
     "line_start": 97,
     "line_end": 97,
     ```

     Dans cet exemple, le secret se trouve à la ligne 97 du fichier `README.md`.

### Utiliser les rapports de merge request {#using-merge-request-reports}

{{< details >}}

- Édition : GitLab Ultimate

{{< /details >}}

Un secret détecté sur une branche non par défaut est appelé une « découverte ». Lorsqu'une découverte est fusionnée dans la branche par défaut, elle devient une « vulnérabilité ».

L'onglet **Rapports** de la merge request affiche les découvertes d'analyses de sécurité susceptibles de devenir des vulnérabilités si la merge request est fusionnée.

Pour afficher les découvertes :

1. Sélectionnez la merge request que vous avez créée à l'étape précédente.
1. Sélectionnez l'onglet **Rapports**.
1. Sélectionnez **Analyse de sécurité**.
1. Vérifiez les informations affichées. Vous devriez voir **La détection des secrets a détecté 1 nouvelle vulnérabilité potentielle**.

Pour une vue détaillée de toutes les découvertes dans une merge request, sélectionnez **Voir toutes les découvertes du pipeline**.

## Trier le secret {#triage-the-secret}

{{< details >}}

- Édition : GitLab Ultimate

{{< /details >}}

Sur GitLab Ultimate, la sortie du job est également écrite dans :

- L'onglet **Sécurité** du pipeline.
- Si une découverte devient une vulnérabilité, le rapport de vulnérabilité.

Pour montrer comment vous pouvez trier un secret à l'aide de l'interface utilisateur, créons une vulnérabilité et modifions son statut dans le rapport de vulnérabilité :

1. Fusionnez la merge request que vous avez créée à la dernière étape, puis attendez que le pipeline se termine.

   Le faux secret est ajouté à `main`, ce qui entraîne la transformation de la découverte en vulnérabilité.
1. Dans la barre latérale gauche, sélectionnez **Sécuriser** > **Rapport de vulnérabilités**.
1. Sélectionnez la **Description** de la vulnérabilité pour afficher :
   - Des détails sur le type de secret.
   - Des conseils de remédiation.
   - Des informations sur le moment et l'endroit où la vulnérabilité a été détectée.
1. Dans la barre latérale droite, dans la section **Statut**, sélectionnez **Modifier**.
   1. Dans la liste déroulante **Statut**, sélectionnez **Rejeter comme... Utilisé dans les tests**.
   1. Ajoutez un commentaire expliquant pourquoi vous avez ajouté le faux secret à votre projet.
   1. Sélectionnez **Modifier le statut**.

La vulnérabilité n'apparaît plus sur la page principale du rapport de vulnérabilité.

## Remédier à une fuite {#remediate-a-leak}

Si vous ajoutez un secret à un dépôt distant, ce secret n'est plus sécurisé et doit être révoqué dès que possible. Vous devez révoquer et remplacer les secrets même s'ils n'ont pas encore été fusionnés dans votre branche par défaut.

Les étapes exactes à suivre pour remédier à une fuite dépendent des politiques de sécurité de votre organisation, mais vous devez au minimum :

1. Révoquer le secret. Lorsqu'un secret est révoqué, il n'est plus valide et ne peut plus être utilisé pour usurper une activité légitime.
1. Supprimer le secret de votre dépôt.

Des conseils de remédiation spécifiques sont écrits dans le job log `secret-detection` et sont disponibles sur la page de détails du rapport de vulnérabilité.

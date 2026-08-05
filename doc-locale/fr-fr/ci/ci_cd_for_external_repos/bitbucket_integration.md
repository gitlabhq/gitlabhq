---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connectez votre dépôt Bitbucket Cloud à GitLab CI/CD.
title: Utiliser GitLab CI/CD avec un dépôt Bitbucket Cloud
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab CI/CD peut être utilisé avec Bitbucket Cloud en :

1. Créant un [projet CI/CD](_index.md).
1. Connectant votre dépôt Git par URL.

Pour utiliser GitLab CI/CD avec un dépôt Bitbucket Cloud :

1. Dans Bitbucket, créez un [**App password**](https://support.atlassian.com/bitbucket-cloud/docs/create-an-app-password/) pour authentifier le script qui définit les statuts de build des commits dans Bitbucket. Les permissions d'écriture sur le dépôt sont requises.

   ![Page Bitbucket Cloud affichant l'interface de création d'App password.](img/bitbucket_app_password_v10_6.png)

1. Dans Bitbucket, depuis votre dépôt, sélectionnez **Clone**, puis copiez l'URL qui commence après `git clone`.
1. Dans GitLab, créez un projet :

   1. Dans le coin supérieur droit, sélectionnez **Créer un nouveau** ({{< icon name="plus" >}}) et **Nouveau projet/dépôt**.
   1. Sélectionnez **Exécuter CI/CD pour un dépôt externe**.
   1. Sélectionnez **Dépôt par URL**.
   1. Remplissez les champs :
      - Pour **URL du dépôt Git**, saisissez l'URL de votre dépôt Bitbucket. Veillez à supprimer votre `@username`.
      - Pour **Nom d'utilisateur**, saisissez le nom d'utilisateur associé à l'App password.
      - Pour **Mot de passe**, saisissez l'App password de Bitbucket.

   GitLab importe le dépôt et active la [mise en miroir Pull](../../user/project/repository/mirror/pull.md). Vous pouvez vérifier que la mise en miroir fonctionne dans le projet via **Paramètres** > **Dépôt** > **Dépôts miroir**.

1. Dans GitLab, générez un [jeton d'accès personnel](../../user/profile/personal_access_tokens.md) avec la portée `api`. Le jeton est utilisé pour authentifier les requêtes provenant du webhook créé dans Bitbucket pour notifier GitLab des nouveaux commits.

1. Dans Bitbucket, depuis **Paramètres** > **Crochets web**, créez un nouveau webhook pour notifier GitLab des nouveaux commits.

1. Définissez l'URL du webhook sur le point de terminaison de [mise en miroir Pull GitLab](../../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project), et utilisez le jeton d'accès personnel que vous venez de générer pour l'authentification.

   ```plaintext
   https://gitlab.example.com/api/v4/projects/:project_id/mirror/pull?private_token=<your_personal_access_token>
   ```

   Le déclencheur du webhook doit être défini sur **Repository Push**.

   ![Page des paramètres du dépôt Bitbucket Cloud affichant la configuration du webhook pour la mise en miroir GitLab.](img/bitbucket_webhook_v10_6.png)

   Après l'enregistrement, testez le webhook en poussant une modification vers votre dépôt Bitbucket.

1. Dans GitLab, depuis **Paramètres** > **CI/CD** > **Variables**, ajoutez des variables pour permettre la communication avec Bitbucket via l'API Bitbucket :

   - `BITBUCKET_ACCESS_TOKEN` : L'App password Bitbucket créé précédemment. Cette variable doit être [masquée](../variables/_index.md#mask-a-cicd-variable).
   - `BITBUCKET_USERNAME` : Le nom d'utilisateur du compte Bitbucket.
   - `BITBUCKET_NAMESPACE` : Définissez cette variable si vos espaces de nommage GitLab et Bitbucket diffèrent.
   - `BITBUCKET_REPOSITORY` : Définissez cette variable si les noms de projet de vos projets GitLab et Bitbucket diffèrent.

1. Dans Bitbucket, ajoutez un script qui pousse le statut du pipeline vers Bitbucket. Le script est créé dans Bitbucket, mais le processus de mise en miroir le copie vers le miroir GitLab. Le pipeline CI/CD de GitLab exécute le script et pousse le statut vers Bitbucket.

   Créez un fichier `build_status`, insérez le script suivant et exécutez `chmod +x build_status` dans votre terminal pour rendre le script exécutable.

   ```shell
   #!/usr/bin/env bash

   # Push GitLab CI/CD build status to Bitbucket Cloud

   if [ -z "$BITBUCKET_ACCESS_TOKEN" ]; then
      echo "ERROR: BITBUCKET_ACCESS_TOKEN is not set"
   exit 1
   fi
   if [ -z "$BITBUCKET_USERNAME" ]; then
       echo "ERROR: BITBUCKET_USERNAME is not set"
   exit 1
   fi
   if [ -z "$BITBUCKET_NAMESPACE" ]; then
       echo "Setting BITBUCKET_NAMESPACE to $CI_PROJECT_NAMESPACE"
       BITBUCKET_NAMESPACE=$CI_PROJECT_NAMESPACE
   fi
   if [ -z "$BITBUCKET_REPOSITORY" ]; then
       echo "Setting BITBUCKET_REPOSITORY to $CI_PROJECT_NAME"
       BITBUCKET_REPOSITORY=$CI_PROJECT_NAME
   fi

   BITBUCKET_API_ROOT="https://api.bitbucket.org/2.0"
   BITBUCKET_STATUS_API="$BITBUCKET_API_ROOT/repositories/$BITBUCKET_NAMESPACE/$BITBUCKET_REPOSITORY/commit/$CI_COMMIT_SHA/statuses/build"
   BITBUCKET_KEY="ci/gitlab-ci/$CI_JOB_NAME"

   case "$BUILD_STATUS" in
   running)
      BITBUCKET_STATE="INPROGRESS"
      BITBUCKET_DESCRIPTION="The build is running!"
      ;;
   passed)
      BITBUCKET_STATE="SUCCESSFUL"
      BITBUCKET_DESCRIPTION="The build passed!"
      ;;
   failed)
      BITBUCKET_STATE="FAILED"
      BITBUCKET_DESCRIPTION="The build failed."
      ;;
   esac

   echo "Pushing status to $BITBUCKET_STATUS_API..."
   curl --request POST "$BITBUCKET_STATUS_API" \
   --user $BITBUCKET_USERNAME:$BITBUCKET_ACCESS_TOKEN \
   --header "Content-Type:application/json" \
   --silent \
   --data "{ \"state\": \"$BITBUCKET_STATE\", \"key\": \"$BITBUCKET_KEY\", \"description\":
   \"$BITBUCKET_DESCRIPTION\",\"url\": \"$CI_PROJECT_URL/-/jobs/$CI_JOB_ID\" }"
   ```

1. Dans Bitbucket, créez un fichier `.gitlab-ci.yml` pour utiliser le script afin de pousser les succès et les échecs du pipeline vers Bitbucket. Similaire au script ajouté précédemment, ce fichier est copié dans le dépôt GitLab dans le cadre du processus de mise en miroir.

   ```yaml
   stages:
     - test
     - ci_status

   unit-tests:
     script:
       - echo "Success. Add your tests!"

   success:
     stage: ci_status
     before_script:
       - ""
     after_script:
       - ""
     script:
       - BUILD_STATUS=passed BUILD_KEY=push ./build_status
     when: on_success

   failure:
     stage: ci_status
     before_script:
       - ""
     after_script:
       - ""
     script:
       - BUILD_STATUS=failed BUILD_KEY=push ./build_status
     when: on_failure
   ```

GitLab est maintenant configuré pour mettre en miroir les modifications depuis Bitbucket, exécuter les pipelines CI/CD configurés dans `.gitlab-ci.yml` et pousser le statut vers Bitbucket.

---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurez et exécutez votre premier pipeline CI/CD dans GitLab.
title: 'Tutoriel : Créer et exécuter votre premier pipeline CI/CD GitLab'
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce tutoriel vous montre comment configurer et exécuter votre premier pipeline CI/CD dans GitLab.

Si vous connaissez déjà les [concepts de base du CI/CD](../_index.md), vous pouvez vous familiariser avec les mots-clés courants dans [Tutoriel : Créer un pipeline complexe](tutorial.md).

## Prérequis {#prerequisites}

Avant de commencer, assurez-vous de disposer des éléments suivants :

- Un projet dans GitLab pour lequel vous souhaitez utiliser le CI/CD.
- Le rôle Maintainer ou Owner pour le projet.

Si vous n'avez pas de projet, vous pouvez créer un projet public gratuitement sur <https://gitlab.com>.

## Étapes {#steps}

Pour créer et exécuter votre premier pipeline :

1. [Vérifiez que vous disposez de runners](#ensure-you-have-runners-available) pour exécuter vos jobs.

   Si vous utilisez GitLab.com, vous pouvez ignorer cette étape. GitLab.com met à votre disposition des runners d'instance.

1. [Créez un fichier `.gitlab-ci.yml`](#create-a-gitlab-ciyml-file) à la racine de votre dépôt. Ce fichier est l'endroit où vous définissez les jobs CI/CD.

Lorsque vous commitez le fichier dans votre dépôt, le runner exécute vos jobs. Les résultats des jobs [sont affichés dans un pipeline](#view-the-status-of-your-pipeline-and-jobs).

## Vérifiez que vous disposez de runners {#ensure-you-have-runners-available}

Dans GitLab, les runners sont des agents qui exécutent vos jobs CI/CD.

Si vous utilisez GitLab.com, vous pouvez ignorer cette étape. GitLab.com met à votre disposition des runners d'instance.

Pour afficher les runners disponibles :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Runners**.

Tant que vous disposez d'au moins un runner actif, avec un cercle vert à côté de lui, vous avez un runner disponible pour traiter vos jobs.

Si vous n'avez pas accès à ces paramètres, contactez votre administrateur GitLab.

### Si vous ne disposez pas d'un runner {#if-you-dont-have-a-runner}

Si vous ne disposez pas d'un runner :

1. [Installez GitLab Runner](https://docs.gitlab.com/runner/install/) sur votre machine locale.
1. [Enregistrez le runner](https://docs.gitlab.com/runner/register/) pour votre projet. Choisissez l'exécuteur `shell`.

Lorsque vos jobs CI/CD s'exécutent, lors d'une étape ultérieure, ils s'exécuteront sur votre machine locale.

## Créer un fichier `.gitlab-ci.yml` {#create-a-gitlab-ciyml-file}

Créez maintenant un fichier `.gitlab-ci.yml`. Il s'agit d'un fichier [YAML](https://en.wikipedia.org/wiki/YAML) dans lequel vous spécifiez des instructions pour GitLab CI/CD.

Dans ce fichier, vous définissez :

- La structure et l'ordre des jobs que le runner doit exécuter.
- Les décisions que le runner doit prendre lorsque des conditions spécifiques sont rencontrées.

Pour créer un fichier `.gitlab-ci.yml` dans votre projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Dépôt**.
1. Au-dessus de la liste de fichiers, sélectionnez la branche vers laquelle vous souhaitez commiter. Si vous n'êtes pas sûr(e), conservez `master` ou `main`. Ensuite, dans le coin supérieur droit, sélectionnez l'icône plus ({{< icon name="plus" >}}) et **Nouveau fichier** :

   ![Le bouton Nouveau fichier pour créer un fichier dans le dossier actuel.](img/new_file_v18_11.png)

1. Pour le **Nom du fichier**, saisissez `.gitlab-ci.yml` et dans la zone de texte plus grande, collez cet exemple de code :

   ```yaml
   build-job:
     stage: build
     script:
       - echo "Hello, $GITLAB_USER_LOGIN!"

   test-job1:
     stage: test
     script:
       - echo "This job tests something"

   test-job2:
     stage: test
     script:
       - echo "This job tests something, but takes more time than test-job1."
       - echo "After the echo commands complete, it runs the sleep command for 20 seconds"
       - echo "which simulates a test that runs 20 seconds longer than test-job1"
       - sleep 20

   deploy-prod:
     stage: deploy
     script:
       - echo "This job deploys something from the $CI_COMMIT_BRANCH branch."
     environment: production
   ```

   Cet exemple montre quatre jobs : `build-job`, `test-job1`, `test-job2` et `deploy-prod`. Les commentaires figurant dans les commandes `echo` s'affichent dans l'interface lorsque vous consultez les jobs. Les valeurs des [variables prédéfinies](../variables/predefined_variables.md) `$GITLAB_USER_LOGIN` et `$CI_COMMIT_BRANCH` sont renseignées lors de l'exécution des jobs.

1. Sélectionnez **Valider les modifications**.

Le pipeline démarre et exécute les jobs que vous avez définis dans le fichier `.gitlab-ci.yml`.

## Afficher le statut de votre pipeline et de vos jobs {#view-the-status-of-your-pipeline-and-jobs}

Examinez maintenant votre pipeline et les jobs qu'il contient.

1. Accédez à **Version** > **Pipelines**. Un pipeline avec trois étapes devrait s'afficher :

   ![La liste des pipelines affiche un pipeline en cours d'exécution avec 3 étapes](img/three_stages_v18_11.png)

1. Affichez une représentation visuelle de votre pipeline en sélectionnant l'ID du pipeline (`#676` dans cet exemple) :

   ![Le graphe de pipeline affiche chaque job, son statut et ses dépendances pour toutes les étapes.](img/pipeline_graph_v18_11.png)

1. Affichez les détails d'un job en sélectionnant le nom du job. Par exemple, `deploy-prod` :

   ![La page de détails du job affiche le statut actuel, les informations de temporisation et la sortie du job log.](img/job_details_v18_11.png)

Vous avez créé avec succès votre premier pipeline CI/CD dans GitLab. Félicitations !

Vous pouvez maintenant commencer à personnaliser votre fichier `.gitlab-ci.yml` et à définir des jobs plus avancés.

## Conseils pour `.gitlab-ci.yml` {#gitlab-ciyml-tips}

Voici quelques conseils pour commencer à travailler avec le fichier `.gitlab-ci.yml`.

Pour la syntaxe complète de `.gitlab-ci.yml`, consultez la [référence complète de la syntaxe YAML CI/CD](../yaml/_index.md).

- Utilisez l'[éditeur de pipeline](../pipeline_editor/_index.md) pour modifier votre fichier `.gitlab-ci.yml`.
- Chaque job contient une section script et appartient à une étape :
  - [`stage`](../yaml/_index.md#stage) décrit l'exécution séquentielle des jobs. Si des runners sont disponibles, les jobs d'une même étape s'exécutent en parallèle.
  - Utilisez le [mot-clé `needs`](../yaml/_index.md#needs) pour [exécuter des jobs hors de l'ordre des étapes](../yaml/needs.md), afin d'augmenter la vitesse et l'efficacité du pipeline.
- Vous pouvez définir une configuration supplémentaire pour personnaliser le comportement de vos jobs et de vos étapes :
  - Utilisez le mot-clé [`rules`](../yaml/_index.md#rules) pour spécifier quand exécuter ou ignorer des jobs. Les mots-clés hérités `only` et `except` sont toujours pris en charge, mais ne peuvent pas être utilisés avec `rules` dans le même job.
  - Conservez les informations persistantes entre les jobs et les étapes dans un pipeline avec [`cache`](../yaml/_index.md#cache) et [`artifacts`](../yaml/_index.md#artifacts). Ces mots-clés permettent de stocker les dépendances et la sortie des jobs, même lors de l'utilisation de runners éphémères pour chaque job.
  - Utilisez le mot-clé [`default`](../yaml/_index.md#default) pour spécifier des configurations supplémentaires appliquées à tous les jobs. Ce mot-clé est souvent utilisé pour définir les sections [`before_script`](../yaml/_index.md#before_script) et [`after_script`](../yaml/_index.md#after_script) qui doivent s'exécuter sur chaque job.

## Sujets connexes {#related-topics}

Migrer depuis :

- [Bamboo](../migration/bamboo.md)
- [CircleCI](../migration/circleci.md)
- [GitHub Actions](../migration/github_actions.md)
- [Jenkins](../migration/jenkins.md)
- [TeamCity](../migration/teamcity.md)

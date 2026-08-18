---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez l'extension GitLab pour VS Code afin de gérer les pipelines CI/CD directement dans votre IDE."
title: "Les pipelines CI/CD dans l'extension VS Code"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895) dans l'extension GitLab VS Code 6.14.0 pour GitLab 18.1 et versions ultérieures.
- Ajout des [job logs de pipeline downstream](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895) pour GitLab 18.1 et versions ultérieures.

{{< /history >}}

Si votre projet utilise des pipelines CI/CD GitLab, vous pouvez utiliser l'extension GitLab pour VS Code pour démarrer, surveiller et mettre à jour des pipelines directement dans votre IDE.

## Prérequis {#prerequisites}

- [Authentifiez l'extension](setup.md#connect-to-gitlab) et connectez-vous à un dépôt sur GitLab.

## Surveiller et gérer les pipelines {#monitor-and-manage-pipelines}

Utilisez l'extension pour surveiller et gérer les pipelines de votre projet.

Prérequis :

- Votre projet utilise des pipelines CI/CD.
- Une merge request existe pour votre branche Git actuelle.
- Le commit le plus récent sur votre branche Git actuelle possède un pipeline CI/CD.

### Afficher le statut du pipeline {#view-pipeline-status}

Pour afficher le statut de votre pipeline de branche, consultez la barre d'état inférieure dans VS Code.

![La barre d'état inférieure, indiquant que le pipeline le plus récent a échoué.](img/status_bar_pipeline_v17_6.png)

Les statuts possibles sont les suivants :

- Pipeline annulé
- Pipeline en échec
- Pipeline réussi
- Pipeline en attente
- Pipeline en cours d'exécution
- Pipeline ignoré
- Aucun pipeline, si un pipeline n'a pas encore été exécuté.

### Gérer les pipelines {#manage-pipelines}

Pour démarrer, surveiller et déboguer des pipelines CI/CD dans GitLab :

1. Dans VS Code, dans la barre d'état inférieure, sélectionnez le statut du pipeline pour ouvrir la **Command Palette** et accéder aux actions disponibles.
1. Sélectionnez l'action souhaitée et suivez les instructions :

   - **Create New Pipeline from Current Branch**
   - **Cancel Last Pipeline**
   - **Download Artifacts from Latest Pipeline**
   - **Retry Last Pipeline**
   - **View Latest Pipeline on GitLab**

### Afficher la sortie d'un job CI/CD {#view-cicd-job-output}

Pour afficher la sortie d'un job CI/CD pour votre branche actuelle :

1. Dans la barre latérale gauche, sélectionnez **GitLab** ({{< icon name="tanuki" >}}).
1. Développez **For current branch** pour afficher le pipeline le plus récent.
1. Sélectionnez un job pour l'ouvrir dans un nouvel onglet VS Code :

   ![Un pipeline contenant des jobs CI/CD réussis et en échec.](img/view_job_output_v17_6.png)

Pour ouvrir le job log d'un pipeline downstream :

1. Trouvez les pipelines downstream dans la liste des jobs du pipeline de branche.
1. Sélectionnez les icônes de flèche pour développer ou réduire les informations du pipeline downstream.
1. Sélectionnez un pipeline downstream pour ouvrir le job log dans un nouvel onglet VS Code.

### Gérer les alertes de pipeline {#manage-pipeline-alerts}

L'extension peut afficher une alerte dans VS Code lorsqu'un pipeline pour votre branche actuelle se termine :

![Alerte indiquant un échec du pipeline](img/pipeline_alert_v19_0.png)

Pour activer ou désactiver les alertes de pipeline :

1. Dans VS Code, ouvrez l'éditeur **Paramètres** :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>,</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>,</kbd>.
1. Selon votre configuration, sélectionnez les paramètres **Utilisateur/utilisatrice** ou **Workspace**.
1. Sélectionnez **Extensions** > **GitLab** > **Autre**.
1. Sous **GitLab : Show Pipeline Update Notifications**, cochez ou décochez la case.

## Gérer votre configuration CI/CD {#manage-your-cicd-configuration}

L'extension fournit également des outils que vous pouvez utiliser pour créer et gérer la configuration CI/CD de votre projet.

### Autocomplétion des variables CI/CD {#autocomplete-cicd-variables}

Lorsque vous rédigez ou modifiez votre fichier de configuration CI/CD, utilisez l'autocomplétion des variables pour les trouver rapidement.

Prérequis :

- Le nom de votre fichier de configuration CI/CD commence par `.gitlab-ci` et se termine par `.yml` ou `.yaml`. Par exemple, `.gitlab-ci.yml` ou `.gitlab-ci.production.yml`

Pour autocompléter une variable CI/CD :

1. Dans VS Code, ouvrez votre fichier `.gitlab-ci.yml` et assurez-vous que l'onglet du fichier est actif.
1. Commencez à saisir le nom de la variable CI/CD. L'extension affiche des options d'autocomplétion.
1. Sélectionnez une option pour l'utiliser :

   ![Options d'autocomplétion affichées pour une chaîne de caractères](img/ci_variable_autocomplete_v16_6.png)

### Tester la configuration GitLab CI/CD {#test-gitlab-cicd-configuration}

Pour tester localement la configuration GitLab CI/CD de votre projet :

1. Dans VS Code, ouvrez votre fichier `.gitlab-ci.yml` et assurez-vous que l'onglet du fichier est actif.
1. Ouvrez la **Command Palette** :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Saisissez `GitLab: Validate GitLab CI Config` et appuyez sur <kbd>Enter</kbd>.

L'extension affiche une alerte si elle détecte un problème dans votre configuration.

### Afficher le fichier de configuration fusionné {#show-merged-configuration-file}

Pour afficher un aperçu de votre fichier de configuration CI/CD fusionné, avec toutes les instructions `includes` et références résolues :

1. Dans VS Code, ouvrez votre fichier `.gitlab-ci.yml` et assurez-vous que l'onglet du fichier est actif.
1. En haut à droite, sélectionnez **Show Merged GitLab CI/CD Configuration** :

   ![L'application VS Code, affichant l'icône pour visualiser les résultats fusionnés.](img/show_merged_configuration_v17_6.png)

VS Code ouvre un nouvel onglet (`.gitlab-ci (Merged).yml`) avec toutes les informations.

## Sujets connexes {#related-topics}

- [Utiliser le CI/CD pour créer votre application](../../topics/build_your_application.md)

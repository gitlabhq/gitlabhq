---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Découvrez le workflow GitLab DevSecOps pour les applications mobiles hybrides React Native, notamment la configuration CI/CD, l'analyse de sécurité Snyk, les tests fonctionnels Sauce Labs et l'intégration ServiceNow."
title: Workflow DevSecOps - Applications mobiles
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce document fournit les instructions et les détails fonctionnels de la solution de workflow GitLab DevSecOps pour la création et la livraison d'applications mobiles hybrides (React Native).

Pour les applications mobiles natives utilisant fastlane, consultez la documentation produit.

Les instructions incluent un exemple d'application [**React Native**](https://reactnative.dev), initialisée à l'aide de `react-native-community/cli`, et fournissent une solution multiplateforme pour les appareils iOS et Android. L'exemple de projet fournit une solution de bout en bout pour l'utilisation des pipelines CI/CD GitLab afin de créer, tester et déployer une application mobile.

## Premiers pas {#getting-started}

Suivez les étapes ci-dessous pour utiliser cet exemple de projet d'application mobile React Native et démarrer rapidement la livraison de votre application mobile avec GitLab.

### Télécharger le composant de solution {#download-the-solution-component}

1. Obtenez le code d'invitation auprès de votre équipe de compte.
1. Téléchargez le composant de solution depuis [la boutique en ligne des composants de solution](https://cloud.gitlab-accelerator-marketplace.com) en utilisant votre code d'invitation.

### Configurer le projet de composant de solution {#set-up-the-solution-component-project}

- Le composant de solution Mobile App du marketplace Product Accelerator a été téléchargé. Le pack de solution inclut l'exemple de projet d'application mobile avec les fichiers CI/CD.
- Créez un nouveau projet de catalogue CI/CD GitLab pour héberger le composant Snyk dans votre environnement. Dans le pack de solution d'application mobile, les fichiers de projet du composant CI/CD Snyk sont inclus et vous permettent de configurer le projet de catalogue CI/CD Snyk.
  1. Créez un nouveau projet GitLab pour héberger ce projet de catalogue CI/CD Snyk
  1. Copiez les fichiers fournis dans votre projet
  1. Configurez les variables CI/CD requises dans les paramètres de votre projet
  1. Assurez-vous que le projet est marqué comme projet de catalogue CI/CD. Pour plus d'informations, consultez [publier un projet de composant](../../ci/components/_index.md#publish-a-component-project).

  > [!note]
  > Un composant public GitLab Snyk est disponible sur GitLab.com. Si vous pouvez accéder au composant public GitLab Snyk, vous n'avez pas besoin de configurer votre propre projet de catalogue CI/CD Snyk. À la place, utilisez directement le composant public en suivant sa documentation.

- Utilisez le pack de solution Change Control Workflow with ServiceNow pour configurer l'intégration DevOps Change Velocity avec GitLab afin d'automatiser la création de demandes de changement dans ServiceNow pour les déploiements nécessitant des contrôles de changement. Consultez la documentation relative au [composant de solution change control workflow with ServiceNow](integrated_servicenow.md), et collaborez avec votre équipe de compte pour obtenir un code d'accès permettant de télécharger le package de solution Change Control Workflow with ServiceNow.
- Copiez les fichiers CI YAML dans votre projet :
  - `.gitlab-ci.yml`
  - `build-android.yml` dans le répertoire des pipelines. Vous devrez mettre à jour le chemin du fichier dans `.gitlab-ci.yml` si le fichier `build-android.yml` est placé dans un emplacement différent de /pipeline, car le fichier principal `.gitlab-ci.yml` fait référence au fichier `build-android.yml` pour le job de build.
  - `build-ios.yml` dans le répertoire des pipelines. Vous devrez mettre à jour le chemin du fichier dans `.gitlab-ci.yml` si le fichier `build-ios.yml` est placé dans un emplacement différent de /pipeline, car le fichier principal `.gitlab-ci.yml` fait référence au fichier `build-ios.yml` pour le job de build.

  ```yaml
  include:
    - local: "pipelines/build-ios.yml"
      inputs:
        image: macos-15-xcode-16
        tag: saas-macos-medium-m1
    - local: "pipelines/build-android.yml"
      inputs:
        image: reactnativecommunity/react-native-android
  ```

- Configurez les variables CI/CD requises dans les paramètres de votre projet. Consultez la section suivante pour comprendre le fonctionnement du pipeline.

## Fonctionnement du pipeline {#how-the-pipeline-works}

Ce pipeline est conçu pour un projet React Native, gérant les builds iOS et Android, ainsi que le test et le déploiement de l'application mobile.

Ce projet inclut une application de démonstration reactCounter simple pour le build React Native sur iOS et Android. Cette version ne signe pas encore les artefacts, il n'est donc pas possible de les charger sur TestFlight ou le Play Store.

Chaque modification utilise un composant pour les incréments de gestion sémantique de version, dont la version est stockée en tant que variable éphémère utilisée pour committer les paquets génériques dans le registre de paquets.

## Structure du pipeline {#pipeline-structure}

Le pipeline se compose des étapes et jobs suivants :

1. `prebuild`
   - `unit test`
   - `Snyk scans`
1. `build`
   - `build IoS package`
   - `build Android package`
1. `test`
   - `dependency scanning`
   - `SAST scanning`
1. `functional-test`
   - `upload_ios/android_app_to_sauce_labs`
   - `automated_test_appium_saucelabs`
1. `app-distribution`
   - `app_distribution_sauce_android`
   - `app_distribution_sauce_ios`
1. `beta-release`
   - `beta-release-dev`
   - `beta-release-approval`

## Prérequis {#prerequisites}

Plusieurs outils tiers sont intégrés dans le workflow de pipeline mobile. Pour exécuter correctement le pipeline, assurez-vous que les prérequis suivants sont en place.

### Intégration de Snyk à l'aide du composant {#snyk-integration-using-the-component}

Pour utiliser le composant CI/CD GitLab Snyk pour les analyses de sécurité, assurez-vous que votre groupe ou projet GitLab est déjà connecté à Snyk ; si ce n'est pas le cas, suivez [ce tutoriel](https://docs.snyk.io/scm-ide-and-ci-cd-integrations/snyk-scm-integrations/gitlab) pour le configurer.

Dans le projet d'application mobile, ajoutez les variables requises pour l'intégration Snyk.

#### Variables CI/CD requises {#required-cicd-variables}

| Variable | Description | Exemple de valeur |
|----------|-------------|---------------|
| `SNYK_TOKEN` | Jeton d'API pour accéder à Snyk | `d7da134c-xxxxxxxxxx` |

Ce projet de démonstration d'application mobile utilise un composant Snyk privé ; c'est pourquoi nous avons ajouté les variables supplémentaires suivantes pour que le projet d'application mobile puisse accéder au projet de composant Snyk privé. Cela n'est toutefois pas nécessaire si votre composant Snyk est public ou accessible au sein de votre groupe.

```yaml
SNYK_PROJECT_ACCESS_USERNAME: "MOBILE_APP_SNYK_COMPONENT_ACCESS"
DOCKER_AUTH_CONFIG: '{"auths":{"registry.gitlab.com":{"username":"$SNYK_PROJECT_ACCESS_USERNAME","password":"$SNYK_PROJECT_ACCESS_TOKEN"}}}'
```

#### Mettre à jour le chemin du composant {#update-the-component-path}

Mettez à jour le chemin du composant dans le fichier `.gitlab-ci.yml` afin que le pipeline puisse référencer correctement le composant Snyk.

```yaml
 - component: $CI_SERVER_FQDN/gitlab-com/product-accelerator/work-streams/packaging/snyk/snyk@1.0.0 #snky sast scan, this examples uses the component in GitLab the product accelerator group. Please update the path and stage accordingly.
    inputs:
      stage: prebuild
      token: $SNYK_TOKEN
```

### Intégration de Sauce Labs {#sauce-labs-integration}

Le CI/CD de ce projet de démonstration d'application mobile est intégré à Sauce Labs pour les tests fonctionnels automatisés. Pour exécuter les tests automatisés dans Sauce Labs, l'application doit être chargée dans le stockage d'applications Sauce Labs. Vous devrez définir les variables requises pour le projet dans GitLab afin d'accéder à Sauce Labs et de charger les artefacts.

#### Variables CI/CD requises {#required-cicd-variables-1}

| Variable | Description | Exemple de valeur |
|----------|-------------|---------------|
| `SAUCE_USERNAME` | Nom d'utilisateur Sauce Labs| `rz` |
| `SAUCE_ACCESS_KEY` | Clé d'API pour accéder à Sauce Labs  | `9f5wewwc-xxxxxxx` |
| `APP_FILE_PATH_IOS` | Chemin du fichier pour trouver les artefacts de build | `ios/build/reactCounter.ipa` |
| `APP_FILE_PATH_ANDROID` | Chemin du fichier pour trouver les artefacts de build | `android/app/build/outputs/apk/release/app-release.apk` |

#### Utiliser Appium pour les tests automatisés {#use-appium-for-automated-testing}

Pour utiliser SauceLabs dans le cadre des tests automatisés, l'application doit être chargée dans SauceLab App Management. Le pipeline utilise le point de terminaison de l'API pour charger l'application dans SauceLabs et la rendre disponible pour les tests.

Un fichier de script de test Appium a été ajouté dans `tests/appium` pour tester l'application mobile React Native à l'aide de WebdriverIO et Sauce Labs. Le script de test utilisera les variables d'environnement suivantes pour accéder à SauceLabs

``` bash
# Using the variables defined in the project

const SAUCE_USERNAME = process.env.SAUCE_USERNAME;
const SAUCE_ACCESS_KEY = process.env.SAUCE_ACCESS_KEY;

```

#### Distribution d'applications (Android et iOS) {#app-distribution-android-and-ios}

Le pipeline GitLab distribue les builds d'application vers SauceLabs TestFairy à des fins de démonstration. SauceLabs TestFairy permet aux utilisateurs de transmettre de nouvelles versions de l'application aux testeurs pour examen et test.

### Intégration de ServiceNow {#servicenow-integration}

Le CI/CD de ce projet de démonstration d'application mobile est intégré à ServiceNow pour les contrôles de changement. Lorsque le pipeline atteint le job de déploiement pour lequel le contrôle de changement est activé dans ServiceNow, une demande de changement est automatiquement créée. Une fois la demande de changement approuvée, le job de déploiement reprend. Avec ce projet de démonstration, le job d'approbation de release bêta est soumis à validation dans ServiceNow et nécessite une approbation manuelle pour continuer.

#### Variables CI/CD {#cicd-variables}

Pour que le pipeline puisse communiquer avec ServiceNow, les intégrations par webhook doivent être créées. Si vous utilisez des points de terminaison d'API pour communiquer avec ServiceNow, vous devrez inclure les variables suivantes. Toutefois, cela n'est pas requis lors de l'utilisation de l'intégration ServiceNow DevOps Change Velocity. Dans le cadre de l'intégration à ServiceNow DevOps Change Velocity, les webhooks seront créés.

| Variable | Description | Exemple de valeur |
|----------|-------------|---------------|
| `SNOW_URL` | URL de votre instance ServiceNow| `https://<SNOW_INSTANCE>.com/` |
| `SNOW_TOOLID` | ID de l'instance ServiceNow  | `3b5w345629212105c5ddaccwonworw2` |
| `SNOW_TOKEN` | Jeton d'API pour accéder à ServiceNow| `Oxxxxxxxxxx` |

## Fichiers et composants inclus {#included-files-and-components}

Le pipeline du projet d'application mobile inclut plusieurs configurations et composants externes :

- Configurations de build locales pour iOS et Android
- Composant SAST (test statique de sécurité des applications)
- Composant de gestion sémantique de version automatique
- Analyse des dépendances
- Composant d'analyse SAST Snyk

## Remarques {#notes}

Contactez votre équipe de compte pour obtenir un code d'invitation permettant d'accéder au composant de solution et pour toute question supplémentaire.

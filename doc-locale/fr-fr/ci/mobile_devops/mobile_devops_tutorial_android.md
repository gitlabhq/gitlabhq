---
stage: Verify
group: Mobile DevOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutoriel : Créer des applications Android avec GitLab Mobile DevOps'
---

Dans ce tutoriel, vous allez créer un pipeline à l'aide de GitLab CI/CD qui génère votre application mobile Android, la signe avec vos identifiants et la distribue sur les stores d'applications.

Pour configurer le Mobile DevOps :

1. [Configurer votre environnement de build](#set-up-your-build-environment)
1. [Configurer la signature du code avec fastlane et Gradle](#configure-code-signing-with-fastlane-and-gradle)
1. [Configurer la distribution d'applications Android avec l'intégration Google Play et fastlane](#set-up-android-apps-distribution-with-google-play-integration-and-fastlane)

## Avant de commencer {#before-you-begin}

Avant de commencer ce tutoriel, assurez-vous de disposer des éléments suivants :

- Un compte GitLab avec accès aux pipelines CI/CD
- Le code de votre application mobile dans un dépôt GitLab
- Un compte développeur Google Play
- [`fastlane`](https://fastlane.tools) installé localement

## Configurer votre environnement de build {#set-up-your-build-environment}

Utilisez des [runners hébergés par GitLab](../runners/_index.md) ou configurez des [runners auto-gérés](https://docs.gitlab.com/runner/#use-self-managed-runners) pour un contrôle total sur l'environnement de build.

Les builds Android utilisent des images Docker, proposant plusieurs versions de l'API Android.

1. Créez un fichier `.gitlab-ci.yml` à la racine de votre dépôt.
1. Ajoutez une image Docker depuis [Fabernovel](https://hub.docker.com/r/fabernovel/android/tags) :

   ```yaml
   test:
     image: fabernovel/android:api-33-v1.7.0
     stage: test
     script:
       - fastlane test
   ```

## Configurer la signature du code avec fastlane et Gradle {#configure-code-signing-with-fastlane-and-gradle}

Pour configurer la signature du code pour Android :

1. Créez un keystore :

   1. Exécutez la commande suivante pour générer un fichier keystore :

      ```shell
      keytool -genkey -v -keystore release-keystore.jks -storepass password -alias release -keypass password \
      -keyalg RSA -keysize 2048 -validity 10000
      ```

   1. Placez la configuration du keystore dans le fichier `release-keystore.properties` :

      ```plaintext
      storeFile=.secure_files/release-keystore.jks
      keyAlias=release
      keyPassword=password
      storePassword=password
      ```

   1. Importez les deux fichiers en tant que [Fichiers sécurisés](../secure_files/_index.md) dans les paramètres de votre projet.
   1. Ajoutez les deux fichiers à votre fichier `.gitignore` pour qu'ils ne soient pas commités dans le contrôle de version.
1. Configurez Gradle pour utiliser le keystore nouvellement créé. Dans le fichier `build.gradle` de l'application :

   1. Immédiatement après la section plugins, ajoutez :

      ```gradle
      def keystoreProperties = new Properties()
      def keystorePropertiesFile = rootProject.file('.secure_files/release-keystore.properties')
      if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
      }
      ```

   1. N'importe où dans le bloc `android`, ajoutez :

      ```gradle
      signingConfigs {
        release {
          keyAlias keystoreProperties['keyAlias']
          keyPassword keystoreProperties['keyPassword']
          storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
          storePassword keystoreProperties['storePassword']
        }
      }
      ```

   1. Ajoutez `signingConfig` au type de build release :

      ```gradle
      signingConfig signingConfigs.release
      ```

Voici des exemples de fichiers `fastlane/Fastfile` et `.gitlab-ci.yml` avec cette configuration :

- `fastlane/Fastfile` : 

  ```ruby
  default_platform(:android)

  platform :android do
    desc "Create and sign a new build"
    lane :build do
      gradle(tasks: ["clean", "assembleRelease", "bundleRelease"])
    end
  end
  ```

- `.gitlab-ci.yml` : 

  ```yaml
  build:
    image: fabernovel/android:api-33-v1.7.0
    stage: build
    script:
      - apt update -y && apt install -y curl
      - wget https://gitlab.com/gitlab-org/cli/-/releases/v1.74.0/downloads/glab_1.74.0_linux_amd64.deb
      - apt install ./glab_1.74.0_linux_amd64.deb
      - glab auth login --hostname $CI_SERVER_FQDN --job-token $CI_JOB_TOKEN
      - glab securefile download --all --output-dir .secure_files/
      - fastlane build
  ```

## Configurer la distribution d'applications Android avec l'intégration Google Play et fastlane {#set-up-android-apps-distribution-with-google-play-integration-and-fastlane}

Les builds signés peuvent être importés sur le Google Play Store à l'aide des intégrations de distribution Mobile DevOps.

1. [Créez un compte de service Google](https://docs.fastlane.tools/actions/supply/#setup) dans Google Cloud Platform et accordez à ce compte l'accès au projet dans Google Play.
1. Activez l'intégration Google Play :
   1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
   1. Sélectionnez **Paramètres** > **Intégrations**.
   1. Sélectionnez **Google Play**.
   1. Sous **Activer l'intégration**, cochez la case **Actif**.
   1. Dans **Package name**, saisissez le nom du package de l'application. Par exemple, `com.gitlab.app_name`.
   1. Dans **Clé de compte de service (.JSON)**, faites glisser ou importez votre fichier de clé.
   1. Sélectionnez **Sauvegarder les modifications**.
1. Ajoutez l'étape de release à votre pipeline.

Voici un exemple de fichier `fastlane/Fastfile` :

```ruby
default_platform(:android)

platform :android do
  desc "Submit a new Beta build to the Google Play store"
  lane :beta do
    upload_to_play_store(
      track: 'internal',
      aab: 'app/build/outputs/bundle/release/app-release.aab',
      release_status: 'draft'
    )
  end
end
```

Voici un exemple de fichier `.gitlab-ci.yml` :

```yaml
beta:
  image: fabernovel/android:api-33-v1.7.0
  stage: beta
  script:
    - fastlane beta
```

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, consultez la [démo de l'intégration Google Play](https://youtu.be/Fxaj3hna4uk).

Félicitations ! Votre application est maintenant configurée pour la génération, la signature et la distribution automatisées. Essayez de créer une merge request pour déclencher votre premier pipeline.

## Sujets connexes {#related-topics}

Consultez le projet [Android Demo](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/demo-projects/android_demo) de Mobile DevOps pour un exemple complet de pipeline de build, signature et release pour Android.

Pour des ressources de référence supplémentaires, consultez la [section DevSecOps](https://about.gitlab.com/blog/categories/devsecops/) du blog GitLab.

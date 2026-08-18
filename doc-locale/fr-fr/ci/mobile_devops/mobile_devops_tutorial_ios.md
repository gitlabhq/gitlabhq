---
stage: Verify
group: Mobile DevOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutoriel : Créer des applications iOS avec GitLab Mobile DevOps'
---

Dans ce tutoriel, vous allez créer un pipeline à l'aide de GitLab CI/CD qui compile votre application mobile iOS, la signe avec vos identifiants et la distribue sur les stores d'applications.

Pour configurer le Mobile DevOps :

1. [Configurer votre environnement de compilation](#set-up-your-build-environment)
1. [Configurer la signature de code avec fastlane](#configure-code-signing-with-fastlane)
1. [Configurer la distribution d'application avec l'intégration Apple Store et fastlane](#set-up-app-distribution-with-apple-store-integration-and-fastlane)

## Avant de commencer {#before-you-begin}

Avant de commencer ce tutoriel, assurez-vous de disposer des éléments suivants :

- Un compte GitLab avec accès aux pipelines CI/CD
- Le code de votre application mobile dans un dépôt GitLab
- Un compte Apple Developer
- [`fastlane`](https://fastlane.tools) installé localement

## Configurer votre environnement de compilation {#set-up-your-build-environment}

Utilisez des [runners hébergés par GitLab](../runners/_index.md) ou configurez des [runners autogérés](https://docs.gitlab.com/runner/#use-self-managed-runners) pour un contrôle total sur l'environnement de compilation.

1. Créez un fichier `.gitlab-ci.yml` à la racine de votre dépôt.
1. Ajoutez une [image macOS prise en charge](../runners/hosted_runners/macos.md#supported-macos-images) pour exécuter un job sur des [runners hébergés GitLab macOS](../runners/hosted_runners/macos.md) (version bêta) :

   ```yaml
   test:
     image: macos-14-xcode-15
     stage: test
     script:
       - fastlane test
     tags:
       - saas-macos-medium-m1
   ```

## Configurer la signature de code avec fastlane {#configure-code-signing-with-fastlane}

Pour configurer la signature de code pour iOS, chargez des certificats signés dans GitLab à l'aide de fastlane :

1. Initialisez fastlane :

   ```shell
   fastlane init
   ```

1. Générez un `Matchfile` avec la configuration :

   ```shell
   fastlane match init
   ```

1. Générez des certificats et des profils dans le portail Apple Developer et chargez ces fichiers dans GitLab :

   ```shell
   PRIVATE_TOKEN=YOUR-TOKEN bundle exec fastlane match development
   ```

1. facultatif. Si vous avez déjà créé des certificats de signature et des profils de provisionnement pour votre projet, utilisez `fastlane match import` pour charger vos fichiers existants dans GitLab :

   ```shell
   PRIVATE_TOKEN=YOUR-TOKEN bundle exec fastlane match import
   ```

Vous êtes invité à saisir le chemin d'accès à vos fichiers. Après avoir fourni ces informations, vos fichiers sont chargés et visibles dans les paramètres CI/CD de votre projet. Si `git_url` vous est demandé lors de l'importation, vous pouvez laisser ce champ vide et appuyer sur <kbd>enter</kbd>.

Voici des exemples de fichiers `fastlane/Fastfile` et `.gitlab-ci.yml` avec cette configuration :

- `fastlane/Fastfile` : 

  ```ruby
  default_platform(:ios)

  platform :ios do
    desc "Build and sign the application for development"
    lane :build do
      setup_ci

      match(type: 'development', readonly: is_ci)

      build_app(
        project: "ios demo.xcodeproj",
        scheme: "ios demo",
        configuration: "Debug",
        export_method: "development"
      )
    end
  end
  ```

- `.gitlab-ci.yml` : 

  ```yaml
  build_ios:
    image: macos-12-xcode-14
    stage: build
    script:
      - fastlane build
    tags:
      - saas-macos-medium-m1
  ```

## Configurer la distribution d'application avec l'intégration Apple Store et fastlane {#set-up-app-distribution-with-apple-store-integration-and-fastlane}

Les builds signés peuvent être chargés dans l'Apple App Store à l'aide des intégrations de distribution Mobile DevOps.

Prérequis :

- Vous devez avoir un identifiant Apple inscrit au programme Apple Developer.
- Vous devez générer une nouvelle clé privée pour votre projet dans le portail Apple App Store Connect.

Pour créer une distribution iOS avec l'intégration Apple Store et fastlane :

1. Générez une clé API pour l'API App Store Connect. Dans le portail Apple App Store Connect, [générez une nouvelle clé privée pour votre projet](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api).
1. Activez l'intégration Apple App Store Connect :
   1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
   1. Sélectionnez **Paramètres** > **Intégrations**.
   1. Sélectionnez **Apple App Store Connect**.
   1. Sous **Activer l'intégration**, cochez la case **Actif**.
   1. Fournissez les informations de configuration d'Apple App Store Connect :
      - **Issuer ID** : L'identifiant d'émetteur Apple App Store Connect.
      - **Key ID** : L'identifiant de la clé privée générée.
      - **Clé privée** : La clé privée générée. Vous ne pouvez télécharger cette clé qu'une seule fois.
      - **Étiquettes et branches protégées uniquement** : Activez cette option pour définir des variables uniquement sur les branches et étiquettes protégées.
   1. Sélectionnez **Sauvegarder les modifications**.
1. Ajoutez l'étape de release à votre pipeline et à votre configuration fastlane.

Voici un exemple de `fastlane/Fastfile` :

```ruby
default_platform(:ios)

platform :ios do
  desc "Build and sign the application for distribution, upload to TestFlight"
  lane :beta do
    setup_ci

    match(type: 'appstore', readonly: is_ci)

    app_store_connect_api_key

    increment_build_number(
      build_number: latest_testflight_build_number(initial_build_number: 1) + 1,
      xcodeproj: "ios demo.xcodeproj"
    )

    build_app(
      project: "ios demo.xcodeproj",
      scheme: "ios demo",
      configuration: "Release",
      export_method: "app-store"
    )

    upload_to_testflight
  end
end
```

Voici un exemple de `.gitlab-ci.yml` :

```yaml
beta_ios:
  image: macos-12-xcode-14
  stage: beta
  script:
    - fastlane beta
```

Félicitations ! Votre application est désormais configurée pour la compilation, la signature et la distribution automatisées. Essayez de créer un merge request pour déclencher votre premier pipeline.

## Exemples de projets {#sample-projects}

Des exemples de projets Mobile DevOps avec des pipelines configurés pour compiler, signer et publier des applications mobiles sont disponibles pour :

- Android
- Flutter
- iOS

Consultez tous les projets dans le groupe [Mobile DevOps Demo Projects](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/demo-projects/).

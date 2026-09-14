---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutoriel : configurer DAST pour analyser votre application web'
---

<!-- vale gitlab_base.FutureTense = NO -->

Apprenez à intégrer le test dynamique de sécurité des applications (DAST) dans votre pipeline CI/CD.

L'analyse statique détecte les vulnérabilités dans le code source. DAST identifie les problèmes de sécurité à l'exécution qui n'apparaissent que lorsque votre application s'exécute dans un environnement réel et interagit avec des services et des workflows utilisateur. Grâce à la solution DAST intégrée à GitLab, vous pouvez configurer GitLab DAST pour vérifier automatiquement ces problèmes à chaque déploiement de code dans un environnement de test.

Dans ce tutoriel, vous apprendrez à :

1. [Configurer l'application Tanuki Shop](#set-up-the-tanuki-shop-application)
1. [Définir le job de build](#define-the-build-job)
1. [Définir le job DAST](#define-the-dast-job)
1. [Configurer les analyses passives et actives](#configure-passive-and-active-scanning)
1. [Vérifier votre configuration](#verify-your-setup)

> [!note]
> L'application Tanuki Shop utilisée dans ce tutoriel ne requiert pas d'authentification. Si votre application nécessite une connexion, consultez [l'authentification DAST](configuration/authentication.md).

## Avant de commencer {#before-you-begin}

- Abonnement GitLab Ultimate
- Le rôle Maintainer pour votre projet

## Configurer l'application Tanuki Shop {#set-up-the-tanuki-shop-application}

Vous commencerez par dupliquer le dépôt Tanuki Shop.

1. Accédez au [dépôt Tanuki Shop](https://gitlab.com/gitlab-da/tutorials/security-and-governance/tanuki-shop).
1. Dans le coin supérieur droit, sélectionnez **Bifurcation**.
1. Sélectionnez votre espace de nommage (personnel ou de groupe) et sélectionnez **Bifurcation du projet**.

   Le dépôt dupliqué contient tous les fichiers nécessaires à ce tutoriel, notamment le code de l'application et la configuration CI/CD initiale. Nous modifierons la configuration au cours des étapes suivantes.

1. Accédez à **Paramètres** > **Général**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Assurez-vous que le bouton bascule **Registre de conteneurs** est activé.
1. Vérifiez que le registre de conteneurs fonctionne :
   1. Accédez à **Déployer** > **Registre de conteneurs**.
   1. Vous devriez voir un registre vide. Si une erreur s'affiche, vérifiez les permissions de votre projet.

   > [!note]
   > Le registre de conteneurs stocke les images Docker générées dans votre pipeline. Si cette étape échoue, le job de build échouera ultérieurement.

## Définir le job de build {#define-the-build-job}

Vous allez maintenant configurer le job de build pour créer une image Docker contenant votre application et la transférer vers le registre de conteneurs.

1. Dans votre projet, modifiez le fichier `.gitlab-ci.yml`.
1. Remplacez le contenu existant par la configuration CI/CD suivante :

   ```yaml
   stages:
     - build
     - dast

   include:
     - template: Security/DAST.gitlab-ci.yml

   # Build: Create the Docker image and push to the container registry
   build:
     services:
       - name: docker:dind
         alias: dind
     image: docker:20.10.16
     stage: build
     script:
       - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
       - docker pull $CI_REGISTRY_IMAGE:latest || true
       - docker build --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --tag $CI_REGISTRY_IMAGE:latest .
       - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
       - docker push $CI_REGISTRY_IMAGE:latest
   ```

## Définir le job DAST {#define-the-dast-job}

Maintenant que le job de build est configuré, vous allez configurer le job DAST.

Cette configuration utilise la fonctionnalité services pour exécuter le conteneur de l'application en parallèle avec le job DAST. L'application est accessible au job `dast` à l'URL `http://yourapp:3000`.

Pour configurer le job DAST :

- Ajoutez ce qui suit au bas du fichier `.gitlab-ci.yml` :

  ```yaml
  # DAST: Scan the application running in a Docker container
  dast:
    services:
      - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        alias: yourapp
    variables:
      DAST_TARGET_URL: http://yourapp:3000
  ```

## Configurer les analyses passives et actives {#configure-passive-and-active-scanning}

DAST prend en charge deux modes d'analyse qui permettent d'équilibrer la couverture de sécurité et la durée d'analyse. Les analyses passives fournissent un retour rapide. Les analyses actives détectent les vulnérabilités qui n'apparaissent que lorsque l'application est testée avec des requêtes spécialement conçues, offrant une validation de sécurité plus approfondie avant que le code n'atteigne la production.

Analyses passives (par défaut, environ 2-5 minutes) :

- Analyser les réponses de l'application sans envoyer de requêtes potentiellement dangereuses
- Examiner les en-têtes HTTP, les cookies, le contenu des réponses et la configuration SSL/TLS
- Sûr à exécuter dans n'importe quel environnement
- Idéal pour un retour rapide dans les pipelines CI/CD

Analyses actives (environ 10-30 minutes selon la taille de l'application) :

- Envoyer des requêtes spécialement conçues pour déclencher des vulnérabilités
- Tester les failles d'injection, les problèmes d'authentification et les vulnérabilités de logique métier
- Plus approfondi mais plus lent
- Idéal pour les branches de fonctionnalités avant la fusion dans la branche principale

> [!note]
> N'exécutez pas d'analyses DAST contre un serveur de production. Non seulement il peut effectuer toutes les actions qu'un utilisateur peut réaliser, comme sélectionner des boutons ou soumettre des formulaires, mais il peut également déclencher des bugs, entraînant la modification ou la perte de données de production. Exécutez uniquement les analyses DAST contre un serveur de test.

Pour configurer les analyses passives et actives :

- Ajoutez ce qui suit au bas du fichier `.gitlab-ci.yml` :

  ```yaml
    rules:
      - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
        variables:
          DAST_FULL_SCAN: "false"  # Passive scan only for main branch (~2-5 mins)
      - if: $CI_COMMIT_REF_NAME != $CI_DEFAULT_BRANCH
        variables:
          DAST_FULL_SCAN: "true"   # Active scan for feature branches (~10-30 mins)
  ```

## Vérifier votre configuration {#verify-your-setup}

Vérifiez que DAST peut détecter des vulnérabilités dans votre application en cours d'exécution.

1. Dans l'éditeur de pipeline, sélectionnez **Valider les modifications** et effectuez un commit sur la branche `gitlab`.

   Un pipeline démarre immédiatement.
1. Accédez à **Version** > **Pipelines** et vérifiez que votre dernier pipeline s'est terminé avec succès.

   Chronologie prévue :
   - Étape de build : 2-3 minutes (création de l'image Docker)
   - Étape DAST : 2-5 minutes (analyse passive)

1. Une fois le pipeline terminé avec succès, accédez à **Sécuriser** > **Rapport de vulnérabilités**.
1. Examinez les vulnérabilités. Pour obtenir de l'aide sur la marche à suivre pour chaque vulnérabilité, consultez [comment remédier à une vulnérabilité](../../remediate/_index.md).

> [!note]
> L'application Tanuki Shop est intentionnellement vulnérable à des fins de démonstration. Vous devriez voir des résultats liés aux politiques de sécurité, à l'exposition d'informations personnellement identifiables (PII) et à d'autres vulnérabilités web courantes.

## Étapes suivantes {#next-steps}

Après avoir suivi ce tutoriel, vous pouvez :

- Configurer les [paramètres avancés de DAST](configuration/customize_settings.md) selon vos besoins spécifiques.
- Configurer des [analyses DAST à la demande](../on-demand_scan.md) pour des tests ponctuels.
- Intégrer DAST avec les [workflows de gestion des vulnérabilités](../../vulnerabilities/_index.md).
- Explorer le [dépôt de démonstrations DAST](https://gitlab.com/gitlab-org/security-products/demos/dast/) pour plus d'exemples.

## Dépannage {#troubleshooting}

### Échec du job de build avec des erreurs d'authentification {#build-job-fails-with-authentication-errors}

Des erreurs d'authentification se produisent lorsque les identifiants du registre de conteneurs ne sont pas disponibles.

Pour résoudre le problème :

1. Vérifiez que le registre de conteneurs est activé :
   1. Accédez à **Paramètres** > **Général**.
   1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
   1. Assurez-vous que le bouton bascule **Registre de conteneurs** est activé.

1. Vérifiez que votre projet dispose d'un jeton CI/CD valide. GitLab fournit automatiquement `$CI_REGISTRY_USER` et `$CI_REGISTRY_PASSWORD`.

### Le job DAST se termine mais aucune vulnérabilité n'est trouvée {#dast-job-completes-but-no-vulnerabilities-are-found}

Ce problème survient lorsque DAST ne peut pas atteindre l'application ou que l'application n'est pas vulnérable.

Pour résoudre ce problème :

1. Vérifiez que l'application est en cours d'exécution :

   ```shell
   curl "http://yourapp:3000"
   ```

1. Consultez les job logs DAST pour détecter les erreurs liées à la connectivité.
1. Vérifiez que la variable `DAST_TARGET_URL` est correctement définie (elle doit être `http://yourapp:3000`).
1. L'application Tanuki Shop devrait présenter des vulnérabilités. Si aucune n'est trouvée, vérifiez que vous utilisez le bon dépôt dupliqué.

## Sujets connexes {#related-topics}

- [Référence de configuration DAST](configuration/customize_settings.md)
- [Politiques de sécurité](../../policies/_index.md)
- [Gestion des vulnérabilités](../../vulnerabilities/_index.md)
- [Solutions de test de sécurité des applications](https://about.gitlab.com/solutions/application-security-testing/)

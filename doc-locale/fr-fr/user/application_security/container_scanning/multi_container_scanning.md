---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyse multi-conteneurs
description: "Analyse des vulnérabilités d'images, configuration, personnalisation et reporting."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version bêta

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/groups/gitlab-org/-/epics/3139) en tant que [version expérimentale](../../../policy/development_stages_support.md) dans GitLab 18.7.

{{< /history >}}

Utilisez l'analyse multi-conteneurs pour analyser plusieurs images de conteneurs dans un seul pipeline. Cette fonctionnalité vous permet de :

- Analyser plusieurs images en parallèle.
- Configurer les cibles d'analyse dans un seul fichier de configuration.
- S'intégrer aux workflows d'analyse de conteneurs existants.

L'analyse multi-conteneurs utilise les [pipelines enfants dynamiques](../../../ci/pipelines/downstream_pipelines.md#dynamic-child-pipelines) pour exécuter les analyses en parallèle, réduisant ainsi le temps d'exécution global du pipeline.

## Images prises en charge {#supported-images}

L'analyse multi-conteneurs prend en charge :

- Les images provenant de registres publics (Docker Hub, GitLab Container Registry et autres)
- Les images provenant de registres privés (avec authentification configurée)
- Les images multi-architectures

## Activer l'analyse multi-conteneurs {#turn-on-multi-container-scanning}

Prérequis :

- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet
- GitLab Runner avec exécuteur Docker
- Un fichier de configuration `.gitlab-multi-image.yml` à la racine de votre dépôt
- Au moins une image de conteneur à analyser

Pour activer l'analyse multi-conteneurs :

1. Créez un fichier `.gitlab-multi-image.yml` à la racine de votre dépôt :

   ```yaml
      scanTargets:
        - name: alpine
          tag: latest
        - name: python
          tag: 3.9-slim
   ```

1. Incluez le template dans votre `.gitlab-ci.yml` :

   ```yaml
      include:
        - template: Jobs/Multi-Container-Scanning.latest.gitlab-ci.yml
   ```

1. Commitez et poussez vos modifications. Le pipeline exécute les analyses automatiquement.

## Configuration {#configuration}

Configurez l'analyse multi-conteneurs en modifiant le fichier `.gitlab-multi-image.yml`.

### Exemple de configuration de base {#basic-configuration-example}

```yaml
scanTargets:
  - name: alpine
    tag: "3.19"
  - name: ubuntu
    tag: "22.04"
```

### Exemple de configuration complète {#complete-configuration-example}

```yaml
# Include license information in reports
includeLicenses: true

# Configure registry authentication
auths:
  registry.example.com:
    username: ${REGISTRY_USER}
    password: ${REGISTRY_PASSWORD}

# Allow insecure connections (not recommended for production)
allowInsecure: false

# Additional CA certificates for custom registries
additionalCaCertificateBundle: |
  -----BEGIN CERTIFICATE-----
  ...
  -----END CERTIFICATE-----

# Images to scan
scanTargets:
  - name: registry.example.com/myapp
    tag: "v1.2.3"
  - name: postgres
    tag: "15-alpine"
```

### Options de configuration {#configuration-options}

> [!note]
> Vous ne pouvez pas spécifier de tags de runner pour les jobs enfants dans l'analyse multi-conteneurs, mais le [ticket 363687](https://gitlab.com/gitlab-org/gitlab/-/work_items/363687) propose de modifier ce comportement.

| Option                          | Type    | Obligatoire | Description                              |
|---------------------------------|---------|----------|------------------------------------------|
| `scanTargets`                   | Tableau   | Oui      | Liste des images de conteneurs à analyser         |
| `scanTargets[].name`            | Chaîne  | Oui      | Nom de l'image (avec registre optionnel)      |
| `scanTargets[].tag`             | Chaîne  | Non       | Tag de l'image (par défaut : `latest`)            |
| `scanTargets[].registry`        | Chaîne  | Non       | Remplacement du registre                        |
| `includeLicenses`               | Booléen | Non       | Inclure les informations de licence dans les rapports   |
| `auths`                         | Objet  | Non       | Identifiants d'authentification du registre      |
| `allowInsecure`                 | Booléen | Non       | Autoriser les connexions HTTPS non sécurisées         |
| `additionalCaCertificateBundle` | Chaîne  | Non       | Certificats CA supplémentaires au format PEM |

## Scénarios courants {#common-scenarios}

Les sections suivantes décrivent quelques exemples de scénarios que vous pouvez adapter à vos besoins.

### Analyser des images provenant de différents registres {#scan-images-from-different-registries}

```yaml
scanTargets:
  - name: docker.io/library/nginx
    tag: "1.25"
  - name: registry.gitlab.com/mygroup/myapp
    tag: "main"
  - name: gcr.io/myproject/service
    tag: "prod"
```

### Utiliser l'authentification par registre privé {#use-private-registry-authentication}

```yaml
auths:
  registry.gitlab.com:
    username: ${CI_REGISTRY_USER}
    password: ${CI_REGISTRY_PASSWORD}
  docker.io:
    username: ${DOCKERHUB_USER}
    password: ${DOCKERHUB_TOKEN}

scanTargets:
  - name: registry.gitlab.com/private/image
    tag: latest
```

### Analyser des versions spécifiques à des fins de conformité {#scan-specific-versions-for-compliance}

```yaml
scanTargets:
  - name: postgres
    tag: "14.10"
  - name: redis
    tag: "7.2.3"
  - name: nginx
    tag: "1.25.3"
```

### Analyser des images construites dynamiquement {#scan-dynamically-built-images}

Si les noms et les tags d'images ne sont connus qu'au moment de l'exécution, vous ne pouvez pas définir `scanTargets` dans un fichier statique `.gitlab-multi-image.yml`.

Pour analyser ces images, remplacez le job `multi-cs::generate-scan` afin de construire le fichier de configuration dynamiquement à partir des artefacts dotenv produits par vos jobs de build :

```yaml
include:
  - template: Jobs/Multi-Container-Scanning.latest.gitlab-ci.yml

.build-rules: &build-rules
  rules:
    - if: $CONTAINER_SCANNING_DISABLED == 'true' || $CONTAINER_SCANNING_DISABLED == '1'
      when: never
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

build-image-1:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  <<: *build-rules
  script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "$CI_REGISTRY"
    - export IMAGE1_NAME="$CI_REGISTRY_IMAGE/app1:$CI_COMMIT_SHORT_SHA-$CI_JOB_ID"
    - docker build -f Dockerfiles/Dockerfile.app1 -t "$IMAGE1_NAME" .
    - docker push "$IMAGE1_NAME"
    - echo "IMAGE1_NAME=$IMAGE1_NAME" >> build1.env
  artifacts:
    reports:
      dotenv: build1.env

build-image-2:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  <<: *build-rules
  script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "$CI_REGISTRY"
    - export IMAGE2_NAME="$CI_REGISTRY_IMAGE/app2:$CI_COMMIT_SHORT_SHA-$CI_JOB_ID"
    - docker build -f Dockerfiles/Dockerfile.app2 -t "$IMAGE2_NAME" .
    - docker push "$IMAGE2_NAME"
    - echo "IMAGE2_NAME=$IMAGE2_NAME" >> build2.env
  artifacts:
    reports:
      dotenv: build2.env

# Override the template job to inject the dynamically generated config
multi-cs::generate-scan:
  needs:
    - job: build-image-1
      artifacts: true
    - job: build-image-2
      artifacts: true
  before_script:
    - !reference [.multi-cs-generate-scan-base, before_script]  # preserve template steps if any
    - IMAGE1_REPO="${IMAGE1_NAME%:*}"
    - IMAGE1_TAG="${IMAGE1_NAME##*:}"
    - IMAGE2_REPO="${IMAGE2_NAME%:*}"
    - IMAGE2_TAG="${IMAGE2_NAME##*:}"
    - |
      cat > .gitlab-multi-image.yml <<EOF
      scanTargets:
        - name: ${IMAGE1_REPO}
          tag: ${IMAGE1_TAG}
        - name: ${IMAGE2_REPO}
          tag: ${IMAGE2_TAG}
      auths:
        registry.gitlab.com: # Replace with your $CI_REGISTRY value for self-managed GitLab
          username: \${CI_REGISTRY_USER}
          password: \${CI_REGISTRY_PASSWORD}
      EOF
```

## Variables CI/CD {#cicd-variables}

Vous pouvez personnaliser le comportement de l'analyse multi-conteneurs en utilisant des variables CI/CD.

| Variable                      | Valeur par défaut                                                | Description                                |
|-------------------------------|--------------------------------------------------------|--------------------------------------------|
| `CONTAINER_SCANNING_DISABLED` | -                                                      | Définir sur `true` ou `1` pour désactiver l'analyse   |
| `AST_ENABLE_MR_PIPELINES`     | `true`                                                 | Activer l'analyse dans les pipelines de merge request |
| `CS_SCANNER_IMAGE`            | `registry.gitlab.com/.../multiple-container-scanner:0` | Image du scanner à utiliser                       |

### Désactiver l'analyse multi-conteneurs {#disable-multi-container-scanning}

Pour désactiver temporairement l'analyse :

```yaml
variables:
  CONTAINER_SCANNING_DISABLED: "true"
```

### Désactiver l'analyse des pipelines de MR {#disable-mr-pipeline-scanning}

```yaml
variables:
  AST_ENABLE_MR_PIPELINES: "false"
```

## Afficher les résultats de l'analyse {#view-scan-results}

Prérequis :

- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet
- L'analyse multi-conteneurs est activée pour le projet
- Un pipeline s'est terminé avec des résultats d'analyse de conteneurs

Pour afficher les résultats de l'analyse :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Accédez à votre merge request ou à la page de détails du pipeline.
1. Sélectionnez l'onglet **Sécurisation**.
1. Affichez les vulnérabilités détectées dans toutes les images analysées.

Chaque image analysée génère :

- Un rapport d'analyse de conteneurs
- Un SBOM CycloneDX (Software Bill of Materials)
- Les informations de licence (si `includeLicenses: true`)

### Structure du pipeline {#pipeline-structure}

L'analyse multi-conteneurs crée deux jobs :

- `multi-cs::generate-scan` : génère la configuration de l'analyse
- `multi-cs::trigger-scan` : déclenche un pipeline enfant avec des jobs d'analyse en parallèle

Le pipeline enfant contient un job par image dans `scanTargets`.

## Dépannage {#troubleshooting}

Lorsque vous utilisez l'analyse multi-conteneurs, vous pouvez rencontrer les problèmes suivants.

### Le pipeline échoue avec « configuration file not found » {#pipeline-fails-with-configuration-file-not-found}

Cause : le fichier `.gitlab-multi-image.yml` est manquant ou se trouve au mauvais emplacement.

Solution : assurez-vous que `.gitlab-multi-image.yml` existe à la racine de votre dépôt.

### L'authentification échoue pour un registre privé {#authentication-fails-for-private-registry}

Cause : identifiants invalides ou configuration d'authentification manquante.

Solution :

1. Vérifiez que les identifiants sont corrects et correctement configurés.

   ```yaml
      auths:
        registry.example.com:
          username: ${REGISTRY_USER}
          password: ${REGISTRY_PASSWORD}
   ```

1. Définissez les variables dans **Paramètres** > **CI/CD** > **Variables**.

### L'analyse prend trop de temps {#scan-takes-too-long}

Cause : plusieurs images volumineuses sont analysées de manière séquentielle.

Solution : l'analyse multi-conteneurs exécute déjà les analyses en parallèle.

Envisagez :

- D'utiliser des images de base plus légères
- D'analyser uniquement des versions d'images spécifiques
- D'ajuster les paramètres de concurrence de GitLab Runner

### Le pipeline enfant n'affiche pas les rapports {#child-pipeline-doesnt-show-reports}

Cause : absence de `strategy: mirror` dans la configuration du déclencheur.

Solution : ceci est configuré par défaut dans le template. Si vous avez personnalisé le template, assurez-vous que le job déclencheur inclut `strategy: mirror`.

### Le pipeline enfant s'exécute sur un runner inattendu {#child-pipeline-runs-on-unexpected-runner}

Il est possible que les jobs du pipeline enfant s'exécutent sur un runner que vous n'attendiez pas.

Ce problème survient car les jobs du pipeline enfant n'héritent pas des tags de runner du job parent. [Le ticket 363687](https://gitlab.com/gitlab-org/gitlab/-/work_items/363687) propose de modifier ce comportement.

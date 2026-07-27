---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Attestations de provenance SLSA niveau 3
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com
- Statut : Expérience

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/547865) dans GitLab 18.3 [avec un flag](../../../../administration/feature_flags/_index.md) nommé `slsa_provenance_statement`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

GitLab peut générer des attestations de provenance compatibles avec le niveau 3 de SLSA. Les principales différences entre les attestations de provenance de niveau 2 et 3 sont les [exigences d'isolation et de non-falsifiabilité](https://slsa.dev/spec/v1.2/build-requirements#isolated).

Pour plus de détails sur les attestations, consultez la [spécification de provenance SLSA](provenance_v1.md) de GitLab.

## Prérequis {#prerequisites}

Ces conditions doivent être remplies pour l'attestation de tout conteneur ou artefact :

- Le projet associé au build est public. Cette exigence est appliquée pour prévenir la divulgation accidentelle d'informations à [Rekor](https://docs.sigstore.dev/logging/overview/).
- Le build doit utiliser l'`build` étape.
- Le `slsa_provenance_statement` feature flag doit être activé pour le projet.

## Générer une attestation pour des artefacts {#generate-an-attestation-for-artifacts}

Pour générer une attestation pour tous les artefacts produits par un build :

- Définissez la `ATTEST_BUILD_ARTIFACTS` variable CI/CD sur `true`.
- L'artefact ne doit pas dépasser 100 Mo.

Par exemple, GitLab génère une attestation pour les artefacts dans ce job CI/CD :

```yaml
build-job:
  stage: build
  variables:
    ATTEST_BUILD_ARTIFACTS: true
  script:
    - echo "Hello, $GITLAB_USER_LOGIN!"
    - echo "Hello, $GITLAB_USER_LOGIN!" > test.txt
  artifacts:
    paths:
      - test.txt
```

## Générer une attestation pour un conteneur {#generate-an-attestation-for-a-container}

Pour générer une attestation pour un conteneur :

- Définissez la variable CI/CD `ATTEST_CONTAINER_IMAGES` sur `true`.
- Définissez la variable `IMAGE_DIGEST` sur une référence SHA256 valide, avec ce format :

  ```plaintext
  sha256:9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9
  org/project-name@sha256:9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9
  9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9
  ```

Par exemple, GitLab génère une attestation pour l'image créée dans ce job CI/CD :

```yaml
build-dockerhub:
  stage: build
  variables:
    ATTEST_CONTAINER_IMAGES: true
    CI_REGISTRY: docker.io
    DOCKER_IMAGE_NAME: sroqueworcel/test-slsa-sbom:stable
  script:
    - echo $DOCKER_REGISTRY_PASSWORD | docker login $CI_REGISTRY -u $DOCKER_REGISTRY_USER --password-stdin
    - docker build -t $DOCKER_IMAGE_NAME .
    - docker push $DOCKER_IMAGE_NAME
    - IMAGE_DIGEST="$(docker inspect --format='{{index .Id}}' "$DOCKER_IMAGE_NAME")"
    - echo "IMAGE_DIGEST=$IMAGE_DIGEST" >> build.env
  artifacts:
    reports:
      dotenv: build.env
```

## Afficher les attestations {#view-attestations}

Les attestations réussies sont stockées dans la page des attestations. Pour afficher les attestations :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Attestations**.

Si l'attestation échoue, le job log CI/CD affiche une erreur.

Vous pouvez également récupérer les attestations réussies avec l'[API Attestations](../../../../api/attestations.md).

## Vérification des attestations {#verifying-attestations}

Vous pouvez vérifier les artefacts et les conteneurs en utilisant l'interface de ligne de commande `glab`. Par exemple :

- Une vérification réussie :

  ```shell
  % glab attestation verify ~/file-or-container -p org/project-name
  Artifact provenance successfully verified. Signatures confirm file.txt was attested by org/project-name
  ```

- Une vérification échouée :

  ```shell
  % glab attestation verify ~/file.txt -p org/project-name

     ERROR

    Unable to find a provenance statement for 1f9e5808a340916aa5618ee13a893dcf9d4f7e2d42a254be0f7eb06a094ab8ea.
  ```

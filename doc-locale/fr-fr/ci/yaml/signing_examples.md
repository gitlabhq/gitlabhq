---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser Sigstore pour la signature et la vérification sans clé
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

Le projet [Sigstore](https://www.sigstore.dev/) fournit une CLI appelée [Cosign](https://docs.sigstore.dev/quickstart/quickstart-cosign/) qui peut être utilisée pour la signature sans clé d'images de conteneurs créées avec GitLab CI/CD. La signature sans clé présente de nombreux avantages, notamment en éliminant la nécessité de gérer, de protéger et de faire tourner une clé privée. Cosign demande une paire de clés à durée de vie courte à utiliser pour la signature, l'enregistre dans un journal de transparence des certificats, puis la supprime. La clé est générée via un jeton obtenu auprès du serveur GitLab en utilisant l'identité OIDC de l'utilisateur qui a exécuté le pipeline. Ce jeton inclut des revendications uniques qui certifient que le jeton a été généré par un pipeline CI/CD. Pour en savoir plus, consultez la [documentation](https://docs.sigstore.dev/quickstart/quickstart-cosign/#example-working-with-containers) de Cosign sur les signatures sans clé.

Pour plus de détails sur le mappage entre les revendications OIDC de GitLab et les extensions de certificats Fulcio, consultez la colonne GitLab de [Mapping OIDC token claims to Fulcio OIDs](https://github.com/sigstore/fulcio/blob/main/docs/oid-info.md#mapping-oidc-token-claims-to-fulcio-oids).

Prérequis :

- Vous devez utiliser GitLab.com.
- La configuration CI/CD de votre projet doit être située dans le projet.

## Signer ou vérifier des images de conteneurs et des artefacts de build en utilisant Cosign {#sign-or-verify-container-images-and-build-artifacts-by-using-cosign}

Vous pouvez utiliser Cosign pour signer et vérifier des images de conteneurs et des artefacts de build.

Prérequis :

- Vous devez utiliser une version de Cosign qui est `>= 2.0.1`.

**Problèmes connus**

- La portion `id_tokens` du fichier de configuration CI/CD doit être située dans le projet en cours de build et de signature. AutoDevOps, les fichiers CI inclus depuis un autre dépôt et les pipelines enfants ne sont pas pris en charge. Le travail visant à supprimer cette limitation est suivi dans l'[epic 11637](https://gitlab.com/groups/gitlab-org/-/epics/11637).

**Bonnes pratiques** :

- Créez et signez une image/un artefact dans le même job pour éviter qu'il soit altéré avant d'être signé.
- Lors de la signature d'images de conteneurs, signez le condensé (qui est immuable) plutôt que le tag.

Les [jetons ID](../secrets/id_token_authentication.md) GitLab peuvent être utilisés par Cosign pour la [signature sans clé](https://docs.sigstore.dev/quickstart/quickstart-cosign/#keyless-signing-of-a-container). Le jeton doit avoir `sigstore` défini comme revendication [`aud`](../secrets/id_token_authentication.md#token-payload). Le jeton peut être utilisé automatiquement par Cosign lorsqu'il est défini dans la variable d'environnement `SIGSTORE_ID_TOKEN`.

Pour en savoir plus sur l'installation de Cosign, consultez la [documentation d'installation de Cosign](https://docs.sigstore.dev/cosign/system_config/installation/).

### Signature {#signing}

#### Images de conteneurs {#container-images}

Le template [`Cosign.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Cosign.gitlab-ci.yml) peut être utilisé pour créer et signer une image de conteneur dans GitLab CI. La signature est automatiquement stockée dans le même dépôt de conteneurs que l'image.

```yaml
include:
- template: Cosign.gitlab-ci.yml
```

Pour en savoir plus sur la signature de conteneurs, consultez la [documentation Cosign Signing Containers](https://docs.sigstore.dev/cosign/signing/signing_with_containers/).

#### Artefacts de build {#build-artifacts}

L'exemple suivant illustre comment signer un artefact de build dans GitLab CI. Vous devez enregistrer le fichier `cosign.bundle` produit par `cosign sign-blob`, qui est utilisé pour la vérification des signatures.

Pour en savoir plus sur la signature d'artefacts, consultez la [documentation Cosign Signing Blobs](https://docs.sigstore.dev/cosign/signing/signing_with_blobs/).

```yaml
build_and_sign_artifact:
  stage: build
  image: alpine:latest
  variables:
    COSIGN_YES: "true"
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  before_script:
    - apk add --update cosign
  script:
    - echo "This is a build artifact" > artifact.txt
    - cosign sign-blob artifact.txt --bundle cosign.bundle
  artifacts:
    paths:
      - artifact.txt
      - cosign.bundle
```

### Vérification {#verification}

**Arguments de ligne de commande**

| Nom                        | Valeur |
|-----------------------------|-------|
| `--certificate-identity`    | Le SAN du certificat de signature émis par Fulcio. Peut être construit avec les informations suivantes provenant du projet où l'image/l'artefact a été signé(e) : URL de l'instance GitLab + chemin du projet + `//` + chemin de configuration CI + `@` \+ chemin de référence. |
| `--certificate-oidc-issuer` | L'URL de l'instance GitLab où l'image/l'artefact a été signé(e). Par exemple, `https://gitlab.com`. |
| `--bundle`                  | Le fichier `bundle` produit par `cosign sign-blob`. Utilisé uniquement pour la vérification des artefacts de build. |

Pour en savoir plus sur la vérification des images/artefacts signés, consultez la [documentation Cosign Verifying](https://docs.sigstore.dev/cosign/verifying/verify/).

#### Images de conteneurs {#container-images-1}

L'exemple suivant illustre comment vérifier une image de conteneur signée dans GitLab CI. Utilisez les [arguments de ligne de commande](#verification) décrits précédemment.

```yaml
verify_image:
  image: alpine:3.20
  stage: verify
  before_script:
    - apk add --update cosign docker
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" $CI_REGISTRY
  script:
    - cosign verify "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG" --certificate-identity "https://gitlab.com/my-group/my-project//path/to/.gitlab-ci.yml@refs/heads/main" --certificate-oidc-issuer "https://gitlab.com"
```

**Informations complémentaires** :

- La double barre oblique inverse entre le chemin du projet et le chemin `.gitlab-ci.yml` n'est pas une erreur et est requise pour que la vérification réussisse. Une erreur courante lors de l'utilisation d'une seule barre oblique est `Error: none of the expected identities matched what was in the certificate, got subjects` suivi de l'URL signée qui contient deux barres obliques entre le chemin du projet et le chemin `.gitlab-ci.yml`.
- Si la vérification se déroule dans le même pipeline que la signature, ce chemin peut être utilisé : `"${CI_PROJECT_URL}//.gitlab-ci.yml@refs/heads/${CI_COMMIT_REF_NAME}"`

#### Artefacts de build {#build-artifacts-1}

L'exemple suivant illustre comment vérifier un artefact de build signé dans GitLab CI. La vérification d'un artefact nécessite à la fois l'artefact lui-même et le fichier `cosign.bundle` produit par `cosign sign-blob`. Utilisez les [arguments de ligne de commande](#verification) décrits précédemment.

```yaml
verify_artifact:
  stage: verify
  image: alpine:latest
  before_script:
    - apk add --update cosign
  script:
    - cosign verify-blob artifact.txt --bundle cosign.bundle --certificate-identity "https://gitlab.com/my-group/my-project//path/to/.gitlab-ci.yml@refs/heads/main" --certificate-oidc-issuer "https://gitlab.com"
```

**Informations complémentaires** :

- La double barre oblique inverse entre le chemin du projet et le chemin `.gitlab-ci.yml` n'est pas une erreur et est requise pour que la vérification réussisse. Une erreur courante lors de l'utilisation d'une seule barre oblique est `Error: none of the expected identities matched what was in the certificate, got subjects` suivi de l'URL signée qui contient deux barres obliques entre le chemin du projet et le chemin `.gitlab-ci.yml`.
- Si la vérification se déroule dans le même pipeline que la signature, ce chemin peut être utilisé : `"${CI_PROJECT_URL}//.gitlab-ci.yml@refs/heads/${CI_COMMIT_REF_NAME}"`

## Utiliser Sigstore et npm pour générer une provenance sans clé {#use-sigstore-and-npm-to-generate-keyless-provenance}

Vous pouvez utiliser Sigstore et npm, avec GitLab CI/CD, pour signer numériquement des artefacts de build sans la complexité de la gestion des clés.

### À propos de la provenance npm {#about-npm-provenance}

[npm CLI](https://docs.npmjs.com/cli/) permet aux mainteneurs de paquets de fournir aux utilisateurs des attestations de provenance. L'utilisation de la génération de provenance via npm CLI permet aux utilisateurs de faire confiance et de vérifier que le paquet qu'ils téléchargent et utilisent provient bien de vous et du système de build qui l'a construit.

Pour plus d'informations sur la publication de paquets npm, consultez le [registre de paquets npm GitLab](../../user/packages/npm_registry/_index.md).

### Sigstore {#sigstore}

[Sigstore](https://www.sigstore.dev/) est un ensemble d'outils que les gestionnaires de paquets et les experts en sécurité peuvent utiliser pour protéger leurs chaînes d'approvisionnement logicielles contre les attaques. En réunissant des technologies open source gratuites telles que Fulcio, Cosign et Rekor, il gère la signature numérique, la vérification et les contrôles de provenance nécessaires pour distribuer et utiliser les logiciels open source de manière plus sécurisée.

**Sujets connexes** :

- [Définition de la provenance SLSA](https://slsa.dev/provenance/v1)
- [Documentation npm](https://docs.npmjs.com/generating-provenance-statements/)
- [npm Provenance RFC](https://github.com/npm/rfcs/blob/main/accepted/0049-link-packages-to-source-and-build.md#detailed-steps-to-publish)

### Génération de provenance dans GitLab CI/CD {#generating-provenance-in-gitlab-cicd}

Maintenant que Sigstore prend en charge GitLab OIDC comme décrit précédemment, vous pouvez utiliser la provenance npm avec GitLab CI/CD et Sigstore pour générer et signer la provenance de vos paquets npm dans un pipeline CI/CD GitLab.

#### Prérequis {#prerequisites}

1. Définissez votre [jeton ID](../secrets/id_token_authentication.md) GitLab `aud` sur `sigstore`.
1. Ajoutez le flag `--provenance` pour que npm publie.

Exemple de contenu à ajouter au fichier `.gitlab-ci.yml` :

```yaml
build:
  image: node:latest
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  script:
    - npm publish --provenance --access public
```

Le template npm GitLab fournit également cette fonctionnalité ; l'exemple se trouve dans la [documentation des templates](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/npm.gitlab-ci.yml).

## Vérification de la provenance npm {#verifying-npm-provenance}

npm CLI fournit également des fonctionnalités permettant aux utilisateurs finaux de vérifier la provenance des paquets.

```plaintext
npm audit signatures
audited 1 package in 0s
1 package has a verified registry signature
```

### Inspection des métadonnées de provenance {#inspecting-the-provenance-metadata}

Le journal de transparence Rekor stocke les certificats et les attestations pour chaque paquet publié avec provenance. Par exemple, voici l'[entrée pour l'exemple suivant](https://search.sigstore.dev/?logIndex=21076013).

Un exemple de document de provenance généré par npm :

```yaml
_type: https://in-toto.io/Statement/v0.1
subject:
  - name: pkg:npm/%40strongjz/strongcoin@0.0.13
    digest:
      sha512: >-
        924a134a0fd4fe6a7c87b4687bf0ac898b9153218ce9ad75798cc27ab2cddbeff77541f3847049bd5e3dfd74cea0a83754e7686852f34b185c3621d3932bc3c8
predicateType: https://slsa.dev/provenance/v0.2
predicate:
  buildType: https://github.com/npm/CLI/gitlab/v0alpha1
  builder:
    id: https://gitlab.com/strongjz/npm-provenance-example/-/runners/12270835
  invocation:
    configSource:
      uri: git+https://gitlab.com/strongjz/npm-provenance-example
      digest:
        sha1: 6e02e901e936bfac3d4691984dff8c505410cbc3
      entryPoint: deploy
    parameters:
      CI: 'true'
      CI_API_GRAPHQL_URL: https://gitlab.com/api/graphql
      CI_API_V4_URL: https://gitlab.com/api/v4
      CI_COMMIT_BEFORE_SHA: 7d3e913e5375f68700e0c34aa90b0be7843edf6c
      CI_COMMIT_BRANCH: main
      CI_COMMIT_REF_NAME: main
      CI_COMMIT_REF_PROTECTED: 'true'
      CI_COMMIT_REF_SLUG: main
      CI_COMMIT_SHA: 6e02e901e936bfac3d4691984dff8c505410cbc3
      CI_COMMIT_SHORT_SHA: 6e02e901
      CI_COMMIT_TIMESTAMP: '2023-05-19T10:17:12-04:00'
      CI_COMMIT_TITLE: trying to publish to gitlab reg
      CI_CONFIG_PATH: .gitlab-ci.yml
      CI_DEFAULT_BRANCH: main
      CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX: gitlab.com:443/strongjz/dependency_proxy/containers
      CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX: gitlab.com:443/strongjz/dependency_proxy/containers
      CI_DEPENDENCY_PROXY_SERVER: gitlab.com:443
      CI_DEPENDENCY_PROXY_USER: gitlab-ci-token
      CI_JOB_ID: '4316132595'
      CI_JOB_NAME: deploy
      CI_JOB_NAME_SLUG: deploy
      CI_JOB_STAGE: deploy
      CI_JOB_STARTED_AT: '2023-05-19T14:17:23Z'
      CI_JOB_URL: https://gitlab.com/strongjz/npm-provenance-example/-/jobs/4316132595
      CI_NODE_TOTAL: '1'
      CI_PAGES_DOMAIN: gitlab.io
      CI_PAGES_URL: https://strongjz.gitlab.io/npm-provenance-example
      CI_PIPELINE_CREATED_AT: '2023-05-19T14:17:21Z'
      CI_PIPELINE_ID: '872773336'
      CI_PIPELINE_IID: '40'
      CI_PIPELINE_SOURCE: push
      CI_PIPELINE_URL: https://gitlab.com/strongjz/npm-provenance-example/-/pipelines/872773336
      CI_PROJECT_CLASSIFICATION_LABEL: ''
      CI_PROJECT_DESCRIPTION: ''
      CI_PROJECT_ID: '45821955'
      CI_PROJECT_NAME: npm-provenance-example
      CI_PROJECT_NAMESPACE: strongjz
      CI_PROJECT_NAMESPACE_SLUG: strongjz
      CI_PROJECT_NAMESPACE_ID: '36018'
      CI_PROJECT_PATH: strongjz/npm-provenance-example
      CI_PROJECT_PATH_SLUG: strongjz-npm-provenance-example
      CI_PROJECT_REPOSITORY_LANGUAGES: javascript,dockerfile
      CI_PROJECT_ROOT_NAMESPACE: strongjz
      CI_PROJECT_TITLE: npm-provenance-example
      CI_PROJECT_URL: https://gitlab.com/strongjz/npm-provenance-example
      CI_PROJECT_VISIBILITY: public
      CI_REGISTRY: registry.gitlab.com
      CI_REGISTRY_IMAGE: registry.gitlab.com/strongjz/npm-provenance-example
      CI_REGISTRY_USER: gitlab-ci-token
      CI_RUNNER_DESCRIPTION: 3-blue.shared.runners-manager.gitlab.com/default
      CI_RUNNER_ID: '12270835'
      CI_RUNNER_TAGS: >-
        ["gce", "east-c", "linux", "ruby", "mysql", "postgres", "mongo",
        "git-annex", "shared", "docker", "saas-linux-small-amd64"]
      CI_SERVER_HOST: gitlab.com
      CI_SERVER_NAME: GitLab
      CI_SERVER_PORT: '443'
      CI_SERVER_PROTOCOL: https
      CI_SERVER_REVISION: 9d4873fd3c5
      CI_SERVER_SHELL_SSH_HOST: gitlab.com
      CI_SERVER_SHELL_SSH_PORT: '22'
      CI_SERVER_URL: https://gitlab.com
      CI_SERVER_VERSION: 16.1.0-pre
      CI_SERVER_VERSION_MAJOR: '16'
      CI_SERVER_VERSION_MINOR: '1'
      CI_SERVER_VERSION_PATCH: '0'
      CI_TEMPLATE_REGISTRY_HOST: registry.gitlab.com
      GITLAB_CI: 'true'
      GITLAB_FEATURES: >-
        elastic_search,ldap_group_sync,multiple_ldap_servers,seat_link,usage_quotas,zoekt_code_search,repository_size_limit,admin_audit_log,auditor_user,custom_file_templates,custom_project_templates,db_load_balancing,default_branch_protection_restriction_in_groups,extended_audit_events,external_authorization_service_api_management,geo,instance_level_scim,ldap_group_sync_filter,object_storage,pages_size_limit,project_aliases,password_complexity,enterprise_templates,git_abuse_rate_limit,required_ci_templates,runner_maintenance_note,runner_performance_insights,runner_upgrade_management,runner_jobs_statistics
      GITLAB_USER_ID: '31705'
      GITLAB_USER_LOGIN: strongjz
    environment:
      name: 3-blue.shared.runners-manager.gitlab.com/default
      architecture: linux/amd64
      server: https://gitlab.com
      project: strongjz/npm-provenance-example
      job:
        id: '4316132595'
      pipeline:
        id: '872773336'
        ref: .gitlab-ci.yml
  metadata:
    buildInvocationId: https://gitlab.com/strongjz/npm-provenance-example/-/jobs/4316132595
    completeness:
      parameters: true
      environment: true
      materials: false
    reproducible: false
  materials:
    - uri: git+https://gitlab.com/strongjz/npm-provenance-example
      digest:
        sha1: 6e02e901e936bfac3d4691984dff8c505410cbc3
```

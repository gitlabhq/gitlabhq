---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sécurité des pipelines
description: "Gestion des secrets, jetons de job, fichiers sécurisés et sécurité cloud."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Gestion des secrets {#secrets-management}

La gestion des secrets est le système que les équipes de développement utilisent pour stocker de manière sécurisée des données sensibles dans un environnement sécurisé avec des contrôles d'accès stricts. Un **secret** est un identifiant sensible qui doit rester confidentiel. Exemples de secrets :

- Mots de passe
- Clés SSH
- Jetons d'accès
- Tout autre type d'identifiant dont l'exposition serait préjudiciable à une organisation

## Stockage des secrets {#secrets-storage}

### Fournisseurs de gestion des secrets {#secrets-management-providers}

Les secrets les plus sensibles et soumis aux politiques les plus strictes doivent être stockés dans un gestionnaire de secrets. Lors de l'utilisation d'une solution de gestionnaire de secrets, les secrets sont stockés en dehors de l'instance GitLab. Il existe un certain nombre de fournisseurs dans ce domaine, notamment [HashiCorp's Vault](https://www.vaultproject.io), [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault) et [Google Cloud Secret Manager](https://cloud.google.com/security/products/secret-manager).

Vous pouvez utiliser les intégrations natives de GitLab pour certains [fournisseurs externes de gestion des secrets](../secrets/_index.md) afin de récupérer ces secrets dans les pipelines CI/CD lorsque cela est nécessaire.

### Variables CI/CD {#cicd-variables}

Les [variables CI/CD](../variables/_index.md) constituent un moyen pratique de stocker et de réutiliser des données dans un pipeline CI/CD, mais les variables sont moins sécurisées que les fournisseurs de gestion des secrets. Valeurs des variables :

- Sont stockées dans les paramètres du projet, du groupe ou de l'instance GitLab. Les utilisateurs ayant accès aux paramètres ont accès aux valeurs des variables qui ne sont pas [masquées](../variables/_index.md#hide-a-cicd-variable).
- Peuvent être [remplacées](../variables/_index.md#use-pipeline-variables), ce qui rend difficile la détermination de la valeur utilisée.
- Peuvent être exposées par une mauvaise configuration accidentelle du pipeline.

Les informations adaptées au stockage dans une variable doivent être des données pouvant être exposées sans risque d'exploitation (non sensibles).

Les données sensibles doivent être stockées dans une solution de gestion des secrets. Si vous ne disposez pas d'une solution de gestion des secrets et souhaitez stocker des données sensibles dans une variable CI/CD, veillez à toujours :

- [Masquer les variables](../variables/_index.md#mask-a-cicd-variable).
- [Cacher les variables](../variables/_index.md#hide-a-cicd-variable).
- [Protéger les variables](../variables/_index.md#protect-a-cicd-variable) dans la mesure du possible.

## Transmettre des paramètres aux pipelines CI/CD {#pass-parameters-to-cicd-pipelines}

Pour transmettre des paramètres aux pipelines CI/CD, utilisez les [entrées CI/CD](../inputs/_index.md) plutôt que les variables de pipeline.

Les entrées fournissent :

- Une validation avec typage sécurisé lors de la création du pipeline.
- Des contrats de paramètres explicites.
- Une disponibilité à portée limitée qui renforce la sécurité.

Envisagez de [désactiver les variables de pipeline](../variables/_index.md#restrict-pipeline-variables) lors de la mise en œuvre des entrées afin de prévenir les failles de sécurité, car les variables de pipeline :

- Manquent de validation de type.
- Peuvent remplacer des variables prédéfinies, entraînant un comportement inattendu.
- Partagent la même portée d'autorisation que les secrets sensibles.

## Intégrité du pipeline {#pipeline-integrity}

Les principaux principes de sécurité permettant de garantir l'intégrité du pipeline sont les suivants :

- **Supply Chain Security** : Les ressources doivent être obtenues à partir de sources fiables et leur intégrité vérifiée.
- **Reproducibility** : Les pipelines doivent produire des résultats cohérents lorsqu'ils utilisent les mêmes entrées.
- **Auditability** : Toutes les dépendances du pipeline doivent être traçables et leur provenance vérifiable.
- **Version Control** : Les modifications apportées aux dépendances du pipeline doivent être suivies et contrôlées.

### Images Docker {#docker-images}

Utilisez toujours des digests SHA pour les images Docker afin de garantir la vérification d'intégrité côté client. Par exemple :

- Node :
  - Utiliser : `image: node@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef`
  - Plutôt que : `image: node:latest`
- Python :
  - Utiliser `image: python@sha256:9876543210abcdef9876543210abcdef9876543210abcdef9876543210abcdef`
  - Plutôt que : `image: python:3.9`

Vous pouvez trouver le digest SHA d'une image avec un tag spécifique en utilisant :

```shell
docker pull node:18.17.1
docker images --digests node:18.17.1
```

Privilégiez les registres de conteneurs qui protègent l'intégrité des images :

- Utilisez les [dépôts de conteneurs protégés](../../user/packages/container_registry/container_repository_protection_rules.md) pour restreindre les utilisateurs pouvant apporter des modifications aux images de conteneurs dans votre dépôt de conteneurs.
- Utilisez les [tags protégés](../../user/packages/container_registry/protected_container_tags.md) pour contrôler qui peut pousser et supprimer des tags de conteneurs.

Dans la mesure du possible, évitez d'utiliser des variables dans les références de conteneurs, car elles peuvent être modifiées pour pointer vers des images malveillantes. Par exemple :

- Privilégier :
  - `image: my-registry.example.com/node:18.17.1`
- Plutôt que :
  - `image: ${CUSTOM_REGISTRY}/node:latest`
  - `image: node:${VERSION}`

### Dépendances de packages {#package-dependencies}

Vous devez verrouiller les dépendances de packages dans vos jobs. Utilisez des versions exactes, définies dans des fichiers de verrouillage :

- npm : 
  - Utiliser : `npm ci`
  - Plutôt que : `npm install`
- yarn :
  - Utiliser : `yarn install --frozen-lockfile`
  - Plutôt que : `yarn install`
- Python :
  - Utilisez :
    - `pip install -r requirements.txt --require-hashes`
    - `pip install -r requirements.lock`
  - Plutôt que : `pip install -r requirements.txt`
- Go :
  - Utiliser les versions exactes depuis `go.sum` :
    - `go mod verify`
    - `go mod download`
  - Plutôt que : `go get ./...`

Par exemple, dans un job CI/CD :

```yaml
javascript-job:
  script:
    - npm ci
```

### Commandes shell et scripts {#shell-commands-and-scripts}

Lors de l'installation d'outils dans un job, spécifiez et vérifiez toujours les versions exactes. Par exemple, dans un job Terraform :

```yaml
terraform_job:
  script:
    # Download specific version
    - |
      wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
      # IMPORTANT: Always verify checksums
      echo "c0ed7bc32ee52ae255af9982c8c88a7a4c610485cf1d55feeb037eab75fa082c terraform_1.5.7_linux_amd64.zip" | sha256sum -c
      unzip terraform_1.5.7_linux_amd64.zip
      mv terraform /usr/local/bin/
    # Use the installed version
    - terraform init
    - terraform plan
```

### Outils de gestion des versions {#version-management-tools}

Utilisez des gestionnaires de versions dans la mesure du possible :

```yaml
node_build:
  script:
    # Use nvm to install and use a specific Node version
    - |
      nvm install 16.15.1
      nvm use 16.15.1
    - node --version  # Verify version
    - npm ci
    - npm run build
```

### Configurations incluses {#included-configurations}

Lors de l'utilisation du [mot-clé `include`](../yaml/_index.md#include) pour ajouter une configuration ou des composants CI/CD à votre pipeline, utilisez une ref spécifique dans la mesure du possible. Par exemple :

```yaml
include:
  - project: 'my-group/my-project'
    ref: 8b0c8b318857c8211c15c6643b0894345a238c4e  # Pin to a specific commit
    file: '/templates/build.yml'
  - project: 'my-group/security'
    ref: v2.1.0                                    # Pin to a protected tag
    file: '/templates/scan.yml'
  - component: 'my-group/security-scans'           # Pin to a specific version
    version: '1.2.3'
```

Évitez les inclusions sans version :

```yaml
include:
  - project: 'my-group/my-project'                   # Unsafe
    file: '/templates/build.yml'
  - component: 'my-group/security-scans'             # Unsafe
  - remote: 'https://example.com/security-scan.yml'  # Unsafe
```

Plutôt que d'inclure des fichiers distants, téléchargez le fichier et enregistrez-le dans votre dépôt. Vous pouvez ensuite inclure la copie locale :

```yaml
include:
  - local: '/ci/security-scan.yml'  # Verified and stored in the repository
```

### Sujets connexes {#related-topics}

1. [CIS Docker Benchmarks](https://www.cisecurity.org/benchmark/docker)
1. Google Cloud : [Design secure deployment pipelines](https://cloud.google.com/architecture/design-secure-deployment-pipelines-bp)

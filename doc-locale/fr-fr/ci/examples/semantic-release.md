---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Publier des paquets npm dans le registre de paquets GitLab à l'aide de semantic-release"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce guide explique comment publier automatiquement des paquets npm dans le [registre de paquets GitLab](../../user/packages/npm_registry/_index.md) à l'aide de [semantic-release](https://github.com/semantic-release/semantic-release).

Vous pouvez également consulter ou dupliquer la [source de l'exemple](https://gitlab.com/gitlab-examples/semantic-release-npm) complète.

## Initialiser le module {#initialize-the-module}

1. Ouvrez un terminal et accédez au dépôt du projet.
1. Exécutez `npm init`. Nommez le module selon [les conventions de nommage du registre de paquets](../../user/packages/npm_registry/_index.md#naming-convention). Par exemple, si le chemin du projet est `gitlab-examples/semantic-release-npm`, nommez le module `@gitlab-examples/semantic-release-npm`.
1. Installez les paquets npm suivants :

   ```shell
   npm install semantic-release @semantic-release/git @semantic-release/gitlab @semantic-release/npm --save-dev
   ```

1. Ajoutez les propriétés suivantes au fichier `package.json` du module :

   ```json
   {
     "scripts": {
       "semantic-release": "semantic-release"
     },
     "publishConfig": {
       "access": "public"
     },
     "files": [ <path(s) to files here> ]
   }
   ```

1. Mettez à jour la clé `files` avec des patterns glob qui sélectionnent tous les fichiers à inclure dans le module publié. Des informations supplémentaires sur `files` sont disponibles [dans la documentation npm](https://docs.npmjs.com/cli/v6/configuring-npm/package-json/#files).
1. Ajoutez un fichier `.gitignore` au projet pour éviter de committer `node_modules` :

   ```plaintext
   node_modules
   ```

## Configurer le pipeline {#configure-the-pipeline}

Créez un fichier `.gitlab-ci.yml` avec le contenu suivant :

```yaml
default:
  image: node:latest
  before_script:
    - npm ci --cache .npm --prefer-offline
    - |
      {
        echo "@${CI_PROJECT_ROOT_NAMESPACE}:registry=${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/"
        echo "${CI_API_V4_URL#https?}/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=\${CI_JOB_TOKEN}"
      } | tee -a .npmrc
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - .npm/

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH

variables:
  NPM_TOKEN: ${CI_JOB_TOKEN}

stages:
  - release

publish:
  stage: release
  script:
    - npm run semantic-release
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

Cet exemple configure le pipeline avec un seul job, `publish`, qui exécute `semantic-release`. La bibliothèque semantic-release publie de nouvelles versions du paquet npm et crée de nouvelles releases GitLab (si nécessaire).

Le `before_script` par défaut génère un fichier `.npmrc` temporaire utilisé pour s'authentifier auprès du registre de paquets pendant le job `publish`.

## Configurer les variables CI/CD {#set-up-cicd-variables}

Dans le cadre de la publication d'un paquet, semantic-release incrémente le numéro de version dans `package.json`. Pour que semantic-release puisse committer cette modification et la transmettre à GitLab, le pipeline nécessite une variable CI/CD personnalisée nommée `GITLAB_TOKEN`. Pour créer cette variable :

1. Ouvrez la barre latérale gauche.
1. Sélectionnez **Paramètres** > **Jetons d'accès**.
1. Dans votre projet, sélectionnez **Ajouter un jeton**.
1. Dans le champ **Nom du jeton**, saisissez un nom de jeton.
   <!-- markdownlint-disable MD044 -->
1. Sous **Sélectionner les portées**, cochez la case **api**.
   <!-- markdownlint-enable MD044 -->
1. Sélectionnez **Créer un jeton d'accès au projet**.
1. Copiez la valeur du jeton.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Variables**.
1. Sélectionnez **Ajouter une variable**.
1. Sous **Visibilité**, sélectionnez **Masquée**.
1. Dans le champ **Clé**, saisissez `GITLAB_TOKEN`.
1. Dans le champ **Valeur**, saisissez la valeur du jeton.
1. Sélectionnez **Ajouter une variable**.

## Configurer semantic-release {#configure-semantic-release}

semantic-release extrait ses informations de configuration depuis un fichier `.releaserc.json` dans le projet. Créez un fichier `.releaserc.json` à la racine du dépôt :

```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/gitlab",
    "@semantic-release/npm",
    [
      "@semantic-release/git",
      {
        "assets": ["package.json"],
        "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
      }
    ]
  ]
}
```

Dans l'exemple de configuration semantic-release précédent, vous pouvez remplacer le nom de la branche par la branche par défaut de votre projet.

## Commencer à publier des releases {#begin-publishing-releases}

Testez le pipeline en créant un commit avec un message tel que :

```plaintext
fix: testing patch releases
```

Transmettez le commit vers la branche par défaut. Le pipeline devrait créer une nouvelle release (`v1.0.0`) sur la page **Release** du projet et publier une nouvelle version du paquet sur la page **Registre de paquets** du projet.

Pour créer une release mineure, utilisez un message de commit tel que :

```plaintext
feat: testing minor releases
```

Ou, pour un changement incompatible :

```plaintext
feat: testing major releases

BREAKING CHANGE: This is a breaking change.
```

Des informations supplémentaires sur la façon dont les messages de commit sont associés aux releases sont disponibles dans [la documentation de semantic-release](https://github.com/semantic-release/semantic-release#how-does-it-work).

## Utiliser le module dans un projet {#use-the-module-in-a-project}

Pour utiliser le module publié, ajoutez un fichier `.npmrc` au projet qui dépend du module. Par exemple, pour utiliser le module de [l'exemple de projet](https://gitlab.com/gitlab-examples/semantic-release-npm) :

```plaintext
@gitlab-examples:registry=https://gitlab.com/api/v4/packages/npm/
```

Ensuite, installez le module :

```shell
npm install --save @gitlab-examples/semantic-release-npm
```

## Dépannage {#troubleshooting}

### Des tags Git supprimés réapparaissent {#deleted-git-tags-reappear}

Un [tag Git](../../user/project/repository/tags/_index.md) supprimé du dépôt peut parfois être recréé par `semantic-release` lorsque les runners GitLab utilisent une version mise en cache du dépôt. Si le job s'exécute sur un runner avec un dépôt en cache qui contient encore le tag, `semantic-release` recrée le tag dans le dépôt principal.

Pour éviter ce comportement, vous pouvez :

- Configurer le runner avec [`GIT_STRATEGY: clone`](../runners/configure_runners.md#git-strategy).
- Inclure la [commande `git fetch --prune-tags`](https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---prune-tags) dans votre script CI/CD.

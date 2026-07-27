---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Déployer un projet GitLab sur Heroku à l'aide de GitLab CI/CD."
title: Utiliser GitLab CI/CD pour déployer sur Heroku
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez déployer une application sur Heroku à l'aide de GitLab CI/CD.

## Prérequis {#prerequisites}

- Un compte [Heroku](https://id.heroku.com/login). Connectez-vous avec un compte Heroku existant ou créez-en un nouveau.

## Déployer sur Heroku {#deploy-to-heroku}

1. Dans Heroku :
   1. Créez une application et copiez le nom de l'application.
   1. Accédez à **Paramètres du compte** et copiez la clé API.
1. Dans votre projet GitLab, créez deux [variables](../variables/_index.md) :
   - `HEROKU_APP_NAME` pour le nom de l'application.
   - `HEROKU_PRODUCTION_KEY` pour la clé API.
1. Modifiez votre fichier `.gitlab-ci.yml` pour ajouter la commande de déploiement Heroku. Cet exemple utilise le gem `dpl` pour Ruby :

   ```yaml
   heroku_deploy:
     stage: production
     script:
       - gem install dpl
       - dpl --provider=heroku --app=$HEROKU_APP_NAME --api-key=$HEROKU_PRODUCTION_KEY
   ```

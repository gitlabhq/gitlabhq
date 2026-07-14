---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser Dpl comme outil de déploiement
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Dpl](https://github.com/travis-ci/dpl) (prononcé comme les lettres D-P-L) est un outil de déploiement conçu pour le déploiement continu, développé et utilisé par Travis CI, mais pouvant également être utilisé avec GitLab CI/CD.

Dpl peut être utilisé pour déployer vers n'importe lequel des [fournisseurs pris en charge](https://github.com/travis-ci/dpl#supported-providers).

## Prérequis {#prerequisite}

Pour utiliser Dpl, vous devez disposer au minimum de Ruby 1.9.3 avec la capacité d'installer des gems.

## Utilisation de base {#basic-usage}

Dpl peut être installé sur n'importe quelle machine avec :

```shell
gem install dpl
```

Cela vous permet de tester toutes les commandes depuis votre terminal local, plutôt que de devoir les tester sur un serveur CI.

Si Ruby n'est pas installé, vous pouvez l'installer sur un système Linux compatible Debian avec :

```shell
apt-get update
apt-get install ruby-dev
```

Dpl offre un support pour un grand nombre de services, notamment : Heroku, Cloud Foundry, AWS/S3, et bien d'autres. Pour l'utiliser, définissez le fournisseur ainsi que tous les paramètres supplémentaires requis par ce fournisseur.

Par exemple, si vous souhaitez l'utiliser pour déployer votre application sur Heroku, vous devez spécifier `heroku` comme fournisseur, et renseigner `api_key` et `app`. Tous les paramètres possibles sont disponibles dans la [section Heroku API](https://github.com/travis-ci/dpl#heroku-api).

```yaml
staging:
  stage: deploy
  script:
    - gem install dpl
    - dpl heroku api --app=my-app-staging --api_key=$HEROKU_STAGING_API_KEY
  environment: staging
```

L'exemple précédent a utilisé Dpl pour déployer `my-app-staging` sur le serveur Heroku avec la clé API stockée dans la variable CI/CD sécurisée `HEROKU_STAGING_API_KEY`.

Pour utiliser un autre fournisseur, consultez la longue liste des [fournisseurs pris en charge](https://github.com/travis-ci/dpl#supported-providers).

## Utiliser Dpl avec Docker {#using-dpl-with-docker}

Dans la plupart des cas, vous avez configuré [GitLab Runner](https://docs.gitlab.com/runner/) pour utiliser les commandes shell de votre serveur. Cela signifie que toutes les commandes sont exécutées dans le contexte de l'utilisateur local (par exemple `gitlab_runner` ou `gitlab_ci_multi_runner`). Cela signifie également que votre conteneur Docker ne dispose probablement pas du runtime Ruby installé. Vous devez l'installer :

```yaml
staging:
  stage: deploy
  script:
    - apt-get update -yq
    - apt-get install -y ruby-dev
    - gem install dpl
    - dpl heroku api --app=my-app-staging --api_key=$HEROKU_STAGING_API_KEY
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: staging
```

La première ligne `apt-get update -yq` met à jour la liste des packages disponibles, tandis que la seconde `apt-get install -y ruby-dev` installe le runtime Ruby sur le système. L'exemple précédent est valable pour tous les systèmes compatibles Debian.

## Utilisation en staging et en production {#usage-in-staging-and-production}

Il est courant dans le workflow de développement de disposer d'environnements de staging (développement) et de production.

Considérez l'exemple suivant : vous souhaitez déployer `main` sur `staging` et tous les tags vers l'environnement `production`. Le fichier `.gitlab-ci.yml` final pour cette configuration ressemblerait à ceci :

```yaml
staging:
  stage: deploy
  script:
    - gem install dpl
    - dpl heroku api --app=my-app-staging --api_key=$HEROKU_STAGING_API_KEY
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: staging

production:
  stage: deploy
  script:
    - gem install dpl
    - dpl heroku api --app=my-app-production --api_key=$HEROKU_PRODUCTION_API_KEY
  rules:
    - if: $CI_COMMIT_TAG
  environment: production
```

Vous avez créé deux jobs de déploiement qui sont exécutés lors de différents événements :

- `staging` : Exécuté pour tous les commits poussés vers la `main`
- `production` : Exécuté pour tous les tags poussés

Les jobs utilisent également deux variables CI/CD sécurisées :

- `HEROKU_STAGING_API_KEY` : Clé API Heroku utilisée pour déployer l'application de staging
- `HEROKU_PRODUCTION_API_KEY` : Clé API Heroku utilisée pour déployer l'application de production

## Stocker les clés API {#storing-api-keys}

Pour stocker les clés API en tant que variables sécurisées :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Variables**.

Les variables définies dans les paramètres du projet sont envoyées avec le script de build au runner. Les variables sécurisées sont stockées en dehors du dépôt. Ne stockez jamais de secrets dans le fichier `.gitlab-ci.yml` de votre projet. Il est également important que la valeur du secret soit masquée dans le job log.

Vous accédez à la variable ajoutée en préfixant son nom par `$` (sur les runners non Windows) ou `%` (pour les runners Windows Batch) :

- `$VARIABLE` : À utiliser pour les runners non Windows
- `%VARIABLE%` : À utiliser pour les runners Windows Batch

En savoir plus sur les [variables CI/CD](../../variables/_index.md).

---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Mesurez et comparez les performances de rendu des pages web entre les branches à l'aide de sitespeed.io."
title: Tests de performance du navigateur
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez les tests de performance du navigateur pour mesurer les performances de rendu de votre application web et détecter les régressions avant qu'elles n'atteignent la production. GitLab utilise [sitespeed.io](https://www.sitespeed.io) pour évaluer chaque page et génère les résultats dans un fichier appelé `browser-performance.json`.

Les résultats sont affichés directement dans la merge request, afin que vous puissiez détecter les régressions de performance dans le cadre de votre processus de révision. Par exemple, une bibliothèque JavaScript ajoutée à `<head>` qui fait baisser le score de vitesse de la page.

> [!note]
> Vous pouvez automatiser cette fonctionnalité avec [Auto DevOps](../../topics/autodevops/_index.md).

## Résultats des tests de performance du navigateur dans les merge requests {#browser-performance-results-in-merge-requests}

Définissez un job dans votre fichier `.gitlab-ci.yml` qui génère l'[artefact de rapport de performance du navigateur](../yaml/artifacts_reports.md#artifactsreportsbrowser_performance). GitLab vérifie ce rapport, compare les principales métriques de performance pour chaque page entre la branche source et la branche cible, et affiche les résultats dans la merge request.

![Métriques de performance du navigateur avec des valeurs dégradées, inchangées et améliorées.](img/browser_performance_testing_v13_4.png)

> [!note]
> Le widget ne s'affiche pas tant que le job ne s'est pas exécuté au moins une fois sur la branche cible, et uniquement si le job s'est exécuté dans le dernier pipeline de la merge request.

## Configurer les tests de performance du navigateur {#configure-browser-performance-testing}

Prérequis :

- [GitLab Runner configuré avec Docker-in-Docker](../docker/using_docker_build.md#use-docker-in-docker).

Pour exécuter le [conteneur sitespeed.io](https://hub.docker.com/r/sitespeedio/sitespeed.io/) sur votre code, utilisez GitLab CI/CD avec Docker-in-Docker :

1. Dans votre fichier `.gitlab-ci.yml`, ajoutez ce qui suit :

   ```yaml
   include:
     template: Verify/Browser-Performance.gitlab-ci.yml

   browser_performance:
     variables:
       URL: https://example.com
   ```

GitLab crée un job `browser_performance` qui exécute sitespeed.io sur l'URL et enregistre le rapport HTML complet en tant qu'[artefact de performance du navigateur](../yaml/artifacts_reports.md#artifactsreportsbrowser_performance). Si [GitLab Pages](../../user/project/pages/_index.md) est activé, vous pouvez consulter le rapport dans votre navigateur.

> [!note]
> Ce modèle ne fonctionne pas avec les clusters Kubernetes. Utilisez plutôt [`template: Jobs/Browser-Performance-Testing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Browser-Performance-Testing.gitlab-ci.yml).

Vous pouvez personnaliser le job à l'aide de variables CI/CD :

| Variable                   | Valeur par défaut                    | Description |
| -------------------------- | -------------------------- | ----------- |
| `SITESPEED_IMAGE`          | `sitespeedio/sitespeed.io` | Image Docker à utiliser. Ne contrôle pas la version. |
| `SITESPEED_VERSION`        | `14.1.0`                   | Version de l'image Docker. |
| `SITESPEED_OPTIONS`        | aucune                       | Options sitespeed.io supplémentaires. Pour plus d'informations, consultez [la configuration de sitespeed.io](https://www.sitespeed.io/documentation/sitespeed.io/configuration/). |
| `SITESPEED_DOCKER_OPTIONS` | aucune                       | Options supplémentaires transmises à `docker run`, telles que `--network` pour se connecter à un réseau Docker spécifique. |

Par exemple, pour remplacer le nombre d'exécutions et modifier la version :

```yaml
include:
  template: Verify/Browser-Performance.gitlab-ci.yml

browser_performance:
  variables:
    URL: https://www.sitespeed.io/
    SITESPEED_VERSION: 13.2.0
    SITESPEED_OPTIONS: -n 5
```

### Configurer le seuil de dégradation {#configure-the-degradation-threshold}

Pour éviter les alertes lors de baisses de score mineures, définissez la variable CI/CD `DEGRADATION_THRESHOLD`. L'alerte s'affiche uniquement lorsque le `Total Score` se dégrade du nombre de points spécifié ou plus.

Par exemple :

```yaml
include:
  template: Verify/Browser-Performance.gitlab-ci.yml

browser_performance:
  variables:
    URL: https://example.com
    DEGRADATION_THRESHOLD: 5
```

`Total Score` est un score combiné entre 0 et 100 pour les performances, l'accessibilité et les bonnes pratiques. Un score de 100 signifie que la page ne présente aucun problème à résoudre. Pour plus d'informations, consultez [la méthode d'évaluation des pages par le coach](https://www.sitespeed.io/documentation/coach/how-to/#what-do-the-coach-do).

### Configurer les tests de performance du navigateur pour les environnements éphémères {#configure-browser-performance-testing-for-review-apps}

Prérequis :

- Le job `browser_performance` doit s'exécuter après le démarrage de l'environnement dynamique.

Pour configurer les tests de performance du navigateur pour les environnements éphémères :

1. Dans le job `review`, générez un fichier de liste d'URL avec l'URL dynamique :

   ```yaml
      script:
        - echo $CI_ENVIRONMENT_URL > environment_url.txt
   ```

1. Enregistrez le fichier en tant qu'artefact :

   ```yaml
      artifacts:
        paths:
          - environment_url.txt
   ```

1. Transmettez le fichier en tant que variable `URL` au job `browser_performance`. Par exemple :

   ```yaml
   stages:
     - deploy
     - performance

   include:
     template: Verify/Browser-Performance.gitlab-ci.yml

   review:
     stage: deploy
     environment:
       name: review/$CI_COMMIT_REF_SLUG
       url: http://$CI_COMMIT_REF_SLUG.$APPS_DOMAIN
     script:
       - run_deploy_script
       - echo $CI_ENVIRONMENT_URL > environment_url.txt
     artifacts:
       paths:
         - environment_url.txt
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
         when: never
       - if: $CI_COMMIT_BRANCH

   browser_performance:
     dependencies:
       - review
     variables:
       URL: environment_url.txt
   ```

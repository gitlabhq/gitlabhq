---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Mesurez et comparez les performances backend des applications entre les branches à l'aide des tests de charge k6."
title: Tests de performance de charge
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez les tests de performance de charge pour mesurer l'impact des modifications de code sur les performances backend de votre application. GitLab utilise [k6](https://k6.io/) pour simuler une charge sur les endpoints de l'application tels que les API et les contrôleurs web, et génère les résultats dans un fichier appelé `load-performance.json`.

Contrairement aux [tests de performance de navigateur](browser_performance_testing.md), qui mesurent le rendu des pages web dans un navigateur, les tests de performance de charge ciblent le côté serveur et permettent d'évaluer les temps de réponse et le débit sous charge.

Les résultats s'affichent directement dans la merge request, ce qui vous permet de détecter les régressions de performance dans le cadre de votre processus de revue.

## Résultats des tests de performance de charge dans les merge requests {#load-performance-results-in-merge-requests}

Définissez un job dans votre fichier `.gitlab-ci.yml` qui génère l'[artefact de rapport de performance de charge](../yaml/artifacts_reports.md#artifactsreportsload_performance). GitLab vérifie ce rapport, compare les métriques clés de performance de charge entre la branche source et la branche cible, et affiche les résultats dans la merge request.

![Une merge request affiche des métriques de performance avec des valeurs TTFB dégradées.](img/load_performance_testing_v18_11.png)

Les métriques clés affichées dans le widget de la merge request sont :

- **Vérifications** : Le taux de réussite en pourcentage des [vérifications](https://k6.io/docs/using-k6/checks) configurées dans le test k6.
- **TTFB P90** : Le 90e percentile du temps nécessaire pour commencer à recevoir des réponses, également connu sous le nom de [Time to First Byte](https://en.wikipedia.org/wiki/Time_to_first_byte) (TTFB).
- **TTFB P95** : Le 95e percentile pour le TTFB.
- **RPS** : Le débit moyen en requêtes par seconde (RPS) que le test a été en mesure d'atteindre.

> [!note]
> Le widget ne s'affiche pas tant que le job n'a pas été exécuté au moins une fois sur la branche cible.

## Configurer les tests de performance de charge {#configure-load-performance-testing}

Utilisez le modèle [`Verify/Load-Performance-Testing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Verify/Load-Performance-Testing.gitlab-ci.yml) inclus avec GitLab pour exécuter des [tests de charge k6](https://k6.io/docs/testing-guides) contre votre application.

Prérequis :

- GitLab Runner configuré pour exécuter des conteneurs Docker, comme le [workflow Docker-in-Docker](../docker/using_docker_build.md#use-docker-in-docker).
- Un environnement de test de pré-production configuré pour les tests de charge. Pour plus d'informations, voir [calculer les utilisateurs simultanés pour les tests de charge](https://k6.io/blog/monthly-visits-concurrent-users).
- Un fichier de test k6 dans le dépôt de votre projet. Pour obtenir des conseils, voir [écrire votre premier test k6](https://grafana.com/docs/k6/latest/get-started/write-your-first-test/).

Pour configurer les tests de performance de charge, ajoutez les éléments suivants à votre fichier `.gitlab-ci.yml` :

```yaml
include:
  template: Verify/Load-Performance-Testing.gitlab-ci.yml

load_performance:
  variables:
    K6_TEST_FILE: <PATH TO K6 TEST FILE IN PROJECT>
```

GitLab crée un job `load_performance` qui exécute le test k6 et enregistre les résultats sous forme d'[artefact de rapport de performance de charge](../yaml/artifacts_reports.md#artifactsreportsload_performance). Le dernier artefact disponible est toujours utilisé. Si [GitLab Pages](../../user/project/pages/_index.md) est activé, vous pouvez consulter le rapport directement dans votre navigateur.

Vous pouvez personnaliser le job avec des variables CI/CD :

| Variable            | Valeur par défaut      | Description |
| ------------------- | ------------ | ----------- |
| `K6_IMAGE`          | `grafana/k6` | Image Docker à utiliser. Ne contrôle pas la version. |
| `K6_VERSION`        | `0.54.0`     | Version de l'image Docker. |
| `K6_TEST_FILE`      | aucune         | Chemin vers le fichier de test k6 dans le dépôt du projet. |
| `K6_OPTIONS`        | aucune         | Options k6 supplémentaires. Pour plus d'informations, voir [référence des options k6](https://k6.io/docs/using-k6/k6-options/reference/). |
| `K6_DOCKER_OPTIONS` | aucune         | Options supplémentaires transmises à `docker run`, telles que `--env-file` pour passer des variables d'environnement au conteneur k6. |

Par exemple, pour remplacer la durée du test :

```yaml
include:
  template: Verify/Load-Performance-Testing.gitlab-ci.yml

load_performance:
  variables:
    K6_TEST_FILE: <PATH TO K6 TEST FILE IN PROJECT>
    K6_OPTIONS: '--duration 30s'
```

> [!note]
> Ce modèle ne fonctionne pas avec les clusters Kubernetes. Utilisez plutôt [`Jobs/Load-Performance-Testing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Load-Performance-Testing.gitlab-ci.yml).

Pour les tests k6 à grande échelle, assurez-vous que l'instance GitLab Runner peut gérer la charge. Les [runners GitLab.com partagés par défaut](../runners/hosted_runners/linux.md) ne disposent probablement pas de spécifications suffisantes pour la plupart des tests k6 de grande envergure. Pour plus de détails, voir [les recommandations de k6 pour l'exécution de tests à grande échelle](https://k6.io/docs/testing-guides/running-large-tests#hardware-considerations).

### Configurer les tests de performance de charge pour les environnements éphémères {#configure-load-performance-testing-for-review-apps}

Prérequis :

- Le job `load_performance` doit s'exécuter après le démarrage de l'environnement dynamique.

Pour configurer les tests de performance de charge pour les environnements éphémères, capturez l'URL dynamique dans un [fichier `.env`](https://docs.docker.com/compose/environment-variables/env-file/) et transmettez-la au conteneur k6 à l'aide de `K6_DOCKER_OPTIONS`. k6 peut ensuite utiliser les variables d'environnement du fichier dans les scripts de test avec du JavaScript standard, par exemple : ``http.get(`${__ENV.ENVIRONMENT_URL}`)``.

Par exemple :

```yaml
stages:
  - deploy
  - performance

include:
  template: Verify/Load-Performance-Testing.gitlab-ci.yml

review:
  stage: deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: http://$CI_ENVIRONMENT_SLUG.example.com
  script:
    - run_deploy_script
    - echo "ENVIRONMENT_URL=$CI_ENVIRONMENT_URL" >> review.env
  artifacts:
    paths:
      - review.env
  rules:
    - if: $CI_COMMIT_BRANCH

load_performance:
  dependencies:
    - review
  variables:
    K6_DOCKER_OPTIONS: '--env-file review.env'
  rules:
    - if: $CI_COMMIT_BRANCH
```

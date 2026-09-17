---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Migration de l'analyseur basé sur le navigateur DAST version 4 vers DAST version 5"
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- L'[analyseur DAST basé sur un proxy](proxy_based_to_browser_based_migration_guide.md) a été [déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/430966) dans GitLab 16.6 et supprimé dans la version 17.0.

{{< /history >}}

[DAST version 5](browser/_index.md) remplace DAST version 4. Ce document sert de guide pour migrer de l'analyseur basé sur le navigateur DAST version 4 vers DAST version 5.

Suivez ce guide de migration si toutes les conditions suivantes s'appliquent :

1. Vous utilisez GitLab DAST pour exécuter un scan DAST dans un pipeline CI/CD.
1. Le job DAST CI/CD est configuré en incluant l'un des modèles DAST `DAST.gitlab-ci.yml` ou `DAST.latest.gitlab-ci.yml`.
1. La variable CI/CD `DAST_VERSION` n'est pas définie ou est définie sur `4` ou moins.
1. La variable CI/CD `DAST_BROWSER_SCAN` est définie sur `true`.

Migrez vers DAST version 5 en lisant les sections suivantes et en apportant les modifications recommandées.

## Versions de l'analyseur DAST {#dast-analyzer-versions}

DAST est disponible en deux versions majeures : 4 et 5. À partir de GitLab 17.0, les modèles DAST `DAST.gitlab-ci.yml` et `DAST.latest.gitlab-ci.yml` utilisent DAST version 5 par défaut. Vous pouvez continuer à utiliser DAST version 4, mais vous ne devriez le faire qu'à titre de mesure provisoire lors de la migration vers DAST version 5. Pour plus de détails, voir [Continuer à utiliser la version 4](#continuing-to-use-version-4).

Chaque version majeure de DAST exécute des analyseurs différents :

- DAST version 4 peut exécuter l'analyseur basé sur un proxy ou l'analyseur basé sur le navigateur, et utilise l'analyseur basé sur un proxy par défaut.
- DAST version 5 exécute uniquement l'analyseur basé sur le navigateur.

DAST version 5 utilise un ensemble de nouvelles variables CI/CD. Des alias ont été créés pour les noms des variables de DAST version 4.

Modifications à effectuer :

- Renommez `DAST_WEBSITE` en `DAST_TARGET_URL`.
- Lorsque vous commencez à utiliser de nouveaux modèles qui définissent `DAST_VERSION` sur 5, assurez-vous que la variable CI/CD `DAST_VERSION` n'est pas définie.

## Continuer à utiliser la version 4 {#continuing-to-use-version-4}

Vous pouvez utiliser l'analyseur DAST version 4 basé sur un proxy jusqu'à GitLab 18.0. Les bugs et vulnérabilités présents dans cet analyseur hérité ne seront pas corrigés.

Modifications à effectuer :

- Pour continuer à utiliser DAST version 4, définissez la variable CI/CD `DAST_VERSION` sur 4.

## Artefacts {#artifacts}

GitLab 17.0 publie automatiquement les artefacts produits par DAST version 5 dans le job CI DAST.

Modifications à effectuer :

- Supprimez `artifacts` de la définition du job CI si vous l'avez remplacé pour exposer le journal de fichiers, le graphe de crawl ou le rapport d'authentification.
- Les variables CI/CD `DAST_BROWSER_FILE_LOG_PATH` et `DAST_FILE_LOG_PATH` ne sont plus nécessaires.

## Couverture des vérifications de vulnérabilités {#vulnerability-check-coverage}

DAST version 4 basé sur le navigateur utilise les vérifications de l'analyseur basé sur un proxy pour les vérifications actives non incluses dans l'analyseur basé sur le navigateur. DAST version 5 basé sur le navigateur n'inclut pas l'analyseur basé sur un proxy, ce qui crée une lacune dans la couverture des vérifications lors de la migration vers la version 5.

Il existe une vérification active basée sur un proxy que l'analyseur basé sur le navigateur ne couvre pas. La migration de la vérification active restante est proposée dans l'epic [13411](https://gitlab.com/groups/gitlab-org/-/epics/13411). Si vous préférez rester sur DAST version 4 jusqu'à la migration de la dernière vérification, voir [Continuer à utiliser la version 4](#continuing-to-use-version-4).

Vérification restante :

- CWE-79 : Cross-site Scripting (XSS)

Suivez la progression de la vérification restante dans l'epic [Remaining active checks for BBD](https://gitlab.com/groups/gitlab-org/-/epics/13411).

## Modifications des variables CI/CD {#changes-to-cicd-variables}

Le tableau suivant présente les actions de migration requises pour chaque variable CI/CD de l'analyseur basé sur le navigateur DAST version 4. Consultez la [configuration](browser/configuration/_index.md) pour plus d'informations sur la configuration de l'analyseur basé sur le navigateur.

| Variable CI/CD DAST version 4               | Action requise    | Notes                                         |
|:--------------------------------------------|:-------------------|:----------------------------------------------|
| `DAST_ADVERTISE_SCAN`                       | Renommer             | Vers `DAST_REQUEST_ADVERTISE_SCAN`              |
| `DAST_AFTER_LOGIN_ACTIONS`                  | Renommer             | Vers `DAST_AUTH_AFTER_LOGIN_ACTIONS`            |
| `DAST_AUTH_COOKIES`                         | Renommer             | Vers `DAST_AUTH_COOKIE_NAMES`                   |
| `DAST_AUTH_DISABLE_CLEAR_FIELDS`            | Renommer             | Vers `DAST_AUTH_CLEAR_INPUT_FIELDS`             |
| `DAST_AUTH_REPORT`                          | Aucune action requise |                                               |
| `DAST_AUTH_TYPE`                            | Aucune action requise |                                               |
| `DAST_AUTH_URL`                             | Aucune action requise |                                               |
| `DAST_AUTH_VERIFICATION_LOGIN_FORM`         | Renommer             | Vers `DAST_AUTH_SUCCESS_IF_NO_LOGIN_FORM`       |
| `DAST_AUTH_VERIFICATION_SELECTOR`           | Renommer             | Vers `DAST_AUTH_SUCCESS_IF_ELEMENT_FOUND`       |
| `DAST_AUTH_VERIFICATION_URL`                | Renommer             | Vers `DAST_AUTH_SUCCESS_IF_AT_URL`              |
| `DAST_BROWSER_PATH_TO_LOGIN_FORM`           | Renommer             | Vers `DAST_AUTH_BEFORE_LOGIN_ACTIONS`           |
| `DAST_BROWSER_ACTION_STABILITY_TIMEOUT`     | Remplacer            | Par `DAST_PAGE_DOM_READY_TIMEOUT`            |
| `DAST_BROWSER_ACTION_TIMEOUT`               | Supprimer             | Non pris en charge                                 |
| `DAST_BROWSER_ALLOWED_HOSTS`                | Renommer             | Vers `DAST_SCOPE_ALLOW_HOSTS`                   |
| `DAST_BROWSER_CACHE`                        | Renommer             | Vers `DAST_USE_CACHE`                           |
| `DAST_BROWSER_COOKIES`                      | Renommer             | Vers `DAST_REQUEST_COOKIES`                     |
| `DAST_BROWSER_CRAWL_GRAPH`                  | Renommer             | Vers `DAST_CRAWL_GRAPH`                         |
| `DAST_BROWSER_CRAWL_TIMEOUT`                | Renommer             | Vers `DAST_CRAWL_TIMEOUT`                       |
| `DAST_BROWSER_DEVTOOLS_LOG`                 | Renommer             | Vers `DAST_LOG_DEVTOOLS_CONFIG`                 |
| `DAST_BROWSER_DOM_READY_AFTER_TIMEOUT`      | Renommer             | Vers `DAST_PAGE_DOM_STABLE_WAIT`                |
| `DAST_BROWSER_ELEMENT_TIMEOUT`              | Renommer             | Vers `DAST_PAGE_ELEMENT_READY_TIMEOUT`          |
| `DAST_BROWSER_EXCLUDED_ELEMENTS`            | Renommer             | Vers `DAST_SCOPE_EXCLUDE_ELEMENTS`              |
| `DAST_BROWSER_EXCLUDED_HOSTS`               | Renommer             | Vers `DAST_SCOPE_EXCLUDE_HOSTS`                 |
| `DAST_BROWSER_EXTRACT_ELEMENT_TIMEOUT`      | Renommer             | Vers `DAST_CRAWL_EXTRACT_ELEMENT_TIMEOUT`       |
| `DAST_BROWSER_FILE_LOG`                     | Renommer             | Vers `DAST_LOG_FILE_CONFIG`                     |
| `DAST_BROWSER_FILE_LOG_PATH`                | Supprimer             | Non requis                            |
| `DAST_BROWSER_IGNORED_HOSTS`                | Renommer             | Vers `DAST_SCOPE_IGNORE_HOSTS`                  |
| `DAST_BROWSER_INCLUDE_ONLY_RULES`           | Renommer             | Vers `DAST_CHECKS_TO_RUN`                       |
| `DAST_BROWSER_LOG`                          | Renommer             | Vers `DAST_LOG_CONFIG`                          |
| `DAST_BROWSER_LOG_CHROMIUM_OUTPUT`          | Renommer             | Vers `DAST_LOG_BROWSER_OUTPUT`                  |
| `DAST_BROWSER_MAX_ACTIONS`                  | Renommer             | Vers `DAST_CRAWL_MAX_ACTIONS`                   |
| `DAST_BROWSER_MAX_DEPTH`                    | Renommer             | Vers `DAST_CRAWL_MAX_DEPTH`                     |
| `DAST_BROWSER_MAX_RESPONSE_SIZE_MB`         | Renommer             | Vers `DAST_PAGE_MAX_RESPONSE_SIZE_MB`           |
| `DAST_BROWSER_NAVIGATION_STABILITY_TIMEOUT` | Renommer             | Vers `DAST_PAGE_DOM_READY_TIMEOUT`              |
| `DAST_BROWSER_NAVIGATION_TIMEOUT`           | Renommer             | Vers `DAST_PAGE_READY_AFTER_NAVIGATION_TIMEOUT` |
| `DAST_BROWSER_NUMBER_OF_BROWSERS`           | Renommer             | Vers `DAST_CRAWL_WORKER_COUNT`                  |
| `DAST_BROWSER_PAGE_LOADING_SELECTOR`        | Renommer             | Vers `DAST_PAGE_IS_LOADING_ELEMENT`             |
| `DAST_BROWSER_PAGE_READY_SELECTOR`          | Renommer             | Vers `DAST_PAGE_IS_READY_ELEMENT`               |
| `DAST_BROWSER_PASSIVE_CHECK_WORKERS`        | Renommer             | Vers `DAST_PASSIVE_SCAN_WORKER_COUNT`           |
| `DAST_BROWSER_SCAN`                         | Supprimer             | Non requis                            |
| `DAST_BROWSER_SEARCH_ELEMENT_TIMEOUT`       | Renommer             | Vers `DAST_CRAWL_SEARCH_ELEMENT_TIMEOUT`        |
| `DAST_BROWSER_STABILITY_TIMEOUT`            | Renommer             | Vers `DAST_PAGE_READY_AFTER_ACTION_TIMEOUT`     |
| `DAST_EXCLUDE_RULES`                        | Renommer             | Vers `DAST_CHECKS_TO_EXCLUDE`                   |
| `DAST_EXCLUDE_URLS`                         | Renommer             | Vers `DAST_SCOPE_EXCLUDE_URLS`                  |
| `DAST_FF_ENABLE_BAS`                        | Supprimer             | Non pris en charge                                 |
| `DAST_FILE_LOG_PATH`                        | Supprimer             | Non requis                            |
| `DAST_FIRST_SUBMIT_FIELD`                   | Renommer             | Vers `DAST_AUTH_FIRST_SUBMIT_FIELD`             |
| `DAST_FULL_SCAN_ENABLED`                    | Renommer             | Vers `DAST_FULL_SCAN`                           |
| `DAST_PASSWORD`                             | Renommer             | Vers `DAST_AUTH_PASSWORD`                       |
| `DAST_PASSWORD_FIELD`                       | Renommer             | Vers `DAST_AUTH_PASSWORD_FIELD`                 |
| `DAST_PATHS`                                | Renommer             | Vers `DAST_TARGET_PATHS`                        |
| `DAST_PATHS_FILE`                           | Renommer             | Vers `DAST_TARGET_PATHS_FROM_FILE`              |
| `DAST_PKCS12_CERTIFICATE_BASE64`            | Aucune action requise |                                               |
| `DAST_PKCS12_PASSWORD`                      | Aucune action requise |                                               |
| `DAST_REQUEST_HEADERS`                      | Aucune action requise |                                               |
| `DAST_SKIP_TARGET_CHECK`                    | Renommer             | Vers `DAST_TARGET_CHECK_SKIP`                   |
| `DAST_SUBMIT_FIELD`                         | Renommer             | Vers `DAST_AUTH_SUBMIT_FIELD`                   |
| `DAST_TARGET_AVAILABILITY_TIMEOUT`          | Renommer             | Vers `DAST_TARGET_CHECK_TIMEOUT`                |
| `DAST_USERNAME`                             | Renommer             | Vers `DAST_AUTH_USERNAME`                       |
| `DAST_USERNAME_FIELD`                       | Renommer             | Vers `DAST_AUTH_USERNAME_FIELD`                 |
| `DAST_WEBSITE`                              | Renommer             | Vers `DAST_TARGET_URL`<br/>GitLab Self-Managed : mettez à niveau votre instance vers la version 17.0 ou ultérieure avant de supprimer `DAST_WEBSITE`. Cette variable est requise si vous utilisez le fichier `DAST.gitlab-ci.yml` inclus avec les versions de GitLab antérieures à la version 17.0. |

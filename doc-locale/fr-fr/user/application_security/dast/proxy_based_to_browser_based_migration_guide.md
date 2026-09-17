---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Migration de l'analyseur proxy DAST vers DAST version 5"
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- L'[analyseur proxy DAST](proxy_based_to_browser_based_migration_guide.md) a été [abandonné](https://gitlab.com/gitlab-org/gitlab/-/issues/430966) dans GitLab 16.6 et supprimé dans la version 17.0.

{{< /history >}}

[DAST version 5](browser/_index.md) remplace l'analyseur proxy par un analyseur basé sur un navigateur. Ce document sert de guide pour migrer de l'analyseur proxy vers DAST version 5.

Suivez ce guide de migration si toutes les conditions suivantes s'appliquent :

1. Vous utilisez GitLab DAST pour exécuter un scan DAST dans un pipeline CI/CD.
1. Le job CI/CD DAST est configuré en incluant l'un des templates DAST `DAST.gitlab-ci.yml` ou `DAST.latest.gitlab-ci.yml`.
1. La variable CI/CD `DAST_VERSION` n'est pas définie ou est définie sur `4` ou moins.
1. La variable CI/CD `DAST_BROWSER_SCAN` n'est pas définie ou est définie sur `false`.

Migrez vers DAST version 5 en lisant les sections suivantes et en appliquant les modifications recommandées.

## Versions de l'analyseur DAST {#dast-analyzer-versions}

DAST est disponible en deux versions majeures : 4 et 5. À partir de GitLab 17.0, les templates DAST `DAST.gitlab-ci.yml` et `DAST.latest.gitlab-ci.yml` utilisent DAST version 5 par défaut. Vous pouvez continuer à utiliser DAST version 4, mais ne le faites qu'à titre de mesure provisoire pendant la migration vers DAST version 5. Pour plus de détails, consultez [Continuer à utiliser l'analyseur proxy](#continuing-to-use-the-proxy-based-analyzer).

Chaque version majeure de DAST utilise des analyseurs différents par défaut :

- DAST version 4 utilise l'analyseur proxy.
- DAST version 5 utilise l'analyseur basé sur un navigateur.

DAST version 5 utilise un ensemble de nouvelles variables CI/CD. Des alias ont été créés pour les noms des variables de DAST version 4.

## Continuer à utiliser l'analyseur proxy {#continuing-to-use-the-proxy-based-analyzer}

Vous pouvez utiliser l'analyseur proxy DAST jusqu'à GitLab 18.0. Les bugs et vulnérabilités de cet analyseur hérité ne seront pas corrigés.

Modifications à apporter :

- Pour continuer à utiliser l'analyseur proxy, définissez la variable CI/CD `DAST_VERSION` sur `4`.

## Artefacts {#artifacts}

GitLab 17.0 publie automatiquement les artefacts produits par DAST version 5 dans le job CI DAST.

Modifications à apporter :

- Supprimez `artifacts` de la définition du job CI si vous l'avez remplacé pour exposer le journal de fichiers, le graphe de navigation ou le rapport d'authentification.
- Les variables CI/CD `DAST_BROWSER_FILE_LOG_PATH` et `DAST_FILE_LOG_PATH` ne sont plus requises.

## Authentification {#authentication}

L'analyseur proxy et DAST version 5 utilisent tous deux l'analyseur basé sur un navigateur pour s'authentifier. La mise à niveau vers DAST version 5 ne modifie pas le fonctionnement de l'authentification.

Modifications à apporter :

- Renommez les variables CI/CD d'authentification ; consultez les variables avec le préfixe `DAST_AUTH`.
- Si ce n'est pas déjà fait, excluez l'URL de déconnexion du scan en utilisant `DAST_SCOPE_EXCLUDE_URLS`.

## Navigation (crawling) {#crawling}

DAST version 5 navigue dans l'application cible via un navigateur pour offrir une meilleure couverture de navigation. Cette opération peut nécessiter plus de ressources qu'une navigation équivalente avec l'analyseur proxy.

Modifications à apporter :

- Utilisez `DAST_TARGET_URL` à la place de `DAST_WEBSITE`.
- Utilisez `DAST_CRAWL_TIMEOUT` à la place de `DAST_SPIDER_MINS`.
- Les variables CI/CD `DAST_USE_AJAX_SPIDER`, `DAST_SPIDER_START_AT_HOST`, `DAST_ZAP_CLI_OPTIONS` et `DAST_ZAP_LOG_CONFIGURATION` ne sont plus prises en charge.
- Configurez `DAST_PAGE_MAX_RESPONSE_SIZE_MB` si DAST doit traiter des corps de réponse de plus de 10 Mo.
- Envisagez de fournir davantage de ressources CPU au GitLab Runner exécutant le job DAST.

## Portée {#scope}

DAST version 5 offre un meilleur contrôle de la portée par rapport à l'analyseur proxy.

Modifications à apporter :

- Utilisez `DAST_SCOPE_ALLOW_HOSTS` à la place de `DAST_ALLOWED_HOSTS`.
- Le domaine de `DAST_TARGET_URL` est automatiquement ajouté à `DAST_SCOPE_ALLOW_HOSTS` ; envisagez d'ajouter des domaines pour les points de terminaison API et les ressources de l'application cible.
- Excluez des domaines du scan en les ajoutant à `DAST_SCOPE_EXCLUDE_HOSTS` (sauf pendant l'authentification).

## Vérifications des vulnérabilités {#vulnerability-checks}

### Modifications requises {#changes-required}

DAST version 5 utilise des définitions de vulnérabilités élaborées par GitLab, qui ne correspondent pas directement aux définitions de l'analyseur proxy.

Modifications à apporter :

- Utilisez `DAST_CHECKS_TO_RUN` à la place de `DAST_ONLY_INCLUDE_RULES`. Remplacez les identifiants utilisés par les identifiants de vérification de vulnérabilité DAST de GitLab.
- Utilisez `DAST_CHECKS_TO_EXCLUDE` à la place de `DAST_EXCLUDE_RULES`. Remplacez les identifiants utilisés par les identifiants de vérification de vulnérabilité DAST de GitLab.
- Consultez la documentation sur les [vérifications de vulnérabilités](browser/checks/_index.md) pour obtenir les descriptions et les identifiants des vérifications de vulnérabilités DAST de GitLab.
- Les variables CI/CD `DAST_AGGREGATE_VULNERABILITIES` et `DAST_MAX_URLS_PER_VULNERABILITY` ne sont plus prises en charge.

### Pourquoi la migration produit des vulnérabilités différentes {#why-migrating-produces-different-vulnerabilities}

Les scans basés sur un proxy et les scans DAST version 5 basés sur un navigateur ne produisent pas les mêmes résultats, car ils utilisent un ensemble différent de vérifications de vulnérabilités.

DAST version 5 n'a pas d'équivalent pour les vérifications basées sur un proxy qui génèrent trop de faux positifs, qui ne valent pas la peine d'être exécutées parce que les navigateurs modernes n'autorisent pas l'exploitation de la vulnérabilité, ou qui ne sont plus considérées comme pertinentes. DAST version 5 inclut des vérifications que l'analyseur proxy ne propose pas.

Les scans de DAST version 5 offrent une meilleure couverture de votre application ; ils peuvent donc identifier davantage de vulnérabilités car une plus grande partie de votre site est analysée.

### Couverture {#coverage}

Une vérification active basée sur un proxy n'a pas encore été implémentée dans l'analyseur DAST basé sur un navigateur. La migration de la vérification active restante est proposée dans l'[epic 13411](https://gitlab.com/groups/gitlab-org/-/epics/13411). Si vous préférez rester sur DAST version 4 jusqu'à la migration de la dernière vérification, consultez [Continuer à utiliser l'analyseur proxy](#continuing-to-use-the-proxy-based-analyzer).

Vérification restante :

- CWE-79 : Cross-site Scripting (XSS)

## Scans à la demande {#on-demand-scans}

Les scans à la demande exécutent un scan basé sur un navigateur en utilisant [DAST version 5](https://gitlab.com/groups/gitlab-org/-/epics/11429) à partir de GitLab 17.0.

## Dépannage {#troubleshooting}

Consultez la documentation sur le [dépannage](browser/troubleshooting.md) de DAST version 5.

## Modifications des variables CI/CD {#changes-to-cicd-variables}

Le tableau suivant présente les actions de migration requises pour chaque variable CI/CD de l'analyseur proxy. Consultez la [configuration](browser/configuration/_index.md) pour plus d'informations sur la configuration de DAST version 5.

| Variable CI/CD de l'analyseur proxy  | Action requise          | Notes                                                                                    |
|:-------------------------------------|:-------------------------|:-----------------------------------------------------------------------------------------|
| `DAST_ADVERTISE_SCAN`                | Renommer                   | En `DAST_REQUEST_ADVERTISE_SCAN`                                                         |
| `DAST_ALLOWED_HOSTS`                 | Renommer                   | En `DAST_SCOPE_ALLOW_HOSTS`                                                              |
| `DAST_API_HOST_OVERRIDE`             | Supprimer                   | Non pris en charge                                                                            |
| `DAST_API_SPECIFICATION`             | Supprimer                   | Non pris en charge                                                                            |
| `DAST_AUTH_EXCLUDE_URLS`             | Renommer                   | En `DAST_SCOPE_EXCLUDE_URLS`                                                             |
| `DAST_AUTO_UPDATE_ADDONS`            | Supprimer                   | Non pris en charge                                                                            |
| `DAST_BROWSER_FILE_LOG_PATH`         | Supprimer                   | N'est plus requis                                                                       |
| `DAST_DEBUG`                         | Supprimer                   | Non pris en charge                                                                            |
| `DAST_EXCLUDE_RULES`                 | Renommer, mettre à jour les identifiants de vérification | En `DAST_CHECKS_TO_EXCLUDE`                                                              |
| `DAST_EXCLUDE_URLS`                  | Renommer                   | En `DAST_SCOPE_EXCLUDE_URLS`                                                             |
| `DAST_FILE_LOG_PATH`                 | Supprimer                   | N'est plus requis                                                                       |
| `DAST_FULL_SCAN_ENABLED`             | Renommer                   | En `DAST_FULL_SCAN`                                                                      |
| `DAST_HTML_REPORT`                   | Supprimer                   | Non pris en charge                                                                            |
| `DAST_INCLUDE_ALPHA_VULNERABILITIES` | Supprimer                   | Non pris en charge                                                                            |
| `DAST_MARKDOWN_REPORT`               | Supprimer                   | Non pris en charge                                                                            |
| `DAST_MASK_HTTP_HEADERS`             | Supprimer                   | Non pris en charge                                                                            |
| `DAST_MAX_URLS_PER_VULNERABILITY`    | Supprimer                   | Non pris en charge                                                                            |
| `DAST_ONLY_INCLUDE_RULES`            | Renommer, mettre à jour les identifiants de vérification | En `DAST_CHECKS_TO_RUN`                                                                  |
| `DAST_PATHS`                         | Aucune                     | Pris en charge                                                                                |
| `DAST_PATHS_FILE`                    | Aucune                     | Pris en charge                                                                                |
| `DAST_PKCS12_CERTIFICATE_BASE64`     | Aucune                     | Pris en charge                                                                                |
| `DAST_PKCS12_PASSWORD`               | Aucune                     | Pris en charge                                                                                |
| `DAST_SKIP_TARGET_CHECK`             | Aucune                     | Pris en charge                                                                                |
| `DAST_SPIDER_MINS`                   | Modifier                   | En `DAST_CRAWL_TIMEOUT` en utilisant une durée. Par exemple, au lieu de `5`, utilisez `5m`          |
| `DAST_SPIDER_START_AT_HOST`          | Supprimer                   | Non pris en charge                                                                            |
| `DAST_TARGET_AVAILABILITY_TIMEOUT`   | Modifier                   | En `DAST_TARGET_CHECK_TIMEOUT` en utilisant une durée. Par exemple, au lieu de `60`, utilisez `60s` |
| `DAST_USE_AJAX_SPIDER`               | Supprimer                   | Non pris en charge                                                                            |
| `DAST_XML_REPORT`                    | Supprimer                   | Non pris en charge                                                                            |
| `DAST_WEBSITE`                              | Renommer             | En `DAST_TARGET_URL`<br/>GitLab Self-Managed : mettez à niveau votre instance vers la version 17.0 ou une version ultérieure avant de supprimer `DAST_WEBSITE`. Cette variable est requise si vous utilisez le fichier `DAST.gitlab-ci.yml` inclus dans les versions de GitLab antérieures à la version 17.0. |
| `DAST_ZAP_CLI_OPTIONS`               | Supprimer                   | Non pris en charge                                                                            |
| `DAST_ZAP_LOG_CONFIGURATION`         | Supprimer                   | Non pris en charge                                                                            |
| `SECURE_ANALYZERS_PREFIX`            | Aucune                     | Pris en charge                                                                                |

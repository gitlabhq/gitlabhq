---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Variables CI/CD disponibles et fichiers de configuration
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/450445) du nom du modèle de `DAST-API.gitlab-ci.yml` vers `API-Security.gitlab-ci.yml` et du préfixe de variable CI/CD de `DAST_API_` vers `APISEC_` dans GitLab 17.1.

{{< /history >}}

## Variables CI/CD disponibles {#available-cicd-variables}

| Variable CI/CD                                                                              | Description |
|---------------------------------------------------------------------------------------------|-------------|
| `SECURE_ANALYZERS_PREFIX`                                                                   | Indiquez l'adresse de base du registre Docker depuis laquelle télécharger l'analyseur. |
| `APISEC_DISABLED`                                                                           | Définissez la valeur 'true' ou '1' pour désactiver l'analyse de sécurité des API. |
| `APISEC_DISABLED_FOR_DEFAULT_BRANCH`                                                        | Définissez la valeur 'true' ou '1' pour désactiver l'analyse de sécurité des API uniquement pour la branche par défaut (production). |
| `APISEC_VERSION`                                                                            | Spécifiez la version du conteneur de test de sécurité des API. La valeur par défaut est `3`. |
| `APISEC_IMAGE_SUFFIX`                                                                       | Indiquez un suffixe d'image de conteneur. La valeur par défaut est aucun. |
| `APISEC_API_PORT`                                                                           | Spécifiez le numéro de port de communication utilisé par le moteur de test de sécurité des API. La valeur par défaut est `5500`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/367734) dans GitLab 15.5. |
| `APISEC_TARGET_URL`                                                                         | URL de base de la cible de test d'API. |
| `APISEC_TARGET_CHECK_SKIP`                                                                  | Désactive l'attente que la cible devienne disponible. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/442699) dans GitLab 17.1. |
| `APISEC_TARGET_CHECK_STATUS_CODE`                                                           | Fournissez le code de statut attendu pour la vérification de disponibilité de la cible. Si non fourni, tout code de statut autre que 500 est acceptable. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/442699) dans GitLab 17.1. |
| [`APISEC_CONFIG`](#configuration-files)                                                     | Fichier de configuration du test de sécurité des API. La valeur par défaut est `.gitlab-dast-api.yml`. |
| [`APISEC_PROFILE`](#configuration-files)                                                    | Profil de configuration à utiliser lors des tests. La valeur par défaut est `Quick`. |
| [`APISEC_EXCLUDE_PATHS`](customizing_analyzer_settings.md#exclude-paths)                    | Exclut des chemins d'URL d'API des tests. |
| [`APISEC_EXCLUDE_URLS`](customizing_analyzer_settings.md#exclude-urls)                      | Exclut des URL d'API des tests. |
| [`APISEC_EXCLUDE_PARAMETER_ENV`](customizing_analyzer_settings.md#exclude-parameters)       | Chaîne JSON contenant les paramètres exclus. |
| [`APISEC_EXCLUDE_PARAMETER_FILE`](customizing_analyzer_settings.md#exclude-parameters)      | Chemin vers un fichier JSON contenant les paramètres exclus. |
| [`APISEC_REQUEST_HEADERS`](customizing_analyzer_settings.md#request-headers)                | Liste d'en-têtes séparés par des virgules (`,`) à inclure dans chaque requête d'analyse. Envisagez d'utiliser `APISEC_REQUEST_HEADERS_BASE64` lors du stockage de valeurs d'en-têtes secrètes dans une [variable masquée](../../../../ci/variables/_index.md#mask-a-cicd-variable), qui présente des restrictions de jeu de caractères. |
| [`APISEC_REQUEST_HEADERS_BASE64`](customizing_analyzer_settings.md#request-headers)         | Liste d'en-têtes séparés par des virgules (`,`) à inclure dans chaque requête d'analyse, encodée en Base64. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/378440) dans GitLab 15.6. |
| [`APISEC_OPENAPI`](enabling_the_analyzer.md#openapi-specification)                          | Fichier de spécification OpenAPI ou URL. |
| [`APISEC_OPENAPI_RELAXED_VALIDATION`](enabling_the_analyzer.md#openapi-specification)       | Assouplit la validation du document. Désactivé par défaut. |
| [`APISEC_OPENAPI_ALL_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)          | Utilise tous les types de médias pris en charge au lieu d'un seul lors de la génération des requêtes. Entraîne une durée de test plus longue. Désactivé par défaut. |
| [`APISEC_OPENAPI_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)              | Types de médias séparés par deux-points (`:`) acceptés pour les tests. Désactivé par défaut. |
| [`APISEC_HAR`](enabling_the_analyzer.md#http-archive-har)                                   | Fichier HTTP Archive (HAR). |
| [`APISEC_GRAPHQL`](enabling_the_analyzer.md#graphql-schema)                                 | Chemin vers le point de terminaison GraphQL, par exemple `/api/graphql`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) dans GitLab 15.4. |
| [`APISEC_GRAPHQL_SCHEMA`](enabling_the_analyzer.md#graphql-schema)                          | Une URL ou un nom de fichier pour un schéma GraphQL au format JSON. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) dans GitLab 15.4. |
| [`APISEC_POSTMAN_COLLECTION`](enabling_the_analyzer.md#postman-collection)                  | Fichier Postman Collection. |
| [`APISEC_POSTMAN_COLLECTION_VARIABLES`](enabling_the_analyzer.md#postman-variables)         | Chemin vers un fichier JSON pour extraire les valeurs des variables Postman. La prise en charge des fichiers séparés par des virgules (`,`) a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/356312) dans GitLab 15.1. |
| [`APISEC_OVERRIDES_FILE`](customizing_analyzer_settings.md#overrides)                       | Chemin vers un fichier JSON contenant les remplacements. |
| [`APISEC_OVERRIDES_ENV`](customizing_analyzer_settings.md#overrides)                        | Chaîne JSON contenant les en-têtes à remplacer. |
| [`APISEC_OVERRIDES_CMD`](customizing_analyzer_settings.md#overrides)                        | Commande de remplacement. |
| [`APISEC_OVERRIDES_CMD_VERBOSE`](customizing_analyzer_settings.md#overrides)                | Lorsque défini sur n'importe quelle valeur. Les sorties de la commande de remplacement sont journalisées dans le fichier d'artefact de job `gl-api-security-scanner.log`. |
| `APISEC_PER_REQUEST_SCRIPT`                                                                 | Chemin complet et nom de fichier pour un script par requête. [Voir le projet de démonstration pour des exemples.](https://gitlab.com/gitlab-org/security-products/demos/api-dast/auth-with-request-example) [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/13691) dans GitLab 17.2. |
| `APISEC_PRE_SCRIPT`                                                                         | Exécute une commande ou un script utilisateur avant le démarrage de la session d'analyse. `sudo` doit être utilisé pour les opérations privilégiées telles que l'installation de paquets. |
| `APISEC_POST_SCRIPT`                                                                        | Exécute une commande ou un script utilisateur après la fin de la session d'analyse. `sudo` doit être utilisé pour les opérations privilégiées telles que l'installation de paquets. |
| [`APISEC_OVERRIDES_INTERVAL`](customizing_analyzer_settings.md#overrides)                   | Fréquence d'exécution de la commande de remplacement en secondes. La valeur par défaut est `0` (une fois). |
| [`APISEC_HTTP_USERNAME`](customizing_analyzer_settings.md#http-basic-authentication)        | Nom d'utilisateur pour l'authentification HTTP. |
| [`APISEC_HTTP_PASSWORD`](customizing_analyzer_settings.md#http-basic-authentication)        | Mot de passe pour l'authentification HTTP. Envisagez d'utiliser `APISEC_HTTP_PASSWORD_BASE64` à la place. |
| [`APISEC_HTTP_PASSWORD_BASE64`](customizing_analyzer_settings.md#http-basic-authentication) | Mot de passe pour l'authentification HTTP, encodé en base64. [Introduit](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing-src/-/merge_requests/702) dans GitLab 15.4. |
| `APISEC_SERVICE_START_TIMEOUT`                                                              | Durée d'attente en secondes pour que l'API cible soit disponible. La valeur par défaut est 300 secondes. |
| `APISEC_TIMEOUT`                                                                            | Durée d'attente en secondes pour les réponses de l'API. La valeur par défaut est 30 secondes. |
| `APISEC_SUCCESS_STATUS_CODES`                                                               | Spécifiez une liste séparée par des virgules (`,`) de codes de statut HTTP indiquant le succès qui déterminent si un job d'analyse de sécurité des API a réussi. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/442219) dans GitLab 17.1. Exemple : `'200, 201, 204'` |

## Fichiers de configuration {#configuration-files}

Pour vous aider à démarrer rapidement, GitLab fournit le fichier de configuration [`gitlab-dast-api-config.yml`](https://gitlab.com/gitlab-org/security-products/analyzers/dast/-/blob/master/config/gitlab-dast-api-config.yml). Ce fichier contient plusieurs profils de test qui effectuent différents nombres de tests. La durée d'exécution de chaque profil augmente à mesure que le nombre de tests augmente. Pour utiliser un fichier de configuration, ajoutez-le à la racine de votre dépôt sous le nom `.gitlab/gitlab-dast-api-config.yml`.

### Profils {#profiles}

Les profils suivants sont prédéfinis dans le fichier de configuration par défaut. Des profils peuvent être ajoutés, supprimés et modifiés en créant une configuration personnalisée.

#### Passive {#passive}

- Application Information Check
- Cleartext Authentication Check
- JSON Hijacking Check
- Sensitive Information Check
- Session Cookie Check

#### Quick {#quick}

- Application Information Check
- Cleartext Authentication Check
- FrameworkDebugModeCheck
- HTML Injection Check
- Insecure Http Methods Check
- JSON Hijacking Check
- JSON Injection Check
- Sensitive Information Check
- Session Cookie Check
- SQL Injection Check
- Token Check
- XML Injection Check

#### Full {#full}

- Application Information Check
- Cleartext AuthenticationCheck
- CORS Check
- DNS Rebinding Check
- Framework Debug Mode Check
- HTML Injection Check
- Insecure Http Methods Check
- JSON Hijacking Check
- JSON Injection Check
- Open Redirect Check
- Sensitive File Check
- Sensitive Information Check
- Session Cookie Check
- SQL Injection Check
- TLS Configuration Check
- Token Check
- XML Injection Check

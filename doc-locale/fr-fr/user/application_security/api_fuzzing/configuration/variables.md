---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Variables CI/CD disponibles
---

| Variable CI/CD                                                                               | Description |
|----------------------------------------------------------------------------------------------|-------------|
| `SECURE_ANALYZERS_PREFIX`                                                                    | Indiquez l'adresse de base du registre Docker depuis laquelle télécharger l'analyseur. |
| `FUZZAPI_VERSION`                                                                            | Indiquez la version du conteneur de fuzzing d'API. La valeur par défaut est `5`. |
| `FUZZAPI_IMAGE_SUFFIX`                                                                       | Indiquez un suffixe d'image de conteneur. La valeur par défaut est aucun. |
| `FUZZAPI_API_PORT`                                                                           | Indiquez le numéro de port de communication utilisé par le moteur de fuzzing d'API. La valeur par défaut est `5500`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/367734) dans GitLab 15.5. |
| `FUZZAPI_TARGET_URL`                                                                         | URL de base de la cible de test d'API. |
| `FUZZAPI_TARGET_CHECK_SKIP`                                                                  | Désactive l'attente que la cible devienne disponible. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/442699) dans GitLab 17.1. |
| `FUZZAPI_TARGET_CHECK_STATUS_CODE`                                                           | Fournissez le code de statut attendu pour la vérification de disponibilité de la cible. Si non fourni, tout code de statut autre que 500 est acceptable. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/442699) dans GitLab 17.1. |
| [`FUZZAPI_PROFILE`](customizing_analyzer_settings.md#api-fuzzing-profiles)                   | Profil de configuration à utiliser lors des tests. La valeur par défaut est `Quick-10`. |
| [`FUZZAPI_EXCLUDE_PATHS`](customizing_analyzer_settings.md#exclude-paths)                    | Exclut des chemins d'URL d'API des tests. |
| [`FUZZAPI_EXCLUDE_URLS`](customizing_analyzer_settings.md#exclude-urls)                      | Exclut des URL d'API des tests. |
| [`FUZZAPI_EXCLUDE_PARAMETER_ENV`](customizing_analyzer_settings.md#exclude-parameters)       | Chaîne JSON contenant les paramètres exclus. |
| [`FUZZAPI_EXCLUDE_PARAMETER_FILE`](customizing_analyzer_settings.md#exclude-parameters)      | Chemin vers un fichier JSON contenant les paramètres exclus. |
| [`FUZZAPI_OPENAPI`](enabling_the_analyzer.md#openapi-specification)                          | Fichier ou URL de spécification OpenAPI. |
| [`FUZZAPI_OPENAPI_RELAXED_VALIDATION`](enabling_the_analyzer.md#openapi-specification)       | Assouplit la validation du document. Désactivé par défaut. |
| [`FUZZAPI_OPENAPI_ALL_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)          | Utilise tous les types de médias pris en charge au lieu d'un seul lors de la génération des requêtes. Entraîne une durée de test plus longue. Désactivé par défaut. |
| [`FUZZAPI_OPENAPI_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)              | Types de médias séparés par deux-points (`:`) acceptés pour les tests. Désactivé par défaut. |
| [`FUZZAPI_HAR`](enabling_the_analyzer.md#http-archive-har)                                   | Fichier HTTP Archive (HAR). |
| [`FUZZAPI_GRAPHQL`](enabling_the_analyzer.md#graphql-schema)                                 | Chemin vers le point de terminaison GraphQL, par exemple `/api/graphql`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) dans GitLab 15.4. |
| [`FUZZAPI_GRAPHQL_SCHEMA`](enabling_the_analyzer.md#graphql-schema)                          | Une URL ou un nom de fichier pour un schéma GraphQL au format JSON. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) dans GitLab 15.4. |
| [`FUZZAPI_POSTMAN_COLLECTION`](enabling_the_analyzer.md#postman-collection)                  | Fichier Postman Collection. |
| [`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`](enabling_the_analyzer.md#postman-variables)         | Chemin vers un fichier JSON pour extraire les valeurs des variables Postman. La prise en charge des fichiers séparés par des virgules (`,`) a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/356312) dans GitLab 15.1. |
| [`FUZZAPI_OVERRIDES_FILE`](customizing_analyzer_settings.md#overrides)                       | Chemin vers un fichier JSON contenant les remplacements. |
| [`FUZZAPI_OVERRIDES_ENV`](customizing_analyzer_settings.md#overrides)                        | Chaîne JSON contenant les en-têtes à remplacer. |
| [`FUZZAPI_OVERRIDES_CMD`](customizing_analyzer_settings.md#overrides)                        | Commande de remplacement. |
| [`FUZZAPI_OVERRIDES_CMD_VERBOSE`](customizing_analyzer_settings.md#overrides)                | Lorsque défini sur n'importe quelle valeur. Affiche la sortie de la commande de remplacement dans la sortie du job. |
| `FUZZAPI_PER_REQUEST_SCRIPT`                                                                 | Chemin complet et nom de fichier pour un script par requête. [Voir le projet de démonstration pour des exemples.](https://gitlab.com/gitlab-org/security-products/demos/api-dast/auth-with-request-example) [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/13691) dans GitLab 17.2. |
| `FUZZAPI_PRE_SCRIPT`                                                                         | Exécute une commande ou un script utilisateur avant le démarrage de la session d'analyse. `sudo` doit être utilisé pour les opérations privilégiées telles que l'installation de paquets. |
| `FUZZAPI_POST_SCRIPT`                                                                        | Exécute une commande ou un script utilisateur après la fin de la session d'analyse. `sudo` doit être utilisé pour les opérations privilégiées telles que l'installation de paquets. |
| [`FUZZAPI_OVERRIDES_INTERVAL`](customizing_analyzer_settings.md#overrides)                   | Fréquence d'exécution de la commande de remplacement en secondes. La valeur par défaut est `0` (une fois). |
| [`FUZZAPI_HTTP_USERNAME`](customizing_analyzer_settings.md#http-basic-authentication)        | Nom d'utilisateur pour l'authentification HTTP. |
| [`FUZZAPI_HTTP_PASSWORD`](customizing_analyzer_settings.md#http-basic-authentication)        | Mot de passe pour l'authentification HTTP. |
| [`FUZZAPI_HTTP_PASSWORD_BASE64`](customizing_analyzer_settings.md#http-basic-authentication) | Mot de passe pour l'authentification HTTP, encodé en Base64. [Introduit](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing-src/-/merge_requests/702) dans GitLab 15.4. |
| `FUZZAPI_SUCCESS_STATUS_CODES`                                                               | Indiquez une liste de codes de statut HTTP de succès séparés par des virgules (`,`) qui déterminent si un job d'analyse par fuzzing d'API a réussi. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/442219) dans GitLab 17.1. Exemple : `'200, 201, 204'` |

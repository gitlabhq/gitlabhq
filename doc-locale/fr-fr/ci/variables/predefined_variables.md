---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Variables CI/CD prédéfinies disponibles dans les pipelines GitLab.
title: Référence des variables CI/CD prédéfinies
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les [variables CI/CD](_index.md) prédéfinies sont disponibles dans chaque pipeline CI/CD GitLab.

Évitez de [remplacer](_index.md#use-pipeline-variables) les variables prédéfinies, car cela peut entraîner un comportement inattendu du pipeline.

## Disponibilité des variables {#variable-availability}

Les variables prédéfinies deviennent disponibles à trois phases différentes de l'exécution du pipeline :

- Pré-pipeline : Les variables pré-pipeline sont disponibles avant la création du pipeline. Ces variables sont les seules qui peuvent être utilisées avec [`include:rules`](../yaml/_index.md#includerules) pour contrôler les fichiers de configuration à utiliser lors de la création du pipeline.
- Pipeline : Les variables de pipeline deviennent disponibles lorsque GitLab crée le pipeline. En plus des variables pré-pipeline, les variables de pipeline peuvent être utilisées pour configurer les [`rules`](../yaml/_index.md#rules) définies dans les jobs, afin de déterminer quels jobs ajouter au pipeline.
- Job uniquement : Ces variables ne sont rendues disponibles à chaque job que lorsqu'un runner prend en charge le job et l'exécute, et :
  - Peuvent être utilisées dans les scripts de job.
  - Ne peuvent pas être utilisées avec les [jobs de déclenchement](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file).
  - Ne peuvent pas être utilisées avec [`workflow`](../yaml/_index.md#workflow), [`include`](../yaml/_index.md#include) ou [`rules`](../yaml/_index.md#rules).

## Variables prédéfinies {#predefined-variables}

| Variable                                        | Disponibilité | Description |
|-------------------------------------------------|--------------|-------------|
| `CHAT_CHANNEL`                                  | Pipeline     | Le canal de chat source qui a déclenché la commande [ChatOps](../chatops/_index.md). |
| `CHAT_INPUT`                                    | Pipeline     | Les arguments supplémentaires transmis avec la commande [ChatOps](../chatops/_index.md). |
| `CHAT_USER_ID`                                  | Pipeline     | L'ID utilisateur du service de chat de l'utilisateur qui a déclenché la commande [ChatOps](../chatops/_index.md). |
| `CI`                                            | Pré-pipeline | Disponible pour tous les jobs exécutés en CI/CD. `true` lorsque disponible. |
| `CI_API_V4_URL`                                 | Pré-pipeline | L'URL racine de l'API GitLab v4. |
| `CI_API_GRAPHQL_URL`                            | Pré-pipeline | L'URL racine GraphQL de l'API GitLab. |
| `CI_BUILD_NETWORK_NAME`                         | Job uniquement     | Le nom du réseau créé par le job. Disponible uniquement avec l'exécuteur Docker lorsque [`FF_NETWORK_PER_BUILD`](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags) est activé. |
| `CI_BUILDS_DIR`                                 | Job uniquement     | Le répertoire de niveau supérieur dans lequel les builds sont exécutés. |
| `CI_COMMIT_AUTHOR`                              | Pré-pipeline | L'auteur du commit au format `Name <email>`. |
| `CI_COMMIT_BEFORE_SHA`                          | Pré-pipeline | Le commit le plus récent précédent présent sur une branche ou un tag. Vaut toujours `0000000000000000000000000000000000000000` pour les pipelines de merge request, les pipelines planifiés, le premier commit dans les pipelines pour les branches ou les tags, ou lors de l'exécution manuelle d'un pipeline. |
| `CI_COMMIT_BRANCH`                              | Pré-pipeline | Le nom de la branche du commit. Disponible dans les pipelines de branche, y compris les pipelines pour la branche par défaut. Non disponible dans les pipelines de merge request ou les pipelines de tag. |
| `CI_COMMIT_DEFAULT_BRANCH_BASE_SHA`             | Pré-pipeline | La base de fusion entre `CI_COMMIT_SHA` et la branche par défaut. Disponible uniquement dans les pipelines de branche non-défaut. Introduit dans GitLab 19.1. |
| `CI_COMMIT_DESCRIPTION`                         | Pré-pipeline | La description du commit. Si le titre contient moins de 100 caractères, le message sans la première ligne. |
| `CI_COMMIT_MESSAGE`                             | Pré-pipeline | Le message complet du commit. |
| `CI_COMMIT_MESSAGE_IS_TRUNCATED`                | Pré-pipeline | `true` si `CI_COMMIT_MESSAGE` est tronqué à la taille spécifiée dans la variable d'environnement système `GITLAB_CI_MAX_COMMIT_MESSAGE_SIZE_IN_BYTES` (par défaut 100 Ko) parce que le message du commit est trop long. Sinon `false`. Introduit dans GitLab 18.6. |
| `CI_COMMIT_REF_NAME`                            | Pré-pipeline | Le nom de la branche ou du tag pour lequel le projet est construit. |
| `CI_COMMIT_REF_PROTECTED`                       | Pré-pipeline | `true` si le job s'exécute pour une référence protégée, `false` sinon. |
| `CI_COMMIT_REF_SLUG`                            | Pré-pipeline | `CI_COMMIT_REF_NAME` en minuscules, raccourci à 63 octets, et avec tout ce qui n'est pas `0-9` et `a-z` remplacé par `-`. Pas de `-` en début / fin. À utiliser dans les URL, les noms d'hôte et les noms de domaine. |
| `CI_COMMIT_SHA`                                 | Pré-pipeline | La révision du commit pour laquelle le projet est construit. |
| `CI_COMMIT_SHORT_SHA`                           | Pré-pipeline | Les huit premiers caractères de `CI_COMMIT_SHA`. |
| `CI_COMMIT_TAG`                                 | Pré-pipeline | Le nom du tag du commit. Disponible uniquement dans les pipelines pour les tags. |
| `CI_COMMIT_TAG_MESSAGE`                         | Pré-pipeline | Le message du tag du commit. Disponible uniquement dans les pipelines pour les tags. |
| `CI_COMMIT_TIMESTAMP`                           | Pré-pipeline | L'horodatage du commit au format [ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A). Par exemple, `2022-01-31T16:47:55Z`. [UTC par défaut](../../administration/timezone.md). |
| `CI_COMMIT_TITLE`                               | Pré-pipeline | Le titre du commit. La première ligne complète du message. |
| `CI_COMMIT_USER_LOGIN`                          | Pré-pipeline | Le nom d'utilisateur GitLab de l'auteur du commit si le profil et l'e-mail de l'auteur sont publics et correspondent à l'e-mail du commit, sinon une chaîne vide. Introduit dans GitLab 18.10. |
| `CI_CONCURRENT_ID`                              | Job uniquement     | L'ID unique de l'exécution de build dans un seul exécuteur. |
| `CI_CONCURRENT_PROJECT_ID`                      | Job uniquement     | L'ID unique de l'exécution de build dans un seul exécuteur et projet. |
| `CI_CONFIG_PATH`                                | Pré-pipeline | Le chemin vers le fichier de configuration CI/CD. Par défaut `.gitlab-ci.yml`. |
| `CI_CONFIG_REF_URI`                             | Pipeline     | Le chemin de référence complet vers la définition du pipeline de niveau supérieur, par exemple `gitlab.example.com/my-group/my-project//.gitlab-ci.yml@refs/heads/main`. Non disponible lorsque la référence source du pipeline ne peut pas être déterminée. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/593105) dans GitLab 19.0. |
| `CI_DEBUG_TRACE`                                | Pipeline     | `true` si la [journalisation de débogage (traçage)](variables_troubleshooting.md#enable-debug-logging) est activée. |
| `CI_DEBUG_SERVICES`                             | Pipeline     | `true` si la [journalisation des conteneurs de service](../services/_index.md#capturing-service-container-logs) est activée. |
| `CI_DEFAULT_BRANCH`                             | Pré-pipeline | Le nom de la branche par défaut du projet. |
| `CI_DEFAULT_BRANCH_SLUG`                        | Pré-pipeline | `CI_DEFAULT_BRANCH` en minuscules, raccourci à 63 octets, et avec tout ce qui n'est pas `0-9` et `a-z` remplacé par `-`. Pas de `-` en début / fin. À utiliser dans les URL, les noms d'hôte et les noms de domaine. |
| `CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX` | Pré-pipeline | Le préfixe d'image de groupe direct pour extraire des images via le proxy de dépendances. |
| `CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX`        | Pré-pipeline | Le préfixe d'image de groupe principal pour extraire des images via le proxy de dépendances. |
| `CI_DEPENDENCY_PROXY_PASSWORD`                  | Pipeline     | Le mot de passe pour extraire des images via le proxy de dépendances. |
| `CI_DEPENDENCY_PROXY_SERVER`                    | Pré-pipeline | Le serveur pour se connecter au proxy de dépendances. Cette variable est équivalente à `$CI_SERVER_HOST:$CI_SERVER_PORT`. |
| `CI_DEPENDENCY_PROXY_USER`                      | Pipeline     | Le nom d'utilisateur pour extraire des images via le proxy de dépendances. |
| `CI_DEPLOY_FREEZE`                              | Pré-pipeline | Disponible uniquement si le pipeline s'exécute pendant une [fenêtre de gel du déploiement](../../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze). `true` lorsque disponible. |
| `CI_DEPLOY_PASSWORD`                            | Job uniquement     | Le mot de passe d'authentification du [jeton de déploiement GitLab](../../user/project/deploy_tokens/_index.md#gitlab-deploy-token), si le projet en possède un. |
| `CI_DEPLOY_USER`                                | Job uniquement     | Le nom d'utilisateur d'authentification du [jeton de déploiement GitLab](../../user/project/deploy_tokens/_index.md#gitlab-deploy-token), si le projet en possède un. |
| `CI_DISPOSABLE_ENVIRONMENT`                     | Pipeline     | Disponible uniquement si le job est exécuté dans un environnement jetable (quelque chose qui est créé uniquement pour ce job et supprimé/détruit après l'exécution - tous les exécuteurs sauf `shell` et `ssh`). `true` lorsque disponible. |
| `CI_ENVIRONMENT_ID`                             | Pipeline     | L'ID de l'environnement pour ce job. Disponible si [`environment:name`](../yaml/_index.md#environmentname) est défini. |
| `CI_ENVIRONMENT_NAME`                           | Pipeline     | Le nom de l'environnement pour ce job. Disponible si [`environment:name`](../yaml/_index.md#environmentname) est défini. |
| `CI_ENVIRONMENT_SLUG`                           | Pipeline     | La version simplifiée du nom de l'environnement, adaptée à l'inclusion dans les DNS, les URL, les labels Kubernetes, etc. Disponible si [`environment:name`](../yaml/_index.md#environmentname) est défini. Le slug est [tronqué à 24 caractères](https://gitlab.com/gitlab-org/gitlab/-/issues/20941). Un suffixe aléatoire est automatiquement ajouté aux [noms d'environnement en majuscules](https://gitlab.com/gitlab-org/gitlab/-/issues/415526). |
| `CI_ENVIRONMENT_URL`                            | Pipeline     | L'URL de l'environnement pour ce job. Disponible si [`environment:url`](../yaml/_index.md#environmenturl) est défini. |
| `CI_ENVIRONMENT_ACTION`                         | Pipeline     | L'annotation d'action spécifiée pour l'environnement de ce job. Disponible si [`environment:action`](../yaml/_index.md#environmentaction) est défini. Peut être `start`, `prepare` ou `stop`. |
| `CI_ENVIRONMENT_TIER`                           | Pipeline     | Le [niveau de déploiement de l'environnement](../environments/_index.md#deployment-tier-of-environments) pour ce job. |
| `CI_GITLAB_FIPS_MODE`                           | Pré-pipeline | Disponible uniquement si le [mode FIPS](../../development/fips_gitlab.md) est activé dans l'instance GitLab. `true` lorsque disponible. |
| `CI_HAS_OPEN_REQUIREMENTS`                      | Pipeline     | Disponible uniquement si le projet du pipeline a une [exigence](../../user/project/requirements/_index.md) ouverte. `true` lorsque disponible. |
| `CI_JOB_GROUP_NAME`                             | Pipeline     | Le nom partagé d'un groupe de jobs, lors de l'utilisation de [`parallel`](../yaml/_index.md#parallel) ou de [jobs groupés manuellement](../jobs/_index.md#group-similar-jobs-together-in-pipeline-views). Par exemple, si le nom du job est `rspec:test: [ruby, ubuntu]`, le `CI_JOB_GROUP_NAME` est `rspec:test`. Il est identique à `CI_JOB_NAME` dans les autres cas. Introduit dans GitLab 17.10. |
| `CI_JOB_ID`                                     | Job uniquement     | L'ID interne du job, unique parmi tous les jobs de l'instance GitLab. |
| `CI_JOB_IMAGE`                                  | Job uniquement     | Le nom de l'image Docker exécutant le job. Disponible uniquement lorsque le job spécifie explicitement une image Docker. |
| `CI_JOB_MANUAL`                                 | Pipeline     | Disponible uniquement si le job a été démarré manuellement. `true` lorsque disponible. |
| `CI_JOB_NAME`                                   | Pipeline     | Le nom du job. |
| `CI_JOB_NAME_SLUG`                              | Pipeline     | `CI_JOB_NAME` en minuscules, raccourci à 63 octets, et avec tout ce qui n'est pas `0-9` et `a-z` remplacé par `-`. Pas de `-` en début / fin. À utiliser dans les chemins. |
| `CI_JOB_STAGE`                                  | Pipeline     | Le nom de l'étape du job. |
| `CI_JOB_STATUS`                                 | Job uniquement     | Le statut du job à mesure que chaque étape du runner est exécutée. À utiliser avec [`after_script`](../yaml/_index.md#after_script). Peut être `success`, `failed` ou `canceled`. |
| `CI_JOB_TIMEOUT`                                | Job uniquement     | Le délai d'expiration du job, en secondes. |
| `CI_JOB_TOKEN`                                  | Job uniquement     | Un token pour s'authentifier auprès de [certains endpoints d'API](../jobs/ci_job_token.md). Le token est valide tant que le job est en cours d'exécution. |
| `CI_JOB_URL`                                    | Job uniquement     | L'URL des détails du job. |
| `CI_JOB_STARTED_AT`                             | Job uniquement     | La date et l'heure de démarrage d'un job, au format [ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A). Par exemple, `2022-01-31T16:47:55Z`. [UTC par défaut](../../administration/timezone.md). |
| `CI_JOB_STARTED_AT_SLUG`                        | Job uniquement     | `CI_JOB_STARTED_AT` en minuscules, raccourci à 63 octets, et avec tout ce qui n'est pas `0-9` et `a-z` remplacé par `-`. Pas de `-` en début / fin. Adapté à une utilisation dans les tags d'image Docker et d'autres identifiants. Introduit dans GitLab 18.7. |
| `CI_KUBERNETES_ACTIVE`                          | Pré-pipeline | Disponible uniquement si le pipeline dispose d'un cluster Kubernetes disponible pour les déploiements. `true` lorsque disponible. |
| `CI_NODE_INDEX`                                 | Pipeline     | L'index du job dans l'ensemble de jobs. Disponible uniquement si le job utilise [`parallel`](../yaml/_index.md#parallel). |
| `CI_NODE_TOTAL`                                 | Pipeline     | Le nombre total d'instances de ce job s'exécutant en parallèle. Défini à `1` si le job n'utilise pas [`parallel`](../yaml/_index.md#parallel). |
| `CI_OPEN_MERGE_REQUESTS`                        | Pré-pipeline | Une liste séparée par des virgules de jusqu'à quatre merge requests qui utilisent la branche et le projet actuels comme source de la merge request. Disponible uniquement dans les pipelines de branche et de merge request si la branche a une merge request associée. Par exemple, `gitlab-org/gitlab!333,gitlab-org/gitlab-foss!11`. |
| `CI_PAGES_DOMAIN`                               | Pré-pipeline | Le domaine de l'instance qui héberge GitLab Pages, sans le sous-domaine de l'espace de nommage. Pour utiliser le nom d'hôte complet, utilisez plutôt `CI_PAGES_HOSTNAME`. |
| `CI_PAGES_HOSTNAME`                             | Job uniquement     | Le nom d'hôte complet du déploiement Pages. |
| `CI_PAGES_URL`                                  | Job uniquement     | L'URL d'un site GitLab Pages. Toujours un sous-domaine de `CI_PAGES_DOMAIN`. Dans GitLab 17.9 et versions ultérieures, la valeur inclut le `path_prefix` lorsqu'un est spécifié. |
| `CI_PIPELINE_ID`                                | Job uniquement     | L'ID au niveau de l'instance du pipeline actuel. Cet ID est unique parmi tous les projets de l'instance GitLab. |
| `CI_PIPELINE_IID`                               | Pipeline     | L'IID (ID interne) au niveau du projet du pipeline actuel. Cet ID est unique uniquement dans le projet actuel. |
| `CI_PIPELINE_SOURCE`                            | Pré-pipeline | Comment le pipeline a été déclenché. La valeur peut être l'une des [sources de pipeline](../jobs/job_rules.md#ci_pipeline_source-predefined-variable). |
| `CI_PIPELINE_TRIGGERED`                         | Pipeline     | `true` pour les pipelines [déclenchés avec un token de déclenchement](../triggers/_index.md). Pour les pipelines déclenchés avec le mot-clé [`trigger`](../yaml/_index.md#trigger), utilisez plutôt [`CI_PIPELINE_SOURCE`](../jobs/job_rules.md#ci_pipeline_source-predefined-variable). |
| `CI_PIPELINE_URL`                               | Job uniquement     | L'URL des détails du pipeline. |
| `CI_PIPELINE_CREATED_AT`                        | Job uniquement     | La date et l'heure de création du pipeline, au format [ISO 8601](https://www.rfc-editor.org/rfc/rfc3339#appendix-A). Par exemple, `2022-01-31T16:47:55Z`. [UTC par défaut](../../administration/timezone.md). |
| `CI_PIPELINE_NAME`                              | Pré-pipeline | Le nom du pipeline défini dans [`workflow:name`](../yaml/_index.md#workflowname). |
| `CI_PIPELINE_SCHEDULE_DESCRIPTION`              | Pré-pipeline | La description de la planification de pipeline. Disponible uniquement dans les pipelines planifiés. Introduit dans GitLab 17.8. |
| `CI_PROJECT_DIR`                                | Job uniquement     | Le chemin complet vers lequel le dépôt est cloné et à partir duquel le job s'exécute. Si le paramètre `builds_dir` de GitLab Runner est défini, cette variable est définie par rapport à la valeur de `builds_dir`. Pour plus d'informations, consultez la [configuration avancée de GitLab Runner](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section). |
| `CI_PROJECT_ID`                                 | Pré-pipeline | L'ID du projet actuel. Cet ID est unique parmi tous les projets de l'instance GitLab. |
| `CI_PROJECT_NAME`                               | Pré-pipeline | Le nom du répertoire du projet. Par exemple, si l'URL du projet est `gitlab.example.com/group-name/project-1`, `CI_PROJECT_NAME` est `project-1`. |
| `CI_PROJECT_NAMESPACE`                          | Pré-pipeline | L'espace de nommage du projet (nom d'utilisateur ou nom de groupe) du job. |
| `CI_PROJECT_NAMESPACE_ID`                       | Pré-pipeline | L'ID d'espace de nommage du projet du job. |
| `CI_PROJECT_NAMESPACE_SLUG`                     | Pré-pipeline | `$CI_PROJECT_NAMESPACE` en minuscules, raccourci à 63 octets, et avec tout ce qui n'est pas `0-9` et `a-z` remplacé par `-`. Pas de `-` en début / fin. |
| `CI_PROJECT_PATH_SLUG`                          | Pré-pipeline | `$CI_PROJECT_PATH` en minuscules, raccourci à 63 octets, et avec tout ce qui n'est pas `0-9` et `a-z` remplacé par `-`. Pas de `-` en début / fin. À utiliser dans les URL et les noms de domaine. |
| `CI_PROJECT_PATH`                               | Pré-pipeline | L'espace de nommage du projet avec le nom du projet inclus. |
| `CI_PROJECT_REPOSITORY_LANGUAGES`               | Pré-pipeline | Une liste en minuscules séparée par des virgules des langages utilisés dans le dépôt. Par exemple `ruby,javascript,html,css`. Le nombre maximum de langages est limité à 5. Un ticket [propose d'augmenter la limite](https://gitlab.com/gitlab-org/gitlab/-/issues/368925). |
| `CI_PROJECT_ROOT_NAMESPACE`                     | Pré-pipeline | L'espace de nommage du projet racine (nom d'utilisateur ou nom de groupe) du job. Par exemple, si `CI_PROJECT_NAMESPACE` est `root-group/child-group/grandchild-group`, `CI_PROJECT_ROOT_NAMESPACE` est `root-group`. |
| `CI_PROJECT_ROOT_NAMESPACE_SLUG`                | Pré-pipeline | `$CI_PROJECT_ROOT_NAMESPACE` en minuscules, raccourci à 63 octets, et avec tout ce qui n'est pas `0-9` et `a-z` remplacé par `-`. Pas de `-` en début / fin. Introduit dans GitLab 19.0. |
| `CI_PROJECT_TITLE`                              | Pré-pipeline | Le nom du projet lisible par l'utilisateur tel qu'affiché dans l'interface web GitLab. |
| `CI_PROJECT_DESCRIPTION`                        | Pré-pipeline | La description du projet telle qu'affichée dans l'interface web GitLab. |
| `CI_PROJECT_TOPICS`                             | Pré-pipeline | Une liste en minuscules séparée par des virgules de [sujets](../../user/project/project_topics.md) (limitée aux 20 premiers) attribués au projet. Introduit dans GitLab 18.3 |
| `CI_PROJECT_URL`                                | Pré-pipeline | L'adresse HTTP(S) du projet. |
| `CI_PROJECT_VISIBILITY`                         | Pré-pipeline | La visibilité du projet. Peut être `internal`, `private` ou `public`. |
| `CI_PROJECT_CLASSIFICATION_LABEL`               | Pré-pipeline | Le [label de classification d'autorisation externe](../../administration/settings/external_authorization.md) du projet. |
| `CI_REGISTRY`                                   | Pré-pipeline | Adresse du serveur de [registre de conteneurs](../../user/packages/container_registry/_index.md), au format `<host>[:<port>]`. Par exemple : `registry.gitlab.example.com`. Disponible uniquement si le registre de conteneurs est activé pour l'instance GitLab. |
| `CI_REGISTRY_IMAGE`                             | Pré-pipeline | Adresse de base du registre de conteneurs pour pousser, extraire ou tagger les images du projet, au format `<host>[:<port>]/<project_full_path>`. Par exemple : `registry.gitlab.example.com/my_group/my_project`. Les noms d'image doivent respecter la [convention de nommage du registre de conteneurs](../../user/packages/container_registry/_index.md#naming-convention-for-your-container-images). Disponible uniquement si le registre de conteneurs est activé pour le projet. |
| `CI_REGISTRY_PASSWORD`                          | Job uniquement     | Le mot de passe pour pousser des conteneurs vers le registre de conteneurs du projet GitLab. Disponible uniquement si le registre de conteneurs est activé pour le projet. La valeur de ce mot de passe est identique à `CI_JOB_TOKEN` et n'est valide que pendant la durée d'exécution du job. Utilisez `CI_DEPLOY_PASSWORD` pour un accès durable au registre |
| `CI_REGISTRY_USER`                              | Job uniquement     | Le nom d'utilisateur pour pousser des conteneurs vers le registre de conteneurs GitLab du projet. Disponible uniquement si le registre de conteneurs est activé pour le projet. |
| `CI_RELEASE_DESCRIPTION`                        | Pipeline     | La description de la release. Disponible uniquement dans les pipelines pour les tags. La longueur de la description est limitée aux 1024 premiers caractères. |
| `CI_REPOSITORY_URL`                             | Job uniquement     | Le chemin complet pour cloner (HTTP) le dépôt avec un [token de job CI/CD](../jobs/ci_job_token.md), au format `https://gitlab-ci-token:$CI_JOB_TOKEN@gitlab.example.com/my-group/my-project.git`. |
| `CI_RUNNER_DESCRIPTION`                         | Job uniquement     | La description du runner. |
| `CI_RUNNER_EXECUTABLE_ARCH`                     | Job uniquement     | Le système d'exploitation/l'architecture de l'exécutable GitLab Runner. Peut ne pas être identique à l'environnement de l'exécuteur. |
| `CI_RUNNER_ID`                                  | Job uniquement     | L'ID unique du runner utilisé. |
| `CI_RUNNER_REVISION`                            | Job uniquement     | La révision du runner exécutant le job. |
| `CI_RUNNER_SHORT_TOKEN`                         | Job uniquement     | L'ID unique du runner, utilisé pour authentifier les nouvelles demandes de job. Le token contient un préfixe et les 17 premiers caractères sont utilisés. |
| `CI_RUNNER_TAGS`                                | Job uniquement     | Un tableau JSON des tags du runner. Par exemple `["tag_1", "tag_2"]`. |
| `CI_RUNNER_VERSION`                             | Job uniquement     | La version de GitLab Runner exécutant le job. |
| `CI_SERVER_FQDN`                                | Pré-pipeline | Le nom de domaine complet (FQDN) de l'instance. Par exemple `gitlab.example.com:8080`. |
| `CI_SERVER_HOST`                                | Pré-pipeline | L'hôte de l'URL de l'instance GitLab, sans protocole ni port. Par exemple `gitlab.example.com`. |
| `CI_SERVER_NAME`                                | Pré-pipeline | Le nom du serveur CI/CD qui coordonne les jobs. |
| `CI_SERVER_PORT`                                | Pré-pipeline | Le port de l'URL de l'instance GitLab, sans hôte ni protocole. Par exemple `8080`. |
| `CI_SERVER_PROTOCOL`                            | Pré-pipeline | Le protocole de l'URL de l'instance GitLab, sans hôte ni port. Par exemple `https`. |
| `CI_SERVER_SHELL_SSH_HOST`                      | Pré-pipeline | L'hôte SSH de l'instance GitLab, utilisé pour accéder aux dépôts Git via SSH. Par exemple `gitlab.com`. |
| `CI_SERVER_SHELL_SSH_PORT`                      | Pré-pipeline | Le port SSH de l'instance GitLab, utilisé pour accéder aux dépôts Git via SSH. Par exemple `22`. |
| `CI_SERVER_REVISION`                            | Pré-pipeline | La révision GitLab qui planifie les jobs. |
| `CI_SERVER_TLS_CA_FILE`                         | Pipeline     | Fichier contenant le certificat CA TLS pour vérifier le serveur GitLab lorsque `tls-ca-file` est défini dans les [paramètres du runner](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section). |
| `CI_SERVER_TLS_CERT_FILE`                       | Pipeline     | Fichier contenant le certificat TLS pour vérifier le serveur GitLab lorsque `tls-cert-file` est défini dans les [paramètres du runner](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section). |
| `CI_SERVER_TLS_KEY_FILE`                        | Pipeline     | Fichier contenant la clé TLS pour vérifier le serveur GitLab lorsque `tls-key-file` est défini dans les [paramètres du runner](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section). |
| `CI_SERVER_URL`                                 | Pré-pipeline | L'URL de base de l'instance GitLab, incluant le protocole et le port. Par exemple `https://gitlab.example.com:8080`. |
| `CI_SERVER_VERSION_MAJOR`                       | Pré-pipeline | La version majeure de l'instance GitLab. Par exemple, si la version de GitLab est `17.2.1`, le `CI_SERVER_VERSION_MAJOR` est `17`. |
| `CI_SERVER_VERSION_MINOR`                       | Pré-pipeline | La version mineure de l'instance GitLab. Par exemple, si la version de GitLab est `17.2.1`, le `CI_SERVER_VERSION_MINOR` est `2`. |
| `CI_SERVER_VERSION_PATCH`                       | Pré-pipeline | La version de correctif de l'instance GitLab. Par exemple, si la version de GitLab est `17.2.1`, le `CI_SERVER_VERSION_PATCH` est `1`. |
| `CI_SERVER_VERSION`                             | Pré-pipeline | La version complète de l'instance GitLab. |
| `CI_SERVER`                                     | Job uniquement     | Disponible pour tous les jobs exécutés en CI/CD. `yes` lorsque disponible. |
| `CI_SHARED_ENVIRONMENT`                         | Pipeline     | Disponible uniquement si le job est exécuté dans un environnement partagé (quelque chose qui persiste entre les invocations CI/CD, comme l'exécuteur `shell` ou `ssh`). `true` lorsque disponible. |
| `CI_TEMPLATE_REGISTRY_HOST`                     | Pré-pipeline | L'hôte du registre utilisé par les templates CI/CD. Par défaut `registry.gitlab.com`. |
| `CI_TRIGGER_SHORT_TOKEN`                        | Job uniquement     | Les 4 premiers caractères du [token de déclenchement](../triggers/_index.md#create-a-pipeline-trigger-token) du job actuel. Disponible uniquement si le pipeline a été [déclenché avec un token de déclenchement](../triggers/_index.md). Par exemple, pour un token de déclenchement `glptt-1234567890abcdefghij`, `CI_TRIGGER_SHORT_TOKEN` serait `1234`. Introduit dans GitLab 17.0.  |
| `CI_UPSTREAM_JOB_ID`                            | Pré-pipeline | ID du job de déclenchement upstream qui a déclenché le pipeline actuel dans un pipeline multi-projets ou parent-enfant. Introduit dans GitLab 18.9. |
| `CI_UPSTREAM_PIPELINE_ID`                       | Pré-pipeline | ID du pipeline upstream qui a déclenché le pipeline actuel dans un pipeline multi-projets ou parent-enfant. Introduit dans GitLab 18.9. |
| `CI_UPSTREAM_PROJECT_ID`                        | Pré-pipeline | ID du projet upstream qui a déclenché le pipeline actuel dans un pipeline multi-projets ou parent-enfant. Introduit dans GitLab 18.9. |
| `GITLAB_CI`                                     | Pré-pipeline | Disponible pour tous les jobs exécutés en CI/CD. `true` lorsque disponible. |
| `GITLAB_FEATURES`                               | Pré-pipeline | La liste séparée par des virgules des fonctionnalités sous licence disponibles pour l'instance GitLab et la licence. |
| `GITLAB_USER_EMAIL`                             | Pipeline     | L'e-mail de l'utilisateur qui a démarré le pipeline, sauf si le job est un job manuel. Dans les jobs manuels, la valeur est l'e-mail de l'utilisateur qui a démarré le job. |
| `GITLAB_USER_ID`                                | Pipeline     | L'ID numérique de l'utilisateur qui a démarré le pipeline, sauf si le job est un job manuel. Dans les jobs manuels, la valeur est l'ID de l'utilisateur qui a démarré le job. |
| `GITLAB_USER_LOGIN`                             | Pipeline     | Le nom d'utilisateur unique de l'utilisateur qui a démarré le pipeline, sauf si le job est un job manuel. Dans les jobs manuels, la valeur est le nom d'utilisateur de l'utilisateur qui a démarré le job. |
| `GITLAB_USER_NAME`                              | Pipeline     | Le nom d'affichage (le **Nom complet** défini par l'utilisateur dans les paramètres du profil) de l'utilisateur qui a démarré le pipeline, sauf si le job est un job manuel. Dans les jobs manuels, la valeur est le nom de l'utilisateur qui a démarré le job. |
| `KUBECONFIG`                                    | Pipeline     | Le chemin vers le fichier `kubeconfig` avec les contextes pour chaque connexion d'agent partagé. Disponible uniquement lorsqu'un [agent GitLab pour Kubernetes est autorisé à accéder au projet](../../user/clusters/agent/ci_cd_workflow.md#authorize-agent-access). |
| `TRIGGER_PAYLOAD`                               | Pipeline     | La charge utile du webhook. Disponible uniquement lorsqu'un pipeline est [déclenché avec un webhook](../triggers/_index.md#access-webhook-payload). |

## Variables prédéfinies pour les pipelines de merge request {#predefined-variables-for-merge-request-pipelines}

Ces variables sont disponibles avant que GitLab crée le pipeline (pré-pipeline). Ces variables peuvent être utilisées avec [`include:rules`](../yaml/includes.md#use-rules-with-include) et comme variables d'environnement dans les jobs.

Le pipeline doit être un [pipeline de merge request](../pipelines/merge_request_pipelines.md) et la merge request doit être ouverte.

| Variable                                    | Description |
|---------------------------------------------|-------------|
| `CI_MERGE_REQUEST_APPROVED`                 | Statut d'approbation de la merge request. `true` lorsque les [approbations de merge request](../../user/project/merge_requests/approvals/_index.md) sont disponibles et que la merge request a été approuvée. |
| `CI_MERGE_REQUEST_ASSIGNEES`                | Liste séparée par des virgules des noms d'utilisateur des personnes assignées à la merge request. Disponible uniquement si la merge request a au moins une personne assignée. |
| `CI_MERGE_REQUEST_DIFF_BASE_SHA`            | Le SHA de base du diff de la merge request. |
| `CI_MERGE_REQUEST_DIFF_ID`                  | La version du diff de la merge request. |
| `CI_MERGE_REQUEST_EVENT_TYPE`               | Le type d'événement de la merge request. Peut être `detached`, `merged_result` ou `merge_train`. |
| `CI_MERGE_REQUEST_DESCRIPTION`              | La description de la merge request. Si la description dépasse 2700 caractères, seuls les 2700 premiers caractères sont stockés dans la variable. |
| `CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED` | `true` si `CI_MERGE_REQUEST_DESCRIPTION` est tronqué à 2700 caractères parce que la description de la merge request est trop longue, sinon `false`. |
| `CI_MERGE_REQUEST_ID`                       | L'ID au niveau de l'instance de la merge request. L'ID est unique parmi tous les projets de l'instance GitLab. |
| `CI_MERGE_REQUEST_IID`                      | L'IID (ID interne) au niveau du projet de la merge request. Cet ID est unique pour le projet actuel et correspond au numéro utilisé dans l'URL, le titre de la page et d'autres emplacements visibles de la merge request. |
| `CI_MERGE_REQUEST_LABELS`                   | Noms de label séparés par des virgules de la merge request. Disponible uniquement si la merge request a au moins un label. |
| `CI_MERGE_REQUEST_MILESTONE`                | Le titre du jalon de la merge request. Disponible uniquement si un jalon est défini pour la merge request. |
| `CI_MERGE_REQUEST_PROJECT_ID`               | L'ID du projet de la merge request. |
| `CI_MERGE_REQUEST_PROJECT_PATH`             | Le chemin du projet de la merge request. Par exemple `namespace/awesome-project`. |
| `CI_MERGE_REQUEST_PROJECT_URL`              | L'URL du projet de la merge request. Par exemple, `http://192.168.10.15:3000/namespace/awesome-project`. |
| `CI_MERGE_REQUEST_REF_PATH`                 | Le chemin de référence de la merge request. Par exemple, `refs/merge-requests/1/head`. |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_NAME`       | Le nom de la branche source de la merge request. |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_PROTECTED`  | `true` lorsque la branche source de la merge request est [protégée](../../user/project/repository/branches/protected.md). |
| `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA`        | Le SHA HEAD de la branche source de la merge request. La variable est vide dans les pipelines de merge request. Le SHA est présent uniquement dans les [pipelines de résultats fusionnés](../pipelines/merged_results_pipelines.md). |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_ID`        | L'ID du projet source de la merge request. |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_PATH`      | Le chemin du projet source de la merge request. |
| `CI_MERGE_REQUEST_SOURCE_PROJECT_URL`       | L'URL du projet source de la merge request. |
| `CI_MERGE_REQUEST_SQUASH_ON_MERGE`          | `true` lorsque l'option [squash lors de la fusion](../../user/project/merge_requests/squash_and_merge.md) est définie. |
| `CI_MERGE_REQUEST_TARGET_BRANCH_NAME`       | Le nom de la branche cible de la merge request. |
| `CI_MERGE_REQUEST_TARGET_BRANCH_PROTECTED`  | `true` lorsque la branche cible de la merge request est [protégée](../../user/project/repository/branches/protected.md). |
| `CI_MERGE_REQUEST_TARGET_BRANCH_SHA`        | Le SHA HEAD de la branche cible de la merge request. La variable est vide dans les pipelines de merge request. Le SHA est présent uniquement dans les [pipelines de résultats fusionnés](../pipelines/merged_results_pipelines.md). |
| `CI_MERGE_REQUEST_TITLE`                    | Le titre de la merge request. |
| `CI_MERGE_REQUEST_DRAFT`                    | `true` si la merge request est un brouillon. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/275981) dans GitLab 17.10. |

## Variables prédéfinies pour les pipelines de pull request externes {#predefined-variables-for-external-pull-request-pipelines}

Ces variables sont disponibles uniquement lorsque :

- Les pipelines sont des [pipelines de pull request externes](../ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests)
- La pull request est ouverte.

| Variable                                      | Description |
|-----------------------------------------------|-------------|
| `CI_EXTERNAL_PULL_REQUEST_IID`                | ID de la pull request depuis GitHub. |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_REPOSITORY`  | Le nom du dépôt source de la pull request. |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_REPOSITORY`  | Le nom du dépôt cible de la pull request. |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_NAME` | Le nom de la branche source de la pull request. |
| `CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_SHA`  | Le SHA HEAD de la branche source de la pull request. |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_NAME` | Le nom de la branche cible de la pull request. |
| `CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_SHA`  | Le SHA HEAD de la branche cible de la pull request. |

## Variables de déploiement {#deployment-variables}

Les intégrations responsables de la configuration du déploiement peuvent définir leurs propres variables prédéfinies définies dans l'environnement de build. Ces variables sont uniquement définies pour les [jobs de déploiement](../environments/_index.md).

Par exemple, l'[intégration Kubernetes](../../user/project/clusters/deploy_to_cluster.md#deployment-variables) définit des variables de déploiement que vous pouvez utiliser avec l'intégration.

La [documentation de chaque intégration](../../user/project/integrations/_index.md) indique si l'intégration dispose de variables de déploiement.

## Variables Auto DevOps {#auto-devops-variables}

Lorsque [Auto DevOps](../../topics/autodevops/_index.md) est activé, des [variables pré-pipeline](#variable-availability) supplémentaires sont mises à disposition :

- `AUTO_DEVOPS_EXPLICITLY_ENABLED` :  A une valeur de `1` pour indiquer qu'Auto DevOps est activé.
- `STAGING_ENABLED` :  Voir [stratégie de déploiement Auto DevOps](../../topics/autodevops/requirements.md#auto-devops-deployment-strategy).
- `INCREMENTAL_ROLLOUT_MODE` :  Voir [stratégie de déploiement Auto DevOps](../../topics/autodevops/requirements.md#auto-devops-deployment-strategy).
- `INCREMENTAL_ROLLOUT_ENABLED` :  Déprécié.

## Variables d'intégration {#integration-variables}

Certaines intégrations rendent des variables disponibles dans les jobs. Ces variables sont disponibles en tant que [variables prédéfinies réservées aux jobs](#variable-availability) :

- [Harbor](../../user/project/integrations/harbor.md) :
  - `HARBOR_URL`
  - `HARBOR_HOST`
  - `HARBOR_OCI`
  - `HARBOR_PROJECT`
  - `HARBOR_USERNAME`
  - `HARBOR_PASSWORD`
- [Apple App Store Connect](../../user/project/integrations/apple_app_store.md) :
  - `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
  - `APP_STORE_CONNECT_API_KEY_KEY_ID`
  - `APP_STORE_CONNECT_API_KEY_KEY`
  - `APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64`
- [Google Play](../../user/project/integrations/google_play.md) :
  - `SUPPLY_PACKAGE_NAME`
  - `SUPPLY_JSON_KEY_DATA`
- [Diffblue Cover](../../integration/diffblue_cover.md) :
  - `DIFFBLUE_LICENSE_KEY`
  - `DIFFBLUE_ACCESS_TOKEN_NAME`
  - `DIFFBLUE_ACCESS_TOKEN`

## Dépannage {#troubleshooting}

Vous pouvez [afficher les valeurs de toutes les variables disponibles pour un job](variables_troubleshooting.md#list-all-variables) avec une commande `script`.

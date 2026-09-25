---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez quelles variables prédéfinies, d'environnement et de jeton ID sont disponibles dans les jobs qui exécutent les flows, et lesquelles ne le sont pas."
title: "Variables d'exécution de flow"
---

{{< details >}}

- Édition : [Gratuite](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Toutes les variables ne sont pas disponibles dans les jobs qui exécutent les flows.

- Certaines variables prédéfinies et spécifiques à l'Agent Platform sont disponibles.
- Les variables prédéfinies filtrées, les variables CI/CD personnalisées et les variables d'identité utilisateur ne sont pas disponibles.

## Variables disponibles {#available-variables}

Les variables suivantes sont disponibles dans les jobs qui exécutent vos flows.

### Variables prédéfinies {#predefined-variables}

Les variables CI/CD prédéfinies suivantes sont disponibles :

| Variable | Description |
|----------|-------------|
| `CI_PROJECT_ID` | ID du projet. |
| `CI_PROJECT_NAME` | Nom du projet. |
| `CI_PROJECT_PATH` | Chemin du projet avec l'espace de nommage. |
| `CI_PROJECT_URL` | URL HTTP du projet. |
| `CI_PROJECT_NAMESPACE` | Espace de nommage du projet. |
| `CI_PROJECT_VISIBILITY` | Visibilité du projet (`public`, `internal` ou `private`). |
| `CI_DEFAULT_BRANCH` | Nom de la branche par défaut. |
| `CI_JOB_ID` | ID du job. |
| `CI_JOB_URL` | URL du job. |
| `CI_JOB_TOKEN` | Jeton d'authentification du job. |
| `CI_JOB_IMAGE` | Image Docker utilisée pour le job. |
| `CI_JOB_STATUS` | Statut du job. |
| `CI_JOB_TIMEOUT` | Délai d'expiration du job en secondes. |
| `CI_JOB_STARTED_AT` | Horodatage de début du job au format ISO 8601. |
| `CI_PIPELINE_ID` | ID du pipeline. |
| `CI_PIPELINE_URL` | URL du pipeline. |
| `CI_REGISTRY_USER` | Nom d'utilisateur du registre de conteneurs (`gitlab-ci-token`). |
| `CI_REGISTRY_PASSWORD` | Mot de passe du registre de conteneurs (jeton de job). |
| `CI_DEPENDENCY_PROXY_USER` | Nom d'utilisateur du proxy de dépendances. |
| `CI_DEPENDENCY_PROXY_PASSWORD` | Mot de passe du proxy de dépendances. |
| `CI_REPOSITORY_URL` | URL de clonage Git avec les identifiants intégrés. |
| `CI_RUNNER_VERSION` | Version du runner. |
| `CI_RUNNER_EXECUTABLE_ARCH` | Architecture du runner (par exemple, `linux/amd64`). |
| `CI_SERVER` | Toujours `yes` dans les environnements CI/CD. |
| `CI_WORKLOAD_REF` | Référence de charge de travail pour l'exécution du flow (par exemple, `refs/workloads/c727f70ba7f`). Il s'agit de références Git internes, automatiquement supprimées lorsque le job du pipeline se termine ou échoue.|

### Variables d'environnement {#environment-variables}

Les variables d'environnement suivantes sont spécifiques à l'Agent Platform. Ces variables sont disponibles dans `setup_script` et dans le runtime principal de l'agent.

Ce tableau documente les variables clés. Des variables internes supplémentaires (par exemple, des indicateurs de débogage et des identifiants de télémétrie) peuvent également être présentes dans le conteneur d'exécution, mais ne sont pas destinées à être utilisées dans la configuration du flow.

| Variable | Description | Exemple |
|----------|-------------|---------|
| `DUO_WORKFLOW_GIT_HTTP_BASE_URL` | URL de base de l'instance GitLab. Utilisez cette variable plutôt que `CI_SERVER_URL`. | `https://gitlab.com` |
| `DUO_WORKFLOW_PROJECT_ID` | ID du projet. Même valeur que `CI_PROJECT_ID`. | `77056053` |
| `DUO_WORKFLOW_NAMESPACE_ID` | ID de l'espace de nommage. | `91555435` |
| `DUO_WORKFLOW_GOAL` | URL du ticket qui a déclenché le flow. | `https://gitlab.com/group/project/-/issues/10` |
| `DUO_WORKFLOW_DEFINITION` | Identifiant de définition du flow. | `developer/v1` |
| `DUO_WORKFLOW_SERVICE_REALM` | Type de déploiement. | `saas` ou `self-managed` |
| `DUO_WORKFLOW_GIT_HTTP_USER` | Nom d'utilisateur Git HTTP pour le clonage. | `oauth` |
| `DUO_WORKFLOW_GIT_HTTP_PASSWORD` | Mot de passe Git HTTP pour le clonage. | *(Jeton OAuth)* |
| `DUO_WORKFLOW_GIT_USER_NAME` | Nom de l'utilisateur qui a déclenché le flow. Utilisé comme committer Git. | `Jane Developer` |
| `DUO_WORKFLOW_GIT_USER_EMAIL` | Adresse e-mail de l'utilisateur qui a déclenché le flow. Utilisée comme adresse e-mail du committer Git. | `jdeveloper@example.com` |
| `DUO_WORKFLOW_GIT_AUTHOR_EMAIL` | Adresse e-mail du compte de service. Utilisée comme adresse e-mail de l'auteur Git. | `service_account_group_<ID>@noreply.gitlab.com` |
| `DUO_WORKFLOW_GIT_AUTHOR_USER_NAME` | Nom du compte de service. Utilisé comme nom de l'auteur Git. | `Duo Developer` |
| `GITLAB_BASE_URL` | URL de base de l'instance GitLab. Même valeur que `DUO_WORKFLOW_GIT_HTTP_BASE_URL`. | `https://gitlab.com` |
| `GITLAB_PROJECT_PATH` | Chemin complet du projet avec l'espace de nommage. Même valeur que `CI_PROJECT_PATH`. | `my-group/my-project` |
| `GITLAB_TOKEN` | Jeton OAuth pour l'accès à l'API GitLab. Même valeur que `DUO_WORKFLOW_GIT_HTTP_PASSWORD`. | *(Jeton OAuth)* |
| `AGENT_PLATFORM_GITLAB_VERSION` | Version de GitLab exécutant le flow. | `18.9.0` |

### Variables de jeton ID {#id-token-variables}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224940) dans GitLab 19.2.

{{< /history >}}

Les [jetons ID](../../../../ci/secrets/id_token_authentication.md) que vous déclarez sont disponibles en tant que variables d'environnement dans le job du flow. Chaque variable utilise le nom du jeton que vous déclarez.

Vous déclarez les jetons ID dans :

- Le fichier `agent-config.yml`, pour les flows qui utilisent CI/CD. Pour plus d'informations, consultez [configurer les jetons ID](_index.md#configure-id-tokens).
- La configuration d'un [agent externe personnalisé](../../agents/external.md#authenticate-with-id-tokens).

Par exemple, lorsque vous déclarez un bloc `id_tokens` avec un jeton `VAULT_ID_TOKEN`, le flow peut utiliser `$VAULT_ID_TOKEN`.

## Non disponible {#not-available}

Les variables suivantes ne sont pas disponibles dans les jobs qui exécutent vos flows.

### Variables prédéfinies filtrées {#filtered-predefined-variables}

Les variables CI/CD prédéfinies suivantes ne sont pas disponibles :

| Variable | Raison |
|----------|--------|
| `CI_REGISTRY` | Filtrée par le portail de variables de charge de travail. Utilisez plutôt un nom d'hôte de registre codé en dur. |
| `CI_REGISTRY_IMAGE` | Filtrée par le portail de variables de charge de travail. Utilisez plutôt un chemin d'image codé en dur. |
| `CI_SERVER_URL`, `CI_SERVER_HOST`, `CI_API_V4_URL` | Filtrée. Utilisez `GITLAB_BASE_URL` ou `DUO_WORKFLOW_GIT_HTTP_BASE_URL` à la place. |
| `CI_COMMIT_SHA`, `CI_COMMIT_BRANCH`, `CI_COMMIT_REF_NAME` | Le job ne dispose d'aucun contexte de commit. La branche source est gérée par l'agent GitLab Duo. |
| `GITLAB_USER_LOGIN`, `GITLAB_USER_EMAIL`, `GITLAB_USER_NAME` | Le job s'exécute en tant que compte de service, et non en tant qu'utilisateur déclencheur. |
| `CI_PIPELINE_SOURCE`, `CI_PIPELINE_IID` | Filtrée par le portail de variables de charge de travail. |

### Identité utilisateur {#user-identity}

Le jeton de job CI utilisé lors de l'exécution du flow est un jeton d'[identité composite](../../composite_identity.md) qui représente à la fois l'utilisateur déclencheur et le compte de service.

Les commits Git créés lors de l'exécution du flow sont validés par l'utilisateur qui a déclenché le flow, mais marqués comme ayant été créés par le compte de service.

Étant donné qu'un compte de service exécute le flow, et non un utilisateur, les variables `GITLAB_USER_LOGIN` et `GITLAB_USER_EMAIL` ne sont pas disponibles.

Toutefois, l'identité de l'utilisateur qui a déclenché le flow est disponible dans `DUO_WORKFLOW_GIT_USER_EMAIL` et `DUO_WORKFLOW_GIT_USER_NAME`, et l'identité du compte de service est disponible dans `DUO_WORKFLOW_GIT_AUTHOR_EMAIL` et `DUO_WORKFLOW_GIT_AUTHOR_USER_NAME`.

### Variables CI/CD personnalisées {#custom-cicd-variables}

Les variables CI/CD personnalisées définies dans **Paramètres** > **CI/CD** > **Variables** pour les projets, les groupes ou l'instance ne sont pas disponibles.

Les variables CI/CD personnalisées comprennent les variables protégées, les variables non protégées, les variables masquées et les variables de fichier.

Toute la configuration du flow doit être fournie dans `agent-config.yml` ou via les [variables d'environnement disponibles](#environment-variables).

## Accéder à l'URL de l'instance GitLab {#accessing-the-gitlab-instance-url}

La variable standard `CI_SERVER_URL` n'est pas disponible. Utilisez `GITLAB_BASE_URL` ou `DUO_WORKFLOW_GIT_HTTP_BASE_URL` à la place.

Par exemple, pour effectuer un appel API dans `setup_script` :

```yaml
setup_script:
  - "curl --silent --header 'JOB-TOKEN: ${CI_JOB_TOKEN}' ${GITLAB_BASE_URL}/api/v4/projects/${CI_PROJECT_ID}"
```

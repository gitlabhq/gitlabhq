---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage des jobs
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous travaillez avec des jobs, vous pouvez rencontrer les problèmes suivants.

## Les jobs ou les pipelines s'exécutent de manière inattendue lors de l'utilisation de `changes:` {#jobs-or-pipelines-run-unexpectedly-when-using-changes}

Il se peut que des jobs ou des pipelines s'exécutent de manière inattendue lors de l'utilisation de [`rules: changes`](../yaml/_index.md#ruleschanges) ou de [`only: changes`](../yaml/deprecated_keywords.md#onlychanges--exceptchanges) sans [pipelines de merge request](../pipelines/merge_request_pipelines.md).

Les pipelines sur des branches ou des tags qui n'ont pas d'association explicite avec une merge request utilisent un SHA précédent pour calculer la différence. Ce calcul est équivalent à `git diff HEAD~` et peut entraîner un comportement inattendu, notamment :

- La règle `changes` est toujours évaluée à true lors du push d'une nouvelle branche ou d'un nouveau tag vers GitLab.
- Lors du push d'un nouveau commit, les fichiers modifiés sont calculés en utilisant le commit précédent comme SHA de base.

De plus, les règles avec `changes` sont toujours évaluées à true dans les [pipelines planifiés](../pipelines/schedules.md). Tous les fichiers sont considérés comme ayant été modifiés lors de l'exécution d'un pipeline planifié, de sorte que des jobs peuvent toujours être ajoutés aux pipelines planifiés qui utilisent `changes`.

## Chemins de fichiers dans les variables CI/CD {#file-paths-in-cicd-variables}

Soyez prudent lorsque vous utilisez des chemins de fichiers dans les variables CI/CD. Un slash de fin peut sembler correct dans la définition de la variable, mais peut devenir invalide lorsqu'il est développé dans `script:`, `changes:`, ou d'autres mots-clés. Par exemple :

```yaml
docker_build:
  variables:
    DOCKERFILES_DIR: 'path/to/files/'  # This variable should not have a trailing '/' character
  script: echo "A docker job"
  rules:
    - changes:
        - $DOCKERFILES_DIR/*
```

Lorsque la variable `DOCKERFILES_DIR` est développée dans la section `changes:`, le chemin complet devient `path/to/files//*`. Les doubles slashes peuvent entraîner un comportement inattendu selon des facteurs tels que le mot-clé utilisé, ou le shell et le système d'exploitation du runner.

## Message d'erreur `You are not allowed to download code from this project.` {#you-are-not-allowed-to-download-code-from-this-project-error-message}

Il se peut que des pipelines échouent lorsqu'un administrateur GitLab exécute un job manuel protégé dans un projet privé.

Les jobs CI/CD clonent généralement le projet au démarrage du job, et cela utilise [les permissions](../../user/permissions.md#project-cicd) de l'utilisateur qui exécute le job. Tous les utilisateurs, y compris les administrateurs, doivent être membres directs d'un projet privé pour cloner la source de ce projet. [Un ticket existe](https://gitlab.com/gitlab-org/gitlab/-/issues/23130) pour modifier ce comportement.

Pour exécuter des jobs manuels protégés :

- Ajoutez l'administrateur en tant que membre direct du projet privé (n'importe quel rôle).
- [Usurpez l'identité d'un utilisateur](../../administration/admin_area.md#user-impersonation) qui est membre direct du projet.

## Un job CI/CD n'utilise pas la configuration la plus récente lors d'une nouvelle exécution {#a-cicd-job-does-not-use-newer-configuration-when-run-again}

La configuration d'un pipeline n'est récupérée qu'au moment de la création du pipeline. Lorsque vous réexécutez un job, la même configuration est utilisée à chaque fois. Si vous mettez à jour des fichiers de configuration, y compris des fichiers distincts ajoutés avec [`include`](../yaml/_index.md#include), vous devez démarrer un nouveau pipeline pour utiliser la nouvelle configuration.

## Avertissement `Job may allow multiple pipelines to run for a single action` {#job-may-allow-multiple-pipelines-to-run-for-a-single-action-warning}

Lorsque vous utilisez [`rules`](../yaml/_index.md#rules) avec une clause `when` sans clause `if`, plusieurs pipelines peuvent s'exécuter. Cela se produit généralement lorsque vous faites un push d'un commit vers une branche associée à une merge request ouverte.

Pour [éviter les pipelines en double](job_rules.md#avoid-duplicate-pipelines), utilisez [`workflow: rules`](../yaml/_index.md#workflow) ou réécrivez vos règles pour contrôler quels pipelines peuvent s'exécuter.

## `This GitLab CI configuration is invalid` pour les expressions de variables {#this-gitlab-ci-configuration-is-invalid-for-variable-expressions}

Vous pouvez recevoir l'une des erreurs `This GitLab CI configuration is invalid` lors de l'utilisation des [expressions de variables CI/CD](job_rules.md#cicd-variable-expressions). Ces erreurs de syntaxe peuvent être causées par une utilisation incorrecte des caractères de guillemets.

Dans les expressions de variables, les chaînes de caractères doivent être entre guillemets, tandis que les variables ne doivent pas l'être. Par exemple :

```yaml
variables:
  ENVIRONMENT: production

job:
  script: echo
  rules:
    - if: $ENVIRONMENT == "production"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

Dans cet exemple, les deux clauses `if:` sont valides parce que la chaîne `production` est entre guillemets et que les variables CI/CD ne le sont pas.

En revanche, ces clauses `if:` sont toutes invalides :

```yaml
variables:
  ENVIRONMENT: production

job:
  script: echo
  rules:       # These rules all cause YAML syntax errors:
    - if: ${ENVIRONMENT} == "production"
    - if: "$ENVIRONMENT" == "production"
    - if: $ENVIRONMENT == production
    - if: "production" == "production"
```

Dans cet exemple :

- `if: ${ENVIRONMENT} == "production"` est invalide, car `${ENVIRONMENT}` n'est pas un formatage valide pour les variables CI/CD dans `if:`.
- `if: "$ENVIRONMENT" == "production"` est invalide, car la variable est entre guillemets.
- `if: $ENVIRONMENT == production` est invalide, car la chaîne de caractères n'est pas entre guillemets.
- `if: "production" == "production"` est invalide, car il n'y a pas de variable CI/CD à comparer.

## La section de job `get_sources` échoue en raison d'un problème HTTP/2 {#get_sources-job-section-fails-because-of-an-http2-problem}

Parfois, des jobs échouent avec l'erreur cURL suivante :

```plaintext
++ git -c 'http.userAgent=gitlab-runner <version>' fetch origin +refs/pipelines/<id>:refs/pipelines/<id> ...
error: RPC failed; curl 16 HTTP/2 send again with decreased length
fatal: ...
```

Vous pouvez contourner ce problème en configurant Git et `libcurl` pour [utiliser HTTP/1.1](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpversion). La configuration peut être ajoutée à :

- Le [`pre_get_sources_script`](../yaml/_index.md#hookspre_get_sources_script) d'un job :

  ```yaml
  job_name:
    hooks:
      pre_get_sources_script:
        - git config --global http.version "HTTP/1.1"
  ```

- Le [`config.toml` du runner](https://docs.gitlab.com/runner/configuration/advanced-configuration/) avec les [variables d'environnement de configuration Git](https://git-scm.com/docs/git-config#ENVIRONMENT) :

  ```toml
  [[runners]]
  ...
  environment = [
    "GIT_CONFIG_COUNT=1",
    "GIT_CONFIG_KEY_0=http.version",
    "GIT_CONFIG_VALUE_0=HTTP/1.1"
  ]
  ```

## Le job utilisant `resource_group` est bloqué {#job-using-resource_group-gets-stuck}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Si un job utilisant [`resource_group`](../yaml/_index.md#resource_group) est bloqué, un administrateur GitLab peut essayer d'exécuter les commandes suivantes depuis la [console Rails](../../administration/operations/rails_console.md#starting-a-rails-console-session) :

```ruby
# find resource group by name
resource_group = Project.find_by_full_path('...').resource_groups.find_by(key: 'the-group-name')
busy_resources = resource_group.resources.where('build_id IS NOT NULL')

# identify which builds are occupying the resource
# (I think it should be 1 as of today)
busy_resources.pluck(:build_id)

# it's good to check why this build is holding the resource.
# Is it stuck? Has it been forcefully dropped by the system?
# free up busy resources
busy_resources.update_all(build_id: nil)
```

## Erreur : `data integrity failure` {#error-data-integrity-failure}

Vous pouvez voir une erreur `data integrity failure` lors du traitement d'un job. Cela peut se produire sur n'importe quel type de job, y compris les jobs de déclenchement pour les [pipelines downstream](../pipelines/downstream_pipelines.md), les jobs en attente d'attribution d'un runner et les jobs bloqués lors du nettoyage.

Consultez vos journaux PostgreSQL et Sidekiq pour identifier la cause sous-jacente. Les causes courantes sur les instances GitLab Self-Managed incluent :

Corruption de séquence de base de données après une mise à niveau : Les journaux PostgreSQL contiennent des erreurs `PG::UniqueViolation`. Vérifiez que les fonctions de déclenchement de la base de données concernées référencent les séquences correctes.

Processus Sidekiq obsolètes après une mise à niveau : Les échecs sont intermittents et la réexécution du job réussit. Vérifiez que tous les nœuds Sidekiq exécutent la version GitLab attendue et redémarrez ceux qui ne le font pas.

SQL ambigu ou invalide suite à des modifications de schéma : Les journaux PostgreSQL contiennent des erreurs SQL provenant de requêtes exécutées lors du traitement du job. Vérifiez si les modifications récentes du schéma ont affecté les requêtes qui s'exécutent pour ce type de job.

Si l'erreur persiste, inspectez le job dans la [console Rails](../../administration/operations/rails_console.md) pour déterminer le `failure_reason` et si un pipeline downstream a été créé.

## Message `You are not authorized to run this manual job` {#you-are-not-authorized-to-run-this-manual-job-message}

Vous pouvez recevoir ce message et avoir le bouton **Exécution** désactivé lorsque vous tentez d'exécuter un job manuel si :

- L'environnement cible est un [environnement protégé](../environments/protected_environments.md) et votre compte n'est pas inclus dans la liste **Autorisés à déployer**.
- Le paramètre permettant d'[éviter les déploiements obsolètes](../environments/deployment_safety.md#prevent-outdated-deployment-jobs) est activé et l'exécution du job écraserait le dernier déploiement.

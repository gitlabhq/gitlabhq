---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Entrées de job
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/17833) dans GitLab 18.10.
- Nécessite GitLab Runner 18.9 ou une version ultérieure.

{{< /history >}}

Utilisez les entrées de job pour définir des paramètres typés et validés pour des jobs CI/CD individuels, qui peuvent être remplacés lors de l'exécution manuelle ou de la reprise des jobs. Contrairement aux [variables CI/CD](../variables/_index.md), les entrées de job offrent :

- Sécurité des types : Les entrées peuvent être `string`, `number`, `boolean` ou `array` avec validation automatique.
- Contrat explicite : Les jobs n'acceptent que les entrées que vous définissez. Les entrées inattendues sont rejetées.
- Capacité de remplacement : Les valeurs d'entrée peuvent être définies lors de l'[exécution](#run-a-manual-job-with-input-values) d'un job et modifiées lors de la [reprise](#retry-a-job-with-different-input-values) du job.

Utilisez les entrées de job pour les paramètres qui contrôlent le comportement du job et qui pourraient nécessiter des ajustements lors de la réexécution d'un job. Par exemple : les cibles de déploiement, les configurations de test ou les feature flags.

Les entrées de job ont une portée limitée au job où elles sont définies et ne sont pas accessibles dans les fichiers inclus ni dans d'autres jobs. Si vous avez besoin de partager une configuration entre des jobs ou des fichiers, utilisez plutôt les [entrées de configuration CI/CD](../inputs/_index.md).

## Comparaison des entrées de job {#job-input-comparison}

### Comparaison avec les entrées de configuration de pipeline CI/CD {#compared-to-cicd-pipeline-configuration-inputs}

Les entrées de job et les [entrées de configuration de pipeline CI/CD](../inputs/_index.md) servent des objectifs différents :

| Fonctionnalité        | Entrées de job                                                              | Entrées de configuration CI/CD |
|----------------|-------------------------------------------------------------------------|---------------------|
| Objectif        | Configurer le comportement d'un job individuel                                       | Configurer des modèles et des composants réutilisables |
| Syntaxe         | `inputs:` dans la définition du job                                             | `spec:inputs:` dans l'en-tête de configuration |
| Interpolation  | `${{ job.inputs.INPUT_NAME }}`                                          | `$[[ inputs.INPUT_NAME ]]` |
| Évaluation     | Valeurs définies lors de la création du job, peuvent être remplacées lors de l'exécution/reprise | Valeurs définies lors de la création du pipeline, fixes pour l'ensemble du pipeline |
| Valeurs par défaut | Obligatoire                                                                | Facultatif |
| Portée          | Un seul job uniquement                                                         | Fichier de configuration entier ou transmis aux fichiers inclus |

### Comparaison avec les variables d'environnement {#compared-to-environment-variables}

Les entrées de job sont interpolées dans la configuration du job lors de sa création. Elles ne sont pas des variables d'environnement et ne sont pas accessibles avec la syntaxe `$INPUT_NAME`. Vous pouvez utiliser les entrées de job directement dans les scripts et d'autres mots-clés pris en charge avec la syntaxe `${{ job.inputs.INPUT_NAME }}`.

## Définir et utiliser les entrées de job {#define-and-use-job-inputs}

Utilisez le mot-clé `inputs` dans un job pour définir des paramètres d'entrée. Chaque entrée doit avoir une valeur par défaut. Référencez les valeurs d'entrée avec la syntaxe d'[expression Moa](../functions/moa.md) `${{ job.inputs.INPUT_NAME }}`.

Par exemple :

```yaml
deploy_job:
  inputs:
    target_env:
      default: staging
      options: [staging, production]
    replicas:
      type: number
      default: 3
    debug_mode:
      type: boolean
      default: false
  script:
    - 'echo "Deploying to ${{ job.inputs.target_env }}"'
    - 'echo "Replicas - ${{ job.inputs.replicas }}"'
    - 'if [ "${{ job.inputs.debug_mode }}" == "true" ]; then set -x; fi'
    - ./deploy.sh
```

### Configuration des entrées {#input-configuration}

Configurez les entrées avec ces mots-clés :

- `default` :  La valeur par défaut utilisée lors de l'exécution du job. Toutes les entrées de job doivent avoir des valeurs par défaut.
- `type` :  facultatif. Le type d'entrée. Peut être `string` (par défaut), `number`, `boolean` ou `array`.
- `description` :  facultatif. Une description lisible par l'humain de l'objectif de l'entrée.
- `options` :  facultatif. Une liste de valeurs autorisées. L'entrée doit correspondre à l'une de ces valeurs.
- `regex` :  facultatif. Un modèle d'expression régulière auquel l'entrée doit correspondre.

Par exemple :

```yaml
test_job:
  inputs:
    test_framework:
      default: rspec
      description: Testing framework to use
      options: [rspec, minitest, cucumber]
    parallel_count:
      type: number
      default: 5
      description: Number of parallel test jobs
    run_integration_tests:
      type: boolean
      default: false
      description: Whether to run integration tests
    test_tags:
      type: array
      default: [smoke, regression]
      description: Test tags to run
  script:
    - bundle exec ${{ job.inputs.test_framework }}
    - 'echo "Running ${{ job.inputs.parallel_count }} parallel jobs"'
```

Les entrées de job sont validées lors de la création du job et lors du remplacement des valeurs d'entrée. Si la validation échoue, le job ne démarre pas et affiche un message d'erreur clair.

### Types d'entrée {#input-types}

Les entrées de job prennent en charge ces types :

- `string` (par défaut) : Valeurs textuelles, par exemple `"staging"` ou `"v1.2.3"`.
- `number` :  Valeurs numériques, par exemple `5`, `3.14` ou `-10`.
- `boolean` :  Valeurs booléennes, soit `true` soit `false`.
- `array` :  Liste de valeurs, par exemple `[1, 2, 3]` ou `["a", "b"]`.

Lors de la transmission de valeurs d'entrée via l'API ou l'interface utilisateur, les tableaux doivent être au format JSON, par exemple : `["value1", "value2"]`.

### Où utiliser les entrées de job {#where-you-can-use-job-inputs}

Vous pouvez utiliser une interpolation simple ou des expressions plus complexes avec des opérateurs et des fonctions. Consultez [le langage d'expression Moa](../functions/moa.md) pour la syntaxe complète.

Les entrées de job peuvent être utilisées dans ces mots-clés de job et leurs sous-clés :

- `script`, `before_script` et `after_script`
- `artifacts`
- `cache`
- `image`
- `services`

### Limitations {#limitations}

Les entrées de job utilisent la syntaxe `${{ job.inputs.INPUT_NAME }}` qui est évaluée lors de l'exécution du job, et non lors de la création de la configuration du pipeline. Vous ne pouvez pas utiliser les entrées de job dans les parties de la configuration qui doivent être évaluées lors de la création du pipeline, telles que :

- Noms de job
- Mot-clé `stage`
- Mot-clé `rules`
- Mot-clé `include`
- Autres mots-clés au niveau du job non répertoriés ci-dessus

Pour configurer ces parties de votre pipeline de manière dynamique, utilisez plutôt les [entrées de configuration de pipeline CI/CD](../inputs/_index.md) avec la syntaxe `$[[ inputs.* ]]`.

## Fournir des valeurs d'entrée {#provide-input-values}

Vous pouvez fournir des valeurs d'entrée de job dans les cas suivants :

- Exécution d'un job manuel.
- Reprise d'un job après son achèvement.

### Exécuter un job manuel avec des valeurs d'entrée {#run-a-manual-job-with-input-values}

Lorsque vous exécutez un job manuel dont des entrées sont définies, vous pouvez spécifier les valeurs d'entrée.

Pour exécuter un job manuel avec des entrées spécifiques :

1. Accédez à la vue du pipeline, du job ou de l'[environnement](../environments/deployments.md#configure-manual-deployments).
1. Sélectionnez le nom du job manuel, et non **Exécution** ({{< icon name="play" >}}).
1. Dans le formulaire, spécifiez les valeurs d'entrée.
1. Sélectionnez **Exécuter le job**.

### Réessayer un job avec d'autres valeurs d'entrée {#retry-a-job-with-different-input-values}

Lorsque vous réessayez un job dont des entrées sont définies, vous pouvez mettre à jour les valeurs d'entrée.

Pour réessayer un job avec d'autres entrées :

1. Accédez à la page des détails du job.
1. Sélectionnez **Essayer à nouveau ce job avec d'autres valeurs** ({{< icon name="chevron-down" >}}).
1. Dans le formulaire, les entrées sont préremplies avec les valeurs de l'exécution précédente. Modifiez les valeurs d'entrée selon vos besoins.
1. Sélectionnez **Exécuter de nouveau le job**.

Pour réessayer avec les mêmes valeurs d'entrée, sélectionnez plutôt **Réessayer** ({{< icon name="retry" >}}).

## Exemples d'entrées de job {#job-input-examples}

### Job de déploiement de base avec des entrées {#basic-deployment-job-with-inputs}

```yaml
deploy:
  when: manual
  inputs:
    target_env:
      default: staging
      description: Target deployment environment
      options: [staging, production]
    version:
      default: latest
      description: Application version to deploy
  script:
    - 'echo "Deploying version ${{ job.inputs.version }} to ${{ job.inputs.target_env }}"'
    - ./deploy.sh --env ${{ job.inputs.target_env }} --version ${{ job.inputs.version }}
```

### Job de test avec validation {#test-job-with-validation}

```yaml
integration_tests:
  inputs:
    test_suite:
      default: smoke
      description: Which test suite to run
      options: [smoke, regression, full]
    parallel_jobs:
      type: number
      default: 5
      description: Number of parallel test runners
    enable_debug:
      type: boolean
      default: false
      description: Enable debug logging
    tags:
      type: array
      default: ["critical"]
      description: Test tags to run
  script:
    - 'if [ "${{ job.inputs.enable_debug }}" == "true" ]; then export DEBUG=1; fi'
    - ./run_tests.sh
        --suite ${{ job.inputs.test_suite }}
        --parallel ${{ job.inputs.parallel_jobs }}
        --tags '${{ job.inputs.tags }}'
```

### Migration de base de données avec vérifications de sécurité {#database-migration-with-safety-checks}

```yaml
migrate_database:
  when: manual
  inputs:
    target_db:
      default: development
      description: Database environment
      options: [development, staging, production]
    migration_name:
      default: ""
      description: Specific migration to run (leave empty for all)
      regex: ^[a-zA-Z0-9_]*$
    dry_run:
      type: boolean
      default: true
      description: Run in dry-run mode without applying changes
  script:
    - 'echo "Running migrations on ${{ job.inputs.target_db }}"'
    - |
      if [ "${{ job.inputs.dry_run }}" == "true" ]; then
        echo "DRY RUN MODE - no changes will be applied"
        MIGRATION_FLAGS="--dry-run"
      fi
    - |
      if [ -n "${{ job.inputs.migration_name }}" ]; then
        ./migrate.sh $MIGRATION_FLAGS --migration ${{ job.inputs.migration_name }}
      else
        ./migrate.sh $MIGRATION_FLAGS --all
      fi
```

## Utiliser les entrées de job avec l'API {#use-job-inputs-with-the-api}

Vous pouvez spécifier des valeurs d'entrée de job lors de l'utilisation de l'API pour exécuter ou réessayer des jobs.

### Exécuter un job manuel avec des entrées {#run-a-manual-job-with-inputs}

Utilisez le [endpoint `POST /projects/:id/jobs/:job_id/play`](../../api/jobs.md#run-a-job) avec le paramètre `job_inputs` :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "job_inputs": {
      "environment": "staging",
      "version": "v2.1.0"
    }
  }' \
  "https://gitlab.example.com/api/v4/projects/1/jobs/456/play"
```

### Réessayer un job avec des entrées {#retry-a-job-with-inputs}

Utilisez le [endpoint `POST /projects/:id/jobs/:job_id/retry`](../../api/jobs.md#retry-a-job) avec le paramètre `job_inputs` :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "job_inputs": {
      "environment": "production",
      "replicas": 10
    }
  }' \
  "https://gitlab.example.com/api/v4/projects/1/jobs/123/retry"
```

### Utiliser GraphQL {#use-graphql}

Vous pouvez utiliser la [mutation `jobPlay`](../../api/graphql/reference/_index.md#mutationjobplay) ou la [mutation `jobRetry`](../../api/graphql/reference/_index.md#mutationjobretry) avec un argument `inputs` :

```graphql
mutation {
  jobPlay(input: {
    id: "gid://gitlab/Ci::Build/123",
    inputs: [
      { name: "environment", value: "production" },
      { name: "replicas", value: 10 }
    ]
  }) {
    job {
      id
      status
    }
    errors
  }
}
```

## Dépannage {#troubleshooting}

### Le job échoue avec `input must have a default value` {#job-fails-with-input-must-have-a-default-value}

Les entrées de job doivent toujours avoir des valeurs par défaut pour garantir que les jobs peuvent s'exécuter dans des pipelines où les entrées ne peuvent pas être spécifiées manuellement.

Pour corriger cette erreur, ajoutez un `default` à chaque entrée :

```yaml
my_job:
  inputs:
    target_env:
      default: staging  # Default specified
  script:
    - echo ${{ job.inputs.target_env }}
```

### La validation de l'entrée échoue avec `unexpected value` {#input-validation-fails-with-unexpected-value}

Lorsque la validation des entrées échoue, vérifiez :

- Si vous utilisez `options`, assurez-vous que la valeur correspond exactement à l'une des options autorisées (sensible à la casse).
- Si vous utilisez `regex`, vérifiez que votre expression régulière correspond à la valeur d'entrée.
- Si vous utilisez `type: number`, assurez-vous que la valeur est numérique et non une chaîne de caractères.
- Si vous utilisez `type: array`, assurez-vous que la valeur est formatée en tableau JSON lors de la transmission via l'API.

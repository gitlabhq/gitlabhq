---
stage: AI-powered features
group: Workflow Catalog
title: Flow Registry Framework v1
ignore_in_report: true
---

{{< details >}}

- Édition : [Gratuite](../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version bêta

{{< /details >}}

Utilisez le Flow Registry Framework v1 pour créer des flux de travail personnalisés basés sur l'IA sur la plateforme GitLab Duo Agent en définissant des composants, des outils et une logique de routage dans un seul fichier YAML.

## Structure de configuration YAML {#yaml-configuration-structure}

Chaque flow est un fichier YAML unique. La structure de niveau supérieur est :

```yaml
version: "v1"
environment: ambient

components:
  # List of components (see Component types)

routers:
  # Routing rules between components (see Routers)

flow:
  entry_point: "component_name"   # First component to run

prompts:                           # Optional - inline prompt definitions
  # Locally defined prompts (see Prompts)
```

### Champs obligatoires {#required-fields}

| Champ | Description |
|---|---|
| `version` | Toujours `"v1"` |
| `environment` | Style d'interaction du flow - voir [Environment](#environment) |
| `components` | Liste des composants qui constituent le flow - voir [Types de composants](#component-types)|
| `routers` | Règles de routage entre les composants - voir [Routers](#routers) |
| `flow` | Point d'entrée et entrées de contexte facultatives - voir [section flow](#flow-section) |

### Champs facultatifs {#optional-fields}

| Champ | Description |
|---|---|
| `name` | Nom du flow lisible par un humain |
| `description` | Description du flow |
| `product_group` | Propriété de l'équipe (par exemple, `agent_foundations`) |
| `prompts` | Définitions de prompts intégrées - voir [Prompts définis localement](#locally-defined-prompts) |
| `response_schemas` | Définitions de schémas de réponse intégrées - voir [Schémas de réponse](#response-schemas) |

### Environment {#environment}

Le champ `environment` déclare le niveau d'interaction humain-IA attendu.

| Valeur | Description |
|---|---|
| `ambient` | Exécution en arrière-plan sans intervention. L'humain délègue une tâche et l'agent s'exécute de manière autonome. Minimisez la participation humaine. À utiliser pour la plupart des flows personnalisés. |
| `chat` | Conversation interactive et bidirectionnelle via une interface de type chat. |
| `chat-partial` | Variante simplifiée de `chat` pour les flows à agent unique. Ignore le code standard. Nécessite exactement un `AgentComponent`. |

## Démarrage rapide {#quick-start}

Pour invoquer un flow, transmettez votre configuration de flow dans un `StartWorkflowRequest` :

```plaintext
flowConfigId: "<your_flow_id>"
flowConfigSchemaVersion: "v1"
flowVersion: "1.0.0"
```

Le reste de cette page documente la structure YAML de la configuration du flow. Pour obtenir des instructions sur l'enregistrement d'un nouveau flow par défaut dans la base de code, consultez le [guide du développeur pour les flows par défaut](foundational_flows/developer.md).

## Variables de contexte de session {#session-context-variables}

Chaque bloc `inputs` de composant extrait des valeurs du contexte de session en utilisant `from: "context:<key>"`. Le framework remplit automatiquement un ensemble de variables toujours disponibles. Vous n'avez pas besoin de déclarer ces variables, mais vous devez les référencer explicitement dans le bloc `inputs` de chaque composant.

### Variables toujours disponibles {#always-available-variables}

| Variable | Type | Description |
|---|---|---|
| `context:goal` | Chaîne | L'objectif ou le message de l'utilisateur qui a déclenché le workflow |
| `context:project_id` | Chaîne | ID de projet GitLab (numérique, sous forme de chaîne) |
| `context:project_http_url_to_repo` | Chaîne | URL de clonage HTTPS complète du dépôt |

> [!note]
> `context:project_id` n'est pas injecté automatiquement dans les templates de prompt. Si votre agent appelle un outil de l'API GitLab (par exemple, `get_merge_request`, `list_issues` ou `create_merge_request`), vous devez l'ajouter aux `inputs` du composant et inclure `Project ID: {{ project_id }}` dans le bloc `user:` du prompt. L'omission de ceci est la cause la plus fréquente d'échecs de flow.

### Variables de contexte standard de la plateforme agent {#agent-platform-standard-context-variables}

Ces variables ne sont disponibles que lorsque vous déclarez la stanza `flow.inputs`. Elles transportent les métadonnées de branche et de session injectées par le runner CI.

| Variable | Type | Description |
|---|---|---|
| `context:inputs.agent_platform_standard_context.primary_branch` | Chaîne | Branche par défaut du dépôt (par exemple, `main`) |
| `context:inputs.agent_platform_standard_context.workload_branch` | Chaîne | Référence Git utilisée par le runner de charge de travail CI |
| `context:inputs.agent_platform_standard_context.session_owner_id` | Chaîne | ID utilisateur GitLab de la personne ayant déclenché le flow |

Déclarez ces variables lorsque votre flow crée des branches, ouvre des merge requests ou doit connaître la branche par défaut. Pour plus d'informations, consultez la [section flow](#flow-section).

## Section flow {#flow-section}

La section `flow` définit le point d'entrée et, facultativement, les catégories de contexte externe à injecter.

### Minimal {#minimal}

```yaml
flow:
  entry_point: "my_first_component"
```

### Avec le contexte standard de la plateforme agent {#with-agent-platform-standard-context}

Obligatoire lorsque votre flow a besoin de `primary_branch`, `workload_branch` ou `session_owner_id` :

```yaml
flow:
  entry_point: "create_feature_branch"
  inputs:
    - category: agent_platform_standard_context
      input_schema:
        primary_branch:
          type: string
          description: The default/primary branch of the repository (for example, 'main', 'master')
        workload_branch:
          type: string
          description: git ref to workload branch
        session_owner_id:
          type: string
          description: Human user's ID that initiated the flow
```

## Types de composants {#component-types}

| Composant | Objectif | IA impliquée | Quand l'utiliser |
|---|---|:---:|---|
| [AgentComponent](#agentcomponent) | Raisonnement IA multi-tour avec outils | Oui | Tâches complexes nécessitant une prise de décision itérative, une conversation ou l'utilisation d'outils en plusieurs étapes. |
| [OneOffComponent](#oneoffcomponent) | Exécution d'outil IA en un seul tour | Oui | Tâches délimitées réalisables en un seul appel LLM avec une logique de nouvelle tentative intégrée. |
| [DeterministicStepComponent](#deterministicstepcomponent) | Exécuter un seul outil avec des arguments fixes | Non | Opérations prévisibles et répétables où les arguments de l'outil proviennent directement de l'état. |
| [HumanInputComponent](#humaninputcomponent) | Demander et traiter les entrées utilisateur | Non | Portes d'approbation, chat interactif ou tout point où un retour humain est nécessaire. |
| [EndComponent / AbortComponent](#endcomponent-and-abortcomponent) | Terminer le workflow | Non | Chaque flow doit se terminer par `"end"` (succès) ou `"abort"` (erreur). |

## AgentComponent {#agentcomponent}

L'AgentComponent est le principal bloc de construction des flows alimentés par l'IA. Il utilise un LLM pour :

- Traiter les entrées.
- Prendre des décisions basées sur un prompt.
- Appeler des outils.
- Maintenir l'historique des conversations.
- Générer des sorties pour les composants en aval.

### Paramètres obligatoires {#required-parameters}

| Paramètre | Description |
|---|---|
| `name` | Identifiant unique. Ne doit pas contenir les caractères `:` ou `.`. |
| `type` | Doit être `"AgentComponent"`. |
| `prompt_id` | ID du template de prompt (local ou basé sur le registre). |

### Paramètres facultatifs {#optional-parameters}

| Paramètre | Valeur par défaut | Description |
|---|---|---|
| `prompt_version` | omis | Contrainte Semver (par exemple, `"^1.0.0"`). Omettez ce paramètre pour utiliser un prompt défini localement. |
| `inputs` | `["context:goal"]` | Liste des sources de données d'entrée. |
| `toolset` | `[]` | Outils disponibles pour l'agent. Voir [Outils disponibles](#available-tools). |
| `description` | Aucune | Obligatoire lorsqu'il est utilisé en tant que sous-agent sous un superviseur. |
| `subagents` | Aucune | Liste des noms de sous-agents. Active le [Mode Superviseur](#supervisor-mode). |
| `max_delegations` | illimité | Nombre maximum d'appels `delegate_task` en Mode Superviseur. |
| `response_schema_id` | Aucune | ID du schéma de sortie structurée. |
| `response_schema_version` | Aucune | Semver pour le schéma basé sur le registre. |
| `model_size_preference` | `null` | `"small"` ou `"large"`. |
| `require_tool_approval` | `false` | Mettre en pause pour approbation humaine avant chaque appel d'outil. |
| `pre_approved_tools` | `[]` | Outils qui ignorent l'étape d'approbation. |
| `compaction` | Aucune | Configuration de la compaction des conversations. |
| `ui_log_events` | `[]` | Événements à afficher dans l'interface utilisateur. Voir [Événements de journal UI](#agentcomponent-ui-log-events). |
| `ui_role_as` | `"agent"` | Rôle d'affichage dans l'interface utilisateur (`"agent"` ou `"tool"`). |

### Sorties {#outputs}

| Clé de sortie | Description |
|---|---|
| `context:{name}.final_answer` | Réponse finale de l'agent (chaîne ou dict avec schéma personnalisé). |
| `context:{name}.final_answer.{field}` | Champ individuel lors de l'utilisation d'un schéma de réponse personnalisé. |
| `conversation_history:{name}` | Historique complet des messages. |

### Entrées {#inputs}

Les entrées du composant extraient des valeurs du contexte de session et les rendent disponibles en tant que variables de template dans le prompt. L'alias `as:` doit correspondre exactement au placeholder `{{ variable }}` dans le template de prompt.

```yaml
# In the component inputs:
inputs:
  - from: "context:goal"
    as: "goal"
  - from: "context:project_id"
    as: "project_id"
  - from: "context:previous_agent.final_answer"
    as: "previous_result"
  - from: "some constant value"
    as: "my_constant"
    literal: true

# In the prompt user block:
user: |
  Project ID: {{ project_id }}
  Goal: {{ goal }}
  Previous result: {{ previous_result }}
```

### Prompts {#prompts}

Chaque AgentComponent a besoin d'un prompt. Définissez-le en ligne dans le YAML du flow (recommandé pour les flows personnalisés) ou référencez-en un depuis le registre de prompts de la passerelle d'IA.

#### Prompts définis localement {#locally-defined-prompts}

Omettez `prompt_version` pour utiliser un prompt en ligne défini dans le bloc `prompts` de niveau supérieur :

```yaml
components:
  - name: "my_agent"
    type: AgentComponent
    prompt_id: "my_prompt"
    # prompt_version omitted - uses local prompt

prompts:
  - prompt_id: "my_prompt"
    name: "My Prompt"
    unit_primitives: []           # always include, even if empty
    prompt_template:
      system: |
        You are a helpful assistant.

        When your task is complete, your final answer is a plain text summary
        of what you did. No further steps are needed after that.
      user: |
        Project ID: {{ project_id }}
        Goal: {{ goal }}
      placeholder: history        # include explicitly
    params:
      timeout: 180
```

#### Prompts du registre {#registry-prompts}

Spécifiez `prompt_version` pour charger depuis le registre de prompts de la passerelle d'IA à l'emplacement `ai_gateway/prompts/definitions/` :

```yaml
components:
  - name: "my_agent"
    type: AgentComponent
    prompt_id: "my_flow/my_prompt"
    prompt_version: "^1.0.0"
```

#### Bonnes pratiques pour la rédaction de prompts {#prompt-writing-best-practices}

- Indiquez toujours à l'agent quand il a terminé. Sans instruction d'arrêt explicite, l'agent tourne en boucle. Terminez chaque prompt `system:` par une phrase telle que : `"When [condition], your final answer is [what to say]. No further steps are needed after that."`
- Transmettez toujours `project_id` dans le bloc `user:` pour tout agent qui appelle des outils de l'API GitLab. L'agent ne peut pas le découvrir par lui-même.
- Faites correspondre les noms de variables exactement. L'alias `as:` dans `inputs` doit correspondre au placeholder `{{ variable }}` dans le template de prompt.
- Incluez toujours `unit_primitives: []` dans les prompts en ligne, même s'il est vide.
- Incluez toujours `placeholder: history` dans les templates de prompt en ligne.

### Outils disponibles {#available-tools}

Configurez les outils en transmettant leur nom en snake_case dans `toolset`. La liste complète se trouve dans `duo_workflow_service/components/tools_registry.py`. Exemples courants :

- Opérations sur les fichiers : `read_file`, `create_file_with_contents`, `edit_file`, `list_dir`, `find_files`, `grep`
- Opérations Git : `run_command`, `create_merge_request`, `create_branch`
- API GitLab : `get_issue`, `list_issues`, `get_merge_request`, `gitlab_merge_request_search`, `get_work_item`, `get_repository_file`, `list_repository_tree`, `create_issue_note`, `create_merge_request_note`, `create_commit`, `gitlab_api_get`, `get_project`

### Options d'outil {#tool-options}

Remplacez les paramètres d'un outil au niveau du composant afin que le LLM ne puisse pas les modifier :

```yaml
toolset:
  - "get_merge_request"                    # simple string - no overrides
  - "create_merge_request_note":           # object form - override a parameter
      "internal": true
```

Les options sont validées par rapport au schéma d'entrée Pydantic de l'outil lors de l'initialisation. Si une clé d'option ne correspond pas à un paramètre valide, une `ValueError` est levée. Lors de l'exécution, les options d'outil ont la priorité sur les valeurs fournies par le LLM.

### Événements de journal UI de l'AgentComponent {#agentcomponent-ui-log-events}

| Événement | Description |
|---|---|
| `on_agent_final_answer` | L'agent envoie sa réponse finale. Cela permet la visibilité de la réponse finale complète dans l'interface utilisateur de session et le journal CI. Désactivez si la sortie contient des données sensibles. |
| `on_tool_execution_success` | Un appel d'outil s'est terminé avec succès. |
| `on_tool_execution_failed` | Un appel d'outil a échoué. |
| `on_tool_approval_request` | L'approbation de l'outil est en attente de décision de l'utilisateur. Doit être inclus pour afficher les demandes d'approbation dans l'interface utilisateur. |

### Approbation d'outil {#tool-approval}

Lorsque `require_tool_approval: true`, le workflow se met en pause après que l'agent génère des appels d'outils et attend la décision de l'utilisateur avant de continuer.

Les types de décision suivants sont pris en charge :

| Décision | Comportement |
|---|---|
| `APPROVE` | L'outil s'exécute normalement. |
| `REJECT` | Message de rejet ajouté à l'historique ; l'agent essaie une approche alternative. |
| `MODIFY` | Rejet plus retour utilisateur ajouté à l'historique ; l'agent s'ajuste en conséquence. |

Un outil est pré-approuvé et ignore l'étape d'approbation s'il apparaît dans l'un des éléments suivants :

- Au niveau du composant : répertorié dans le paramètre `pre_approved_tools` sur le composant. Contrôlé par l'auteur du flow dans le YAML.
- Au niveau du workflow : spécifié via `pre_approved_agent_privileges` dans le `startRequest` du workflow. Contrôlé par l'appelant du workflow au moment de l'invocation.

Si tous les appels d'outils sont pré-approuvés depuis l'une ou l'autre source, le flow d'approbation est entièrement ignoré et les outils s'exécutent immédiatement.

```yaml
components:
  - name: "code_editor"
    type: AgentComponent
    prompt_id: "code_assistant"
    prompt_version: "^1.0.0"
    require_tool_approval: true
    pre_approved_tools: ["read_file", "list_dir", "find_files"]
    toolset: ["read_file", "list_dir", "find_files", "edit_file", "run_command"]
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
      - "on_tool_approval_request"
    inputs: ["context:goal"]
```

### Modes d'utilisation {#usage-modes}

| Mode | Quand | `description` obligatoire |
|---|---|---|
| Autonome | Composant ordinaire dans le flow. | Non |
| Géré | Sous-agent délégué par un superviseur. | Oui |
| Superviseur | Orchestre les sous-agents via `delegate_task`. | Non (sur le superviseur lui-même) |

### Mode Superviseur {#supervisor-mode}

Lorsque `subagents` est fourni, l'agent devient un superviseur avec accès à `delegate_task` et `final_response_tool` automatiquement. Lorsque le LLM appelle `delegate_task`, le framework :

1. Assigne ou reprend une sous-session numérotée pour le sous-agent nommé.
1. Amorce l'historique des conversations du sous-agent avec le prompt de délégation.
1. Achemine l'exécution vers la boucle ReAct du sous-agent.
1. À la fin du sous-agent, injecte le résultat dans l'historique du superviseur et rend le contrôle au superviseur.

#### Contraintes {#constraints}

- `subagents` doit contenir au moins une entrée.
- Chaque sous-agent répertorié doit avoir un champ `description`.
- Un `AgentComponent` ne peut être la propriété que d'un seul superviseur au maximum.
- Le prompt système du superviseur doit indiquer au LLM quand utiliser `delegate_task` et `final_response_tool`.

#### Sorties du superviseur {#supervisor-outputs}

| Clé de sortie | Description |
|---|---|
| `context:{supervisor_name}.final_answer` | Réponse finale du superviseur. |
| `conversation_history:{supervisor_name}` | Historique des messages propres au superviseur. |

### Schémas de réponse {#response-schemas}

Les schémas de réponse contraignent la sortie d'un AgentComponent à un format structuré. Sans schéma, l'agent retourne une chaîne simple dans `final_answer`. Avec un schéma, `final_answer` est un dict et chaque champ est également accessible en tant que `context:{name}.final_answer.{field}`.

#### Schéma en ligne (recommandé pour les flows personnalisés) {#inline-schema-recommended-for-custom-flows}

```yaml
components:
  - name: "code_reviewer"
    type: AgentComponent
    prompt_id: "code_review_prompt"
    response_schema_id: "code_review"   # no response_schema_version = inline lookup
    toolset: ["read_file"]

response_schemas:
  - schema_id: "code_review"
    definition:
      "$schema": "http://json-schema.org/draft-07/schema#"
      title: "code_review_response"
      type: object
      properties:
        summary:
          type: string
          description: "Brief summary of findings"
        overall_score:
          type: integer
          minimum: 1
          maximum: 10
      required: [summary, overall_score]
```

#### Schéma du registre {#registry-schema}

Fournissez à la fois `response_schema_id` et `response_schema_version` pour charger depuis le registre côté serveur à l'emplacement `ai_gateway/response_schemas/definitions/` :

```yaml
components:
  - name: "code_reviewer"
    type: AgentComponent
    prompt_id: "code_review/detailed_analysis"
    prompt_version: "^1.0.0"
    response_schema_id: "analysis/code_review"
    response_schema_version: "^1.0.0"
```

Les composants en aval peuvent référencer des champs de schéma individuels :

```yaml
inputs:
  - from: "context:code_reviewer.final_answer.overall_score"
    as: "score"
```

#### Référence de définition de schéma {#schema-definition-reference}

Les schémas de réponse utilisent le format [JSON Schema](https://json-schema.org/). Champs de niveau supérieur importants :

| Champ | Description |
|---|---|
| `$schema` | Dialecte de schéma. Par défaut `draft-07` si non fourni. |
| `title` | Correspond au nom de l'outil que l'agent appelle pour sa réponse finale. Ne doit pas correspondre à un nom d'outil existant - une collision lève une `ValueError`. |
| `type` | Doit être `"object"`. |
| `properties` | Objets JSON imbriqués définissant les champs du schéma. Prend en charge le type `"object"` pour les structures imbriquées. |
| `required` | Liste des noms de champs qui doivent être présents dans la sortie. |

Les contraintes de validation JSON Schema suivantes sont prises en charge par les schémas de réponse d'AgentComponent.

##### Contraintes numériques (entier/nombre) {#numeric-constraints-integernumber}

| Contrainte JSON Schema | Paramètre de champ Pydantic | Description |
|---|---|---|
| `minimum` | `ge=` | Valeur minimale (inclusive) - supérieure ou égale à. |
| `maximum` | `le=` | Valeur maximale (inclusive) - inférieure ou égale à. |
| `exclusiveMinimum` | `gt=` | Valeur minimale (exclusive) - strictement supérieure à. |
| `exclusiveMaximum` | `lt=` | Valeur maximale (exclusive) - strictement inférieure à. |
| `multipleOf` | `multiple_of=` | La valeur doit être un multiple de ce nombre. |

##### Contraintes de chaîne {#string-constraints}

| Contrainte JSON Schema | Paramètre de champ Pydantic | Description |
|---|---|---|
| `minLength` | `min_length=` | Longueur minimale de la chaîne en caractères. |
| `maxLength` | `max_length=` | Longueur maximale de la chaîne en caractères. |
| `pattern` | `pattern=` | Modèle d'expression régulière auquel la chaîne doit correspondre. |

##### Contraintes de tableau {#array-constraints}

| Contrainte JSON Schema | Paramètre de champ Pydantic | Description |
|---|---|---|
| `minItems` | `min_length=` | Nombre minimum d'éléments dans le tableau. |
| `maxItems` | `max_length=` | Nombre maximum d'éléments dans le tableau. |

##### Énumération et constantes {#enumeration-and-constants}

| Contrainte JSON Schema | Type Python | Description |
|---|---|---|
| `enum` | `Literal[val1, val2, ...]` | Le champ doit être l'une des valeurs spécifiées. |
| `const` | `Literal[value]` | Le champ doit être exactement cette valeur. |

##### Métadonnées {#metadata}

| Champ JSON Schema | Paramètre de champ Pydantic | Description |
|---|---|---|
| `default` | `default=` | Valeur par défaut pour les champs facultatifs. |
| `examples` | `examples=` | Exemples de valeurs présentés à l'agent à titre indicatif. |

##### Exemple de schéma complet {#full-schema-example}

```json
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "title": "code_review_response_tool",
    "type": "object",
    "properties": {
        "summary": {
            "type": "string",
            "description": "Brief summary of the code review findings"
        },
        "issues_found": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "severity": {
                        "type": "string",
                        "enum": ["low", "medium", "high", "critical"]
                    },
                    "description": { "type": "string" },
                    "file_path": { "type": "string" },
                    "line_number": { "type": "integer" }
                },
                "required": ["severity", "description"]
            }
        },
        "recommendations": {
            "type": "array",
            "items": { "type": "string" }
        },
        "overall_score": {
            "type": "integer",
            "minimum": 1,
            "maximum": 10
        }
    },
    "required": ["summary", "issues_found", "overall_score"]
}
```

### Exemple d'AgentComponent {#agentcomponent-example}

```yaml
components:
  - name: "code_assistant"
    type: AgentComponent
    prompt_id: "code_review_helper"
    prompt_version: "^1.0.0"
    inputs: ["context:goal"]
    require_tool_approval: true
    pre_approved_tools: ["read_file", "list_dir", "find_files"]
    toolset:
      - "read_file"
      - "list_dir"
      - "find_files"
      - "create_file_with_contents"
      - "create_merge_request_note":
          "internal": true
      - "edit_file"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
    ui_role_as: "agent"
```

## HumanInputComponent {#humaninputcomponent}

Le HumanInputComponent :

- Met en pause l'exécution du workflow.
- Présente un prompt à l'humain.
- Reprend lorsque l'humain répond.

Utilisez-le pour les portes de révision, les approbations et les boucles de retour.

### Paramètres obligatoires {#required-parameters-1}

| Paramètre | Description |
|---|---|
| `name` | Identifiant unique. Ne doit pas contenir les caractères `:` ou `.`. |
| `type` | Doit être `"HumanInputComponent"`. |
| `sends_response_to` | Nom de l'AgentComponent qui reçoit la réponse de l'humain dans son historique de conversation. [Il doit s'agir d'un composant qui a déjà été exécuté](#critical-constraint-sends_response_to-must-point-to-an-already-run-component). |
| `message_template` | Template Jinja2 présenté à l'humain. Peut référencer des variables via `inputs`. |

### Paramètres facultatifs {#optional-parameters-1}

| Paramètre | Valeur par défaut | Description |
|---|---|---|
| `interaction_type` | `"approval"` | `"approval"` affiche des boutons Approuver/Rejeter/Modifier. `"input"` affiche un champ de saisie de texte. Définissez toujours ce paramètre explicitement - ne vous fiez pas à la valeur par défaut. |
| `inputs` | `[]` | Variables à afficher dans `message_template`. |
| `ui_log_events` | `[]` | Doit toujours inclure les deux [événements de journal UI](#ui-log-events). |

### Contrainte critique : `sends_response_to` doit pointer vers un composant déjà exécuté {#critical-constraint-sends_response_to-must-point-to-an-already-run-component}

> [!note]
> Il s'agit du champ le plus souvent mal compris dans `HumanInputComponent`.

Le framework injecte le retour de l'humain dans l'historique de conversation existant du composant cible. Si ce composant n'a pas encore été exécuté, il n'a pas d'entrée dans l'historique de conversation et le framework plante avec `KeyError('<component_name>')`.

> [!note]
> `sends_response_to` doit désigner un composant dont l'exécution est déjà terminée avant le déclenchement de la porte.

En pratique, cela signifie presque toujours pointer vers l'agent qui s'est exécuté juste avant la porte.

Si la cible de la route `modify` n'a pas encore été exécutée, transmettez-lui le retour via ses `inputs` à la place :

```yaml
# Correct pattern - sends_response_to points to the already-run agent
- name: "review_gate"
  type: HumanInputComponent
  sends_response_to: "suggester_agent"    # suggester already ran ✅
  interaction_type: "approval"
  ...

# The modify handler gets feedback through inputs instead:
- name: "modify_handler"
  type: AgentComponent
  inputs:
    - from: "context:review_gate.approval"
      as: "human_feedback"               # feedback passed explicitly ✅
```

```yaml
# Wrong pattern - crashes with KeyError
- name: "review_gate"
  sends_response_to: "modify_handler"    # has not run yet → KeyError ❌
```

### Événements de journal UI {#ui-log-events}

Les deux événements doivent être inclus. Sans eux, la porte est invisible dans l'interface utilisateur de session :

| Événement | Description |
|---|---|
| `on_user_input_prompt` | Affiche le prompt et rend le contrôle de saisie correct (boutons ou zone de texte). |
| `on_user_response` | Capture la réponse de l'humain dans le journal de chat de l'interface utilisateur. |

### Sorties {#outputs-1}

| Clé de sortie | Description |
|---|---|
| `context:{name}.approval` | La décision de l'humain : `"approve"`, `"reject"` ou `"modify"`. |
| `conversation_history:{sends_response_to}` | Le message de l'humain, injecté dans l'historique de l'agent cible. |

### Router d'approbation - trois valeurs, pas deux {#approval-router---three-values-not-two}

Lorsque `interaction_type: "approval"`, l'humain peut répondre avec trois valeurs. Votre router doit gérer les trois ou le chemin `modify` tombe silencieusement vers `default_route` :

| Valeur | Signification |
|---|---|
| `"approve"` | L'humain a accepté - passer à l'étape suivante. |
| `"reject"` | L'humain a rejeté - acheminer vers la fin ou la gestion des erreurs. |
| `"modify"` | L'humain a fourni un retour - acheminer vers un agent précédent pour révision. |

```yaml
routers:
  - from: "review_gate"
    condition:
      input: "context:review_gate.approval"
      routes:
        "approve": "next_step"
        "modify": "prior_agent"      # loop back - feedback available in history or inputs
        "reject": "end"
        "default_route": "end"       # always include a fallback
```

### Liste de vérification du HumanInputComponent {#humaninputcomponent-checklist}

Avant d'enregistrer votre YAML, vérifiez :

- `interaction_type` est explicitement défini (`"approval"` ou `"input"`).
- `ui_log_events` inclut à la fois `"on_user_input_prompt"` et `"on_user_response"`.
- Le router en aval utilise `condition:` (et non `to:`).
- Le router gère `"approve"`, `"modify"` et `"reject"` explicitement.
- `"default_route"` est présent dans le router.
- `sends_response_to` pointe vers un composant qui a déjà été exécuté avant le déclenchement de la porte.
- Si la cible `modify` n'a pas encore été exécutée, ses `inputs` incluent `from: "context:{gate_name}.approval" as: "human_feedback"`.

### Modèles d'utilisation {#usage-patterns}

#### Workflow d'approbation {#approval-workflow}

```yaml
components:
  - name: "user_approval"
    type: HumanInputComponent
    sends_response_to: "proposal_agent"   # proposal_agent already ran
    interaction_type: "approval"
    message_template: |
      Please review the proposed changes and choose an action:
      - ✅ Approve: Proceed
      - ✏️ Modify: Provide feedback for revision
      - ❌ Reject: Discard
    ui_log_events:
      - "on_user_input_prompt"
      - "on_user_response"

routers:
  - from: "user_approval"
    condition:
      input: "context:user_approval.approval"
      routes:
        "approve": "executor"
        "modify": "proposal_agent"
        "reject": "end"
        "default_route": "end"
```

#### Chat interactif {#interactive-chat}

```yaml
components:
  - name: "user_input"
    type: HumanInputComponent
    sends_response_to: "chat_agent"
    interaction_type: "input"
    message_template: "How can I help you today?"
    ui_log_events:
      - "on_user_input_prompt"
      - "on_user_response"

routers:
  - from: "user_input"
    to: "chat_agent"
  - from: "chat_agent"
    to: "user_input"  # loop back for continued interaction
```

## DeterministicStepComponent {#deterministicstepcomponent}

Exécute un seul outil directement sans intervention du LLM. Les paramètres sont extraits de l'état du flow. Chaînez plusieurs instances pour exécuter des opérations d'outils séquentielles.

### Paramètres obligatoires {#required-parameters-2}

| Paramètre | Description |
|---|---|
| `name` | Identifiant unique. Ne doit pas contenir les caractères `:` ou `.`. |
| `type` | Doit être `"DeterministicStepComponent"`. |
| `tool_name` | Nom du seul outil à exécuter. |

### Paramètres facultatifs {#optional-parameters-2}

| Paramètre | Valeur par défaut | Description |
|---|---|---|
| `toolset` | auto | Ensemble d'outils contenant l'outil (créé automatiquement si omis). |
| `inputs` | `[]` | Sources d'entrée mappées aux paramètres de l'outil. |
| `ui_log_events` | `[]` | Événements à afficher dans l'interface utilisateur. |
| `ui_role_as` | `"tool"` | Rôle d'affichage dans l'interface utilisateur. |

### Sorties {#outputs-2}

| Clé de sortie | Description |
|---|---|
| `context:{name}.tool_responses` | Résultat de l'exécution de l'outil. |
| `context:{name}.error` | Toute erreur survenue. |
| `context:{name}.execution_result` | `"success"` ou `"failed"`. |

### Validation {#validation}

Le composant valide les arguments de l'outil lors de l'initialisation :

- Vérifie que l'outil spécifié existe dans l'ensemble d'outils.
- Vérifie que tous les paramètres d'outil obligatoires sont configurés dans `inputs`.
- Vérifie que les paramètres correspondent au schéma attendu de l'outil.

Les erreurs sont détectées au moment de la configuration plutôt qu'à l'exécution.

### Exemple : chaîner plusieurs outils {#example-chain-multiple-tools}

```yaml
components:
  - name: "read_config"
    type: DeterministicStepComponent
    inputs:
      - from: "context:goal"
        as: "config_path"
    tool_name: "read_file"
    ui_log_events:
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

  - name: "backup_config"
    type: DeterministicStepComponent
    inputs:
      - from: "context:read_config.tool_responses"
        as: "contents"
      - from: "config_backup.txt"
        as: "file_path"
        literal: true
    tool_name: "create_file_with_contents"
```

## OneOffComponent {#oneoffcomponent}

Se situe entre `AgentComponent` et `DeterministicStepComponent`. Utilise un LLM pour générer des appels d'outils en un seul tour, puis se termine en cas de succès. Inclut une logique de nouvelle tentative intégrée pour les exécutions échouées.

À utiliser lorsqu'une tâche peut être accomplie en un seul appel LLM mais bénéficie du raisonnement LLM pour déterminer les paramètres de l'outil.

### Paramètres obligatoires {#required-parameters-3}

| Paramètre | Description |
|---|---|
| `name` | Identifiant unique. Ne doit pas contenir les caractères `:` ou `.`. |
| `type` | Doit être `"OneOffComponent"`. |
| `prompt_id` | Prompt qui instruit l'appel d'outil. |
| `toolset` | Outils disponibles pour le tour unique. |

### Paramètres facultatifs {#optional-parameters-3}

| Paramètre | Valeur par défaut | Description |
|---|---|---|
| `prompt_version` | omis | Omettez ce paramètre pour utiliser un prompt défini localement. |
| `inputs` | `["context:goal"]` | Sources de données d'entrée. |
| `max_correction_attempts` | `3` | Limite de nouvelles tentatives pour les exécutions d'outils échouées. |
| `model_size_preference` | `null` | `"small"` ou `"large"`. |
| `compaction` | Aucune | Configuration de la compaction des conversations. |
| `ui_log_events` | `[]` | Événements à afficher dans l'interface utilisateur. |

### Sorties {#outputs-3}

| Clé de sortie | Description |
|---|---|
| `context:{name}.tool_responses` | Résultats de l'exécution de l'outil. |
| `context:{name}.tool_calls` | Enregistrement des appels d'outils effectués. |
| `context:{name}.execution_result` | `"success"` ou `"failed"`. |

### Événements de journal UI {#ui-log-events-1}

| Événement | Description |
|---|---|
| `on_tool_call_input` | L'outil est sur le point d'être appelé avec ses arguments. |
| `on_tool_execution_success` | L'outil s'est terminé avec succès. |
| `on_tool_execution_failed` | L'exécution de l'outil a échoué. |
| `on_agent_reasoning` | L'agent n'a pas pu produire d'appels d'outils en raison de limitations. |

### Architecture interne {#internal-architecture}

Le OneOffComponent est composé de trois nœuds internes :

- Nœud LLM (`{name}#llm`) : utilise `AgentNode` pour générer un ou plusieurs appels d'outils.
- Nœud d'outils (`{name}#tools`) : exécute les appels d'outils avec correction d'erreur via `ToolNodeWithErrorCorrection`.
- Nœud de sortie (`{name}#exit`) : gère la complétion et la journalisation de l'état.

### Exemple {#example}

```yaml
components:
  - name: "file_reader"
    type: OneOffComponent
    prompt_id: "read_specific_file"
    prompt_version: "^1.0.0"
    inputs:
      - from: "context:goal"
        as: "target_file"
    toolset:
      - "read_file"
    max_correction_attempts: 2
    ui_log_events:
      - "on_tool_call_input"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
```

## EndComponent et AbortComponent {#endcomponent-and-abortcomponent}

Les deux sont automatiquement disponibles dans chaque flow. Aucune définition nécessaire.

| Nom | Clé de router | Statut défini | Quand l'utiliser |
|---|---|---|---|
| EndComponent | `"end"` | `COMPLETED` | Le workflow s'est terminé avec succès. |
| AbortComponent | `"abort"` | `ERROR` | Erreur irrécupérable ; nouvelles tentatives épuisées. |

```yaml
routers:
  - from: "my_component"
    to: "end"    # successful completion

  - from: "my_component"
    to: "abort"  # error termination
```

## Routers {#routers}

Les routers définissent la manière dont l'exécution se déplace entre les composants après la fin de chacun d'eux.

### Router simple {#simple-router}

Achemine inconditionnellement vers le composant suivant :

```yaml
routers:
  - from: "component_a"
    to: "component_b"
```

### Router conditionnel {#conditional-router}

Achemine en fonction de la valeur d'une variable de contexte :

```yaml
routers:
  - from: "component_a"
    condition:
      input: "context:component_a.final_answer"
      routes:
        "approved": "component_b"
        "rejected": "end"
        "default_route": "end"   # fallback if value matches nothing
```

Incluez toujours `"default_route"` pour éviter les impasses silencieuses.

## Problèmes courants {#common-pitfalls}

| Symptôme | Cause principale | Correction |
|---|---|---|
| L'agent indique qu'il ne trouve pas le projet ou n'a pas de contexte de projet | `project_id` absent des `inputs` du composant | Ajoutez `- from: "context:project_id" as: "project_id"` à chaque composant qui appelle des outils de l'API GitLab, et incluez `Project ID: {{ project_id }}` dans le bloc `user:`. |
| `primary_branch` est indéfini | Stanza `flow.inputs` manquante | Ajoutez le bloc `flow.inputs` complet avec le schéma `agent_platform_standard_context`. |
| La porte HITL n'affiche rien dans l'interface utilisateur | `ui_log_events` manquant sur `HumanInputComponent` | Ajoutez `on_user_input_prompt` et `on_user_response` à `ui_log_events`. |
| `KeyError('<component_name>')` lors de la modification | `sends_response_to` pointe vers un composant qui n'a pas encore été exécuté. | Pointez `sends_response_to` vers l'agent le plus récemment terminé ; transmettez le retour à la cible de modification via ses `inputs`. |
| La réponse `modify` est acheminée de façon inattendue vers `default_route` | Route `"modify"` manquante dans le router | Ajoutez `"modify": "<target_component>"` à chaque router conditionnel après un `HumanInputComponent`. |
| L'agent tourne en boucle indéfiniment | Instruction d'arrêt manquante dans le prompt | Terminez chaque prompt `system:` par une instruction de complétion explicite. |
| Crash `NoneType: None` au démarrage de la session | Syntaxe Jinja2 `{{ }}` dans le prompt système de l'agent | La plateforme rend le prompt système via Jinja2 avant de le transmettre au modèle. Tout `{{ variable }}` dans le texte du prompt est traité comme une variable de template. Utilisez la notation `<<variable>>` dans la documentation ou échappez avec `{% raw %}{{ }}{% endraw %}`. |
| Erreur d'analyse YAML au chargement | `unit_primitives: []` manquant sur le prompt en ligne | Incluez toujours `unit_primitives: []`, même lorsqu'il est vide. |
| L'agent reçoit une variable vide | L'alias `as:` ne correspond pas au placeholder `{{ }}` | Vérifiez que la valeur `as:` dans `inputs` correspond exactement au nom du placeholder. |

## Exemples de flows {#flow-examples}

### Flow ambiant simple avec prompt local {#simple-ambient-flow-with-local-prompt}

```yaml
version: "v1"
environment: ambient

components:
  - name: "code_analyzer"
    type: AgentComponent
    prompt_id: "code_review_prompt"
    inputs:
      - from: "context:goal"
        as: "mr_link"
    toolset: ["read_file", "list_dir"]
    ui_log_events:
      - "on_agent_final_answer"

prompts:
  - prompt_id: "code_review_prompt"
    name: "Code Review"
    unit_primitives: []
    prompt_template:
      system: |
        You are an experienced software developer. Conduct a thorough code review
        and provide actionable feedback. When complete, your final answer is a
        summary of your findings. No further steps are needed after that.
      user: |
        Please conduct a code review for the merge request at: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

routers:
  - from: "code_analyzer"
    to: "end"

flow:
  entry_point: "code_analyzer"
```

### Flow ambiant avec options d'outil pour un comportement d'outil contrôlé {#ambient-flow-with-tool-options-for-controlled-tool-behavior}

```yaml
version: "v1"
environment: ambient

components:
  - name: "security_agent"
    type: AgentComponent
    prompt_id: "security_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - from: "context:goal"
        as: "mr_link"
    toolset:
      - "create_merge_request_note":
          "internal": true
      - "get_merge_request"
    ui_log_events:
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
      - "on_agent_final_answer"

  - name: "general_agent"
    type: AgentComponent
    prompt_id: "general_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - from: "context:goal"
        as: "mr_link"
    toolset:
      - "create_merge_request_note"
    ui_log_events:
      - "on_tool_execution_success"
      - "on_tool_execution_failed"
      - "on_agent_final_answer"

prompts:
  - prompt_id: "security_prompt"
    name: "Security Analysis Prompt"
    unit_primitives: []
    prompt_template:
      system: |
        You are a security analyst. Review the MR and leave an internal note
        summarizing any security concerns. When complete, your final answer is
        a confirmation that the note was posted. No further steps are needed.
      user: |
        Project ID: {{ project_id }}
        Merge Request: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

  - prompt_id: "general_prompt"
    name: "General Summary Prompt"
    unit_primitives: []
    prompt_template:
      system: |
        You are a helpful assistant. Leave a public note on the MR summarizing
        the changes. When complete, your final answer is a confirmation that
        the note was posted. No further steps are needed.
      user: |
        Project ID: {{ project_id }}
        Merge Request: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

routers:
  - from: "security_agent"
    to: "general_agent"
  - from: "general_agent"
    to: "end"

flow:
  entry_point: "security_agent"
```

### Flow d'approbation HITL {#hitl-approval-flow}

Ce flow propose une action, la présente pour révision humaine, et l'exécute lors de l'approbation. Il illustre le modèle `sends_response_to` correct et les trois routes du router.

```yaml
version: "v1"
environment: ambient

components:
  - name: "proposal_agent"
    type: AgentComponent
    prompt_id: "proposal_prompt"
    inputs:
      - from: "context:goal"
        as: "goal"
      - from: "context:project_id"
        as: "project_id"
    toolset:
      - "get_issue"
      - "list_issues"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

  - name: "review_gate"
    type: HumanInputComponent
    sends_response_to: "proposal_agent"     # proposal_agent has already run ✅
    interaction_type: "approval"
    message_template: |
      The agent has proposed an action. Please review and choose:
      - ✅ Approve: Proceed with the proposed action
      - ✏️ Modify: Provide feedback - the agent will revise
      - ❌ Reject: Discard
    ui_log_events:
      - "on_user_input_prompt"
      - "on_user_response"

  - name: "executor_agent"
    type: AgentComponent
    prompt_id: "executor_prompt"
    inputs:
      - from: "context:goal"
        as: "goal"
      - from: "context:project_id"
        as: "project_id"
      - from: "context:proposal_agent.final_answer"
        as: "approved_proposal"
    toolset:
      - "update_issue"
      - "create_issue_note"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

prompts:
  - prompt_id: "proposal_prompt"
    name: "Proposal Agent"
    unit_primitives: []
    prompt_template:
      system: |
        Review the goal and propose a concrete action. Do not execute anything yet.
        When you have formed your proposal, your final answer is a clear description
        of the proposed action. No further steps are needed after that.
      user: |
        Project ID: {{ project_id }}
        Goal: {{ goal }}
      placeholder: history
    params:
      timeout: 180

  - prompt_id: "executor_prompt"
    name: "Executor Agent"
    unit_primitives: []
    prompt_template:
      system: |
        Execute the approved proposal. If the human provided modification feedback,
        it is in your conversation history - incorporate it before executing.
        When execution is complete, your final answer is a confirmation of what
        was done. No further steps are needed after that.
      user: |
        Project ID: {{ project_id }}
        Goal: {{ goal }}
        Approved proposal: {{ approved_proposal }}
      placeholder: history
    params:
      timeout: 180

routers:
  - from: "proposal_agent"
    to: "review_gate"
  - from: "review_gate"
    condition:
      input: "context:review_gate.approval"
      routes:
        "approve": "executor_agent"
        "modify": "proposal_agent"    # loops back - feedback in proposal_agent history
        "reject": "end"
        "default_route": "end"
  - from: "executor_agent"
    to: "end"

flow:
  entry_point: "proposal_agent"
```

### Flow avec préférence de taille de modèle {#flow-with-model-size-preference}

Achemine les tâches légères vers un modèle plus petit et les tâches complexes vers un modèle plus grand :

```yaml
version: "v1"
environment: ambient

components:
  - name: "explorer"
    type: AgentComponent
    prompt_id: "explorer_agent"
    prompt_version: "^1.0.0"
    model_size_preference: "small"
    inputs: ["context:goal"]
    toolset:
      - "read_file"
      - "list_dir"
      - "find_files"
    ui_log_events:
      - "on_tool_execution_success"

  - name: "implementer"
    type: AgentComponent
    prompt_id: "implementer_agent"
    prompt_version: "^1.0.0"
    model_size_preference: "large"
    inputs:
      - from: "context:goal"
        as: "goal"
      - from: "context:explorer.final_answer"
        as: "codebase_context"
    toolset:
      - "read_file"
      - "edit_file"
      - "create_file_with_contents"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

routers:
  - from: "explorer"
    to: "implementer"
  - from: "implementer"
    to: "end"

flow:
  entry_point: "explorer"
```

### Flow multi-agent avec superviseur {#multi-agent-supervisor-flow}

```yaml
version: "v1"
environment: ambient

components:
  - name: "developer"
    type: AgentComponent
    description: "Implements code changes, creates and edits files based on requirements."
    prompt_id: "developer_agent"
    prompt_version: "^1.0.0"
    toolset:
      - "read_file"
      - "edit_file"
      - "create_file_with_contents"
      - "list_dir"
      - "find_files"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"

  - name: "tester"
    type: AgentComponent
    description: "Writes and runs automated tests to verify code correctness."
    prompt_id: "tester_agent"
    prompt_version: "^1.0.0"
    toolset:
      - "read_file"
      - "create_file_with_contents"
      - "run_command"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"

  - name: "supervisor"
    type: AgentComponent
    prompt_id: "supervisor_agent"
    prompt_version: "^1.0.0"
    inputs: ["context:goal"]
    subagents:
      - name: "developer"
      - name: "tester"
    max_delegations: 20
    toolset:
      - "get_issue"
    ui_log_events:
      - "on_agent_final_answer"
      - "on_tool_execution_success"
      - "on_tool_execution_failed"

routers:
  - from: "supervisor"
    to: "end"

flow:
  entry_point: "supervisor"
```

### Flow chat-partial pour la revue de code conversationnelle {#chat-partial-flow-for-conversational-code-review}

```yaml
version: "v1"
environment: chat-partial

components:  # exactly one AgentComponent when using chat-partial
  - name: "code_analyzer"
    type: AgentComponent
    prompt_id: "code_review_prompt"
    ui_log_events: ["on_agent_final_answer"]
    inputs:
      - from: "context:goal"
        as: "mr_link"
    toolset: ["read_file", "list_dir"]

prompts:
  - prompt_id: "code_review_prompt"
    name: "Code Review Prompt"
    unit_primitives: []
    prompt_template:
      system: |
        You are an experienced software developer. Conduct a thorough code review
        and mentor engineers on best practices.
      user: |
        Please conduct a code review for the merge request at: {{ mr_link }}
      placeholder: history
    params:
      timeout: 180

routers: []
flow: {}
```

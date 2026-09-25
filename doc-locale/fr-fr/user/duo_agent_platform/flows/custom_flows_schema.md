---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Schéma YAML de flow personnalisé
---

{{< details >}}

- Édition : [Gratuite](../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated {{< /details >}}

{{< history >}}

- Passage en [disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/602415) dans GitLab 19.2.

{{< /history >}}

Les flows personnalisés utilisent la syntaxe de la [spécification flow registry v1](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/flow_registry/v1.md). La spécification v1 définit la structure YAML complète, notamment les champs `version`, `environment`, `components`, `prompts`, `routers` et `flow`.

Certains champs de la spécification v1 sont restreints dans les flows personnalisés. Pour plus d'informations, consultez [les champs restreints](#restricted-fields).

La configuration YAML a également une taille maximale. Pour plus d'informations, consultez [les limites de taille de configuration](../ai_catalog.md#configuration-size-limits).

## Valeurs d'objectif par type de déclencheur {#goal-values-by-trigger-type}

Lorsque vous concevez un flow personnalisé, la valeur d'objectif dépend du type de déclencheur qui démarre le flow. Un flow peut avoir plusieurs types de déclencheurs configurés, et chaque type de déclencheur transmet une valeur différente en tant que `context:goal`. Votre flow doit gérer le format d'objectif pour chaque type de déclencheur que vous configurez.

Pour plus d'informations sur les types de déclencheurs, consultez [les déclencheurs](../triggers/_index.md).

Les composants accèdent à l'objectif via le champ `inputs` :

```yaml
components:
  - name: "my_agent"
    type: AgentComponent
    prompt_id: "my_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - "context:goal"
```

### Événements de mention {#mention-events}

Lorsqu'un utilisateur mentionne le compte de service du flow dans un commentaire, le texte complet du commentaire et le contexte de la ressource sont transmis en tant qu'objectif.

L'objectif utilise ce format :

```plaintext
Input: <comment_text>
Context: {<resource_type> IID: <iid>}
```

Par exemple, si un utilisateur écrit `@ai-my-flow Can you work on this?` sur le ticket `#2`, l'objectif est :

```plaintext
Input: @ai-my-flow Can you work on this?
Context: {Issue IID: 2}
```

### Événements Assigner et Assigner un relecteur {#assign-and-assign-reviewer-events}

Lorsque le compte de service du flow est assigné à un ticket ou à une merge request, ou assigné en tant que relecteur, l'IID de la ressource est transmis en tant qu'objectif.

Par exemple, si le compte de service du flow est assigné en tant que relecteur sur la merge request `!10`, la valeur de `context:goal` est `10`.

Utilisez l'IID avec `context:project_id` pour lire la ressource :

```yaml
components:
  - name: "review_mr"
    type: AgentComponent
    prompt_id: "review_mr_prompt"
    inputs:
      - from: "context:project_id"
        as: "project_id"
      - from: "context:goal"
        as: "mr_iid"
```

### Événements de pipeline {#pipeline-events}

Lorsqu'un événement de pipeline déclenche le flow, la totalité du [payload du webhook d'événement de pipeline](../../project/integrations/webhook_events.md#pipeline-events) est transmise en tant qu'objectif.

## Propriétés de niveau supérieur facultatives {#optional-top-level-properties}

### `coding_environment` {#coding_environment}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/606480) dans GitLab 19.3.

{{< /history >}}

La propriété facultative `coding_environment` déclare le type d'environnement de codage dont le flow a besoin au démarrage d'une charge de travail.

| Valeur | Description |
|-------|-------------|
| `full` | Valeur par défaut lorsqu'elle n'est pas renseignée. Un clone du dépôt, des scripts de configuration, des hooks Git et le cache de dépendances. À utiliser pour les flows qui lisent ou écrivent des fichiers du dépôt. |
| `none` | Aucun clone du dépôt. Les scripts de configuration et le cache de dépendances sont ignorés. Le hook Git de session Duo est toujours installé, de sorte qu'un flow qui clone lui-même le dépôt conserve ses commits attribués à Duo. À utiliser pour les flows uniquement via API qui interagissent exclusivement avec les API GitLab et n'ont pas besoin de dépôt local. Les outils d'agent qui lisent ou écrivent des fichiers du dépôt n'ont rien sur quoi agir. La valeur `none` ne bloque pas l'accès au dépôt. Un flow disposant de l'outil `run_command` peut toujours cloner lui-même le dépôt. La propriété contrôle uniquement ce que GitLab prépare avant le démarrage du flow. |

Utilisez la valeur `full` lorsque le flow nécessite un checkout, afin que le clone s'effectue une seule fois, en amont, et non pendant l'exécution.

Si vous ajoutez une valeur autre que `full` ou `none`, la validation du schéma échoue et le flow ne s'exécute pas.

Si vous n'ajoutez pas la propriété `coding_environment`, le flow reçoit l'environnement complet et conserve l'accès au dépôt.

Exemple :

```yaml
version: v1
environment: ambient
coding_environment: none
components:
  - name: "api_agent"
    type: AgentComponent
    prompt_id: "my_api_prompt"
    inputs:
      - "context:goal"
routers:
  - from: "api_agent"
    to: end
flow:
  entry_point: "api_agent"
```

## Champs restreints {#restricted-fields}

Certains champs et fonctionnalités de la spécification v1 sont restreints afin de garantir le bon fonctionnement des flows personnalisés dans GitLab.

### `environment` {#environment}

Le champ `environment` ne prend en charge que la valeur `ambient` dans les flows personnalisés.

Les valeurs `chat` et `chat-partial` ne sont pas prises en charge.

### `model` dans les prompts {#model-in-prompts}

Le champ `model` à l'intérieur d'une entrée `prompts` n'est pas pris en charge.

Le modèle est déterminé par le fournisseur de modèle configuré dans les paramètres de votre groupe ou instance.

### Champs `AgentComponent` {#agentcomponent-fields}

Les champs `response_schema_id` et `response_schema_version` ne sont pas pris en charge.

### Champs `OneOffComponent` {#oneoffcomponent-fields}

Le champ `ui_role_as` n'est pas pris en charge.

### `stop` dans les paramètres de prompt {#stop-in-prompt-parameters}

Le champ `stop` n'est pas pris en charge à l'intérieur d'une entrée `params`.

### Champs de niveau supérieur {#top-level-fields}

Les champs `name`, `description` et `product_group` de la spécification v1 ne sont pas pris en charge. Les flows personnalisés rejettent ces champs.

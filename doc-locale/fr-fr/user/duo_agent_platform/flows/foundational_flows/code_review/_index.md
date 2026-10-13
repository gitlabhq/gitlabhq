---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Flow Code Review
---

{{< details >}}

- Édition : [Gratuite](../../../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- LLM : Anthropic Claude Sonnet 5 Vertex
- LLM pour GitLab 19.0 ou antérieur : [LLM par défaut](../../../../gitlab_duo/model_selection.md#default-models) pour GitLab Duo Code Review, la version non agentique.
- Sur GitLab.com, [sélectionnez un modèle différent](../../../model_selection.md#select-a-model-for-a-feature) en utilisant le paramètre **Agentic Code Review**.
- Sur GitLab Self-Managed et GitLab Dedicated, [sélectionnez un modèle différent](../../../../../administration/gitlab_duo/model_selection.md#select-a-model-for-code-review-flow) en utilisant le paramètre approprié à votre version de GitLab.
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduction en [version bêta](../../../../../policy/development_stages_support.md) dans GitLab [18.7](https://gitlab.com/groups/gitlab-org/-/epics/18645) [avec le feature flag](../../../../../administration/feature_flags/_index.md) `duo_code_review_on_agent_platform`. Désactivé par défaut.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) dans GitLab 18.8. [Suppression](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209) du feature flag `duo_code_review_on_agent_platform`
- Disponibilité pour l'édition Gratuite sur GitLab.com avec des GitLab Credits dans GitLab 18.10.
- LLM [mis à jour](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/5555) vers Claude Sonnet 4.6 Vertex le 20 mai 2026.
- LLM [mis à jour](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/merge_requests/6422) vers Claude Sonnet 5 Vertex le 6 août 2026.

{{< /history >}}

> [!note]
> Selon vos paramètres d'extension et de groupe, GitLab exécute l'une des deux fonctionnalités de revue de code :
>
> - Flux de revue de code : la version agentique, qui fait partie de GitLab Duo Agent Platform.
> - Revue de code GitLab Duo : la version non agentique, disponible uniquement pour les utilisateurs disposant du module d'extension GitLab Duo Enterprise.
>
> Cette page décrit la version agentique.
>
> Pour plus d'informations sur la comparaison des deux fonctionnalités et sur l'activation du flow Code Review pour les sièges GitLab Duo Enterprise, consultez [Utiliser GitLab Duo pour réviser votre code](../../../../project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code).

Le flow Code Review simplifie les revues de code grâce à l'IA agentique.

Ce flow :

- Analyse les modifications de code.
- Fournit une meilleure compréhension du contexte, notamment de la structure du dépôt et des dépendances entre fichiers.
- Fournit des commentaires de revue détaillés assortis de retours exploitables.
- Prend en charge des instructions de revue personnalisées adaptées à votre projet.

## Prérequis {#prerequisites}

- Satisfaire aux [prérequis pour GitLab Duo Agent Platform](../../../_index.md#prerequisites).
- Activer **Autoriser les flows par défaut** et **Revue de code** [pour le groupe principal](../_index.md#turn-foundational-flows-on-or-off).
- Disposer du rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.
- [Définir un espace de nommage GitLab Duo par défaut](../../../../profile/preferences.md#set-a-default-gitlab-duo-namespace) si vous appartenez à plusieurs espaces de nommage GitLab Duo.
- [Configurez vos propres runners](../../execution/_index.md#configure-runners-to-execute-flows) avec le tag `gitlab--duo` et un exécuteur prenant en charge les images Docker, ou activez les [runners hébergés par GitLab](../../../../../ci/runners/hosted_runners/_index.md) pour votre projet. Le flow Code Review s'exécute en tant que job CI/CD et nécessite un runner pour fonctionner.

## Utiliser le flow {#use-the-flow}

Le flow Code Review est disponible dans l'interface GitLab et via l'API REST.

### Demander une revue de code dans l'interface GitLab {#request-a-review-in-the-gitlab-ui}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/20484) de l'utilisation d'un flow dans une conversation GitLab Duo Agentic Chat dans GitLab 19.2 [avec le feature flag](../../../../../administration/feature_flags/_index.md) `agentic_foundational_flow_tool`. Activé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Pour demander une revue de code dans l'interface GitLab :

1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et repérez votre merge request.
1. Utilisez l'une des méthodes suivantes pour demander une revue :
   - Désigner `@GitLabDuo` comme relecteur
   - Saisir l'action rapide `/assign_reviewer @GitLabDuo` dans une zone de commentaire
   - Mentionner `@GitLabDuo` dans une zone de commentaire et demander une revue
   - Dans la barre latérale GitLab Duo, ouvrez une conversation Agentic Chat nouvelle ou existante. Demandez à Agentic Chat d'examiner la merge request.
1. Pour surveiller la progression, dans la barre latérale gauche, sélectionnez **IA** > **Sessions**.

   Si vous êtes dans Agentic Chat, vous pouvez également effectuer les actions suivantes :
   - Voir la progression dans la conversation Chat.
   - Sélectionnez **Afficher la session de l'agent** dans la conversation.

### Demander une revue de code via l'API REST {#request-a-review-through-the-rest-api}

{{< details >}}

- Statut : version expérimentale

{{< /details >}}

{{< history >}}

- Déclenchement de la revue de code via l'API REST [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250117) dans GitLab 19.4.

{{< /history >}}

Pour demander une revue de code via l'API REST, [déclenchez le flow](../../../../../api/duo_agent_platform_flows.md#trigger-a-flow) avec ces paramètres :

- Définissez `project_id` sur le projet qui contient la merge request.
- Définissez `goal` sur l'IID de la merge request à réviser, ou sur l'URL complète de cette merge request.
- Attribuez la valeur `code_review/v1` à `workflow_definition`. Vous pouvez également définir `ai_catalog_item_consumer_id` sur l'[ID du consommateur](../../../../../api/duo_agent_platform_flows.md#look-up-the-consumer-id) pour le flow Code Review.
- Définissez `start_workflow` sur `true` pour démarrer la revue immédiatement.

L'exemple suivant déclenche une revue de code de la merge request `42` :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "42",
    "workflow_definition": "code_review/v1",
    "start_workflow": true
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

## Interagir avec GitLab Duo dans les revues {#interact-with-gitlab-duo-in-reviews}

Après une revue, vous pouvez discuter du retour avec GitLab Duo dans les interactions de commentaires. Les interactions sont une fonctionnalité distincte du flow Code Review.

Pour plus d'informations, consultez [interagir avec GitLab Duo](../../../../project/merge_requests/duo_in_merge_requests.md#interact-with-gitlab-duo).

## Prise en compte du contexte {#contextual-awareness}

Le flow Code Review se déroule en deux étapes :

1. Pré-analyse : le flow inspecte les diffs de la merge request et s'en sert pour repérer le contexte associé à récupérer dans le dépôt du projet. La pré-analyse inclut généralement les listes de répertoires et le contenu des fichiers connexes, comme les tests et les dépendances référencés par les modifications. Le contexte exact récupéré dépend de l'analyse des diffs.
1. Revue : le flow exécute la revue en fournissant les données suivantes au grand modèle de langage. L'étape de revue ne peut pas récupérer de contexte supplémentaire à la demande.

   - Les résultats de l'étape de pré-analyse
   - Le titre de la merge request
   - La description de la merge request
   - Les diffs de la merge request
   - Les versions originales des fichiers
   - Les noms de fichiers
   - Les instructions de revue personnalisées

Pour définir le contenu à exclure, consultez la section [Exclure le contexte de GitLab Duo](../../../context.md#exclude-context-from-gitlab-duo).

### Limites applicables aux fichiers et au contexte {#file-and-context-limits}

Le flow Code Review applique deux limites pour que la taille de l'invite reste exploitable :

- Pour les fichiers de plus de 10 000 lignes, seul le diff est envoyé au modèle. Le contenu complet du fichier n'est pas inclus.
- Le contexte total collecté par la pré-analyse est limité à environ 1 Mio. Lorsque cette limite est dépassée, le contexte est tronqué à environ 800 Kio avant l'exécution de l'étape de revue.

Ces limites s'appliquent aux données collectées par le flow et sont indépendantes de la fenêtre de contexte du [modèle sélectionné](../../../model_selection.md).

Pour les merge requests très volumineuses, la revue peut ne pas tenir compte d'une partie du contexte tronqué. Pour réduire ce risque :

- Divisez la merge request en merge requests plus petites.
- [Excluez le contexte](../../../context.md#exclude-context-from-gitlab-duo) des fichiers qui ne sont pas pertinents pour la revue
- Demandez à un propriétaire de groupe ou à un administrateur d'instance de sélectionner un modèle différent pour [GitLab.com](../../../model_selection.md#select-a-model-for-a-feature) ou [GitLab Self-Managed et GitLab Dedicated](../../../../../administration/gitlab_duo/model_selection.md#select-a-model-for-code-review-flow).

## Instructions de revue de code personnalisées {#custom-code-review-instructions}

Personnalisez le comportement du flow Code Review à l'aide d'un fichier `mr-review-instructions.yaml`.

Vous pouvez orienter GitLab Duo à l'aide d'instructions de revue propres au dépôt :

- Mettre l'accent sur certains aspects de la qualité du code, comme la sécurité, les performances et la maintenabilité
- Appliquer les normes de codage et les bonnes pratiques propres à votre projet
- Cibler des modèles de fichiers précis au moyen de critères de revue adaptés
- Fournir des explications plus détaillées pour certains types de modifications

Le flow Code Review ne consulte pas les fichiers `AGENTS.md` et `SKILL.md`.

Pour configurer des instructions personnalisées, consultez la section [Personnaliser les instructions de revue pour GitLab Duo](../../../customize/review_instructions.md).

## Revues automatiques {#automatic-reviews}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/506537) des revues automatiques pour les projets en paramètre d'interface dans GitLab 18.0.
- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/554070) des revues automatiques pour les groupes dans GitLab 18.4 en tant que [version bêta](../../../../../policy/development_stages_support.md#beta) [avec un feature flag](../../../../../administration/feature_flags/_index.md) nommé `cascading_auto_duo_code_review_settings`. Désactivé par défaut.
- [Suppression](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240) du feature flag `cascading_auto_duo_code_review_settings` dans GitLab 18.7.
- Les revues automatiques pour les groupes et les applications [activées par défaut](https://gitlab.com/gitlab-org/gitlab/-/work_items/592822) pour les nouveaux essais GitLab Duo sur GitLab.com dans GitLab 19.1.

{{< /history >}}

Les revues automatiques de GitLab Duo garantissent que toutes les merge requests de votre projet ou groupe reçoivent une revue initiale.

Lorsqu'un utilisateur crée une merge request, GitLab Duo la révise automatiquement, sauf si :

- Elle est marquée comme brouillon. Pour que GitLab Duo passe la merge request en revue, marquez-la comme prête.
- Elle ne contient aucune modification. Pour que GitLab Duo passe la merge request en revue, ajoutez-y des modifications.
- Elle correspond à une ou plusieurs règles d'exclusion que vous avez définies. Pour que GitLab Duo révise la merge request, demandez manuellement une revue.

Pour les nouveaux essais GitLab Duo sur GitLab.com à partir de GitLab 19.1, les revues automatiques sont activées par défaut pour les groupes.

{{< tabs >}}

{{< tab title="Projet" >}}

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour activer les revues automatiques pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Requêtes de fusion**.
1. Dans la section **Revue de code GitLab Duo**, sélectionnez **Autoriser l'analyse automatique de GitLab Duo**.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< tab title="Groupe" >}}

Prérequis :

- Le rôle Propriétaire pour le groupe.

Pour activer les revues automatiques pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Requêtes de fusion**.
1. Dans la section **Revue de code GitLab Duo**, sélectionnez **Autoriser l'analyse automatique de GitLab Duo**.
1. Sélectionnez **Enregistrer les modifications**.

Les paramètres se propagent du groupe vers le projet. Les paramètres les plus spécifiques remplacent les paramètres plus généraux.

{{< /tab >}}

{{< /tabs >}}

Après avoir activé les revues automatiques, vous pouvez définir des règles pour exclure des merge requests spécifiques.

Pour savoir comment l'utilisation des crédits est attribuée aux revues automatiques, consultez la section [Déterminer quelle fonctionnalité de revue de code s'exécute](../../../../project/merge_requests/duo_in_merge_requests.md#determine-which-review-feature-runs).

### Exclure des merge requests pour un projet {#exclude-merge-requests-for-a-project}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240236) dans GitLab 19.2 en [version bêta](../../../../../policy/development_stages_support.md#beta) [avec le feature flag](../../../../../administration/feature_flags/_index.md) `duo_code_review_automated_rules`. Activé par défaut.
- [Disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245852) dans GitLab 19.3. Le feature flag `duo_code_review_automated_rules` a été supprimé.

{{< /history >}}

Lorsque les révisions automatiques sont activées pour un projet, GitLab Duo révise chaque merge request éligible. Pour exclure des merge requests spécifiques, définissez des règles d'exclusion dans un fichier `.gitlab/duo/mr-review-automated-rules.yaml`.

Les règles d'exclusion empêchent uniquement les révisions automatiques. Vous pouvez toujours demander une révision manuellement pour toute merge request exclue.

Pour définir des règles d'exclusion :

1. À la racine de votre dépôt, créez un répertoire `.gitlab/duo` s'il n'existe pas déjà.
1. Dans le répertoire `.gitlab/duo`, créez un fichier nommé `mr-review-automated-rules.yaml`.
1. Ajoutez des règles d'exclusion en utilisant le format suivant :

   ```yaml
   exclude:
     target_branches:
       - <pattern>
     source_branches:
       - <pattern>
     authors:
       - <pattern>
   ```

   Chaque clé est optionnelle. GitLab Duo ignore la révision automatique lorsqu'une merge request correspond à un modèle dans n'importe quelle catégorie :

   - `target_branches` : correspond au nom de la branche cible de la merge request.
   - `source_branches` : correspond au nom de la branche source de la merge request.
   - `authors` : correspond au nom d'utilisateur de l'auteur de la merge request.

   Les modèles prennent en charge la correspondance par caractères génériques (glob). Par exemple, `dependabot/*` correspond à toute branche source commençant par `dependabot/`.

   Par exemple, pour ignorer les révisions automatiques des merge requests ciblant une branche de release ou créées par un compte bot :

   ```yaml
   exclude:
     target_branches:
       - "release/*"
     authors:
       - "*-bot"
   ```

1. Commitez le fichier sur la branche par défaut de votre dépôt.

GitLab Duo lit les règles d'exclusion depuis la branche par défaut de votre dépôt. GitLab Duo n'applique pas les règles sur les autres branches.

### Exclure des merge requests pour un groupe {#exclude-merge-requests-for-a-group}

Pour définir des règles d'exclusion pour tous les projets d'un groupe et de ses sous-groupes, spécifiez un projet à utiliser comme modèle. Le projet modèle doit contenir un fichier `.gitlab/duo/mr-review-automated-rules.yaml`.

GitLab Duo combine les règles d'exclusion du projet modèle du groupe avec les règles définies dans le projet individuel. Si la même catégorie est définie aux deux niveaux, les règles du projet ont la priorité. Lorsqu'un groupe et ses sous-groupes définissent chacun un projet modèle, GitLab Duo combine les règles de chaque niveau.

> [!note]
> Si vous avez déjà configuré un projet pour stocker les [instructions de revue personnalisées](../../../customize/review_instructions.md#configure-custom-review-instructions-for-a-group) pour votre groupe, stockez votre `mr-review-automated-rules.yaml` dans le même projet. Vous ne pouvez spécifier qu'un seul projet pour personnaliser la revue de code pour un groupe, GitLab vérifie donc automatiquement ce projet pour les règles d'exclusion également. Vous n'avez pas besoin de suivre à nouveau les étapes ci-dessous.

Prérequis :

- Le rôle Propriétaire pour le groupe.
- Un projet du groupe contient les règles d'exclusion que vous souhaitez définir.

Pour configurer des règles d'exclusion pour un groupe :

{{< tabs >}}

{{< tab title="GitLab.com" >}}

Pour un groupe principal :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe principal.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Fonctionnalités de GitLab Duo** > **Personnaliser la revue de code**, sélectionnez le projet qui contient le fichier `.gitlab/duo/mr-review-automated-rules.yaml`.
1. Sélectionnez **Enregistrer les modifications**.

Pour un groupe ou un sous-groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe ou votre sous-groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Fonctionnalités de GitLab Duo**.
1. Sous **Personnaliser la revue de code**, sélectionnez le projet contenant le fichier `.gitlab/duo/mr-review-automated-rules.yaml`.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< tab title="GitLab Self-Managed et GitLab Dedicated" >}}

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe ou votre sous-groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Fonctionnalités de GitLab Duo**.
1. Sous **Personnaliser la revue de code**, sélectionnez le projet contenant le fichier `.gitlab/duo/mr-review-automated-rules.yaml`.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< /tabs >}}

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec le flow Code Review, vous pouvez rencontrer des problèmes.

Pour obtenir des informations sur la résolution de ces problèmes, consultez [Dépannage](troubleshooting.md).

## Sujets connexes {#related-topics}

- [GitLab Duo dans les merge requests](../../../../project/merge_requests/duo_in_merge_requests.md)
- [Modèles d'IA de GitLab Duo Agent Platform](../../../model_selection.md)
- [Activer le flow Code Review pour les sièges GitLab Duo Enterprise](../../../../project/merge_requests/duo_in_merge_requests.md#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats).

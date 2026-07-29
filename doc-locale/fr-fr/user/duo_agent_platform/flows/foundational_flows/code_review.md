---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Flow Code Review
---

{{< details >}}

- Édition : [Gratuite](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- LLM : Anthropic Claude Sonnet 4.6 Vertex
- [Sélectionnez un autre modèle](../../model_selection.md) avec le paramètre **Revue de code agentique**.
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduction en tant que [version bêta](../../../../policy/development_stages_support.md) dans GitLab [18.7](https://gitlab.com/groups/gitlab-org/-/epics/18645) [avec un feature flag](../../../../administration/feature_flags/_index.md) nommé `duo_code_review_on_agent_platform`. Désactivés par défaut.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) dans GitLab 18.8. Le feature flag `duo_code_review_on_agent_platform` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209).
- Disponibilité dans l'édition Gratuite sur GitLab.com avec GitLab Credits dans GitLab 18.10.
- [Mise à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876) du grand modèle de langage (LLM) vers Claude Sonnet 4.6 Vertex dans GitLab 19.1.

{{< /history >}}

> [!note]
> Selon vos paramètres d'extension et de groupe, GitLab exécute l'une des deux fonctionnalités de revue de code :
>
> - Flux de revue de code : la version agentique, qui fait partie de GitLab Duo Agent Platform.
> - Revue de code GitLab Duo : la version non agentique, disponible uniquement pour les utilisateurs disposant du module complémentaire GitLab Duo Enterprise.
>
> Cette page décrit la version agentique.
>
> Pour plus d'informations sur la comparaison des deux fonctionnalités et sur l'activation du flow Code Review pour les sièges GitLab Duo Enterprise, consultez [utiliser GitLab Duo pour réviser votre code.](../../../project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code).

Le flow Code Review simplifie les revues de code grâce à l'IA agentique.

Ce flow :

- Analyse les modifications de code.
- Fournit une meilleure compréhension du contexte, notamment de la structure du dépôt et des dépendances entre fichiers.
- Fournit des commentaires de revue détaillés assortis de retours exploitables.
- Prend en charge des instructions de revue personnalisées adaptées à votre projet.

Ce flow est disponible uniquement dans l'interface utilisateur de GitLab.

## Prérequis {#prerequisites}

- Satisfaire aux [prérequis pour GitLab Duo Agent Platform](../../_index.md#prerequisites).
- Activer **Autoriser les flows par défaut** et **Revue de code** [pour le groupe principal](_index.md#turn-foundational-flows-on-or-off).
- Disposer du rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.
- [Définir un espace de nommage GitLab Duo par défaut](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace) si vous appartenez à plusieurs espaces de nommage GitLab Duo.
- [Configurez vos propres runners](../execution.md#configure-runners-to-execute-flows) avec le tag `gitlab--duo` et un exécuteur prenant en charge les images Docker, ou activez les [runners hébergés par GitLab](../../../../ci/runners/hosted_runners/_index.md) pour votre projet. Le flow Code Review s'exécute en tant que job CI/CD et nécessite un runner pour fonctionner.

## Utiliser le flow {#use-the-flow}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/20484) de l'utilisation d'un flow dans une conversation GitLab Duo Agentic Chat dans GitLab 19.2 [avec un feature flag](../../../../administration/feature_flags/_index.md) nommé `agentic_foundational_flow_tool`. Activé par défaut.

{{< /history >}}

> [!flag]
> Un feature flag contrôle la disponibilité de cette fonctionnalité. Pour plus d'informations, consultez l'historique.

Pour utiliser le flow Code Review dans une merge request :

1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et repérez votre merge request.
1. Utilisez l'une des méthodes suivantes pour demander une revue :
   - Désigner `@GitLabDuo` comme relecteur
   - Saisir l'action rapide `/assign_reviewer @GitLabDuo` dans une zone de commentaire
   - Mentionner `@GitLabDuo` dans une zone de commentaire et demander une revue
   - Dans la barre latérale GitLab Duo, ouvrez une conversation Agentic Chat nouvelle ou existante. Demandez à Agentic Chat d'examiner la merge request.
1. Pour surveiller la progression, dans la barre latérale gauche, sélectionnez **IA** > **Sessions**.

   Si vous êtes dans Agentic Chat, vous pouvez également effectuer les actions suivantes :
   - Voir la progression dans la conversation Chat.
   - Sélectionnez **View Agent Session** dans la conversation.

## Interagir avec GitLab Duo dans les revues {#interact-with-gitlab-duo-in-reviews}

{{< history >}}

- [Mise à jour](https://gitlab.com/gitlab-org/gitlab/-/work_items/601102) des interactions dans les commentaires dans GitLab 19.1 pour utiliser GitLab Duo Agent Platform.

{{< /history >}}

En plus de désigner GitLab Duo comme relecteur, vous pouvez interagir avec GitLab Duo de l'une des manières suivantes :

- Répondre aux commentaires de revue pour demander des précisions ou d'autres approches
- Mentionner `@GitLabDuo` dans un fil de discussion pour poser des questions complémentaires

Les discussions avec GitLab Duo dans les commentaires utilisent GitLab Duo Agent Platform et [consomment des crédits](../../../../subscriptions/gitlab_credits.md).

Les commentaires transmis à GitLab Duo n'influencent pas les revues ultérieures des autres merge requests. L'ajout de cette fonctionnalité est proposé dans le [ticket 560116](https://gitlab.com/gitlab-org/gitlab/-/issues/560116).

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

Pour définir le contenu à exclure, consultez la section [Exclure le contexte de GitLab Duo](../../context.md#exclude-context-from-gitlab-duo).

### Limites applicables aux fichiers et au contexte {#file-and-context-limits}

Le flow Code Review applique deux limites pour que la taille de l'invite reste exploitable :

- Pour les fichiers de plus de 10 000 lignes, seul le diff est envoyé au modèle. Le contenu complet du fichier n'est pas inclus.
- Le contexte total collecté par la pré-analyse est limité à environ 1 Mio. Lorsque cette limite est dépassée, le contexte est tronqué à environ 800 Kio avant l'exécution de l'étape de revue.

Ces limites s'appliquent aux données collectées par le flow et sont indépendantes de la fenêtre de contexte du [modèle sélectionné](../../model_selection.md).

Pour les merge requests très volumineuses, la revue peut ne pas tenir compte d'une partie du contexte tronqué. Pour réduire ce risque :

- Diviser la merge request en merge requests plus petites
- [Exclure le contexte](../../context.md#exclude-context-from-gitlab-duo) des fichiers qui ne sont pas pertinents pour la revue

## Instructions de revue de code personnalisées {#custom-code-review-instructions}

Personnalisez le comportement du flow Code Review à l'aide d'un fichier `mr-review-instructions.yaml`.

Vous pouvez orienter GitLab Duo à l'aide d'instructions de revue propres au dépôt :

- Mettre l'accent sur certains aspects de la qualité du code, comme la sécurité, les performances et la maintenabilité
- Appliquer les normes de codage et les bonnes pratiques propres à votre projet
- Cibler des modèles de fichiers précis au moyen de critères de revue adaptés
- Fournir des explications plus détaillées pour certains types de modifications

Le flow Code Review ne consulte pas les fichiers `AGENTS.md` et `SKILL.md`.

Pour configurer des instructions personnalisées, consultez la section [Personnaliser les instructions de revue pour GitLab Duo](../../customize/review_instructions.md).

## Revues automatiques de GitLab Duo pour un projet {#automatic-reviews-from-gitlab-duo-for-a-project}

{{< history >}}

- [Conversion](https://gitlab.com/gitlab-org/gitlab/-/issues/506537) en paramètre d'interface utilisateur dans GitLab 18.0.

{{< /history >}}

Les revues automatiques de GitLab Duo déclenchent une revue initiale pour toutes les merge requests de votre projet. Après la création d'une merge request, GitLab Duo la passe en revue, sauf si :

- Elle est marquée comme brouillon. Pour que GitLab Duo passe la merge request en revue, marquez-la comme prête.
- Elle ne contient aucune modification. Pour que GitLab Duo passe la merge request en revue, ajoutez-y des modifications.

Prérequis :

- Vous devez disposer au minimum du [rôle Chargé de maintenance](../../../permissions.md) dans un projet.

Pour que `@GitLabDuo` passe automatiquement les merge requests en revue :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Requêtes de fusion**.
1. Dans la section **Revue de code GitLab Duo**, sélectionnez **Autoriser l'analyse automatique de GitLab Duo**.
1. Sélectionnez **Enregistrer les modifications**.

Pour savoir comment l'utilisation des crédits est attribuée aux revues automatiques, consultez la section [Déterminer quelle fonctionnalité de revue de code s'exécute](../../../project/merge_requests/duo_in_merge_requests.md#determine-which-review-feature-runs).

## Revues automatiques de GitLab Duo pour les groupes et les applications {#automatic-reviews-from-gitlab-duo-for-groups-and-applications}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/554070) dans GitLab 18.4 en tant que [version bêta](../../../../policy/development_stages_support.md#beta) [avec un feature flag](../../../../administration/feature_flags/_index.md) nommé `cascading_auto_duo_code_review_settings`. Désactivés par défaut.
- [Suppression](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240) du feature flag `cascading_auto_duo_code_review_settings` dans GitLab 18.7.
- [Activation par défaut](https://gitlab.com/gitlab-org/gitlab/-/work_items/592822) pour les nouveaux essais GitLab Duo sur GitLab.com dans GitLab 19.1.

{{< /history >}}

Utilisez les paramètres de groupe ou d'application pour activer les revues automatiques pour plusieurs projets.

Pour les nouveaux essais GitLab Duo sur GitLab.com à partir de GitLab 19.1, les revues automatiques sont activées par défaut pour les groupes.

Prérequis :

- Pour activer les revues automatiques pour les groupes, vous devez disposer du rôle Propriétaire dans le groupe.
- Pour activer les revues automatiques pour tous les projets, vous devez disposer d'un accès administrateur.

Pour activer les revues automatiques pour les groupes :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Requêtes de fusion**.
1. Dans la section **Revue de code GitLab Duo**, sélectionnez **Autoriser l'analyse automatique de GitLab Duo**.
1. Sélectionnez **Enregistrer les modifications**.

Pour activer les revues automatiques pour tous les projets :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Dans la section **Revue de code GitLab Duo**, sélectionnez **Autoriser l'analyse automatique de GitLab Duo**.
1. Sélectionnez **Enregistrer les modifications**.

Les paramètres s'appliquent en cascade de l'application au groupe, puis au projet. Les paramètres les plus spécifiques remplacent les paramètres plus généraux.

Pour savoir comment l'utilisation des crédits est attribuée aux revues automatiques, consultez la section [Déterminer quelle fonctionnalité de revue de code s'exécute](../../../project/merge_requests/duo_in_merge_requests.md#determine-which-review-feature-runs).

## Exclure des merge requests des révisions automatiques {#exclude-merge-requests-from-automatic-reviews}

{{< details >}}

- Statut : version bêta

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240236) dans GitLab 19.2 en tant que [version bêta](../../../../policy/development_stages_support.md#beta) [avec un flag](../../../../administration/feature_flags/_index.md) nommé `duo_code_review_automated_rules`. Activé par défaut.

{{< /history >}}

> [!flag]
> Un feature flag contrôle la disponibilité de cette fonctionnalité. Pour plus d'informations, consultez l'historique.

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

> [!note]
> Si vous utilisez des [instructions de révision personnalisées pour un groupe](../../customize/review_instructions.md#configure-custom-review-instructions-for-a-group), ajoutez vos règles d'exclusion au même projet modèle. Vous n'avez pas besoin de spécifier à nouveau le projet modèle dans l'interface utilisateur. GitLab Duo lit automatiquement le fichier `mr-review-automated-rules.yaml`.

GitLab Duo combine les règles d'exclusion du projet modèle du groupe avec les règles définies dans le projet individuel. Si la même catégorie est définie aux deux niveaux, les règles du projet ont la priorité. Lorsqu'un groupe et ses sous-groupes définissent chacun un projet modèle, GitLab Duo combine les règles de chaque niveau.

Prérequis :

- Le rôle Owner pour le groupe.
- Un projet du groupe contient les règles d'exclusion que vous souhaitez définir.

Pour configurer des règles d'exclusion pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général** > **Fonctionnalités de GitLab Duo**.
1. Sous **Customize code review**, sélectionnez le projet contenant le fichier `.gitlab/duo/mr-review-automated-rules.yaml`.
1. Sélectionnez **Enregistrer les modifications**.

## Dépannage {#troubleshooting}

### `Error DCR4000` {#error-dcr4000}

Vous pouvez obtenir une erreur indiquant `Code Review Flow is not enabled. Contact your group administrator to enable the foundational flow in the top-level group. Error code: DCR4000`.

Cette erreur se produit lorsque les [flows par défaut](_index.md) ou le flow Code Review sont désactivés.

Contactez votre administrateur et demandez-lui d'activer le flow Code Review pour votre groupe principal.

### `Error DCR4001` {#error-dcr4001}

Vous pouvez obtenir une erreur indiquant `Code Review Flow is enabled but the service account needs to be verified. Contact your administrator. Error code: DCR4001`.

Cette erreur se produit lorsque le flow Code Review est activé, mais que le compte de service du groupe principal n'existe pas ou n'est pas prêt.

Demandez à votre administrateur de [vérifier que le compte de service existe](../../troubleshooting.md#foundational-flow-service-account-not-created) et de suivre les étapes pour résoudre les problèmes éventuels.

### `Error DCR4002` {#error-dcr4002}

Vous pouvez obtenir une erreur indiquant `No GitLab Credits remain for this billing period. To continue using Code Review Flow, contact your administrator. Error code: DCR4002`.

Cette erreur se produit lorsque vous avez utilisé tous les GitLab Credits qui vous ont été attribués pour la période de facturation en cours.

Contactez votre administrateur pour acheter des crédits supplémentaires ou attendez que vos crédits soient réinitialisés au début de la prochaine période de facturation.

### `Error DCR4003` {#error-dcr4003}

Vous pouvez obtenir une erreur indiquant `<User>, you don't have permission to create a pipeline for Code Review Flow in this project. Contact your administrator to update your permissions. Error code: DCR4003`.

Cette erreur se produit parce que le flow Code Review s'exécute dans un pipeline CI/CD et que vous n'avez pas l'autorisation de créer des pipelines dans ce projet.

Contactez votre administrateur et demandez-lui de vous accorder les [autorisations requises pour exécuter des pipelines](../../../permissions.md).

### `Error DCR4004` {#error-dcr4004}

Vous pouvez obtenir une erreur indiquant `<User>, you need to set a default GitLab Duo namespace to use Code Review Flow in this project. Please set a default GitLab Duo namespace in your preferences. Error code: DCR4004`.

Cette erreur se produit lorsque GitLab Duo ne parvient pas à identifier l'espace de nommage GitLab Duo par défaut de la personne qui a lancé la revue.

Définissez un espace de nommage GitLab Duo par défaut dans vos [préférences](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace), puis demandez à nouveau une revue.

### `Error DCR4005` {#error-dcr4005}

Vous pouvez obtenir une erreur indiquant `Code Review Flow could not obtain the required authentication tokens to connect to the GitLab AI Gateway and the GitLab API. Please request a new review. If the issue persists, contact your administrator. Error code: DCR4005`.

Le flow Code Review nécessite des jetons d'authentification pour se connecter à la passerelle d'IA GitLab et à l'API GitLab. Cette erreur se produit lorsque ces jetons ne peuvent pas être générés, généralement en raison d'une configuration GitLab Duo incorrecte ou d'un problème temporaire d'infrastructure.

Pour les instances autogérées, demandez à votre administrateur de vérifier la [configuration de GitLab Duo](../../../../administration/gitlab_duo/configure/_index.md).

### `Error DCR4006` {#error-dcr4006}

Vous pouvez obtenir une erreur indiquant `Code Review Flow could not add the service account to this project. Contact your administrator to verify that the service account has the required project access. Error code: DCR4006`.

Cette erreur se produit lorsque le compte de service ne peut pas être ajouté comme membre du projet. Cela peut se produire lorsqu'un verrouillage de l'appartenance au groupe est activé ou lorsque le compte de service ne dispose pas de l'accès requis.

Contactez votre administrateur et demandez-lui de vérifier que le compte de service peut être ajouté au projet avec le rôle Développeur.

### `Error DCR4007` {#error-dcr4007}

Vous pouvez obtenir une erreur indiquant `Code Review Flow is not available for this project. Contact your administrator to verify that the flow is enabled and the required configuration is in place. Error code: DCR4007`.

Cette erreur se produit lorsque le flow est désactivé ou que la configuration requise pour le projet est manquante.

Contactez votre administrateur et demandez-lui de vérifier que [le flow est activé](_index.md#turn-foundational-flows-on-or-off) pour le projet.

### `Error DCR4008` {#error-dcr4008}

Vous pouvez obtenir une erreur indiquant `Code Review Flow could not create the required CI/CD pipeline. Please request a new review. If the problem persists, contact your administrator. Error code: DCR4008`.

Cette erreur se produit lorsque le flow Code Review ne peut pas créer ou configurer le pipeline CI/CD chargé d'exécuter la revue, en raison de problèmes de disponibilité des runners ou de problèmes de configuration interne.

Essayez de relancer la revue. Si l'erreur persiste, contactez votre administrateur.

### `Error DCR4009` {#error-dcr4009}

Vous pouvez obtenir une erreur indiquant `Code Review Flow could not retrieve the source branch for this merge request. Please request a new review. Error code: DCR4009`.

Cette erreur se produit lorsque le flow Code Review ne parvient pas à récupérer la branche source de la merge request.

Essayez de relancer la revue.

### `Error DCR5000` {#error-dcr5000}

Vous pouvez obtenir une erreur indiquant `Something went wrong while starting Code Review Flow. Please try again later. Error code: DCR5000`.

Cette erreur se produit lorsque GitLab Duo Agent Platform ne parvient pas à démarrer le flow Code Review en raison d'une erreur interne.

Essayez de relancer la revue. Si l'erreur persiste, contactez votre administrateur.

### `Error DCR5001` {#error-dcr5001}

Vous pouvez obtenir une erreur indiquant `Code Review Flow completed the review but could not post the review comments. Please request a new review to try again. Error code: DCR5001`.

Cette erreur se produit lorsque le flow Code Review termine la révision mais, après plusieurs tentatives, ne peut pas publier les commentaires de révision. Cela est souvent dû à des problèmes d'infrastructure transitoires.

Demandez une nouvelle révision. Si l'erreur persiste, contactez votre administrateur.

### Contexte manquant dans les revues de merge requests volumineuses {#missing-context-in-large-merge-request-reviews}

Le flow Code Review peut ne pas tenir compte de tout le contexte lorsqu'une merge request contient de nombreux fichiers modifiés de grande taille.

Cela peut se produire lorsque les résultats de la pré-analyse dépassent les [limites applicables aux fichiers et au contexte](#file-and-context-limits) et que les données sont tronquées avant l'exécution de l'étape de revue.

Pour améliorer la revue :

- .Divisez la merge request en merge requests plus petites.
- [Excluez le contexte](../../context.md#exclude-context-from-gitlab-duo) des fichiers qui ne sont pas pertinents pour la revue
- Demandez à une personne disposant du rôle Chargé de maintenance ou Propriétaire de [sélectionner un autre modèle](../../model_selection.md) avec le paramètre **Revue de code agentique**.

### Script de diagnostic de configuration {#configuration-diagnostic-script}

Si vous ne parvenez pas à identifier la cause d'un problème du flow Code Review à partir des codes d'erreur documentés, vous pouvez exécuter un script de diagnostic pour vérifier votre configuration GitLab Duo.

Le script vérifie toute la chaîne de configuration requise pour le flow Code Review, notamment les vérifications applicables à toutes les fonctionnalités de GitLab Duo Agent Platform.

Pour en savoir plus, consultez la section [Exécuter le script de diagnostic de configuration](../../troubleshooting.md#run-the-configuration-diagnostic-script).

## Sujets connexes {#related-topics}

- [GitLab Duo dans les merge requests](../../../project/merge_requests/duo_in_merge_requests.md)
- [Modèles d'IA de GitLab Duo Agent Platform](../../model_selection.md)
- [Activer le flow Code Review pour les sièges GitLab Duo Enterprise](../../../project/merge_requests/duo_in_merge_requests.md#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats).

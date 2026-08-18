---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Utilisez les fonctionnalités assistées par IA pour obtenir des informations pertinentes sur une merge request.
title: GitLab Duo dans les merge requests
---

> [!disclaimer]

GitLab Duo est conçu pour fournir des informations contextuellement pertinentes tout au long du cycle de vie d'une merge request.

## Générer une description en résumant les modifications du code {#generate-a-description-by-summarizing-code-changes}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module complémentaire : GitLab Duo Enterprise
- Offre : GitLab.com, GitLab Self-Managed
- Statut : version bêta

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- [LLM par défaut](../../gitlab_duo/model_selection.md#default-models)
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/epics/10401) dans GitLab 16.2 en tant que [version expérimentale](../../../policy/development_stages_support.md#experiment).
- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/429882) en version bêta dans GitLab 16.10.
- À partir de GitLab 17.6, le module d'extension GitLab Duo est devenu obligatoire.
- LLM [mis à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186862) vers Claude 3.7 Sonnet dans GitLab 17.10
- Le feature flag `add_ai_summary_for_new_mr` [activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186108) dans GitLab 17.11.
- Modifié pour inclure GitLab Premium dans GitLab 18.0.
- LLM [mis à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193208) vers Claude 4.0 Sonnet dans GitLab 18.1.

{{< /history >}}

Lorsque vous créez ou modifiez une merge request, utilisez GitLab Duo Merge Request Summary pour créer une description de merge request.

1. [Créez une nouvelle merge request](creating_merge_requests.md).
1. Dans le champ **Description**, placez votre curseur à l'endroit où vous souhaitez insérer la description.
1. Dans la barre d'outils au-dessus de la zone de texte, sélectionnez **Résumer les modifications apportées au code** ({{< icon name="tanuki-ai" >}}).

   ![Au-dessus de la zone de texte, une barre d'outils affiche un bouton « Résumer les modifications apportées au code ».](img/merge_request_ai_summary_v17_6.png)

La description est insérée à l'emplacement de votre curseur.

<i class="fa-youtube-play" aria-hidden="true"></i> [Visionner une présentation](https://www.youtube.com/watch?v=CKjkVsfyFd8&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

Donnez votre avis sur cette fonctionnalité dans le [ticket 443236](https://gitlab.com/gitlab-org/gitlab/-/issues/443236).

Utilisation des données : le diff des modifications entre la tête de la branche source et la branche cible est envoyé au grand modèle de langage.

## Utiliser GitLab Duo pour réviser votre code {#use-gitlab-duo-to-review-your-code}

GitLab Duo peut examiner votre merge request pour détecter des erreurs potentielles et fournir des commentaires sur la conformité aux standards.

Lorsque vous demandez une revue à GitLab Duo, il exécute automatiquement l'une des deux fonctionnalités de revue de code en fonction de votre add-on. Les utilisateurs disposant du rôle Owner pour le groupe peuvent configurer la fonctionnalité qui s'exécute pour tous les utilisateurs.

| Détail              | [Flow Code Review](../../duo_agent_platform/flows/foundational_flows/code_review.md) | [GitLab Duo Code Review](../../gitlab_duo/code_review.md) |
|---------------------|--------------------------------------------------------------------------------------|-----------------------------------------------------------|
| Relecteur            | `@GitLabDuo`                                                                         | `@GitLabDuo`                                              |
| Type                | Agentique                                                                              | Non agentique                                               |
| Add-on requis     | Aucun. Utilise des GitLab Credits.                                                           | GitLab Duo Enterprise                                     |
| Sensibilité au contexte   | Compréhension approfondie de la structure du dépôt et des dépendances entre fichiers           | Centré sur la merge request et les diffs de fichiers qu'elle contient |
| Analyse            | Raisonnement agentique multi-étapes                                                         | Passage unique                                               |
| Création de session    | {{< yes >}}                                                                          | {{< no >}}                                                |
| Revues automatiques   | {{< yes >}}                                                                          | {{< yes >}}                                               |
| Instructions personnalisées | {{< yes >}}                                                                          | {{< yes >}}                                               |
| Commentaires personnalisés     | {{< yes >}}                                                                          | {{< yes >}}                                               |

### Déterminer quelle fonctionnalité de revue s'exécute {#determine-which-review-feature-runs}

Par défaut, la fonctionnalité de revue de code que GitLab exécute dépend de l'utilisateur qui initie la revue.

| Déclencheur de revue                          | Utilisateur initiant la revue                      |
|-----------------------------------------|--------------------------------------|
| Revue demandée manuellement               | L'utilisateur qui demande la revue.    |
| Merge request créée (pas en brouillon)     | L'auteur de la merge request.            |
| Merge request en brouillon marquée comme prête     | L'auteur de la merge request.            |

Si l'utilisateur initiant la revue dispose d'un siège GitLab Duo Enterprise, GitLab Duo Code Review s'exécute. Sinon, le flow Code Review s'exécute. Les deux fonctionnalités peuvent s'exécuter dans le même projet.

Les utilisateurs disposant du rôle Owner pour le groupe peuvent [configurer toutes les revues pour utiliser le flow Code Review](#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats), quel que soit le type de siège. Lorsque le flow Code Review s'exécute, l'utilisation des crédits est attribuée à l'utilisateur initiant la revue.

Pour déterminer quelle fonctionnalité exécute une revue, vérifiez le fil d'activité de la merge request. Le flow Code Review démarre une session de revue lors de son exécution. Si aucune session de revue n'apparaît, GitLab Duo Code Review exécute la revue.

![Fil d'activité de la merge request montrant une session de revue démarrée par GitLab Duo.](img/gitlab_duo_code_review_flow_session_v18_10.png)

Une fois la revue terminée, vous pouvez également rechercher une session de flow Code Review dans les [sessions de votre projet](../../duo_agent_platform/sessions/_index.md#view-sessions-for-your-project).

#### Activer le flow Code Review pour les sièges GitLab Duo Enterprise {#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240432) dans GitLab 19.2 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `duo_code_review_dap_routing_consent_enabled`. Activé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/602689) dans GitLab 19.3. Le feature flag `duo_code_review_dap_routing_consent_enabled` a été supprimé.

{{< /history >}}

Pour éviter que les titulaires de siège GitLab Duo Enterprise n'utilisent une fonctionnalité qui consomme des GitLab Credits, toutes les revues de code qu'ils initient utilisent GitLab Duo Code Review par défaut. Ce comportement se produit même si un utilisateur disposant du rôle Owner active le flow Code Review pour le groupe.

Vous pouvez modifier ce paramètre par défaut et configurer toutes les revues de code pour utiliser le flow Code Review à la place, quel que soit le siège de l'utilisateur.

Pour remplacer la fonctionnalité de revue de code par défaut pour les sièges GitLab Duo Enterprise :

{{< tabs >}}

{{< tab title="GitLab.com" >}}

Prérequis :

- Le rôle Propriétaire pour le groupe principal.
- [Flow Code Review](../../duo_agent_platform/flows/foundational_flows/code_review.md#prerequisites) activé et configuré correctement pour votre groupe principal.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Exécution des flux** > **Autoriser les flows par défaut**, décochez la case **Flux de revue de code**, puis cochez-la à nouveau.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Enable Code Review Flow**.

{{< /tab >}}

{{< tab title="GitLab Self-Managed et GitLab Dedicated" >}}

Prérequis :

- Le rôle Maintainer ou Owner pour le groupe.
- [Flow Code Review](../../duo_agent_platform/flows/foundational_flows/code_review.md#prerequisites) activé et configuré correctement pour l'instance.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe ou votre sous-groupe.
1. Sélectionnez **Paramètres** > **Généralités**.
1. Développez **Fonctionnalités de GitLab Duo**.
1. Sous **Exécution des flux**, décochez la case **Flux de revue de code**, puis sélectionnez **Sauvegarder les modifications**.
1. Développez à nouveau **Fonctionnalités de GitLab Duo** et, sous **Exécution des flux**, cochez la case **Flux de revue de code**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Enable Code Review Flow**.
1. Sélectionnez **Enregistrer les modifications**.

{{< /tab >}}

{{< /tabs >}}

Le flow Code Review s'exécute désormais pour toutes les revues de code dans le groupe et consomme des GitLab Credits. Pour revenir à GitLab Duo Code Review pour toutes les revues, désactivez le flow Code Review.

## Résoudre une discussion avec GitLab Duo {#resolve-a-discussion-with-gitlab-duo}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version bêta

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/600990) en [version bêta](../../../policy/development_stages_support.md) dans GitLab 19.2 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `resolve_discussion_with_duo`. Activé par défaut.

{{< /history >}}

Utilisez GitLab Duo pour résoudre les discussions de revue sur les merge requests.

Lorsque vous demandez à GitLab Duo de résoudre une discussion, il lit le commentaire de revue et le code environnant, apporte la modification demandée sur la branche source, puis effectue un commit et pousse la modification. GitLab Duo répond ensuite à la discussion avec un résumé de la modification et résout le fil de discussion.

Cette fonctionnalité utilise le flow Developer sur la [plateforme GitLab Duo Agent](../../duo_agent_platform/_index.md).

Prérequis :

- Le rôle Développeur, Chargé de maintenance ou Propriétaire pour le projet.
- Les [prérequis pour la plateforme GitLab Duo Agent](../../duo_agent_platform/_index.md#prerequisites).
- **Autoriser les flows par défaut** et **Développeur** activés [pour le groupe principal](../../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off).
- [Règles push configurées pour autoriser un compte de service](../../duo_agent_platform/troubleshooting.md#configure-push-rules-to-allow-a-service-account).
- [Vos propres runners configurés](../../duo_agent_platform/flows/execution.md#configure-runners-to-execute-flows) ou [runners hébergés par GitLab](../../../ci/runners/hosted_runners/_index.md) activés pour votre projet.

Pour résoudre une discussion avec GitLab Duo :

1. Dans la merge request, accédez à une discussion non résolue.
1. À côté de **Résoudre le fil de conversation**, sélectionnez **Autres options de résolution** ({{< icon name="chevron-down" >}}).
1. Sélectionnez **Résoudre avec GitLab Duo**.

GitLab Duo démarre une session que vous pouvez suivre dans les [sessions de votre projet](../../duo_agent_platform/sessions/_index.md#view-sessions-for-your-project).

## Résumer une revue de code {#summarize-a-code-review}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module complémentaire : GitLab Duo Enterprise
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version expérimentale

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- [LLM par défaut](../../gitlab_duo/model_selection.md#default-models)
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/epics/10466) dans GitLab 16.0 en tant que [version expérimentale](../../../policy/development_stages_support.md#experiment).
- Le feature flag `summarize_my_code_review` [activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182448) dans GitLab 17.10.
- LLM [mis à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183873) vers Claude 3.7 Sonnet dans GitLab 17.11.
- Modifié pour inclure GitLab Premium dans GitLab 18.0.
- LLM [mis à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193685) vers Claude 4.0 Sonnet dans GitLab 18.1.

{{< /history >}}

Lorsque vous avez terminé votre revue d'une merge request et que vous êtes prêt à [soumettre votre revue](reviews/_index.md#submit-a-review), utilisez GitLab Duo Code Review Summary pour générer un résumé de vos commentaires.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accédez à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez la merge request que vous souhaitez réviser.
1. Lorsque vous êtes prêt à soumettre votre revue, sélectionnez **Finish review**.
1. Sélectionnez **Add Summary**.

Le résumé s'affiche dans la zone de commentaire. Vous pouvez modifier et affiner le résumé avant de soumettre votre revue.

<i class="fa-youtube-play" aria-hidden="true"></i> [Visionner une présentation](https://www.youtube.com/watch?v=Bx6Zajyuy9k)

Donnez votre avis sur cette fonctionnalité expérimentale dans le [ticket 408991](https://gitlab.com/gitlab-org/gitlab/-/issues/408991).

Utilisation des données : lorsque vous utilisez cette fonctionnalité, les données suivantes sont envoyées au grand modèle de langage :

- Texte du commentaire en brouillon

## Générer un message de commit de fusion {#generate-a-merge-commit-message}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module complémentaire : GitLab Duo Enterprise, GitLab Duo with Amazon Q
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- [LLM par défaut](../../gitlab_duo/model_selection.md#default-models)
- LLM pour Amazon Q : Amazon Q Developer
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/epics/10453) dans GitLab 16.2 en tant que [version expérimentale](../../../policy/development_stages_support.md#experiment) [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `generate_commit_message_flag`. Désactivés par défaut.
- Le feature flag `generate_commit_message_flag` [activé par défaut](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158339) dans GitLab 17.2.
- Le feature flag `generate_commit_message_flag` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173262) dans GitLab 17.7.
- Modifié pour inclure GitLab Premium dans GitLab 18.0.
- LLM [mis à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193793) vers Claude 4.0 Sonnet dans GitLab 18.1.
- Prise en charge d'Amazon Q ajoutée dans GitLab 18.3.

{{< /history >}}

Lors de la préparation de la fusion de votre merge request, modifiez le message de commit de fusion proposé à l'aide de GitLab Duo Merge Commit Message Generation.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accédez à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et repérez votre merge request.
1. Cochez la case **Modifier le message de validation** dans le widget de fusion.
1. Sélectionnez **Générer un message de validation**.
1. Vérifiez le message de commit fourni et choisissez **Insérer** pour l'ajouter au commit.

<i class="fa-youtube-play" aria-hidden="true"></i> [Visionner une présentation](https://www.youtube.com/watch?v=fUHPNT4uByQ)

Utilisation des données : lorsque vous utilisez cette fonctionnalité, les données suivantes sont envoyées au grand modèle de langage :

- Contenu du fichier
- Le nom du fichier

## Sujets connexes {#related-topics}

- [Contrôler la disponibilité de GitLab Duo](../../gitlab_duo/turn_on_off.md)
- [Toutes les fonctionnalités de GitLab Duo](../../gitlab_duo/_index.md)
- [Résoudre les conflits de merge avec GitLab Duo](../../project/merge_requests/conflicts.md#resolve-conflicts-with-gitlab-duo)

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec GitLab Duo dans les merge requests, vous pouvez rencontrer les problèmes suivants.

### Réponse non reçue {#response-not-received}

Si vous demandez une revue à GitLab Duo en mentionnant ou en répondant à `@GitLabDuo`, et que vous ne recevez pas de réponse, cela peut être dû au fait que vous ne disposez pas de l'add-on GitLab Duo approprié.

Pour vérifier votre add-on GitLab Duo, demandez au Owner de votre groupe de vérifier les [attributions de sièges GitLab Duo](../../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users) du groupe.

Pour modifier votre add-on GitLab Duo, contactez votre administrateur.

### Impossible d'assigner GitLab Duo comme relecteur {#unable-to-assign-gitlab-duo-to-review}

Si vous ne pouvez pas assigner GitLab Duo comme relecteur, cela peut être dû au fait que vous ne disposez pas de l'add-on GitLab Duo approprié.

Pour vérifier votre add-on GitLab Duo, demandez au Owner de votre groupe de vérifier les [attributions de sièges GitLab Duo](../../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users) du groupe.

Pour modifier votre add-on GitLab Duo, contactez votre administrateur.

### Erreur :`GitLab Duo Code Review was not automatically added...` {#error-gitlab-duo-code-review-was-not-automatically-added}

Si vous essayez de créer une merge request avec les revues automatiques de GitLab Duo activées, vous pouvez obtenir le message d'erreur suivant :

```plaintext
GitLab Duo Code Review was not automatically added because your account requires
GitLab Duo Enterprise. Contact your administrator to upgrade your account.
```

Contactez votre administrateur pour lui demander d'[acheter un siège GitLab Duo Enterprise](../../../subscriptions/subscription-add-ons.md#purchase-gitlab-duo) et de vous l'attribuer.

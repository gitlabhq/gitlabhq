---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo Code Review (non-agentique)
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module d'extension : GitLab Duo Enterprise
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- [LLM par défaut](model_selection.md#default-models)
- [Sélectionner un modèle différent](model_selection.md#select-a-model-for-a-feature) à l'aide du paramètre **Non-Agentic Code Review**.
- Disponible sur [GitLab Duo avec des modèles auto-hébergés](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/14825) dans GitLab 17.5 en tant que [version expérimentale](../../policy/development_stages_support.md#experiment) derrière deux feature flags nommés [`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106) et [`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632), tous deux désactivés par défaut.
- Les feature flags [`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106) et [`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632) activés par défaut sur GitLab.com, GitLab Self-Managed et GitLab Dedicated dans la version 17.10.
- [Passage](https://gitlab.com/gitlab-org/gitlab/-/issues/516234) en version bêta dans GitLab 17.10.
- Disponibilité étendue à GitLab Premium dans GitLab 18.0.
- Feature flag `ai_review_merge_request` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190639) dans GitLab 18.1.
- Feature flag `duo_code_review_chat` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190640) dans GitLab 18.1.
- Disponibilité générale dans GitLab 18.1.
- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/524929) : disponible sur GitLab Duo avec les modèles auto-hébergés en version bêta dans GitLab 18.3.
- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/548975) : disponibilité générale sur GitLab Duo avec les modèles auto-hébergés dans GitLab 18.4.

{{< /history >}}

> [!note]
> Selon vos paramètres d'extension et de groupe, GitLab exécute l'une des deux fonctionnalités de revue de code :
>
> - Flux de revue de code : la version agentique, qui fait partie de GitLab Duo Agent Platform.
> - Revue de code GitLab Duo : la version non agentique, disponible uniquement pour les utilisateurs disposant du module d'extension GitLab Duo Enterprise.
>
> Cette page décrit la version non-agentique. Découvrez [les différences entre les deux fonctionnalités](../project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code).

GitLab Duo Code Review vous aide à rationaliser les revues de code dans vos projets.

## Utiliser GitLab Duo Code Review {#use-gitlab-duo-code-review}

Lorsque votre merge request est prête à être révisée, utilisez GitLab Duo Code Review pour effectuer une revue initiale :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et repérez votre merge request.
1. Dans une zone de commentaire, saisissez l'action rapide `/assign_reviewer @GitLabDuo`, ou assignez GitLab Duo comme relecteur.

<i class="fa-youtube-play" aria-hidden="true"></i> [Visionner une présentation](https://www.youtube.com/watch?v=SG3bhD1YjeY&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW&index=2)

Donnez votre avis sur cette fonctionnalité dans [le ticket 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386).

### Prise en compte du contexte {#contextual-awareness}

Lorsque vous utilisez GitLab Duo Code Review, les données suivantes sont envoyées au grand modèle de langage :

- Titre de la merge request
- Description de la merge request
- Contenu des fichiers avant application des modifications (pour le contexte)
- Diffs de la merge request
- Noms de fichiers
- Instructions personnalisées

Pour spécifier le contenu à exclure, consultez [exclure le contexte de la revue de code](context.md#exclude-context-from-code-review).

#### Comportement sur les grandes merge requests {#behavior-on-large-merge-requests}

GitLab Duo Code Review envoie les diffs de la merge request et le contenu original des fichiers modifiés au modèle. Le prompt combiné est soumis à la fenêtre de contexte du [modèle sélectionné](model_selection.md).

Pour les grandes merge requests, GitLab Duo Code Review utilise un mécanisme de secours pour améliorer les chances de réussite de la revue :

1. La requête initiale inclut les diffs de la merge request et le contenu original des fichiers.
1. Si cette requête échoue, GitLab Duo Code Review effectue automatiquement une nouvelle tentative sans le contenu original des fichiers.
1. Si la nouvelle tentative échoue également, GitLab Duo Code Review retourne un message d'erreur générique.

La nouvelle tentative sans le contenu des fichiers réduit la taille du prompt, mais réduit également le contexte dont dispose le modèle lors de la revue de vos modifications. Les commentaires pourraient être moins précis qu'une revue incluant le contenu original des fichiers.

Le délai d'expiration de la requête de la passerelle d'IA pour GitLab Duo Code Review est de 120 secondes. Les revues qui ne se terminent pas dans ce délai s'affichent également comme des erreurs génériques.

Pour réduire le risque d'échec des revues sur les grandes merge requests :

- Divisez les grandes merge requests en merge requests plus petites.
- [Excluez le contexte](context.md#exclude-context-from-code-review) des fichiers qui ne sont pas pertinents pour la revue
- Demandez à un propriétaire de groupe ou à un administrateur d'instance de sélectionner un modèle différent à l'aide du paramètre **Non-Agentic Code Review**. Consultez [GitLab.com](model_selection.md#select-a-model-for-a-feature) ou [GitLab Self-Managed et GitLab Dedicated](../../administration/gitlab_duo/model_selection.md#select-a-model-for-the-instance).

## Interagir avec GitLab Duo dans les revues {#interact-with-gitlab-duo-in-reviews}

Vous pouvez mentionner `@GitLabDuo` dans les commentaires pour interagir avec GitLab Duo sur votre merge request. Vous pouvez poser des questions de suivi sur ses commentaires de revue, ou poser des questions sur n'importe quel fil de discussion dans votre merge request.

Les interactions avec GitLab Duo peuvent contribuer à améliorer les suggestions et les retours au fur et à mesure que vous travaillez à l'amélioration de votre merge request.

Les commentaires transmis à GitLab Duo n'influencent pas les revues ultérieures des autres merge requests. Une demande de fonctionnalité existe pour ajouter cette fonctionnalité, consultez [le ticket 560116](https://gitlab.com/gitlab-org/gitlab/-/issues/560116).

## Instructions de revue de code personnalisées {#custom-code-review-instructions}

Vous pouvez créer des instructions personnalisées de revue de merge request pour garantir des standards de revue de code cohérents et spécifiques dans votre projet.

Pour plus d'informations, consultez [personnaliser les instructions de revue pour GitLab Duo](customize_duo/review_instructions.md).

## Revues automatiques {#automatic-reviews}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/506537) des revues automatiques pour les projets vers un paramètre d'interface utilisateur dans GitLab 18.0.
- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/554070) des revues automatiques pour les groupes et les instances dans GitLab 18.4 en tant que [version bêta](../../policy/development_stages_support.md#beta) [avec un feature flag](../../administration/feature_flags/_index.md) nommé `cascading_auto_duo_code_review_settings`. Fonctionnalité désactivée par défaut.
- [Suppression](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240) du feature flag `cascading_auto_duo_code_review_settings` dans GitLab 18.7.

{{< /history >}}

Les revues automatiques de GitLab Duo garantissent que toutes les merge requests de votre projet, groupe ou instance reçoivent une revue initiale.

Lorsqu'un utilisateur crée une merge request, GitLab Duo la révise automatiquement sauf si :

- Elle est marquée comme brouillon. Pour que GitLab Duo passe la merge request en revue, marquez-la comme prête.
- Elle ne contient aucune modification. Pour que GitLab Duo passe la merge request en revue, ajoutez-y des modifications.
- Elle correspond à une ou plusieurs règles d'exclusion que vous avez définies. Pour que GitLab Duo révise la merge request, demandez manuellement une revue.

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

Les paramètres se propagent du groupe au projet. Les paramètres les plus spécifiques remplacent les paramètres plus généraux.

{{< /tab >}}

{{< tab title="Instance" >}}

Prérequis :

- Accès administrateur

Pour activer les revues automatiques pour une instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Dans la section **Revue de code GitLab Duo**, sélectionnez **Autoriser l'analyse automatique de GitLab Duo**.
1. Sélectionnez **Enregistrer les modifications**.

Les paramètres se propagent de l'instance au groupe, puis au projet. Les paramètres les plus spécifiques remplacent les paramètres plus généraux.

{{< /tab >}}

{{< /tabs >}}

Après avoir activé les revues automatiques, vous pouvez définir des règles pour exclure des merge requests spécifiques.

### Exclure des merge requests pour un projet {#exclude-merge-requests-for-a-project}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240236) dans GitLab 19.2 en [version bêta](../../policy/development_stages_support.md#beta) [avec le feature flag](../../administration/feature_flags/_index.md) `duo_code_review_automated_rules`. Activés par défaut.
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
> Si vous avez déjà configuré un projet pour stocker les [instructions de revue personnalisées](customize_duo/review_instructions.md#configure-custom-review-instructions-for-a-group) de votre groupe, stockez votre `mr-review-automated-rules.yaml` dans le même projet. Vous ne pouvez spécifier qu'un seul projet pour personnaliser la revue de code pour un groupe, GitLab vérifie donc automatiquement ce projet pour les règles d'exclusion également. Vous n'avez pas besoin de suivre à nouveau les étapes ci-dessous.

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

### La revue échoue sur une grande merge request {#review-fails-on-a-large-merge-request}

GitLab Duo Code Review pourrait ne pas parvenir à publier une revue sur des merge requests comportant de nombreux fichiers modifiés volumineux. Les causes courantes sont les suivantes :

- La taille combinée des diffs et du contenu original des fichiers dépasse la fenêtre de contexte du modèle.
- La requête de la passerelle d'IA prend plus de 120 secondes.

Pour plus de détails sur le comportement de nouvelle tentative et de délai d'expiration, consultez [comportement sur les grandes merge requests](#behavior-on-large-merge-requests).

Pour contourner l'échec :

- Divisez la merge request en merge requests plus petites.
- [Excluez le contexte](context.md#exclude-context-from-code-review) des fichiers qui ne sont pas pertinents pour la revue
- Demandez à un propriétaire de groupe ou à un administrateur d'instance de sélectionner un modèle différent à l'aide du paramètre **Non-Agentic Code Review**. Consultez [GitLab.com](model_selection.md#select-a-model-for-a-feature) ou [GitLab Self-Managed et GitLab Dedicated](../../administration/gitlab_duo/model_selection.md#select-a-model-for-the-instance).

Pour plus d'informations, consultez [le ticket 596794](https://gitlab.com/gitlab-org/gitlab/-/work_items/596794).

## Sujets connexes {#related-topics}

- [GitLab Duo dans les merge requests](../project/merge_requests/duo_in_merge_requests.md)
- [Activer le flow Code Review pour les sièges GitLab Duo Enterprise](../project/merge_requests/duo_in_merge_requests.md#turn-on-code-review-flow-for-gitlab-duo-enterprise-seats).

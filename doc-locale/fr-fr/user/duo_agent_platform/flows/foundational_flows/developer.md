---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: flow Developer
---

{{< details >}}

- Niveau : [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduit en tant que [version bêta](../../../../policy/development_stages_support.md) dans GitLab 18.3 [avec un flag](../../../../administration/feature_flags/_index.md) nommé `duo_workflow_in_ci`. Désactivé par défaut, mais peut être activé pour l'instance ou un utilisateur.
- Renommé de `Issue to MR` en `Developer Flow` avec un feature flag nommé `duo_developer_button` dans GitLab 18.6. Désactivé par défaut, mais peut être activé pour l'instance ou un utilisateur. Le feature flag `duo_workflow` doit également être activé, mais il l'est par défaut.
- [Disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) dans GitLab 18.8.
- Les feature flags `duo_workflow_in_ci`, `duo_developer_button` et `duo_workflow` ont été supprimés dans GitLab 18.9.
- Disponible sur le niveau Free sur GitLab.com avec des GitLab Credits dans GitLab 18.10.
- Les déclencheurs de mention ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228817) dans GitLab 18.11.

{{< /history >}}

Le flow Developer vous aide à travailler plus efficacement sur les tickets et les merge requests. Vous pouvez utiliser le flow Developer pour :

- Créer un merge request brouillon à partir d'un ticket.
- Itérer sur un merge request existant en fonction des retours de révision.
- Rechercher des approches d'implémentation et publier les résultats dans un fil de discussion.
- Diviser un grand merge request en plusieurs merge requests plus petits et ciblés.
- Résoudre les conflits de merge.

## Prérequis {#prerequisites}

- Remplir les [prérequis pour la plateforme GitLab Duo Agent](../../_index.md#prerequisites).
- Activer **Autoriser les flux de base** et **Développeur** [pour le groupe principal](_index.md#turn-foundational-flows-on-or-off).
- Avoir le rôle Développeur, Mainteneur ou Propriétaire pour le projet.
- [Configurer des règles push pour autoriser un compte de service](../../troubleshooting.md#configure-push-rules-to-allow-a-service-account).
- [Configurer vos propres runners](../execution.md#configure-runners) ou activer les [runners hébergés par GitLab](../../../../ci/runners/hosted_runners/_index.md) pour votre projet.

## Configurer votre projet {#set-up-your-project}

Pour aider le flow Developer à produire de meilleurs résultats, vous devez configurer votre projet avec les paramètres facultatifs suivants :

- Ajouter un fichier `AGENTS.md` : Documentez les conventions de votre projet, telles que les commandes de test, les règles de linting, le format de commit et les modèles de codage. Le flow Developer utilise ce fichier comme contexte lors du travail dans votre dépôt. Pour plus d'informations, consultez [Fichiers de personnalisation AGENTS.md](../../customize/agents_md.md).
- Configurer l'environnement d'exécution : Si votre projet nécessite des outils spécifiques (par exemple, Go, Python ou Node.js), configurez l'environnement de l'agent avec un fichier `agent-config.yml`. Avec un environnement correctement configuré, le flow Developer peut exécuter des tests et vérifier ses propres modifications avant de les committer. Pour plus d'informations, consultez [Configurer l'exécution du flow](../execution.md).

## Utiliser le flow {#use-the-flow}

Prérequis :

- Les types d'événements **Mentionne** et **Assigner** sont [configurés](../../triggers/_index.md) dans le déclencheur du flow Developer.

### Mentionner Duo Developer dans une discussion {#mention-duo-developer-in-a-discussion}

Pour transformer votre commentaire en tâche actionnable pour le flow Developer, mentionnez-le avec `@duo-developer-<namespace>` dans une discussion. Remplacez `<namespace>` par votre chemin d'espace de nommage GitLab (par exemple, `gitlab-org`).

En fonction du contenu du ticket ou du merge request et de la quantité de contexte que vous fournissez, le flow peut exécuter les tâches suivantes :

- Modifications du code
- Création de merge requests et de tickets
- Rechercher une approche d'implémentation et faire un rapport en retour ou effectuer les mises à jour en conséquence

Par exemple :

```plaintext
@duo-developer-<namespace> research approaches for implementing pagination
on the /users endpoint, then create a draft MR with the most
promising approach.
```

Le flow Developer répond avec un lien vers sa session.

Vous pouvez également, pour surveiller la progression, sélectionner **IA** > **Sessions** dans la barre latérale gauche.

### Générer un merge request à partir d'un ticket {#generate-a-merge-request-from-an-issue}

Pour créer un merge request à partir d'un ticket :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Ticket**.
1. Sélectionnez le ticket pour lequel vous souhaitez créer un merge request.
1. Pour créer un merge request à partir du ticket, vous pouvez :
   - Assigner le compte de service Duo Developer au ticket :
     1. Dans la barre latérale droite, dans la section **Personnes assignées**, sélectionnez **Éditer**.
     1. Saisissez `duo developer` et sélectionnez-le dans les résultats de recherche.
   - Sous l'en-tête du ticket, sélectionnez **Generate MR with GitLab Duo**.
1. Facultatif. Pour surveiller la progression du flow, dans la barre latérale gauche, sélectionnez **IA** > **Sessions**.
1. Une fois la session terminée, consultez le merge request depuis le lien dans la section **Activité** du ticket.

## Bonnes pratiques {#best-practices}

### Fournir un contexte clair {#provide-clear-context}

Le flow Developer ne connaît que ce que vous lui dites ou ce qui est disponible dans le contexte du ticket, du merge request ou du fil de discussion. Les mêmes pratiques qui aident un collaborateur humain s'appliquent ici :

- Rédigez une description claire du problème avec des liens vers les fichiers ou discussions pertinents.
- Incluez des critères d'acceptation qui définissent à quoi ressemble le « terminé ».
- Spécifiez les chemins de fichiers exacts lorsque vous les connaissez.
- Incluez des exemples de code de modèles existants pour maintenir la cohérence.

### Soyez explicite lorsque vous mentionnez Duo Developer dans les discussions {#be-explicit-when-mentioning-duo-developer-in-discussions}

Lorsque vous mentionnez Duo Developer dans une discussion, dites-lui exactement ce que vous souhaitez qu'il fasse. Par exemple :

- « Créez un merge request brouillon qui implémente la pagination pour le point de terminaison `/api/users`. »
- « Prenez en compte les retours de révision sur ce merge request. »
- « Divisez les modifications de journalisation en un merge request séparé. »
- « Recherchez des approches pour migrer ce service vers gRPC et publiez vos résultats ici. »
- « Il y a des conflits de merge sur ce merge request. Veuillez les résoudre. »

Sans instructions explicites, le flow choisit sa propre approche, qui peut ne pas correspondre à vos attentes.

### Maintenir les tâches ciblées {#keep-tasks-focused}

Décomposez les tâches complexes en demandes plus petites, ciblées et orientées vers l'action. Les tâches larges et ouvertes sont plus susceptibles d'atteindre les limites d'itération.

## Exemples {#examples}

### Ticket pour générer un merge request {#issue-for-generating-a-merge-request}

Cet exemple montre un ticket bien conçu que le flow Developer peut utiliser pour générer un merge request.

```plaintext
## Description
The users endpoint currently returns all users at once,
which will cause performance issues as the user base grows.
Implement cursor-based pagination for the `/api/users` endpoint
to handle large datasets efficiently.

## Implementation plan
Add pagination to GET /users API endpoint.
Include pagination metadata in /users API response (per_page, page).
Add query parameters for per page size limit (default 5, max 20).

#### Files to modify
- `src/api/users.py` - Add pagination parameters and logic.
- `src/models/user.py` - Add pagination query method.
- `tests/api/test_users_api.py` - Add pagination tests.

## Acceptance criteria
- Accepts page and per_page query parameters (default: page=5, per_page=10).
- Limits per_page to a maximum of 20 users.
- Maintains existing response format for user objects in data array.
```

### Itérer sur les retours de révision d'un merge request {#iterate-on-merge-request-review-feedback}

Après avoir révisé un merge request, vous pouvez mentionner le flow Developer pour traiter vos retours. Par exemple, dans un commentaire de révision sur une ligne spécifique :

```plaintext
@duo-developer-<namespace> move this validation logic into the `BaseService` class
in `app/services/base_service.rb` instead of duplicating it here.
```

Vous pouvez également soumettre une révision complète, puis mentionner le flow Developer pour traiter tous les fils de discussion ouverts :

```plaintext
@duo-developer-<namespace> please address the review feedback on this MR.
```

### Diviser un merge request {#split-a-merge-request}

Si un merge request est devenu trop volumineux, vous pouvez demander au flow Developer d'en extraire une partie dans un merge request séparé :

```plaintext
@duo-developer-<namespace> the logging changes in this MR are out of scope.
Split them into a separate MR.
```

### Rechercher une approche d'implémentation {#research-an-implementation-approach}

Vous pouvez demander au flow Developer d'analyser un problème et de faire un rapport avant d'effectuer des modifications :

```plaintext
@duo-developer-<namespace> research whether the `PUT /api/users` endpoint also needs
rate limiting like we added to the `POST /api/users` endpoint.
Post your findings here.
```

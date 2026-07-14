---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Merge requests
description: "Créez des merge requests pour réviser les modifications du code, gérer les discussions et fusionner des branches."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Le menu des actions de la barre latérale a été [modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/373757) pour déplacer également les actions sur les tickets, les incidents et les epics dans GitLab 16.0.
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127001) dans GitLab 16.9. L'indicateur de fonctionnalité `moved_mr_sidebar` a été supprimé.

{{< /history >}}

Les merge requests constituent un espace centralisé permettant à votre équipe de réviser le code, d'engager des discussions et de suivre les modifications du code. Pour décrire la raison d'une modification, associez une merge request à un ticket et fermez automatiquement le ticket lors de la fusion de la merge request.

Les merge requests permettent de s'assurer que les experts du domaine examinent vos modifications proposées et que les exigences de sécurité de votre organisation sont respectées. En créant votre merge request tôt dans le processus de développement, votre équipe a le temps de détecter les bugs et les problèmes de qualité du code.

Lors de la consultation d'une merge request, vous voyez :

- Une description de la demande.
- Les modifications du code et les revues de code en ligne.
- Des informations sur les pipelines CI/CD.
- Des rapports de fusionnabilité.
- Des commentaires.
- La liste des commits.

## Personnes assignées et relecteurs {#assignees-and-reviewers}

Une merge request comporte deux rôles :

- **Personne assignée** : Détient la merge request et est responsable de sa progression. La personne assignée est généralement l'auteur ou l'autrice.
- **Relecteur** : Examine les modifications et fournit des retours. Un relecteur peut demander des modifications ou, s'il y est éligible, approuver la merge request.

Les [règles et paramètres d'approbation](approvals/_index.md) de votre projet déterminent qui peut approuver les merge requests.

Pour plus d'informations, voir [assigner une personne assignée](#assign-a-user-to-a-merge-request) et [demander un relecteur](reviews/_index.md#request-a-review).

## Créer une merge request {#create-a-merge-request}

Découvrez les différentes manières de [créer une merge request](creating_merge_requests.md).

### Utiliser des modèles de merge request {#use-merge-request-templates}

Lorsque vous créez une merge request, GitLab vérifie l'existence d'un [modèle de description](../description_templates.md) pour ajouter des données à votre merge request. GitLab vérifie ces emplacements dans l'ordre de 1 à 5, et applique le premier modèle trouvé à votre merge request :

| Nom | Interface utilisateur du projet<br>paramètre | Groupe<br>`default.md` | Instance<br>`default.md` | Projet<br>`default.md` | Aucun modèle |
|:-----|:---------------------:|:---------------------:|:------------------------:|:-----------------------:|:-----------:|
| Message de commit standard | 1  |           2           |            3             |            4            |      5      |
| Message de commit avec un modèle de fermeture de ticket comme `Closes #1234` | 1 | 2 | 3 | 4 | 5 \* |
| Nom de branche [préfixé d'un identifiant de ticket](../repository/branches/_index.md#prefix-branch-names-with-a-number), comme `1234-example` | 1 \* | 2 \* | 3 \* | 4 \* | 5 \* |

> [!note]
> Les éléments marqués d'un astérisque (\*) ajoutent également un [modèle de fermeture de ticket](../issues/managing_issues.md#closing-issues-automatically).

## Afficher les merge requests {#view-merge-requests}

Vous pouvez afficher les merge requests pour votre projet, votre groupe ou vous-même.

{{< tabs >}}

{{< tab title="Pour vous-même" >}}

Pour afficher toutes les merge requests nécessitant votre participation, utilisez l'une des options suivantes :

- Raccourci clavier : <kbd>Shift</kbd>+<kbd>M</kbd>
- Dans la barre latérale gauche, sélectionnez **Requêtes de fusion**.
- Dans la barre supérieure, sélectionnez **Rechercher ou aller à**. Dans la liste déroulante, sélectionnez **Requêtes de fusion**.

{{< /tab >}}

{{< tab title="Pour un projet" >}}

Pour afficher toutes les merge requests d'un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion**.

Ou, pour utiliser un raccourci clavier, appuyez sur <kbd>g</kbd>+<kbd>m</kbd>.

{{< /tab >}}

{{< tab title="Pour tous les projets d'un groupe" >}}

Pour afficher les merge requests de tous les projets d'un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion**.

Si votre groupe contient des sous-groupes, cette vue affiche également les merge requests des projets du sous-groupe.

{{< /tab >}}

{{< tab title="Pour un fichier" >}}

Lorsque vous consultez un fichier dans votre dépôt, GitLab affiche un badge indiquant le nombre de merge requests ouvertes qui ciblent la branche actuelle et modifient le fichier. Le badge vous aide à identifier les fichiers présentant des modifications en attente.

La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, voir [afficher les merge requests ouvertes pour un fichier](../repository/files/_index.md#view-open-merge-requests-for-a-file).

Pour afficher les merge requests ouvertes pour un fichier :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Accédez au fichier que vous souhaitez consulter.
1. En haut à droite de l'écran, à côté du nom du fichier, recherchez le badge vert indiquant le nombre de merge requests {{< icon name="merge-request-open" >}} **Ouvrir**.
1. Sélectionnez le badge pour afficher la liste des merge requests ouvertes créées au cours des 30 derniers jours.
1. Sélectionnez une merge request dans la liste pour accéder à cette merge request.

{{< /tab >}}

{{< /tabs >}}

## Filtrer la liste des merge requests {#filter-the-list-of-merge-requests}

{{< history >}}

- Filtrage par `source branch` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134555) dans GitLab 16.6.
- Filtrage par `merged by` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) dans GitLab 16.9. Disponible uniquement lorsque le feature flag `mr_merge_user_filter` est activé.
- Filtrage par `merged by` [disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142666) dans GitLab 17.0. L'indicateur de fonctionnalité `mr_merge_user_filter` a été supprimé.
- Filtrage par `merged before` et `merged after` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209458) dans GitLab 18.6.

{{< /history >}}

Pour filtrer la liste des merge requests :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion**.
1. Au-dessus de la liste des merge requests, sélectionnez **Rechercher ou filtrer les résultats**.
1. Dans la liste déroulante, sélectionnez l'attribut par lequel vous souhaitez filtrer. Quelques exemples :
   - **By environment or deployment date**.
   - **ID** : Saisissez le filtre `#30` pour ne retourner que la merge request 30.
   - Filtres utilisateur :
     - **Approuvée par**, pour les merge requests déjà approuvées par un utilisateur. GitLab Premium et GitLab Ultimate uniquement.
     - **Approbateur**, pour les merge requests que cet utilisateur est éligible à approuver. (Pour plus d'informations, consultez la section relative aux [propriétaires du code](../codeowners/_index.md)). GitLab Premium et GitLab Ultimate uniquement.
     - **Fusionné par**, pour les merge requests fusionnées par cet utilisateur.
     - **Relecteur**, pour les merge requests examinées par cet utilisateur.
1. Sélectionnez ou saisissez l'opérateur à utiliser pour filtrer l'attribut. Les opérateurs suivants sont disponibles :
   - `=` : Est
   - `!=` : N'est pas
1. Saisissez le texte par lequel filtrer l'attribut. Vous pouvez filtrer certains attributs par **Aucun** ou **Tout**.
1. Répétez ce processus pour filtrer par d'autres attributs, joints par un `AND` logique.
1. Sélectionnez un **Sens de tri**, soit {{< icon name="sort-lowest" >}} pour l'ordre décroissant, soit {{< icon name="sort-highest" >}} pour l'ordre croissant.

### Par environnement ou date de déploiement {#by-environment-or-deployment-date}

Pour filtrer les merge requests par données de déploiement, telles que l'environnement ou une date, vous pouvez saisir (ou sélectionner dans la liste déroulante) les éléments suivants :

- Environnement
- Déployé avant
- Déployé après

> [!note]
> Les projets qui utilisent une [méthode de fusion fast-forward](methods/_index.md#fast-forward-merge) ne renvoient pas de résultats, car cette méthode ne crée pas de commit de fusion.

Pour filtrer par environnement, sélectionnez une option dans la liste déroulante des environnements disponibles.

Pour filtrer par `Deployed before` ou `Deployed after`, saisissez manuellement une date de déploiement :

- La date correspond au moment où le déploiement vers un environnement (déclenché par le commit de fusion) s'est terminé avec succès.
- Utilisez le format `YYYY-MM-DD`. Pour spécifier à la fois une date et une heure, utilisez des guillemets doubles (`"YYYY-MM-DD HH:MM"`).

## Ajouter des modifications à une merge request {#add-changes-to-a-merge-request}

Si vous avez la permission d'ajouter des modifications à une merge request, vous pouvez le faire de plusieurs façons. La méthode à utiliser dépend de la complexité de votre modification et de la nécessité d'accéder à un environnement de développement :

- [Modifier les changements dans le Web IDE](../web_ide/_index.md) dans votre navigateur avec le raccourci clavier <kbd>.</kbd>. Utilisez cette méthode basée sur le navigateur pour modifier plusieurs fichiers, ou si vous n'êtes pas à l'aise avec les commandes Git. Vous ne pouvez pas exécuter de tests depuis le Web IDE.
- [Modifier les changements dans Ona](../../../integration/gitpod.md#launch-ona-in-gitlab), si vous avez besoin d'un environnement complet pour modifier des fichiers et exécuter des tests ensuite. Ona prend en charge le kit de développement GitLab (GDK). Pour utiliser Ona, vous devez activer Ona dans votre compte utilisateur.
- [Envoyer des modifications depuis la ligne de commande](../../../topics/git/commands.md), si vous êtes familier avec Git et la ligne de commande.

## Assigner un utilisateur à une merge request {#assign-a-user-to-a-merge-request}

Pour assigner la merge request à un utilisateur, utilisez l'action rapide `/assign @user` dans une zone de texte d'une merge request, ou :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Dans la barre latérale droite, dans la section **Personnes assignées**, sélectionnez **Modifier**.
1. Recherchez l'utilisateur que vous souhaitez assigner, puis sélectionnez-le. Avec GitLab Free, vous pouvez assigner un seul utilisateur par merge request. Avec GitLab Premium et GitLab Ultimate, vous pouvez assigner plusieurs utilisateurs :

   ![La barre latérale de la merge request affichant plusieurs utilisateurs assignés.](img/merge_request_assignees_v16_0.png)

GitLab ajoute la merge request à la page **Requêtes de fusion assignées** de l'utilisateur.

## Participants {#participants}

Les participants sont des utilisateurs qui ont interagi avec une merge request. Pour obtenir des informations sur la consultation des participants, voir [participants](../../participants.md).

## Fusionner une merge request {#merge-a-merge-request}

Pendant le processus de revue de la merge request, les relecteurs fournissent des retours sur vos modifications. Lorsqu'un relecteur est satisfait des modifications, il peut configurer la merge request en [fusion automatique](auto_merge.md), même si certaines vérifications de fusion échouent. Une fois toutes les vérifications de fusion réussies, la merge request est automatiquement fusionnée, sans autre action de votre part.

Permissions de fusion par défaut :

- La branche par défaut, généralement `main`, est protégée.
- Seuls les Maintainers et les rôles supérieurs peuvent fusionner dans la branche par défaut.
- Les Developers peuvent fusionner n'importe quelle merge request ciblant une branche non protégée.

Pour déterminer si vous avez la permission de fusionner une merge request spécifique, GitLab vérifie :

- Votre rôle dans le projet. Par exemple, Developer, Maintainer ou Owner.
- Les protections de la branche cible.

## Clore une merge request {#close-a-merge-request}

Si vous décidez d'arrêter définitivement les travaux sur une merge request, clôturez-la plutôt que de [la supprimer](manage.md#delete-a-merge-request).

Prérequis :

- Vous devez être l'auteur ou une personne assignée de la merge request, ou disposer du rôle Developer, Maintainer ou Owner pour le projet.

Pour clore une merge request dans le projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Faites défiler jusqu'à la zone de commentaire en bas de la page.
1. Après la zone de commentaire, sélectionnez **Clore la requête de fusion**.

GitLab clôture la merge request, mais conserve les enregistrements de la merge request, ses commentaires et tous les pipelines associés.

### Supprimer la branche source {#delete-the-source-branch}

{{< history >}}

- Option permettant de supprimer la branche source depuis une merge request fermée [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237646) dans GitLab 19.1.

{{< /history >}}

Pour supprimer la branche source d'une merge request :

- Lorsque vous créez une merge request, en sélectionnant **Delete source branch when merge request accepted**.
- Lorsque vous fusionnez une merge request, si vous avez le rôle Maintainer, en sélectionnant **Supprimer la branche source**.
- Lorsque vous clôturez une merge request sans la fusionner, en sélectionnant **Supprimer la branche source**.

Un administrateur peut définir cette option comme valeur par défaut dans les paramètres du projet.

L'utilisateur qui configure la fusion automatique ou fusionne la merge request effectue la suppression de la branche. Si cet utilisateur ne dispose pas du rôle approprié, par exemple dans un projet dupliqué, la suppression de la branche source échoue.

### Mettre à jour les merge requests lorsque la branche cible est fusionnée {#update-merge-requests-when-target-branch-merges}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les merge requests sont souvent enchaînées, l'une dépendant du code ajouté ou modifié dans une autre merge request. Pour prendre en charge des merge requests petites et individuelles, GitLab peut mettre à jour jusqu'à quatre merge requests ouvertes lorsque leur branche cible fusionne dans `main`. Par exemple :

- Merge request 1 : fusion de `feature-alpha` dans `main`.
- Merge request 2 : fusion de `feature-beta` dans `feature-alpha`.

Si ces merge requests sont ouvertes en même temps, et que la merge request 1 (`feature-alpha`) fusionne dans `main`, GitLab met à jour la destination de la merge request 2 de `feature-alpha` vers `main`.

Les merge requests avec des mises à jour de contenu interconnectées sont généralement traitées de l'une des manières suivantes :

- La merge request 1 fusionne d'abord dans `main`. La merge request 2 est ensuite reciblée vers `main`.
- La merge request 2 fusionne dans `feature-alpha`. La merge request 1 mise à jour, qui contient maintenant le contenu de `feature-alpha` et de `feature-beta`, fusionne dans `main`.

Cette fonctionnalité ne fonctionne que lorsqu'une merge request est fusionnée. La sélection de **Remove source branch** après la fusion ne reciblant pas les merge requests ouvertes. Cette amélioration est [proposée comme suivi](https://gitlab.com/gitlab-org/gitlab/-/issues/321559).

## Workflows de merge request {#merge-request-workflows}

Pour un développeur ou une développeuse qui travaille en équipe :

1. Vous extrayez une nouvelle branche et soumettez vos modifications via une merge request.
1. Vous recueillez les retours de votre équipe.
1. Vous optimisez votre code à l'aide des [rapports de qualité du code](../../../ci/testing/code_quality.md).
1. Vous vérifiez vos modifications grâce aux [rapports de tests unitaires](../../../ci/testing/unit_test_reports.md) dans GitLab CI/CD.
1. Vous évitez les dépendances dont les licences sont incompatibles avec votre projet, grâce aux [politiques d'approbation des licences](../../compliance/license_approval_policies.md).
1. Vous demandez l'[approbation](approvals/_index.md) à votre responsable.
1. Votre responsable :
   1. Envoie un commit avec sa revue finale.
   1. Approuve la merge request.
   1. La configure en [fusion automatique](auto_merge.md) (anciennement **Fusionner lorsque le pipeline réussit**).
1. Vos modifications sont déployées en production avec des [jobs manuels](../../../ci/jobs/job_control.md#create-a-job-that-must-be-run-manually) pour GitLab CI/CD.
1. Votre implémentation est livrée à votre client.

Pour un développeur ou une développeuse web qui rédige une page web pour le site de votre entreprise :

1. Vous extrayez une nouvelle branche et soumettez une nouvelle page via une merge request.
1. Vous recueillez les retours de vos relecteurs.
1. Vous prévisualisez vos modifications avec les [environnements éphémères](../../../ci/review_apps/_index.md).
1. Vous demandez à vos web designers d'implémenter leurs modifications.
1. Vous demandez l'approbation à votre responsable.
1. Après approbation, GitLab :
   - [Squashe](squash_and_merge.md) les commits.
   - Fusionne le commit.
   - [Déploie les modifications en staging avec GitLab Pages](https://about.gitlab.com/blog/ci-deployment-and-environments/).
1. Votre équipe de production effectue un cherry-pick du commit de fusion vers la production.

## Filtrer l'activité dans une merge request {#filter-activity-in-a-merge-request}

{{< history >}}

- Le feature flag `mr_activity_filters` [activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/387070) dans GitLab 16.0.
- [Activé sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126998) par défaut dans GitLab 16.3.
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132355) dans GitLab 16.5. L'indicateur de fonctionnalité `mr_activity_filters` a été supprimé.
- Filtre pour les commentaires de bots [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128473) dans GitLab 16.9.

{{< /history >}}

Pour comprendre l'historique d'une merge request, filtrez son fil d'activité pour n'afficher que les éléments pertinents pour vous.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion**.
1. Sélectionnez une merge request.
1. Faites défiler jusqu'à **Activité**.
1. Sur le côté droit de la page, sélectionnez **Activity filter** pour afficher les options de filtre. Si vous avez déjà sélectionné des options de filtre, ce champ affiche un résumé de vos choix, comme **Activity + 5 more**.
1. Sélectionnez les types d'activité que vous souhaitez voir. Les options incluent :

   - Personnes assignées et relecteurs
   - Approbations
   - Commentaires (des bots)
   - Commentaires (des utilisateurs)
   - Commits et branches
   - Modifications
   - Labels
   - Statut de verrouillage
   - Mentions
   - Statut de la merge request
   - Suivi

1. facultatif. Sélectionnez **Sort** ({{< icon name="sort-lowest" >}}) pour inverser l'ordre de tri.

Votre sélection persiste pour toutes les merge requests. Vous pouvez également modifier l'ordre de tri à l'aide du bouton de tri situé à droite.

## Gérer les fils de commentaires {#manage-comment-threads}

Les discussions dans une merge request comprennent des commentaires simples et des fils de commentaires. Les fils de discussion ouverts (non résolus) bloquent la fusion d'une merge request, mais pas les commentaires simples. Lorsqu'une discussion dans un fil de discussion est terminée, [résolvez le fil de discussion](../../discussions/_index.md#resolve-a-thread) pour réduire son affichage. Si un fil de commentaires est important mais ne doit pas bloquer la merge request, déplacez-le vers un ticket pour poursuivre la discussion.

### Développer tous les fils de discussion {#expand-all-threads}

GitLab affiche le nombre de fils de discussion ouverts dans le coin supérieur droit d'une merge request. Cette merge request comporte trois fils de discussion ouverts :

![Une merge request avec trois fils de discussion ouverts et les options de gestion des fils de discussion.](img/open_threads_v18_5.png)

Pour afficher tous les commentaires dans les fils de discussion réduits, développez les fils de discussion :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Dans la merge request, en haut à droite, trouvez la liste déroulante **Open threads** et sélectionnez **Options du fil de conversation** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Afficher tous les commentaires**.

### Déplacer les fils de discussion ouverts vers un ticket {#move-open-threads-to-an-issue}

Pour déplacer les fils de discussion ouverts vers un nouveau ticket et débloquer une merge request :

{{< tabs >}}

{{< tab title="Déplacer un fil de discussion" >}}

Si vous avez un fil de discussion ouvert spécifique dans une merge request, vous pouvez créer un ticket pour le résoudre séparément :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Dans la merge request, trouvez le fil de discussion que vous souhaitez déplacer.
1. Sous la dernière réponse au fil de discussion, à côté de **Résoudre le fil de conversation**, sélectionnez **Créer un ticket pour résoudre le fil de discussion** ({{< icon name="work-item-new" >}}).
1. Remplissez les champs du nouveau ticket et sélectionnez **Créer un ticket**.

GitLab marque le fil de discussion comme résolu et ajoute un lien depuis la merge request vers le nouveau ticket.

{{< /tab >}}

{{< tab title="Déplacer tous les fils de discussion ouverts" >}}

Si vous avez plusieurs fils de discussion ouverts dans une merge request, vous pouvez créer un ticket pour les résoudre séparément :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez votre merge request.
1. Dans la merge request, en haut à droite, trouvez la liste déroulante **Open threads** et sélectionnez **Options du fil de conversation** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Tout résoudre avec un nouveau ticket**.
1. Remplissez les champs du nouveau ticket et sélectionnez **Créer un ticket**.

GitLab marque tous les fils de discussion comme résolus et ajoute un lien depuis la merge request vers le nouveau ticket.

{{< /tab >}}

{{< /tabs >}}

### Empêcher la fusion si tous les fils de discussion ne sont pas résolus {#prevent-merge-unless-all-threads-are-resolved}

Vous pouvez empêcher la fusion des merge requests tant que des fils de discussion restent ouverts. Lorsque vous activez ce paramètre, le compteur **Open threads** dans une merge request apparaît en orange tant qu'au moins un fil de discussion reste ouvert.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Requêtes de fusion**.
1. Dans la section **Vérifications de fusion**, cochez la case **Tous les fils de conversation doivent être résolus**.
1. Sélectionnez **Sauvegarder les modifications**.

### Résoudre automatiquement les fils de discussion lorsqu'ils ne sont plus d'actualité {#automatically-resolve-threads-when-they-become-outdated}

Vous pouvez configurer les merge requests pour résoudre automatiquement les fils de discussion lorsqu'un nouveau push modifie les lignes que ces fils de discussion décrivent.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Requêtes de fusion**.
1. Dans la section **Options de fusion**, sélectionnez **Résoudre automatiquement les discussions des diffs de requête de fusion lorsqu'elles ne sont plus d'actualité**.
1. Sélectionnez **Sauvegarder les modifications**.

Les fils de discussion sont désormais résolus si un push rend une section diff obsolète. Les fils de discussion sur les lignes inchangées et les fils de discussion résolvables de niveau supérieur ne sont pas résolus.

## Déplacer les notifications et les éléments de la liste de tâches {#move-notifications-and-to-dos}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132678) dans GitLab 16.5 [avec un flag](../../../administration/feature_flags/_index.md) nommé `notifications_todos_buttons`. Désactivée par défaut.
- [Les tickets et incidents](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133474), ainsi que les [epics](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133881) ont également été mis à jour.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Lorsque vous activez ce feature flag, les boutons de notifications et d'éléments de la liste de tâches se déplacent vers le coin supérieur droit de la page.

- Sur les merge requests, ces boutons apparaissent à l'extrême droite des onglets.
- Sur les tickets, les incidents et les epics, ces boutons apparaissent en haut de la barre latérale droite.

## Sujets connexes {#related-topics}

- [Protéger votre dépôt](../repository/protect.md)
- [Réviser une merge request](reviews/_index.md)
- [Merge requests empilées](reviews/stacked_merge_requests.md)
- [Autorisation pour les merge requests](authorization_for_merge_requests.md)
- [Tests et rapports](../../../ci/testing/_index.md)
- [Commentaires et fils de discussion](../../discussions/_index.md)
- [Suggérer des modifications du code](reviews/suggestions.md)
- [Pipelines CI/CD](../../../ci/_index.md)
- [Options push](../../../topics/git/commit.md) pour les merge requests
- [Validation du titre de la merge request](title_validation.md)

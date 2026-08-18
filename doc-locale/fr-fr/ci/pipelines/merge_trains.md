---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez les merge trains pour mettre en file d'attente les merge requests et éviter les conflits de branches dans GitLab CI/CD."
title: Merge trains
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Dans les projets avec des fusions fréquentes vers la branche par défaut, les modifications apportées dans différentes merge requests peuvent entrer en conflit les unes avec les autres. Utilisez les merge trains pour placer les merge requests dans une file d'attente. Chaque merge request est comparée aux autres merge requests antérieures pour s'assurer qu'elles fonctionnent toutes ensemble.

Pour plus d'informations sur :

- Le fonctionnement des merge trains, consultez le [workflow du merge train](#merge-train-workflow).
- Les raisons pour lesquelles vous pourriez vouloir utiliser les merge trains, lisez [How starting merge trains improve efficiency for DevOps](https://about.gitlab.com/blog/all-aboard-merge-trains/).

## Workflow du merge train {#merge-train-workflow}

Un merge train démarre lorsqu'aucune merge request n'est en attente de fusion et que vous sélectionnez [**Fusionner** ou **Configurer la fusion automatique**](#start-a-merge-train). GitLab lance un pipeline de merge train qui vérifie que les modifications peuvent être fusionnées dans la branche par défaut. Ce premier pipeline est identique à un [pipeline de résultats fusionnés](merged_results_pipelines.md), qui s'exécute sur les modifications des branches source et cible combinées. L'auteur du commit de résultat fusionné interne est l'utilisateur qui a initié la fusion.

Pour mettre en file d'attente une deuxième merge request afin qu'elle fusionne immédiatement après la fin du premier pipeline, sélectionnez [**Fusionner** ou **Configurer la fusion automatique**](#add-a-merge-request-to-a-merge-train) pour l'ajouter au train. Ce deuxième pipeline de merge train s'exécute sur les modifications des _deux_ merge requests combinées avec la branche cible. De même, si vous ajoutez une troisième merge request, ce pipeline s'exécute sur les modifications des trois merge requests fusionnées avec la branche cible. Les pipelines s'exécutent tous en parallèle.

Chaque merge request fusionne dans la branche cible uniquement après :

- La fin avec succès du pipeline de la merge request.
- La fusion de toutes les autres merge requests mises en file d'attente avant elle.

Si un pipeline de merge train échoue, la merge request n'est pas fusionnée. GitLab supprime cette merge request du merge train et lance de nouveaux pipelines pour toutes les merge requests qui étaient mises en file d'attente après elle.

Par exemple :

Trois merge requests (`A`, `B` et `C`) sont ajoutées à un merge train dans l'ordre, ce qui crée trois pipelines de résultats fusionnés qui s'exécutent en parallèle :

1. Le premier pipeline s'exécute sur les modifications de `A` combinées avec la branche cible.
1. Le deuxième pipeline s'exécute sur les modifications de `A` et `B` combinées avec la branche cible.
1. Le troisième pipeline s'exécute sur les modifications de `A`, `B` et `C` combinées avec la branche cible.

Si le pipeline pour `B` échoue :

- Le premier pipeline (`A`) continue de s'exécuter.
- `B` est supprimée du train.
- Le pipeline pour `C` [est annulé](#automatic-pipeline-cancellation), et un nouveau pipeline démarre pour les modifications de `A` et `C` combinées avec la branche cible (sans les modifications de `B`).

Si `A` se termine avec succès, elle fusionne dans la branche cible, et `C` continue de s'exécuter. Toutes les nouvelles merge requests ajoutées au train incluent les modifications de `A` désormais dans la branche cible, et les modifications de `C` provenant du merge train.

<i class="fa-youtube-play" aria-hidden="true"></i> Regardez cette vidéo pour une démonstration sur [comment l'exécution parallèle des merge trains peut empêcher les commits de casser la branche par défaut](https://www.youtube.com/watch?v=D4qCqXgZkHQ).

### Annulation automatique de pipeline {#automatic-pipeline-cancellation}

GitLab CI/CD détecte les pipelines redondants et les annule pour économiser des ressources.

Les pipelines de merge train redondants se produisent lorsque :

- Le pipeline échoue pour l'une des merge requests dans le merge train.
- Vous [ignorez le merge train et fusionnez immédiatement](#skip-the-merge-train-and-merge-immediately).
- Vous [supprimez une merge request d'un merge train](#remove-a-merge-request-from-a-merge-train).

Dans ces cas, GitLab doit créer de nouveaux pipelines de merge train pour certaines ou toutes les merge requests du train. Les anciens pipelines comparaient les modifications combinées précédentes dans le merge train, qui ne sont plus valides, et ces anciens pipelines sont donc annulés.

## Activer les merge trains {#enable-merge-trains}

Prérequis :

- Vous devez disposer du rôle Maintainer.
- Votre dépôt doit être un dépôt GitLab, et non un [dépôt externe](../ci_cd_for_external_repos/_index.md).
- Votre pipeline doit être [configuré pour utiliser les pipelines de merge request](merge_request_pipelines.md#prerequisites). Sinon, vos merge requests risquent de rester bloquées dans un état non résolu ou vos pipelines pourraient être abandonnés.
- Vous devez avoir [les pipelines de résultats fusionnés activés](merged_results_pipelines.md#enable-merged-results-pipelines).

Pour activer les merge trains :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Requêtes de fusion**.
1. Dans la section **Options de fusion**, assurez-vous que **Activer les pipelines de résultats fusionnés** est activé et sélectionnez **Activer les trains de fusion**.
1. Sélectionnez **Sauvegarder les modifications**.

## Démarrer un merge train {#start-a-merge-train}

Prérequis :

- Vous devez disposer des [autorisations](../../user/permissions.md) nécessaires pour fusionner ou pousser vers la branche cible.

Pour démarrer un merge train :

1. Accédez à une merge request.
1. Sélectionnez :
   - Lorsqu'aucun pipeline n'est en cours d'exécution, **Fusionner**.
   - Lorsqu'un pipeline est en cours d'exécution, [**Configurer la fusion automatique**](../../user/project/merge_requests/auto_merge.md).

Le statut du merge train de la merge request s'affiche sous le widget du pipeline avec un message similaire à `A new merge train has started and this merge request is the first of the queue. View merge train details.` Vous pouvez sélectionner le lien pour afficher le merge train.

D'autres merge requests peuvent maintenant être ajoutées au train.

## Afficher un merge train {#view-a-merge-train}

{{< history >}}

- Visualisation du merge train [introduite](https://gitlab.com/groups/gitlab-org/-/epics/13705) dans GitLab 17.3.

{{< /history >}}

Vous pouvez afficher le merge train pour obtenir une meilleure visibilité sur l'ordre et le statut des merge requests dans la file d'attente. La page de détails du merge train affiche les merge requests actives dans la file d'attente et les merge requests fusionnées qui faisaient partie du train.

Pour accéder aux détails du merge train depuis la liste des merge requests :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion**.
1. Au-dessus de la liste des merge requests, sélectionnez **Trains de fusion**.
1. facultatif. Filtrez les merge trains par branche cible.

Vous pouvez également accéder à cette vue en sélectionnant **Voir les détails du train de fusion** depuis :

- Le widget du pipeline et les notes système sur une merge request ajoutée à un merge train.
- La page de détails du pipeline pour un pipeline de merge train.

Vous pouvez également supprimer ({{< icon name="close" >}}) une merge request depuis la vue des détails du merge train.

## Ajouter une merge request à un merge train {#add-a-merge-request-to-a-merge-train}

{{< history >}}

- La fusion automatique pour les merge trains [introduite](https://gitlab.com/groups/gitlab-org/-/epics/10874) dans GitLab 17.2 [avec un flag](../../administration/feature_flags/_index.md) nommé `merge_when_checks_pass_merge_train`. Désactivée par défaut. Désactivé par défaut.
- La fusion automatique pour les merge trains [activée](https://gitlab.com/gitlab-org/gitlab/-/issues/470667) sur GitLab.com dans GitLab 17.2.
- La fusion automatique pour les merge trains [activée](https://gitlab.com/gitlab-org/gitlab/-/issues/470667) par défaut dans GitLab 17.4.
- La fusion automatique pour les merge trains [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174357) dans GitLab 17.7. L'indicateur de fonctionnalité `merge_when_checks_pass_merge_train` a été supprimé.

{{< /history >}}

Prérequis :

- Vous devez disposer des [autorisations](../../user/permissions.md) nécessaires pour fusionner ou pousser vers la branche cible.

Pour ajouter une merge request à un merge train :

1. Accédez à une merge request.
1. Sélectionnez :
   - Lorsqu'aucun pipeline n'est en cours d'exécution, **Fusionner**.
   - Lorsqu'un pipeline est en cours d'exécution, [**Configurer la fusion automatique**](../../user/project/merge_requests/auto_merge.md).

Le statut du merge train de la merge request s'affiche sous le widget du pipeline avec un message similaire à `This merge request is 2 of 3 in queue.`

Chaque merge train peut exécuter un [nombre maximum de pipelines en parallèle](#merge-train-parallel-pipeline-limit). La limite par défaut est de 20. Si vous ajoutez au merge train plus de merge requests que la limite autorisée, les merge requests supplémentaires sont mises en file d'attente jusqu'à ce qu'un pipeline se termine. Le nombre de merge requests en file d'attente est illimité.

## Supprimer une merge request d'un merge train {#remove-a-merge-request-from-a-merge-train}

Lorsque vous supprimez une merge request d'un merge train :

- Tous les pipelines des merge requests mises en file d'attente après la merge request supprimée redémarrent.
- Les pipelines redondants [sont annulés](#automatic-pipeline-cancellation).

Vous pouvez ajouter de nouveau la merge request à un merge train ultérieurement.

Pour supprimer une merge request d'un merge train :

- Depuis une merge request, sélectionnez **Annuler la fusion automatique**.
- Depuis les [détails du merge train](#view-a-merge-train), à côté de la merge request, sélectionnez {{< icon name="close" >}}.

## Ignorer le merge train et fusionner immédiatement {#skip-the-merge-train-and-merge-immediately}

Si vous avez une merge request prioritaire, comme un correctif critique qui doit être fusionné d'urgence, vous pouvez sélectionner **Fusionner immédiatement**.

> [!warning]
> La fusion immédiate peut utiliser beaucoup de ressources CI/CD. N'utilisez cette option que dans les situations critiques.

Lorsque vous fusionnez une merge request immédiatement :

- Les commits de la merge request sont fusionnés, en ignorant le statut du merge train.
- Les pipelines de merge train pour toutes les autres merge requests du train [sont annulés](#automatic-pipeline-cancellation).
- Un nouveau merge train démarre et toutes les merge requests du merge train d'origine sont ajoutées à ce nouveau merge train, avec un nouveau pipeline de merge train pour chacune. Ces nouveaux pipelines de merge train contiennent désormais les commits ajoutés par la merge request qui a été fusionnée immédiatement.

> [!note]
> L'option **merge immediately** peut ne pas être disponible si votre projet utilise la méthode de fusion [fast-forward](../../user/project/merge_requests/methods/_index.md#fast-forward-merge) et que la branche source est en retard par rapport à la branche cible. Consultez le [ticket 434070](https://gitlab.com/gitlab-org/gitlab/-/issues/434070) pour plus de détails.

### Fusionner immédiatement sans redémarrer les pipelines de merge train {#merge-immediately-without-restarting-merge-train-pipelines}

{{< details >}}

- Statut :  Expérience

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/414505) dans GitLab 16.5 [avec un flag](../../administration/feature_flags/_index.md) nommé `merge_trains_skip_train`. Désactivé par défaut.
- [Activée](https://gitlab.com/gitlab-org/gitlab/-/issues/422111) en tant que [fonctionnalité expérimentale](../../policy/development_stages_support.md) dans GitLab 16.10.

{{< /history >}}

> [!flag]
> Sur GitLab Self-Managed, cette fonctionnalité est disponible par défaut. Pour masquer la fonctionnalité, un administrateur peut [désactiver le feature flag](../../administration/feature_flags/_index.md) nommé `merge_trains_skip_train`. Sur GitLab.com et GitLab Dedicated, cette fonctionnalité est disponible.

Vous pouvez autoriser la fusion des merge requests sans redémarrer complètement un merge train en cours d'exécution. Utilisez cette fonctionnalité pour fusionner rapidement des modifications qui peuvent ignorer le pipeline en toute sécurité, par exemple des mises à jour mineures de documentation.

Vous ne pouvez pas ignorer les merge trains pour les méthodes de fusion fast-forward ou semi-linéaire. Pour plus d'informations, consultez le [ticket 429009](https://gitlab.com/gitlab-org/gitlab/-/issues/429009).

L'ignorance des merge trains est une fonctionnalité expérimentale. Elle peut être modifiée ou entièrement supprimée dans les futures versions de release.

> [!warning]
> Vous pouvez utiliser cette fonctionnalité pour fusionner rapidement des correctifs de sécurité ou des correctifs de bugs, mais les modifications de la merge request qui a ignoré le train ne sont pas vérifiées par rapport aux autres merge requests du train. Si ces autres pipelines de merge train se terminent avec succès et fusionnent, il existe un risque que les modifications combinées soient incompatibles. La branche cible pourrait alors nécessiter un travail supplémentaire pour résoudre les nouveaux échecs.

Prérequis :

- Vous devez disposer du rôle Maintainer.
- Vous devez avoir [les merge trains activés](#enable-merge-trains).

Pour activer l'ignorance du train sans redémarrage de pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Requêtes de fusion**.
1. Dans la section **Options de fusion**, assurez-vous que les options **Activer les pipelines de résultats fusionnés** et **Activer les trains de fusion** sont activées.
1. Sélectionnez **Fusionner immédiatement sans redémarrer le train de fusion**.
1. Sélectionnez **Sauvegarder les modifications**.

Pour fusionner une merge request en ignorant le merge train, utilisez le [point de terminaison de l'API de fusion des merge requests](../../api/merge_requests.md#merge-a-merge-request) pour fusionner avec l'attribut `skip_merge_train` défini sur `true`.

La merge request fusionne, et les pipelines de merge train existants ne sont pas annulés ni redémarrés.

### Limite de pipeline parallèle du merge train {#merge-train-parallel-pipeline-limit}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/374188) dans GitLab 19.0.

{{< /history >}}

Par défaut, chaque [merge train](../../ci/pipelines/merge_trains.md) peut exécuter un maximum de 20 pipelines en parallèle. Lorsque cette limite est atteinte, les merge requests supplémentaires sont mises en file d'attente jusqu'à ce qu'un emplacement de pipeline soit disponible.

Pour modifier cette limite pour votre projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Requêtes de fusion**.
1. Dans la section **Options de fusion**, définissez une valeur pour **Maximum parallel pipelines per merge train**. La valeur minimale est `1`. Une valeur de `1` traite les merge requests séquentiellement sans parallélisme.
1. Sélectionnez **Sauvegarder les modifications**.

La limite du projet ne peut pas dépasser la [limite de l'instance](../../administration/cicd/limits.md#merge-train-parallel-pipeline-limit).

Vous pouvez également utiliser l'[API des projets](../../api/projects.md), ou l'[API GraphQL](../../api/graphql/reference/_index.md#projectcicdsetting).

## Dépannage {#troubleshooting}

### Merge request retirée du merge train {#merge-request-dropped-from-the-merge-train}

Si une merge request devient impossible à fusionner pendant l'exécution d'un pipeline de merge train, le merge train retire automatiquement votre merge request. Les causes courantes incluent :

- La conversion de la merge request en [brouillon](../../user/project/merge_requests/drafts.md).
- Un conflit de fusion.
- Un nouveau fil de discussion non résolu, lorsque [tous les fils de discussion doivent être résolus](../../user/project/merge_requests/_index.md#prevent-merge-unless-all-threads-are-resolved) est activé.

Vous pouvez trouver la raison pour laquelle la merge request a été retirée du merge train dans les notes système. Vérifiez la section **Activité** dans l'onglet **Vue d'ensemble** pour trouver un message similaire à : `User removed this merge request from the merge train because ...`

### Impossible d'utiliser la fusion automatique {#cannot-use-auto-merge}

Vous ne pouvez pas utiliser la [fusion automatique](../../user/project/merge_requests/auto_merge.md) (anciennement **Fusionner lorsque le pipeline réussit**) pour ignorer le merge train lorsque les merge trains sont activés. Consultez le [ticket 12267](https://gitlab.com/gitlab-org/gitlab/-/issues/12267) pour plus d'informations.

### Impossible de réessayer le pipeline de merge train {#cannot-retry-merge-train-pipeline}

Lorsqu'un pipeline de merge train échoue, la merge request est retirée du train et le pipeline ne peut pas être réessayé après son échec. Les pipelines de merge train s'exécutent sur le résultat fusionné des modifications de la merge request et des modifications des autres merge requests déjà présentes dans le train. Si la merge request est retirée du train, le résultat fusionné est obsolète et le pipeline ne peut pas être réessayé.

Vous pouvez :

- [Ajoutez de nouveau la merge request au train](#add-a-merge-request-to-a-merge-train), ce qui déclenche un nouveau pipeline.
- Ajoutez le mot-clé [`retry`](../yaml/_index.md#retry) au job s'il échoue de manière intermittente. S'il réussit après une nouvelle tentative, la merge request n'est pas supprimée du merge train.

### Impossible d'ajouter une merge request au merge train {#cannot-add-a-merge-request-to-the-merge-train}

Lorsque [**Les pipelines doivent réussir**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) est activé, mais que le dernier pipeline a échoué :

- Les options **Configurer la fusion automatique** ou **Fusionner** ne sont pas disponibles.
- La merge request affiche `The pipeline for this merge request failed. Please retry the job or push a new commit to fix the failure.`

Avant de pouvoir rajouter une merge request à un merge train, vous pouvez essayer de :

- Réessayez le job ayant échoué. S'il réussit et qu'aucun autre job n'a échoué, le pipeline est marqué comme réussi.
- Relancez l'intégralité du pipeline. Dans l'onglet **Pipelines**, sélectionnez **Exécuter le pipeline**.
- Poussez un nouveau commit qui résout le problème, ce qui déclenche également un nouveau pipeline.

Consultez [le ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/35135) pour plus d'informations.

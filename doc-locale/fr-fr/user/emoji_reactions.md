---
stage: Plan
group: Work Items
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Réactions par émoji
description: "Réagissez avec des émojis sur les tickets, les commentaires et d'autres éléments pour donner votre avis sans rédiger un long fil de discussion."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lors d'une collaboration en ligne, les occasions de manifester votre enthousiasme sont moins nombreuses. Réagissez avec des émojis sur :

- [Tickets](project/issues/_index.md).
- [Tâches](tasks.md).
- [Merge requests](project/merge_requests/_index.md) et [snippets](snippets.md).
- [Epics](group/epics/_index.md).
- [Objectifs et résultats clés](okrs.md).
- [Pages wiki](project/wiki/_index.md).
- Partout où vous pouvez avoir un fil de discussion.

![Sélecteur de réactions par émoji avec différentes catégories, dont une zone de recherche.](img/award_emoji_select_v14_6.png)

Les réactions par émoji facilitent grandement l'échange de commentaires sans créer un long fil de discussion.

Les émojis « Pouce en l'air » et « Pouce en bas » servent à calculer la position d'un ticket ou d'une merge request lors du [tri par popularité](project/issues/sorting_issue_lists.md#sorting-by-popularity).

Pour plus d'informations, consultez l'[API des réactions par émoji](../api/emoji_reactions.md).

## Réactions par émoji pour les commentaires {#emoji-reactions-for-comments}

Les réactions par émoji peuvent également être appliquées à des commentaires individuels lorsque vous souhaitez célébrer une réalisation ou marquer votre accord avec une opinion.

Pour ajouter une réaction par émoji :

1. Dans le coin supérieur droit du commentaire, sélectionnez le sourire ({{< icon name="slight-smile" >}}).
1. Sélectionnez un émoji dans le sélecteur d'émojis.

Pour supprimer une réaction par émoji, sélectionnez à nouveau l'émoji.

## Émojis personnalisés {#custom-emoji}

Les émojis personnalisés s'affichent dans le sélecteur d'émojis partout où vous pouvez réagir avec des émojis.

Pour ajouter une réaction par émoji à un commentaire ou une description :

1. Sélectionnez **Ajouter une réaction** ({{< icon name="slight-smile" >}}).
1. Sélectionnez le logo GitLab ({{< icon name="tanuki" >}}) ou faites défiler vers le bas jusqu'à la section **Personnalisé**.
1. Sélectionnez un émoji dans le sélecteur d'émojis.

![Section des émojis personnalisés dans le sélecteur de réactions.](img/custom_emoji_reactions_v16_2.png)

Pour les utiliser dans une zone de texte, saisissez le nom du fichier entre deux deux-points. Par exemple, `:thank-you:`.

### Importer des émojis personnalisés dans un groupe {#upload-custom-emoji-to-a-group}

Importez vos émojis personnalisés dans un groupe pour les utiliser dans tous ses sous-groupes et projets.

Prérequis :

- Vous devez disposer au minimum du rôle Développeur pour le groupe.

Pour importer des émojis personnalisés :

1. Sur une description ou un commentaire, sélectionnez **Ajouter une réaction** ({{< icon name="slight-smile" >}}).
1. En bas du sélecteur d'émojis, sélectionnez **Créer un nouvel émoji**.
1. Saisissez un nom et une URL pour l'émoji personnalisé.
1. Sélectionnez **Enregistrer**.

Vous pouvez également importer des émojis personnalisés dans une instance GitLab via l'API GraphQL. Pour plus d'informations, consultez [utiliser des émojis personnalisés avec GraphQL](../api/graphql/custom_emoji.md).

---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Naviguez entre les merge requests chaînées qui s'appuient les unes sur les autres pour livrer une fonctionnalité."
title: Merge requests empilées
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/232425) dans GitLab 19.1.

{{< /history >}}

Lorsque vous divisez un changement important en merge requests plus petites qui s'appuient les unes sur les autres, GitLab les regroupe dans une pile. Chaque merge request dans une pile cible la branche source de la merge request en dessous d'elle, de sorte que les changements forment une chaîne depuis la branche par défaut jusqu'au travail le plus récent.

Utilisez les piles pour :

- Continuer à apporter de nouveaux changements pendant que les merge requests précédentes sont en cours de révision.
- Réviser et fusionner chaque changement indépendamment, depuis le bas de la pile vers le haut.
- Maintenir la visibilité des relations entre les merge requests dépendantes lors de la révision.

GitLab détecte automatiquement une pile. Une merge request rejoint une pile lorsqu'elle cible la branche source d'une autre merge request ouverte, ou lorsqu'une autre merge request ouverte cible sa branche source. Une pile peut contenir jusqu'à 10 merge requests.

Pour créer des merge requests empilées depuis la ligne de commande, utilisez [les diffs empilés](../stacked_diffs.md) dans la CLI GitLab.

## Naviguer dans une pile {#navigate-a-stack}

Lorsqu'une merge request fait partie d'une pile, l'en-tête de la merge request affiche un contrôle de pile à côté de la branche source. La liste déroulante affiche la position de la merge request actuelle dans la pile, par exemple **1 of 2**.

![Une liste déroulante dans l'en-tête de la merge request, développée pour afficher les merge requests dans la pile.](img/stacked_merge_requests_v19_1.png)

Pour vous déplacer entre les merge requests dans une pile :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion**.
1. Ouvrez une merge request qui appartient à une pile.
1. Dans l'en-tête de la merge request, sélectionnez la liste déroulante (par exemple, **1 of 2**).
1. Dans la liste, sélectionnez la merge request que vous souhaitez ouvrir.

La liste affiche toutes les merge requests de la pile, triées du haut de la pile vers le bas. Pour chaque merge request, la liste affiche le titre, la date d'ouverture ainsi que le nombre de fichiers modifiés, d'ajouts et de suppressions. Une flèche indique la merge request que vous consultez.

## Fusionner une pile {#merge-a-stack}

GitLab est conçu pour vous permettre de fusionner une pile depuis le bas vers le haut. La merge request en bas de la pile cible la branche par défaut et fusionne en premier, même si c'est la seule merge request qui cible directement la branche par défaut. Les merge requests au-dessus d'elle fusionnent ensuite dans l'ordre.

Pour fusionner une pile depuis le bas vers le haut :

1. Fusionnez la merge request du bas dans la branche par défaut.
1. GitLab recible automatiquement la merge request suivante vers la branche par défaut.
1. Révisez et fusionnez la merge request reciblée.
1. Répétez les étapes précédentes jusqu'à ce que la pile soit vide.

Pour plus d'informations sur la façon dont GitLab met à jour la branche cible, consultez [mettre à jour les merge requests lorsque la branche cible fusionne](../_index.md#update-merge-requests-when-target-branch-merges).

## Sujets connexes {#related-topics}

- [Diffs empilés](../stacked_diffs.md)
- [Workflow des merge requests](../_index.md)

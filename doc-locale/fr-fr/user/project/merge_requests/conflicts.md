---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Comprenez les conflits de merge et apprenez à les résoudre dans les projets Git.
title: Conflits de merge
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Des conflits de merge surviennent lorsque deux branches dans un merge request, la source et la cible, ont des modifications différentes sur les mêmes lignes de code. Dans la plupart des cas, GitLab peut fusionner les modifications, mais lorsque des conflits surviennent, vous devez décider quelles modifications conserver.

![Un merge request bloqué en raison d'un conflit de merge](img/conflicts_v16_7.png)

Pour résoudre un merge request avec des conflits, vous devez soit :

- Créer un commit de merge.
- Résoudre le conflit via un rebase.

GitLab résout les conflits en créant un commit de merge dans la branche source sans le fusionner dans la branche cible. Vous pouvez ensuite examiner et tester le commit de merge pour vérifier qu'il ne contient aucune modification non intentionnelle et ne compromet pas votre build.

## Comprendre les blocs de conflit {#understand-conflict-blocks}

Lorsque Git détecte un conflit nécessitant une décision de votre part, il marque le début et la fin du bloc de conflit avec des marqueurs de conflit :

- `<<<<<<< HEAD` marque le début du bloc de conflit.
- Vos modifications sont affichées.
- `=======` marque la fin de vos modifications.
- Les dernières modifications de la branche cible sont affichées.
- `>>>>>>>` marque la fin du conflit.

Pour résoudre un conflit, supprimez :

1. La version des lignes en conflit que vous ne souhaitez pas conserver.
1. Les trois marqueurs de conflit : le début, la fin et la ligne `=======` entre les deux versions.

## Conflits que vous pouvez résoudre dans l'interface utilisateur {#conflicts-you-can-resolve-in-the-user-interface}

Vous pouvez résoudre les conflits de merge dans l'interface utilisateur GitLab si le fichier en conflit :

- Est un fichier texte non binaire.
- Fait moins de 200 Ko avec les marqueurs de conflit ajoutés.
- Utilise un encodage compatible UTF-8.
- Ne contient pas de marqueurs de conflit.
- Existe sous le même chemin dans les deux branches.

Si un fichier ne répond pas à ces critères, vous devez résoudre le conflit manuellement.

## Méthodes de résolution des conflits {#conflict-resolution-methods}

GitLab affiche les [conflits disponibles pour la résolution](#conflicts-you-can-resolve-in-the-user-interface) dans l'interface utilisateur, et vous pouvez également résoudre les conflits en utilisant les méthodes suivantes :

- GitLab Duo :  Idéal pour la résolution automatique et de bout en bout des conflits.
- Mode interactif :  Idéal pour les conflits où vous n'avez qu'à sélectionner la version d'une ligne à conserver.
- Éditeur en ligne :  Convient aux conflits complexes nécessitant des modifications manuelles pour combiner les changements.
- Ligne de commande :  Offre un contrôle total sur les conflits complexes. Pour plus d'informations, consultez [résoudre les conflits depuis la ligne de commande](../../../topics/git/git_rebase.md#resolve-conflicts-from-the-command-line).

### Résoudre les conflits avec GitLab Duo {#resolve-conflicts-with-gitlab-duo}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut :  Bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235919) dans GitLab 19.0 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `mr_ai_resolve_conflicts`. Activé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

GitLab Duo peut analyser de manière autonome les conflits de merge, modifier les fichiers en conflit, créer un commit et pousser vers la branche source.

Prérequis :

- Le rôle Developer, Maintainer ou Owner.
- Accès push à la branche source.
- [Prérequis de la plateforme GitLab Duo Agent](../../duo_agent_platform/_index.md#prerequisites).
- [Fonctionnalités bêta et expérimentales](../../duo_agent_platform/turn_on_off.md#turn-on-beta-and-experimental-features) activées.
- Un merge request avec des conflits [pouvant être résolus dans l'interface utilisateur](#conflicts-you-can-resolve-in-the-user-interface).

Pour résoudre les conflits avec GitLab Duo :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez le merge request.
1. Sélectionnez **Vue d'ensemble**.
1. Trouvez les détails du conflit de merge et demandez à GitLab Duo de résoudre les conflits :
   - Dans la section des rapports du merge request, sélectionnez **Résoudre les conflits**, puis sélectionnez **Resolve with GitLab Duo**.
   - Dans le widget de merge, trouvez la ligne de vérification des conflits et sélectionnez **Resolve with GitLab Duo**.

GitLab Duo analyse les conflits, les résout, valide les modifications et pousse vers la branche source. Une fois terminé, GitLab Duo publie un commentaire récapitulatif sur le merge request.

GitLab Duo respecte les règles de protection des branches et ne force pas le push vers les branches protégées.

### Mode interactif {#interactive-mode}

Le mode interactif fusionne la branche cible dans la branche source avec vos modifications choisies.

Pour résoudre les conflits de merge en mode interactif :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez le merge request.
1. Sélectionnez **Vue d'ensemble** et faites défiler jusqu'à la section des rapports du merge request.
1. Trouvez le message de conflits de merge et sélectionnez **Résoudre les conflits**. GitLab affiche une liste de fichiers avec des conflits de merge. Les lignes en conflit sont mises en surbrillance.

1. Pour chaque conflit, sélectionnez **Utilisez les nôtres** ou **Utilisez les leurs** pour marquer la version des lignes en conflit que vous souhaitez conserver. Cette décision est connue sous le nom de « résolution du conflit ».
1. Lorsque vous avez résolu tous les conflits, saisissez un **Message de commit**.
1. Sélectionnez **Validation sur la branche source**.

### Éditeur en ligne {#inline-editor}

Certains conflits de merge sont plus complexes et vous devez modifier les lignes manuellement pour les résoudre.

L'éditeur de résolution de conflits de merge vous aide à résoudre ces conflits dans GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez le merge request.
1. Sélectionnez **Vue d'ensemble** et faites défiler jusqu'à la section des rapports du merge request.
1. Trouvez le message de conflits de merge et sélectionnez **Résoudre les conflits**. GitLab affiche une liste de fichiers avec des conflits de merge.
1. Trouvez le fichier à modifier manuellement et faites défiler jusqu'au bloc de conflit.
1. Dans l'en-tête de ce fichier, sélectionnez **Modifier en ligne** pour ouvrir l'éditeur. Dans cet exemple, le bloc de conflit commence à la ligne 1350 et se termine à la ligne 1356 :

   ![Éditeur de conflits de merge](img/merge_conflict_editor_v16_7.png)

1. Après avoir résolu le conflit, saisissez un **Message de commit**.
1. Sélectionnez **Validation sur la branche source**.

## Rebase {#rebase}

Si votre merge request est bloqué avec un message `Checking ability to merge automatically`, vous pouvez :

- Dans un commentaire du merge request, exécutez l'[action rapide `/rebase`](../quick_actions.md#rebase).
- Dans le widget de merge, sélectionnez **Rebaser la branche source**.
- [Rebaser avec Git](../../../topics/git/git_rebase.md#rebase).

Pour résoudre les problèmes de pipeline CI/CD, consultez [le débogage des pipelines CI/CD](../../../ci/debugging.md).

Pour les projets utilisant la méthode de merge semi-linéaire ou fast-forward, vous pouvez également activer le [rebase automatique avant le merge](methods/_index.md#automatic-rebase-before-merge) pour ignorer l'étape de rebase manuelle.

### Rebase dans l'interface utilisateur GitLab {#rebase-in-the-gitlab-ui}

Pour déclencher un rebase depuis l'interface utilisateur GitLab, utilisez l'[action rapide `/rebase`](../quick_actions.md#rebase) ou l'option de rebase dans le widget du merge request.

Prérequis :

- Aucun conflit de merge n'existe.
- Vous devez disposer au minimum du [rôle Developer](../../permissions.md) pour le projet source.
- Si le merge request est dans une duplication, celle-ci doit autoriser les commits [des membres du projet en amont](allow_collaboration.md).

Pour rebaser la branche d'un merge request depuis l'interface utilisateur GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et trouvez le merge request.
1. L'une ou l'autre des options :
   - Dans l'onglet **Vue d'ensemble**, faites défiler jusqu'au widget du merge request et sélectionnez **Rebaser la branche source**.
   - Dans un commentaire, saisissez `/rebase` et sélectionnez **Commentaire**.

GitLab planifie puis exécute un rebase de la branche par rapport à la branche par défaut. GitLab affiche le rebase terminé sous forme de note système.

> [!note]
> Si vous avez configuré la signature des commits pour les commits effectués via l'interface utilisateur GitLab, les commits web perdent leurs signatures de commit [lors du rebase via l'interface utilisateur](../repository/signed_commits/web_commits.md#web-commits-become-unsigned-after-rebase).

## Sujets connexes {#related-topics}

- [Rebase et résolution des conflits](../../../topics/git/git_rebase.md)
- [Introduction au rebase Git et au force-push](../../../topics/git/git_rebase.md)
- [Applications Git pour visualiser le workflow Git](https://git-scm.com/downloads/guis)
- [Résolution automatique des conflits avec `git rerere`](https://git-scm.com/book/en/v2/Git-Tools-Rerere)

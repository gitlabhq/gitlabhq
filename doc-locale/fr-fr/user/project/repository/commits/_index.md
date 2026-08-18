---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Afficher des informations sur l'historique des commits d'un dépôt."
title: Validation
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- La liste des commits a été [repensée](https://gitlab.com/groups/gitlab-org/-/epics/17482) avec des commits regroupés, une recherche par jetons et un nouveau menu d'actions dans GitLab 19.1.

{{< /history >}}

La liste **Validation** affiche l'historique des commits de votre dépôt. Utilisez-la pour parcourir les modifications du code, afficher les détails des commits et vérifier les signatures des commits. Les commits sont regroupés par jour, et vous pouvez filtrer la liste par auteur, message de commit, date ou révision Git.

La liste affiche :

- Hash de commit : Identifiant unique (SHA) pour chaque commit.
- Message de commit : Titre et description du commit.
- Auteur : Nom et avatar de l'utilisateur qui a effectué le commit.
- Horodatage : Date de création du commit.
- Statut du pipeline : Résultats du pipeline CI/CD, si configuré.
- Vérification de la signature : Statut de la signature GPG, SSH ou X.509.
- Tags : Tous les tags pointant vers ce commit.

![Exemple de liste de commits d'un dépôt](img/repository_commits_list_v19_1.png)

## Afficher les commits {#view-commits}

Pour afficher l'historique des commits de votre dépôt :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Validation**.

Pour afficher la description complète d'un commit, sélectionnez l'icône de développement ({{< icon name="chevron-down" >}}) sur le côté droit du commit. Pour réduire la description, sélectionnez à nouveau l'icône de développement ({{< icon name="chevron-down" >}}).

## Afficher les détails d'un commit {#view-commit-details}

Examinez les modifications spécifiques apportées dans n'importe quel commit, y compris les modifications, ajouts et suppressions de fichiers.

Pour afficher les détails d'un commit :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Validation**.
1. Sélectionnez le commit pour ouvrir la page de détails du commit.

La page de détails du commit affiche :

- Informations sur le commit : Hash du commit, auteur, validateur, commits parents et horodatage.
- Message de commit : Titre et description du commit.
- Modifications de fichiers : Tous les fichiers modifiés avec la vue diff.
- Statistiques : Nombre de lignes modifiées, ajoutées et supprimées.
- Détails du pipeline : Statut et détails du pipeline CI/CD associé.
- Références : Branches et tags contenant ce commit.
- Merge requests associées : Liens vers les merge requests associées au commit.

## Parcourir les fichiers du dépôt par révision Git {#browse-repository-files-by-git-revision}

Pour afficher tous les fichiers et dossiers du dépôt à une révision Git spécifique, telle qu'un SHA de commit, un nom de branche ou un tag :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Validation**.
1. Choisissez l'une des options suivantes :
   - Filtrer par révision Git :
      1. En haut, sélectionnez pour ouvrir la liste déroulante **Sélectionner une révision Git**.
      1. Sélectionnez ou recherchez une révision Git.
   - Sélectionnez un commit spécifique dans la liste des commits.
1. En haut à droite, sélectionnez **Parcourir les fichiers**.

Vous êtes redirigé vers la page du [dépôt](../_index.md) à cette révision spécifique.

## Filtrer et rechercher des commits {#filter-and-search-commits}

Utilisez la barre de recherche pour filtrer l'historique des commits par auteur, message de commit ou date. Vous pouvez combiner plusieurs filtres simultanément.

### Filtrer par date {#filter-by-date}

Pour filtrer les commits par date :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Validation**.
1. Dans la barre de recherche, sélectionnez **Committed after** ou **Committed before** dans la liste déroulante de filtres.
1. Saisissez une date.

Pour afficher les commits d'une plage de dates spécifique, utilisez les deux filtres conjointement.

### Filtrer par auteur {#filter-by-author}

Pour filtrer les commits par un ou plusieurs auteurs :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Validation**.
1. Dans la barre de recherche, sélectionnez **Auteur** dans la liste déroulante de filtres.
1. Sélectionnez ou recherchez un ou plusieurs auteurs.

La liste est mise à jour pour n'afficher que les commits des auteurs sélectionnés.

Si le filtrage par auteur ne fonctionne pas pour les noms contenant des caractères spéciaux, utilisez le format de paramètre d'URL. Par exemple, ajoutez `?author=Elliot%20Stevens` à l'URL.

### Filtrer par révision Git {#filter-by-git-revision}

Pour filtrer les commits par révision Git, telle qu'une branche, un tag ou un SHA de commit :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Validation**.
1. Dans la liste déroulante en haut, sélectionnez ou recherchez une révision Git. Par exemple, un nom de branche, un tag ou un SHA de commit.
1. Sélectionnez la révision Git pour afficher la liste des commits filtrés.

### Rechercher par message de commit {#search-by-commit-message}

Pour rechercher des commits par contenu du message :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Validation**.
1. Dans la barre de recherche, sélectionnez **Message** dans la liste déroulante de filtres.
1. Saisissez vos termes de recherche.

Vous pouvez également rechercher par SHA de commit, complet ou partiel, pour trouver directement un commit spécifique.

### Partager et mettre en favoris des vues filtrées {#share-and-bookmark-filtered-views}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/599000) dans GitLab 19.1.

{{< /history >}}

Lorsque vous filtrez la liste des commits ou modifiez la taille de la page, l'URL est mise à jour pour refléter votre vue actuelle. Vous pouvez :

- Copiez l'URL pour partager une vue filtrée.
- Mettez l'URL en favoris pour enregistrer une combinaison de filtres.
- Utilisez les boutons Précédent et Suivant du navigateur pour naviguer entre les états de filtre.

L'URL utilise ces paramètres :

| Paramètre          | Description |
|--------------------|-------------|
| `author`           | Nom d'utilisateur de l'auteur du commit. |
| `message`          | Texte à rechercher dans les messages de commit. |
| `committed_after`  | Date du commit le plus ancien, au format `YYYY-MM-DD`. |
| `committed_before` | Date du commit le plus récent, au format `YYYY-MM-DD`. |
| `page_size`        | Nombre de commits par page. La valeur par défaut est `20`. |

## Naviguer entre les pages de commits {#navigate-between-pages-of-commits}

La liste des commits utilise une pagination basée sur les curseurs. Pour naviguer entre les pages :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Validation**.
1. En bas de la liste, sélectionnez **Précédent** ou **Suivant** pour naviguer entre les pages.

## Accéder aux actions de la liste de commits {#access-commit-list-actions}

La page des commits inclut un menu d'actions avec des liens rapides pour la révision Git actuelle.

Pour accéder au menu d'actions :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Validation**.
1. Dans le coin supérieur droit, sélectionnez l'ellipse verticale ({{< icon name="ellipsis_v" >}}) pour ouvrir le menu d'actions.

Le menu d'actions inclut :

- **Parcourir les fichiers** : Afficher tous les fichiers du dépôt à la révision Git sélectionnée.
- **Subscribe to commits RSS feed** : S'abonner à un flux RSS des commits pour la révision actuelle.

## Effectuer un cherry-pick d'un commit {#cherry-pick-a-commit}

Appliquer les modifications d'un commit spécifique à un autre.

Prérequis :

- Vous devez disposer du rôle Developer, Maintainer ou Owner pour le projet.
- La branche cible doit exister.

Pour effectuer un cherry-pick d'un commit :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Validation**.
1. Sélectionnez le commit sur lequel vous souhaitez effectuer un cherry-pick.
1. Dans le coin supérieur droit, sélectionnez **Options**, puis **Effectuer un cherry-pick**.
1. Dans la boîte de dialogue :
   - Dans les listes déroulantes, sélectionnez le projet cible et la branche.
   - facultatif. Sélectionnez **Start a new merge request** pour créer une merge request avec les modifications.
   - Sélectionnez **Effectuer un cherry-pick**.

GitLab crée un nouveau commit sur la branche cible avec les modifications sélectionnées par cherry-pick. Si la branche est [protégée](../branches/protected.md) ou que vous ne disposez pas des autorisations appropriées, GitLab vous invite à [créer une nouvelle merge request](../../merge_requests/_index.md#create-a-merge-request).

## Défaire un commit {#revert-a-commit}

Créer un nouveau commit qui annule les modifications d'un commit précédent.

Prérequis :

- Vous devez disposer du rôle Developer, Maintainer ou Owner pour le projet.

Pour défaire un commit :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Validation**.
1. Sélectionnez le commit que vous souhaitez défaire.
1. Dans le coin supérieur droit, sélectionnez **Options**, puis **Défaire**.
1. Dans la boîte de dialogue :
   - Sélectionnez la branche cible pour le commit de restauration.
   - facultatif. Sélectionnez **Start a new merge request** pour créer une merge request.
   - Sélectionnez **Défaire**.

GitLab crée un nouveau commit qui inverse les modifications du commit sélectionné. Si la branche est [protégée](../branches/protected.md) ou que vous ne disposez pas des autorisations appropriées, GitLab vous invite à [créer une nouvelle merge request](../../merge_requests/_index.md#create-a-merge-request).

## Télécharger le contenu d'un commit {#download-commit-contents}

Pour télécharger le contenu du diff d'un commit :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Validation**.
1. Sélectionnez le commit que vous souhaitez télécharger.
1. Dans le coin supérieur droit, sélectionnez **Options**.
1. Sous **Téléchargements**, sélectionnez **Plain Diff**.

## Vérifier les signatures des commits {#verify-commit-signatures}

GitLab vérifie les signatures GPG, SSH et X.509 pour garantir l'authenticité des commits. Les commits vérifiés affichent un badge **Vérifié**.

Pour plus d'informations, consultez [les commits signés](../signed_commits/_index.md).

### Afficher les détails de la signature {#view-signature-details}

Pour afficher les informations de signature :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Validation**.
1. Trouvez un commit avec un badge **Vérifié** ou **Non vérifiée**.
1. Sélectionnez le badge pour afficher les détails de la signature, notamment :
   - Type de signature (GPG, SSH ou X.509)
   - Empreinte de clé
   - Statut de vérification
   - Identité du signataire

## Afficher le statut et les détails du pipeline {#view-pipeline-status-and-details}

La liste des commits inclut une icône de statut du pipeline CI/CD à côté de chaque commit. Pour afficher les détails du pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Validation**.
1. Sélectionnez l'icône de statut du pipeline à côté de n'importe quel commit.

## Sujets connexes {#related-topics}

- [Commits signés](../signed_commits/_index.md)
- [Comparer les révisions](../compare_revisions.md)
- [Gestion des fichiers](../files/_index.md)
- [Historique des fichiers Git](../files/git_history.md)
- [Tags](../tags/_index.md)

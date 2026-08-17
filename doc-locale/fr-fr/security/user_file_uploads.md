---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Gérez le contrôle d'accès et la sécurité des fichiers téléversés vers les tickets, les merge requests et les epics."
title: Téléversements de fichiers utilisateur
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les utilisateurs peuvent téléverser des fichiers vers :

- Des tickets ou des merge requests dans un projet.
- Des epics dans un groupe.

GitLab génère des URL directes pour ces fichiers téléversés avec un identifiant aléatoire de 32 caractères afin d'empêcher les utilisateurs non autorisés de deviner les URL. Cette randomisation offre une certaine sécurité pour les fichiers contenant des informations sensibles.

Les fichiers téléversés par les utilisateurs vers les tickets GitLab, les merge requests et les epics contiennent `/uploads/<32-character-id>` dans le chemin de l'URL.

> [!warning]
> Soyez prudent lorsque vous téléchargez des fichiers provenant de sources inconnues ou non fiables, en particulier si le fichier est un exécutable ou un script.

## Contrôle d'accès pour les fichiers téléversés {#access-control-for-uploaded-files}

L'accès aux fichiers non-image téléversés vers :

- Les tickets ou les merge requests est déterminé par la visibilité du projet.
- Les epics de groupe est déterminé par la visibilité du groupe.

Pour les projets ou groupes publics, tout le monde peut accéder à ces fichiers via l'URL de pièce jointe directe, même si le ticket, la merge request ou l'epic est confidentiel. Pour les projets privés et internes, GitLab garantit que seuls les membres authentifiés du projet peuvent accéder aux fichiers téléversés non-image, tels que les PDF. Par défaut, les fichiers image ne font pas l'objet de la même restriction, et tout le monde peut les afficher à l'aide de l'URL. Pour protéger les fichiers image, [activez les vérifications d'autorisation pour tous les fichiers multimédias](#enable-authorization-checks-for-all-media-files), afin qu'ils ne soient visibles que par les utilisateurs authentifiés.

Les vérifications d'authentification pour les images peuvent entraîner des problèmes d'affichage dans le corps des e-mails de notification. Les e-mails sont fréquemment lus depuis des clients (tels qu'Outlook, Apple Mail ou votre appareil mobile) qui ne sont pas authentifiés auprès de GitLab. Les images dans les e-mails apparaissent cassées et indisponibles si le client n'est pas autorisé à accéder à GitLab.

## Activer les vérifications d'autorisation pour tous les fichiers multimédias {#enable-authorization-checks-for-all-media-files}

Seuls les membres authentifiés du projet peuvent afficher les pièces jointes non-image (y compris les PDF) dans les projets privés et internes.

Pour appliquer les exigences d'authentification aux fichiers image dans les projets privés ou internes :

Prérequis :

- Vous devez avoir le rôle Chargé de maintenance ou Propriétaire pour le projet.
- Les paramètres de visibilité de votre projet doivent être **Privé** ou **Interne**.

Pour configurer les paramètres d'authentification pour tous les fichiers multimédias :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Faites défiler jusqu'à **Visibilité du projet** et sélectionnez **Nécessite une authentification pour afficher les fichiers multimédia**.

> [!note]
> Vous ne pouvez pas sélectionner cette option pour les projets publics.

## Supprimer des fichiers téléversés {#delete-uploaded-files}

{{< history >}}

- Prise en charge de l'API REST [ajoutée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) dans GitLab 17.2.

{{< /history >}}

Vous devez supprimer un fichier téléversé lorsque ce fichier contient des informations sensibles ou confidentielles. Une fois le fichier supprimé, les utilisateurs ne peuvent plus y accéder et l'URL directe renvoie une erreur 404.

Les propriétaires et les mainteneurs de projet peuvent utiliser l'[explorateur GraphQL interactif](../api/graphql/_index.md#interactive-graphql-explorer) pour accéder à un [endpoint GraphQL](../api/graphql/reference/_index.md#mutationuploaddelete) et supprimer un fichier téléversé.

Par exemple :

```graphql
mutation{
  uploadDelete(input: { projectPath: "<path/to/project>", secret: "<32-character-id>" , filename: "<filename>" }) {
    upload {
      id
      size
      path
    }
    errors
  }
}
```

Les membres du projet qui ne disposent pas du rôle Mainteneur ou Propriétaire ne peuvent pas accéder à cet endpoint GraphQL.

Vous pouvez également utiliser l'API REST pour les [projets](../api/project_markdown_uploads.md#delete-an-uploaded-file-by-secret-and-filename) ou les [groupes](../api/group_markdown_uploads.md#delete-an-uploaded-file-by-secret-and-filename) afin de supprimer un fichier téléversé.

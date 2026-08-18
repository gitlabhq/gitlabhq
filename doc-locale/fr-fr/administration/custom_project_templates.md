---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: Configurez des modèles de projets et rendez-les disponibles pour tous les projets de votre instance GitLab.
title: Modèles de projets personnalisés pour votre instance
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour accélérer la création de projets sur votre instance, configurez un groupe contenant des modèles de projets. Les utilisateurs peuvent alors créer [de nouveaux projets basés sur vos modèles](../user/project/_index.md#create-a-project-from-a-custom-template) qui incluent les outils et la configuration communs que vous spécifiez.

Pour en savoir plus sur les données copiées à partir des modèles de projets, consultez [ce qui est copié à partir des modèles](../user/group/custom_project_templates.md#what-is-copied-from-the-templates).

Avant de rendre les modèles de projets disponibles pour votre instance, sélectionnez un groupe pour gérer les modèles. Pour éviter toute modification inattendue des modèles, créez un nouveau groupe à cet effet, plutôt que de réutiliser un groupe existant. Si vous réutilisez un groupe existant créé à un autre effet, les utilisateurs disposant du rôle Maintainer pourraient modifier les modèles de projets sans en comprendre les effets secondaires.

## Sélectionner un groupe pour gérer les modèles de projets {#select-a-group-to-manage-template-projects}

Prérequis :

- Accès administrateur.

Pour sélectionner le groupe chargé de gérer les modèles de projets pour votre instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Modèles**.
1. Développez **Modèles de projets personnalisés**.
1. Sélectionnez un groupe à utiliser.
1. Sélectionnez **Sauvegarder les modifications**.

Une fois que vous avez configuré le groupe comme source de modèles de projets, les nouveaux projets ajoutés à ce groupe deviennent disponibles en tant que modèles.

## Configurer un projet pour une utilisation en tant que modèle {#configure-a-project-for-use-as-a-template}

Après avoir créé un groupe pour gérer les modèles de projets, configurez la visibilité et la disponibilité des fonctionnalités de chaque modèle de projet.

Prérequis :

- Vous devez être soit l'administrateur de l'instance, soit un utilisateur disposant d'un rôle vous permettant de configurer le projet.

1. Assurez-vous que le projet appartient directement au groupe, et non via un sous-groupe. Les projets des sous-groupes du groupe choisi ne peuvent pas être utilisés comme modèles.
1. Pour configurer quels utilisateurs peuvent sélectionner le modèle de projet, définissez la [visibilité du projet](../user/public_access.md#change-project-visibility) :
   - Les projets **Public** et **Interne** peuvent être sélectionnés par tout utilisateur authentifié.
   - Les projets **Privé** ne peuvent être sélectionnés que par les membres de ce projet.
1. Examinez les [paramètres des fonctionnalités](../user/project/settings/_index.md#configure-project-features-and-permissions) du projet. Toutes les fonctionnalités de projet activées doivent être définies sur **Toute personne ayant accès**, à l'exception de **GitLab Pages** et de **Sécurité et conformité**.

Les informations du dépôt et de la base de données copiées vers chaque nouveau projet sont identiques aux données exportées avec l'import/export de projets GitLab. Cela inclut l'historique complet des commits Git du modèle de projet. Pour plus d'informations, consultez [migrer les données GitLab à l'aide des exports de fichiers](../user/project/settings/import_export.md).

Pour créer un modèle sans historique de commits, initialisez votre modèle de projet avec un seul commit contenant tous les fichiers que vous souhaitez inclure.

## Sujets connexes {#related-topics}

- [Modèles de projets personnalisés pour les groupes](../user/group/custom_project_templates.md).

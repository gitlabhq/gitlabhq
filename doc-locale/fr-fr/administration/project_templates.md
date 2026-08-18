---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: Configurez des modèles de projets personnalisés et intégrés pour les projets de votre instance GitLab.
title: Modèles de projets pour votre instance
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les modèles de projets remplissent les nouveaux projets avec des fichiers et une configuration. Sur votre instance, vous pouvez configurer des modèles de projets personnalisés à partir d'un groupe que vous gérez, et contrôler si les modèles de projets intégrés sont disponibles pour les utilisateurs.

## Modèles de projets personnalisés {#custom-project-templates}

Pour accélérer la création de projets sur votre instance, configurez un groupe contenant des projets modèles. Les utilisateurs peuvent alors créer [de nouveaux projets basés sur vos modèles](../user/project/_index.md#create-a-project-from-a-custom-template) qui incluent les outils et la configuration communs que vous spécifiez.

Pour en savoir plus sur les données copiées depuis les projets modèles, consultez [ce qui est copié depuis les modèles](../user/group/custom_project_templates.md#what-is-copied-from-the-templates).

Avant de rendre les projets modèles disponibles sur votre instance, sélectionnez un groupe pour gérer les modèles. Pour éviter toute modification inattendue des modèles, créez un nouveau groupe à cet effet plutôt que de réutiliser un groupe existant. Si vous réutilisez un groupe existant créé à des fins différentes, les utilisateurs disposant du rôle Maintainer pourraient modifier les projets modèles sans en comprendre les effets secondaires.

### Sélectionner un groupe pour gérer les projets modèles {#select-a-group-to-manage-template-projects}

Prérequis :

- Disposer d'un accès administrateur.

Pour sélectionner le groupe chargé de gérer les modèles de projets pour votre instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Modèles**.
1. Développez **Modèles de projets personnalisés**.
1. Sélectionnez un groupe à utiliser.
1. Sélectionnez **Enregistrer les modifications**.

Une fois le groupe configuré comme source de modèles de projets, les nouveaux projets ajoutés à ce groupe deviennent disponibles en tant que modèles.

### Configurer un projet pour l'utiliser comme modèle {#configure-a-project-for-use-as-a-template}

Une fois le groupe créé pour gérer les projets modèles, configurez la visibilité et la disponibilité des fonctionnalités de chaque projet modèle.

Prérequis :

- Vous devez être soit l'administrateur de l'instance, soit un utilisateur disposant d'un rôle vous permettant de configurer le projet.

1. Assurez-vous que le projet appartient directement au groupe, et non via un sous-groupe. Les projets issus des sous-groupes du groupe sélectionné ne peuvent pas être utilisés comme modèles.
1. Pour configurer les utilisateurs pouvant sélectionner le modèle de projet, définissez la [visibilité du projet](../user/public_access.md#change-project-visibility) :
   - Les projets **Public** et **Interne** peuvent être sélectionnés par tout utilisateur authentifié.
   - Les projets **Privé** ne peuvent être sélectionnés que par les membres de ce projet.
1. Vérifiez les [paramètres des fonctionnalités](../user/project/settings/_index.md#configure-project-features-and-permissions) du projet. Toutes les fonctionnalités du projet activées doivent être définies sur **Toute personne ayant accès**, à l'exception de **GitLab Pages** et de **Sécurité et conformité**.

Les informations du dépôt et de la base de données copiées dans chaque nouveau projet sont identiques aux données exportées via la fonctionnalité d'import/export de projets GitLab. Cela inclut l'historique complet des commits Git du projet modèle. Pour plus d'informations, consultez [migrer les données GitLab à l'aide d'exports de fichiers](../user/project/settings/import_export.md).

Pour créer un modèle sans historique de commits, initialisez votre projet modèle avec un seul commit contenant tous les fichiers que vous souhaitez inclure.

## Modèles de projets intégrés {#built-in-project-templates}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230641) dans GitLab 19.0 [avec le feature flag](feature_flags/_index.md) `use_built_in_project_templates_enabled`. Désactivés par défaut.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/593623) dans GitLab 19.2. Le feature flag `use_built_in_project_templates_enabled` a été supprimé.

{{< /history >}}

Les [modèles de projets intégrés](../user/project/_index.md#create-a-project-from-a-built-in-template) remplissent les nouveaux projets avec des fichiers de démarrage. Par défaut, ces modèles sont disponibles pour tous les utilisateurs. En tant qu'administrateur, vous pouvez désactiver ce paramètre pour l'instance et, si vous le souhaitez, l'imposer afin que les Owners de groupes ne puissent pas le remplacer. Les Owners de groupes peuvent également [contrôler ce paramètre pour leurs groupes](../user/group/manage.md#control-built-in-project-templates).

Le paramètre utilise l'héritage en cascade :

- Par défaut, les groupes racines héritent de la valeur de l'instance.
- Les sous-groupes héritent de la valeur de leur groupe ancêtre le plus proche.
- Une valeur spécifique à un groupe remplace la valeur héritée.
- Lorsque vous imposez le paramètre pour l'instance, tous les groupes en héritent.
- Lorsque vous imposez le paramètre pour un groupe, tous les sous-groupes en héritent.
- Lorsque vous modifiez le paramètre de l'instance, la nouvelle valeur se propage à tous les groupes.
- Lorsque vous modifiez le paramètre d'un groupe, la nouvelle valeur se propage à tous les sous-groupes.

### Configurer les modèles de projets intégrés {#configure-built-in-project-templates}

Prérequis :

- Être administrateur.

Pour contrôler les modèles de projets intégrés pour l'instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Sélectionnez **Paramètres** > **Modèles**.
1. Développez **Modèles de projets intégrés**.
1. Cochez ou décochez la case **Activer les modèles de projets intégrés**.
1. Facultatif. Pour empêcher les groupes de modifier ce paramètre, cochez la case **Imposer à tous les groupes**.
1. Sélectionnez **Enregistrer les modifications**.

## Sujets connexes {#related-topics}

- [Modèles de projets personnalisés pour les groupes](../user/group/custom_project_templates.md).

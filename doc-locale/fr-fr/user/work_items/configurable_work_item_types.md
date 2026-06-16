---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Créez, contrôlez et configurez des types d'éléments de travail avec des noms et des icônes correspondant aux processus de planification de votre organisation."
title: "Types d'éléments de travail configurables"
---

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/7897) dans GitLab 19.0 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `work_item_configurable_types`. Activé par défaut.

{{< /history >}}

Personnalisez les types d'éléments de travail pour les adapter à vos workflows de planification. Créez de nouveaux types avec des noms et des icônes, et contrôlez quels types sont disponibles dans vos projets. La configuration d'un type d'élément de travail s'applique en cascade à tous les projets.

Les nouveaux types sont disponibles uniquement au niveau du projet. Leurs widgets et restrictions de hiérarchie correspondent à ceux des tickets. Vous pouvez associer de nouveaux types à des [champs personnalisés](custom_fields.md) et des [cycles de vie de statut](status.md). Vous pouvez également filtrer par type d'élément de travail dans les [vues enregistrées](saved_views.md) et les tableaux des tickets.

## Limites et règles de nommage {#limits-and-naming-rules}

Vous pouvez avoir un maximum de 40 types d'éléments de travail dans un groupe principal ou une organisation, y compris les types fournis par GitLab. Les noms de types doivent être uniques dans un espace de nommage ou une organisation et ne pas dépasser 48 caractères. Un type ne peut pas partager un nom avec un autre type, y compris les types archivés et désactivés. Vulnérabilité, merge request, commit, pipeline, alerte, révision, diff, rapport et sha sont des noms réservés qui ne peuvent pas être utilisés.

Lorsque vous renommez un type (par exemple, renommer `Feature` en `Enhancement`), le nom d'origine est disponible pour un nouveau type. Vous pouvez renommer un type avec son nom d'origine si ce nom n'a pas été pris.

## États des types d'éléments de travail {#work-item-type-states}

Chaque type d'élément de travail possède l'un des états suivants :

| État | Description |
|-------|-------------|
| Activé | L'état par défaut. Le type est disponible pour créer des éléments de travail et apparaît dans les filtres. |
| Désactivé | Le type ne peut pas être utilisé pour créer de nouveaux éléments de travail et n'apparaît pas dans les filtres. Vous pouvez toujours renommer et modifier l'icône d'un type désactivé. Les éléments de travail existants de ce type ne sont pas affectés. |
| Archivé | Le type est supprimé de toutes les listes, filtres et flux de création. Vous pouvez uniquement afficher et désarchiver les types archivés au niveau du groupe principal ou de l'organisation. Vous ne pouvez pas renommer ou modifier l'icône d'un type archivé. |
| Verrouillé | Le type est lié à une fonctionnalité GitLab spécifique et ne peut pas être renommé, désactivé ou archivé. Par exemple, les types Ticket, Incident, Epic et Task sont verrouillés. |

> [!note]
> Les epics apparaissent comme un type d'élément de travail au niveau du projet, mais sont désactivés pour les projets car les epics ne sont disponibles qu'au niveau du groupe.

## Créer un type d'élément de travail {#create-a-work-item-type}

Créez un type d'élément de travail avec un nom et une icône pour représenter une catégorie de travail spécifique.

Prérequis :

- Sur GitLab.com : Vous devez disposer au minimum du rôle Maintainer pour le groupe principal.
- Sur GitLab Self-Managed : Vous devez être un administrateur d'instance ou un propriétaire d'organisation.

Pour créer un type d'élément de travail :

1. Accédez aux paramètres des éléments de travail :
   - Sur GitLab.com : Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe principal. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Éléments de travail**.
   - Sur GitLab Self-Managed : Dans le coin supérieur droit, sélectionnez **Admin**. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Éléments de travail**.
1. Dans la section **Types d'éléments de travail**, sélectionnez **Nouveau type**.
1. Saisissez un nom pour le type.
1. Sélectionnez une icône.
1. Sélectionnez **Enregistrer**.

## Modifier un type d'élément de travail {#edit-a-work-item-type}

Mettez à jour le nom ou l'icône d'un type d'élément de travail existant.

Prérequis :

- Sur GitLab.com : Vous devez disposer au minimum du rôle Maintainer pour le groupe principal.
- Sur GitLab Self-Managed : Vous devez être un administrateur d'instance ou un propriétaire d'organisation.
- Le type ne doit pas être verrouillé ou archivé.

Pour modifier un type d'élément de travail :

1. Accédez aux paramètres des éléments de travail :
   - Sur GitLab.com : Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe principal. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Éléments de travail**.
   - Sur GitLab Self-Managed : Dans le coin supérieur droit, sélectionnez **Admin**. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Éléments de travail**.
1. Dans la section **Types d'éléments de travail**, trouvez le type que vous souhaitez modifier.
1. Sélectionnez **Modifier le nom et l'icône**.
1. Mettez à jour le nom, l'icône, ou les deux.
1. Sélectionnez **Enregistrer**.

> [!note]
> Les types liés à certaines fonctionnalités de GitLab ne peuvent pas être modifiés. Par exemple, les types Ticket, Incident, Epic et Task sont verrouillés et ne peuvent pas être renommés ou voir leur icône modifiée.

## Archiver un type d'élément de travail {#archive-a-work-item-type}

Archivez un type d'élément de travail pour le supprimer de toutes les listes, filtres et flux de création. Les types archivés restent dans le système, et les éléments de travail existants de ce type ne sont pas affectés.

Prérequis :

- Sur GitLab.com : Vous devez disposer au minimum du rôle Maintainer pour le groupe principal.
- Sur GitLab Self-Managed : Vous devez être un administrateur d'instance ou un propriétaire d'organisation.

Pour archiver un type d'élément de travail :

1. Accédez aux paramètres des éléments de travail :
   - Sur GitLab.com : Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe principal. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Éléments de travail**.
   - Sur GitLab Self-Managed : Dans le coin supérieur droit, sélectionnez **Admin**. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Éléments de travail**.
1. Dans la section **Types d'éléments de travail**, trouvez le type que vous souhaitez archiver.
1. Sélectionnez **Archiver**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Archiver**.

Les types archivés sont visibles uniquement au niveau du groupe principal ou de l'organisation dans l'onglet **Archivées**. Ils ne sont pas visibles au niveau du sous-groupe ou du projet.

## Désarchiver un type d'élément de travail {#unarchive-a-work-item-type}

Restaurez un type d'élément de travail archivé pour le rendre à nouveau disponible.

Prérequis :

- Sur GitLab.com : Vous devez disposer au minimum du rôle Maintainer pour le groupe principal.
- Sur GitLab Self-Managed : Vous devez être un administrateur d'instance ou un propriétaire d'organisation.
- Le nombre total de types actifs doit être inférieur au maximum de 40.

Pour désarchiver un type d'élément de travail :

1. Accédez aux paramètres des éléments de travail :
   - Sur GitLab.com : Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe principal. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Éléments de travail**.
   - Sur GitLab Self-Managed : Dans le coin supérieur droit, sélectionnez **Admin**. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Éléments de travail**.
1. Dans la section **Types d'éléments de travail**, sélectionnez l'onglet **Archivées**.
1. Trouvez le type que vous souhaitez restaurer.
1. Sélectionnez **Désarchiver**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Désarchiver**.

## Contrôles de disponibilité des types {#type-availability-controls}

Contrôlez quels types d'éléments de travail sont disponibles dans vos projets. La disponibilité des types comporte trois niveaux :

- **Personnalisation des types dans les projets** : Un commutateur au niveau du groupe principal ou de l'organisation qui autorise ou empêche les projets de personnaliser la disponibilité des types. Désactivé par défaut.
- **Disponibilité par type pour tous les projets** : Activez ou désactivez un type spécifique dans tous les projets descendants.
- **Disponibilité par projet** : Les projets individuels peuvent activer ou désactiver des types pour leur propre portée.

### Autoriser la personnalisation des types dans les projets {#allow-type-customization-in-projects}

Contrôlez la possibilité pour les projets de personnaliser les types disponibles.

Prérequis :

- Sur GitLab.com : Vous devez disposer au minimum du rôle Maintainer pour le groupe principal.
- Sur GitLab Self-Managed : Vous devez être un administrateur d'instance ou un propriétaire d'organisation.

Pour activer ou désactiver la personnalisation des types :

1. Accédez aux paramètres des éléments de travail :
   - Sur GitLab.com : Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe principal. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Éléments de travail**.
   - Sur GitLab Self-Managed : Dans le coin supérieur droit, sélectionnez **Admin**. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Éléments de travail**.
1. Dans la section **Personnalisation des types dans les projets**, sélectionnez **Activer** ou **Désactiver**.

Lorsque vous désactivez la personnalisation des types, tous les types sont traités comme activés dans tous les projets, quels que soient les paramètres de visibilité précédents. Les remplacements par projet sont conservés mais ignorés. La réactivation de la personnalisation des types restaure la configuration précédente.

### Activer ou désactiver un type pour tous les projets {#enable-or-disable-a-type-for-all-projects}

Contrôlez la disponibilité d'un type spécifique dans tous les projets descendants à la fois. Cela supprime tous les remplacements par projet pour ce type.

Prérequis :

- Sur GitLab.com : Vous devez disposer au minimum du rôle Maintainer pour le groupe principal.
- Sur GitLab Self-Managed : Vous devez être un administrateur d'instance ou un propriétaire d'organisation.

Pour activer ou désactiver un type pour tous les projets :

1. Accédez aux paramètres des éléments de travail :
   - Sur GitLab.com : Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe principal. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Éléments de travail**.
   - Sur GitLab Self-Managed : Dans le coin supérieur droit, sélectionnez **Admin**. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Éléments de travail**.
1. Dans la section **Types d'éléments de travail**, trouvez le type.
1. Dans le menu des actions du type, sélectionnez **Activer pour tous les projets** ou **Désactiver pour tous les projets**.

### Activer ou désactiver un type dans un projet {#enable-or-disable-a-type-in-a-project}

Contrôlez quels types sont disponibles dans un projet spécifique.

Prérequis :

- Vous devez disposer au minimum du rôle Maintainer pour le projet.

Pour activer ou désactiver un type dans un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Éléments de travail**.
1. Dans la section **Types d'éléments de travail activés**, trouvez le type.
1. Activez ou désactivez le type.

Lorsque vous désactivez un type dans un projet, ce type ne peut pas être utilisé pour créer de nouveaux éléments de travail dans ce projet. Les éléments de travail existants de ce type ne sont pas affectés.

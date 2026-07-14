---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Afficher, créer, modifier et résoudre des incidents, et modifier la gravité, le statut et la politique d'escalade des incidents."
title: Événements de chronologie
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/344059) dans GitLab 15.2 [avec un flag](../../administration/feature_flags/_index.md) nommé `incident_timeline`. Activé par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/353426) dans GitLab 15.3.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/353426) dans GitLab 15.5. [Feature flag `incident_timeline`](https://gitlab.com/gitlab-org/gitlab/-/issues/343386) supprimé.

{{< /history >}}

Les chronologies d'incidents constituent une part importante de la documentation des incidents. Les chronologies permettent de montrer aux dirigeants et aux observateurs externes ce qui s'est passé lors d'un incident, ainsi que les étapes suivies pour le résoudre.

## Afficher la chronologie {#view-the-timeline}

Les événements de la chronologie d'incident sont listés par ordre chronologique croissant. Ils sont regroupés par date et listés par ordre croissant de l'heure à laquelle ils se sont produits :

![Liste des événements de la chronologie d'incident](img/timeline_events_v15_1.png)

Pour afficher la chronologie d'événements d'un incident :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Incidents**.
1. Sélectionnez un incident.
1. Sélectionnez l'onglet **Chronologie**.

## Créer un événement {#create-an-event}

Vous pouvez créer un événement de chronologie de plusieurs façons dans GitLab.

### Utiliser le formulaire {#using-the-form}

Créez manuellement un événement de chronologie à l'aide du formulaire.

Prérequis :

- Vous devez disposer du rôle Developer, Maintainer ou Owner pour le projet.

Pour créer un événement de chronologie :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Incidents**.
1. Sélectionnez un incident.
1. Sélectionnez l'onglet **Chronologie**.
1. Sélectionnez **Ajouter un nouvel événement à la chronologie**.
1. Renseignez les champs obligatoires.
1. Sélectionnez **Enregistrer** ou **Sauvegarder et ajouter un autre événement**.

### Utiliser une action rapide {#using-a-quick-action}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/368721) dans GitLab 15.4.

{{< /history >}}

Vous pouvez créer un événement de chronologie à l'aide de [l'action rapide `/timeline`](../../user/project/quick_actions.md#timeline).

### À partir d'un commentaire sur l'incident {#from-a-comment-on-the-incident}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/344058) dans GitLab 15.4.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Developer, Maintainer ou Owner pour le projet.

> [!warning]
> Les notes internes ajoutées aux chronologies d'incidents dans les incidents publics et internes sont visibles par toute personne ayant accès à l'incident.

Pour créer un événement de chronologie à partir d'un commentaire sur l'incident :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Incidents**.
1. Sélectionnez un incident.
1. Créez un commentaire ou choisissez un commentaire existant.
1. Sur le commentaire que vous souhaitez ajouter, sélectionnez **Ajouter un commentaire à la chronologie de l'incident** ({{< icon name="clock" >}}).

Le commentaire apparaît dans la chronologie de l'incident en tant qu'événement de chronologie.

### Lors des changements de gravité d'un incident {#when-incident-severity-changes}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/375280) dans GitLab 15.6.

{{< /history >}}

Un nouvel événement de chronologie est créé lorsqu'une personne [modifie la gravité](manage_incidents.md#change-severity) d'un incident.

![Événement de chronologie d'incident pour un changement de gravité](img/timeline_event_for_severity_change_v15_6.png)

### Lors des changements de labels {#when-labels-change}

{{< details >}}

- Statut : Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/365489) dans GitLab 15.3 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `incident_timeline_events_from_labels`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

Un nouvel événement de chronologie est créé lorsqu'une personne ajoute ou supprime des [labels](../../user/project/labels.md) sur un incident.

## Supprimer un événement {#delete-an-event}

{{< history >}}

- Possibilité de supprimer un événement lors de sa modification [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/372265) dans GitLab 15.7.

{{< /history >}}

Vous pouvez également supprimer des événements de chronologie.

Prérequis :

- Vous devez disposer du rôle Developer, Maintainer ou Owner pour le projet.

Pour supprimer un événement de chronologie :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Incidents**.
1. Sélectionnez un incident.
1. Sélectionnez l'onglet **Chronologie**.
1. À droite d'un événement de chronologie, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}) puis sélectionnez **Supprimer**.
1. Pour confirmer, sélectionnez **Supprimer l'événement**.

Autrement :

1. À droite d'un événement de chronologie, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}) puis sélectionnez **Éditer**.
1. Sélectionnez **Supprimer**.
1. Pour confirmer, sélectionnez **Supprimer l'événement**.

## Tags d'incident {#incident-tags}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/8741) dans GitLab 15.9 [avec un flag](../../administration/feature_flags/_index.md) nommé `incident_event_tags`. Désactivé par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/387647) dans GitLab 15.9.
- [Activé sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/387647) dans GitLab 15.10.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/387647) dans GitLab 15.11. L'indicateur de fonctionnalité `incident_event_tags` a été supprimé.

{{< /history >}}

[Lors de la création d'un événement à l'aide du formulaire](#using-the-form) ou lors de sa modification, vous pouvez spécifier des tags d'incident pour capturer les horodatages pertinents de l'incident. Les tags de chronologie sont facultatifs. Vous pouvez choisir plusieurs tags par événement. Lorsque vous créez un événement de chronologie et sélectionnez les tags, la note de l'événement est renseignée avec un message par défaut. Cela permet une création rapide d'événements. Si une note a déjà été définie, elle n'est pas modifiée. Les tags ajoutés s'affichent à côté de l'horodatage.

## Règles de formatage {#formatting-rules}

Les événements de chronologie d'incident prennent en charge les fonctionnalités [GitLab Flavored Markdown](../../user/markdown.md) suivantes.

- [Code](../../user/markdown.md#code-spans-and-blocks).
- [Emoji](../../user/markdown.md#emoji).
- [Emphase](../../user/markdown.md#emphasis).
- [Références spécifiques à GitLab](../../user/markdown.md#gitlab-specific-references).
- [Images](../../user/markdown.md#images), affichées sous forme de lien vers l'image téléchargée.
- [Liens](../../user/markdown.md#links).

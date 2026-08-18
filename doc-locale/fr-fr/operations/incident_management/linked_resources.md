---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Affichez et mettez à jour les ressources liées dans les incidents GitLab, y compris comment utiliser les actions rapides pour les URL et les réunions Zoom."
title: Ressources liées dans les incidents
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/230852) dans GitLab 15.3 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `incident_resource_links_widget`. Désactivé par défaut.
- [Activée sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/364755) dans GitLab 15.3.
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/issues/364755) dans GitLab 15.5. L'indicateur de fonctionnalité `incident_resource_links_widget` a été supprimé.

{{< /history >}}

Pour aider les membres de votre équipe à trouver les liens importants sans avoir à parcourir de nombreux commentaires, vous pouvez ajouter des ressources liées à un ticket d'incident.

Ressources que vous pourriez vouloir lier :

- Le canal Slack de l'incident
- Réunion Zoom
- Ressources pour résoudre les incidents

## Afficher les ressources liées d'un incident {#view-linked-resources-of-an-incident}

Les ressources liées à un incident sont répertoriées sous l'onglet **Résumé**.

![Liste des ressources liées](img/linked_resources_list_v15_3.png)

Pour afficher les ressources liées d'un incident :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Incidents**.
1. Sélectionnez un incident.

## Ajouter une ressource liée {#add-a-linked-resource}

Ajoutez manuellement une ressource liée depuis un incident.

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner pour le projet.

Pour ajouter une ressource liée :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Incidents**.
1. Sélectionnez un incident.
1. Dans la section **Linked resources**, sélectionnez l'icône plus ({{< icon name="plus-square" >}}).
1. Renseignez les champs obligatoires.
1. Sélectionnez **Ajouter**.

### Utilisation d'une action rapide {#using-a-quick-action}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/374964) dans GitLab 15.5.

{{< /history >}}

Pour ajouter plusieurs liens à un incident, utilisez l'[action rapide `/link`](../../user/project/quick_actions.md#link) :

```plaintext
/link https://example.link.us/j/123456789
```

Vous pouvez également soumettre une courte description avec le lien. La description s'affiche à la place de l'URL dans la section **Linked resources** de l'incident :

```plaintext
/link https://example.link.us/j/123456789 multiple alerts firing
```

### Lier des réunions Zoom depuis un incident {#link-zoom-meetings-from-an-incident}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/230853) dans GitLab 15.4.

{{< /history >}}

Utilisez l'[action rapide `/zoom`](../../user/project/quick_actions.md#zoom) pour ajouter plusieurs liens Zoom à un incident :

```plaintext
/zoom https://example.zoom.us/j/123456789
```

Vous pouvez également soumettre une courte description facultative avec le lien. La description s'affiche à la place de l'URL dans la section **Linked resources** du ticket d'incident :

```plaintext
/zoom https://example.zoom.us/j/123456789 Low on memory incident
```

## Supprimer une ressource liée {#remove-a-linked-resource}

Vous pouvez également supprimer une ressource liée.

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner pour le projet.

Pour supprimer une ressource liée :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Incidents**.
1. Sélectionnez un incident.
1. Dans la section **Linked resources**, sélectionnez **Supprimer** ({{< icon name="close" >}}).

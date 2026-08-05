---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Comprendre et gérer les alertes dans GitLab, notamment en consultant les listes d'alertes, en modifiant les statuts, en assignant des alertes, en déclenchant des actions et en répondant aux notifications d'astreinte."
title: Alertes
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les alertes sont une entité essentielle de votre workflow de gestion des incidents. Elles représentent un événement notable susceptible d'indiquer une panne ou une interruption de service. GitLab fournit une vue liste pour le triage et une vue détaillée pour approfondir l'investigation de ce qui s'est passé.

## Liste des alertes {#alert-list}

Les utilisateurs disposant du rôle Developer, Maintainer ou Owner peuvent accéder à la liste des alertes via **Supervision** > **Alertes** dans la barre latérale de votre projet. La liste des alertes affiche les alertes triées par heure de début, mais vous pouvez modifier l'ordre de tri en sélectionnant les en-têtes dans la liste des alertes.

La liste des alertes affiche les informations suivantes :

![La liste des alertes affichant des détails sur les alertes ouvertes](img/alert_list_v13_1.png)

- **Recherche en cours** : La liste des alertes prend en charge une recherche simple en texte libre sur le titre, la description, l'outil de supervision et les champs de service.
- **Gravité** : L'importance actuelle d'une alerte et le niveau d'attention qu'elle doit recevoir. Pour obtenir la liste de tous les statuts, consultez [Gravité de la gestion des alertes](#alert-severity).
- **Heure de début** : Il y a combien de temps l'alerte s'est déclenchée. Ce champ utilise le modèle GitLab standard `X time ago`, mais est accompagné d'une info-bulle de date/heure granulaire selon les paramètres régionaux de l'utilisateur.
- **Description de l'alerte** : La description de l'alerte, qui tente de capturer les données les plus significatives.
- **Nombre d'événements** : Le nombre de fois qu'une alerte s'est déclenchée.
- **Ticket** : Un lien vers le ticket d'incident qui a été créé pour l'alerte.
- **Statut** : Le statut actuel de l'alerte :
  - **Déclenchée** : L'investigation n'a pas commencé.
  - **Acquittée** : Quelqu'un investigate activement le problème.
  - **Résolue** : Aucun travail supplémentaire n'est requis.
  - **Ignorée** : Aucune action n'est entreprise sur l'alerte.

## Gravité des alertes {#alert-severity}

Chaque niveau d'alerte contient une icône à forme et code couleur uniques pour vous aider à identifier la gravité d'une alerte en particulier. Ces icônes de gravité vous aident à identifier immédiatement les alertes que vous devez prioriser dans votre investigation :

![Icônes de gravité des alertes affichant différentes couleurs et formes pour les niveaux critique, élevé, moyen, faible, information et inconnu](img/alert_management_severity_v13_0.png)

Les alertes contiennent l'une des icônes suivantes :

<!-- vale gitlab_base.SubstitutionWarning = NO -->

| Gravité | Icône                    | Couleur (hexadécimal) |
|----------|-------------------------|---------------------|
| Critique | {{< icon name="severity-critical" >}} | `#8b2615`           |
| Élevée     | {{< icon name="severity-high" >}}     | `#c0341d`           |
| Moyenne   | {{< icon name="severity-medium" >}}   | `#fca429`           |
| Faible      | {{< icon name="severity-low" >}}      | `#fdbc60`           |
| Info     | {{< icon name="severity-info" >}}     | `#418cd8`           |
| Inconnue  | {{< icon name="severity-unknown" >}}  | `#bababa`           |

<!-- vale gitlab_base.SubstitutionWarning = YES -->

## Page des détails de l'alerte {#alert-details-page}

Accédez à la vue des détails de l'alerte en visitant la [liste des alertes](#alert-list) et en sélectionnant une alerte dans la liste. Vous devez disposer du rôle Developer, Maintainer ou Owner pour accéder aux alertes. Sélectionnez n'importe quelle alerte dans la liste pour examiner sa page de détails.

Les alertes fournissent les onglets **Vue d'ensemble** et **Détails de l'alerte** pour vous donner la quantité d'informations dont vous avez besoin.

### Onglet Détails de l'alerte {#alert-details-tab}

L'onglet **Détails de l'alerte** comporte deux sections. La section supérieure fournit une courte liste de détails critiques tels que la gravité, l'heure de début, le nombre d'événements et l'outil de supervision d'origine. La deuxième section affiche la charge utile complète de l'alerte.

### Onglet Métriques {#metrics-tab}

Dans de nombreux cas, les alertes sont associées à des métriques. Vous pouvez téléverser des captures d'écran de graphiques de métriques dans l'onglet **Métriques**.

Pour ce faire, vous pouvez :

- Sélectionner **Téléverser**, puis sélectionner une image dans votre navigateur de fichiers.
- Faire glisser un fichier depuis votre navigateur de fichiers et le déposer dans la zone de dépôt.

Lorsque vous téléversez une image, vous pouvez ajouter du texte à l'image et la lier au graphique d'origine.

![Un onglet de métriques d'incident avec une option pour ajouter un lien texte](img/incident_metrics_tab_text_link_modal_v14_9.png)

Si vous ajoutez un lien, il s'affiche au-dessus de l'image téléversée.

### Onglet Flux d'activité {#activity-feed-tab}

L'onglet **Flux d'activité** est un journal d'activité sur l'alerte. Lorsque vous effectuez une action sur une alerte, celle-ci est enregistrée sous forme de note système. Cela vous donne une chronologie linéaire de l'historique d'investigation et d'assignation de l'alerte.

Les actions suivantes génèrent une note système :

- [Mise à jour du statut d'une alerte](#change-an-alerts-status)
- [Création d'un incident basé sur une alerte](manage_incidents.md#from-an-alert)
- [Assignation d'une alerte à un utilisateur](#assign-an-alert)
- [Escalade d'une alerte vers les intervenants d'astreinte](paging.md#escalating-an-alert)

![Flux d'activité d'alerte GitLab affichant trois notes système](img/alert_detail_activity_feed_v13_5.png)

## Actions sur les alertes {#alert-actions}

Différentes actions sont disponibles dans GitLab pour faciliter le triage et la réponse aux alertes.

### Modifier le statut d'une alerte {#change-an-alerts-status}

Vous pouvez modifier le statut d'une alerte.

Les statuts disponibles sont :

- Déclenchée (par défaut pour les nouvelles alertes)
- Acquittée
- Résolue

Prérequis :

- Vous devez disposer du rôle Développeur, Chargé de maintenance ou Propriétaire.

Pour modifier le statut d'une alerte :

- Depuis la [liste des alertes](#alert-list) :
  1. Dans la colonne **Statut**, en regard d'une alerte, sélectionnez la liste déroulante de statut.
  1. Sélectionnez un statut.
- Depuis la [page des détails de l'alerte](#alert-details-page) :
  1. Dans la barre latérale droite, sélectionnez **Éditer**.
  1. Sélectionnez un statut.

Pour arrêter les notifications par e-mail pour les récurrences d'alertes dans les projets avec [les notifications par e-mail activées](paging.md#email-notifications-for-alerts), modifiez le statut de l'alerte en le faisant passer de **Déclenchée**.

#### Résoudre une alerte en fermant l'incident lié {#resolve-an-alert-by-closing-the-linked-incident}

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner.

Lorsque vous [fermez un incident](manage_incidents.md#close-an-incident) lié à une alerte, GitLab [modifie le statut de l'alerte](#change-an-alerts-status) en **Résolue**. Vous êtes alors crédité de la modification du statut de l'alerte.

#### En tant qu'intervenant d'astreinte {#as-an-on-call-responder}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les intervenants d'astreinte peuvent répondre aux [pages d'alerte](paging.md#escalating-an-alert) en modifiant le statut de l'alerte.

La modification du statut a les effets suivants :

- Vers **Acquittée** : limite les pages d'astreinte en fonction de la [politique d'escalade](escalation_policies.md) du projet.
- Vers **Résolue** : met en sourdine toutes les pages d'astreinte pour l'alerte.
- De **Résolue** à **Déclenchée** : relance l'escalade de l'alerte.

Dans GitLab 15.1 et versions antérieures, la mise à jour du statut d'une [alerte avec un incident associé](manage_incidents.md#from-an-alert) met également à jour le statut de l'incident. Dans [GitLab 15.2 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/356057), le statut de l'incident est indépendant et ne se met pas à jour lorsque le statut de l'alerte change.

### Assigner une alerte {#assign-an-alert}

Dans les grandes équipes, où la responsabilité d'une alerte est partagée, il peut être difficile de suivre qui investigate et travaille dessus. L'assignation des alertes facilite la collaboration et la délégation en indiquant quel utilisateur est responsable de l'alerte. GitLab ne prend en charge qu'une seule personne assignée par alerte.

Pour assigner une alerte :

1. Affichez la liste des alertes actuelles :

   1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
   1. Sélectionnez **Supervision** > **Alertes**.

1. Sélectionnez l'alerte souhaitée pour afficher ses détails.

   ![Page des détails de l'alerte avec la barre latérale droite développée, affichant la liste déroulante Personne assignée pour assigner ou désassigner des utilisateurs](img/alert_details_assignees_v13_1.png)

1. Si la barre latérale droite n'est pas développée, sélectionnez **Étendre la barre latérale** ({{< icon name="chevron-double-lg-right" >}}) pour la développer.

1. Dans la barre latérale droite, localisez la **Personne assignée**, puis sélectionnez **Éditer**. Dans la liste, sélectionnez chaque utilisateur que vous souhaitez assigner à l'alerte. GitLab crée un [élément de la liste de tâches](../../user/todos.md) pour chaque utilisateur.

Une fois leur partie de l'investigation ou de la correction de l'alerte terminée, les utilisateurs peuvent se désassigner de l'alerte. Pour retirer une personne assignée, sélectionnez **Éditer** en regard de la liste déroulante **Personne assignée** et supprimez l'utilisateur de la liste des personnes assignées, ou sélectionnez **Non assigné(s)**.

### Créer un élément de la liste de tâches à partir d'une alerte {#create-a-to-do-item-from-an-alert}

Vous pouvez créer manuellement un [élément de la liste de tâches](../../user/todos.md) pour vous-même à partir d'une alerte, et le consulter ultérieurement dans votre **Liste des pense-bêtes**.

Pour ajouter un élément de la liste de tâches, dans la barre latérale droite, sélectionnez **Ajouter une tâche à faire**.

### Déclencher des actions à partir des alertes {#trigger-actions-from-alerts}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Activez la création automatique d'[incidents](incidents.md) à chaque déclenchement d'une alerte.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

Pour configurer les actions :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Supervision**.
1. Développez la section **Alertes**, puis sélectionnez l'onglet **Paramètres d'alerte**.
1. Cochez la case **Créer un incident**.
1. Facultatif. Pour personnaliser l'incident, dans le menu **Modèle d'incident**, sélectionnez un modèle à ajouter au [résumé de l'incident](incidents.md#summary). Si la liste déroulante est vide, [créez d'abord un modèle de ticket](../../user/project/description_templates.md#create-a-description-template).
1. Facultatif. Pour envoyer [une notification par e-mail](paging.md#email-notifications-for-alerts), cochez la case **Envoyer une seule notification par e-mail aux Propriétaires et aux Chargés de maintenance pour les nouvelles alertes.**.
1. Sélectionnez **Sauvegarder les modifications**.

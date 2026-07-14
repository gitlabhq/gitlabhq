---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Incidents
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Un incident est une interruption ou une panne de service qui doit être rétablie en urgence. Les incidents sont essentiels dans les workflows de gestion des incidents. Utilisez GitLab pour trier, gérer et remédier aux incidents.

## Liste des incidents {#incidents-list}

Lorsque vous [consultez la liste des incidents](manage_incidents.md#view-a-list-of-incidents), elle contient les éléments suivants :

- **État** : Pour filtrer les incidents par état, sélectionnez **Ouvrir**, **Fermé** ou **Tous** au-dessus de la liste des incidents.
- **Recherche en cours** : Recherchez des titres et des descriptions d'incidents ou [filtrez la liste](#filter-the-incidents-list).
- **Gravité** : Gravité d'un incident particulier, qui peut prendre l'une des valeurs suivantes :
  - {{< icon name="severity-critical" >}} Critique - S1
  - {{< icon name="severity-high" >}} Élevée - S2
  - {{< icon name="severity-medium" >}} Moyenne - S3
  - {{< icon name="severity-low" >}} Faible - S4
  - {{< icon name="severity-unknown" >}} Inconnue
- **Incident** : Le titre de l'incident, qui tente de capturer les informations les plus pertinentes.
- **Statut** : Le statut de l'incident, qui peut prendre l'une des valeurs suivantes :
  - Déclenché
  - Pris en charge
  - Résolu

  Dans l'édition Premium ou Ultimate, ce champ est également lié à [l'escalade d'astreinte](paging.md#escalating-an-incident) pour l'incident.

- **Date de création** : Il y a combien de temps l'incident a été créé. Ce champ utilise le modèle GitLab standard `X time ago`. Survolez cette valeur pour afficher la date et l'heure exactes, formatées selon vos paramètres régionaux.
- **Personnes assignées** : L'utilisateur assigné à l'incident.
- **Publié(s)** : Indique si l'incident est publié sur une [page de statut](status_page.md).

![Liste des incidents](img/incident_list_v15_6.png)

Pour un exemple de la liste des incidents en action, consultez ce [projet de démonstration](https://gitlab.com/gitlab-org/monitor/monitor-sandbox/-/incidents).

### Trier la liste des incidents {#sort-the-incident-list}

La liste des incidents affiche les incidents triés par date de création, du plus récent au plus ancien.

Pour trier selon une autre colonne ou modifier l'ordre de tri, sélectionnez la colonne.

Les colonnes disponibles pour le tri :

- Gravité
- Statut
- Durée avant SLA
- Publié(s)

### Filtrer la liste des incidents {#filter-the-incidents-list}

Pour filtrer la liste des incidents par auteur ou par personne assignée, saisissez ces valeurs dans la zone de recherche.

## Détails de l'incident {#incident-details}

### Résumé {#summary}

La section de résumé des incidents fournit des informations critiques sur l'incident et le contenu du modèle de ticket (si [sélectionné](alerts.md#trigger-actions-from-alerts)). La barre mise en surbrillance en haut de l'incident s'affiche de gauche à droite :

- Le lien vers l'alerte d'origine.
- L'heure de début de l'alerte.
- Le nombre d'événements.

Sous la barre de mise en surbrillance, un résumé inclut les champs suivants :

- Heure de début
- Gravité
- `full_query`
- Outil de supervision

Le résumé de l'incident peut être davantage personnalisé en utilisant le [Markdown aromatisé GitLab](../../user/markdown.md).

Si un incident est [créé à partir d'une alerte](alerts.md#trigger-actions-from-alerts) qui a fourni du Markdown pour l'incident, ce Markdown est ajouté au résumé. Si un modèle d'incident est configuré pour le projet, le contenu du modèle est ajouté à la fin.

Les commentaires sont affichés dans des fils de discussion, mais peuvent être affichés de manière chronologique [en activant la vue des mises à jour récentes](#recent-updates-view).

Lorsque vous apportez des modifications à un incident, GitLab crée des [notes système](../../user/project/system_notes.md) et les affiche sous le résumé.

### Métriques {#metrics}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Dans de nombreux cas, les incidents sont associés à des métriques. Vous pouvez télécharger des captures d'écran des graphiques de métriques dans l'onglet **Métriques** :

![Onglet Métriques des incidents](img/incident_metrics_tab_v13_8.png)

Lorsque vous téléchargez une image, vous pouvez l'associer à un texte ou à un lien vers le graphique d'origine.

![Fenêtre modale de lien textuel](img/incident_metrics_tab_text_link_modal_v14_9.png)

Si vous ajoutez un lien, vous pouvez accéder au graphique d'origine en sélectionnant le lien hypertexte au-dessus de l'image téléchargée.

### Détails de l'alerte {#alert-details}

Les incidents affichent les détails des alertes liées dans un onglet séparé. Pour renseigner cet onglet, l'incident doit avoir été créé avec une alerte liée. Les incidents créés automatiquement à partir d'alertes ont ce champ renseigné.

![Détails de l'alerte d'incident](img/incident_alert_details_v13_4.png)

### Événements de chronologie {#timeline-events}

Les chronologies d'incidents offrent une vue d'ensemble de haut niveau de ce qui s'est passé au cours d'un incident et des étapes qui ont été suivies pour le résoudre.

En savoir plus sur les [événements de chronologie](incident_timeline_events.md) et la façon d'activer cette fonctionnalité.

### Vue des mises à jour récentes {#recent-updates-view}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour voir les dernières mises à jour d'un incident, sélectionnez **Activer la vue des mises à jour récentes** ({{< icon name="history" >}}) dans la barre de commentaires. Les commentaires s'affichent sans fil de discussion et de manière chronologique, du plus récent au plus ancien.

### Compte à rebours du contrat de niveau de service {#service-level-agreement-countdown-timer}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez activer le compte à rebours du contrat de niveau de service (SLA) sur les incidents pour suivre les contrats de niveau de service (SLA) que vous avez conclus avec vos clients. Le minuteur démarre automatiquement lors de la création de l'incident et affiche le temps restant avant l'expiration de la période SLA. Le minuteur est également mis à jour dynamiquement toutes les 15 minutes, de sorte que vous n'avez pas à actualiser la page pour voir le temps restant.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

Pour configurer le minuteur :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Supervision**.
1. Développez la section **Incidents**, puis sélectionnez l'onglet **Paramètres des incidents**.
1. Sélectionnez **Activer le compte à rebours « durée avant SLA »**.
1. Définissez une limite de temps par incréments de 15 minutes.
1. Sélectionnez **Sauvegarder les modifications**.

Après avoir activé le compte à rebours SLA, la colonne **Durée avant SLA** est disponible dans la liste des incidents et en tant que champ sur les nouveaux incidents. Si l'incident n'est pas clôturé avant la fin de la période SLA, GitLab ajoute un label `missed::SLA` à l'incident.

## Sujets connexes {#related-topics}

- [Créer un incident](manage_incidents.md#create-an-incident)
- [Créer un incident automatiquement](alerts.md#trigger-actions-from-alerts) chaque fois qu'une alerte est déclenchée
- [Afficher la liste des incidents](manage_incidents.md#view-a-list-of-incidents)
- [Assigner à un utilisateur](manage_incidents.md#assign-to-a-user)
- [Modifier la gravité de l'incident](manage_incidents.md#change-severity)
- [Modifier le statut de l'incident](manage_incidents.md#change-status)
- [Modifier la politique d'escalade](manage_incidents.md#change-escalation-policy)
- [Clôturer un incident](manage_incidents.md#close-an-incident)
- [Clôturer automatiquement les incidents via des alertes de rétablissement](manage_incidents.md#automatically-close-incidents-via-recovery-alerts)
- [Ajouter un élément de la liste de tâches](../../user/todos.md#create-a-to-do-item)
- [Ajouter des labels](../../user/project/labels.md)
- [Assigner un jalon](../../user/project/milestones/_index.md)
- [Rendre un incident confidentiel](../../user/project/issues/confidential_issues.md)
- [Définir une date d'échéance](../../user/project/issues/due_dates.md)
- [Activer/désactiver les notifications](../../user/profile/notifications.md#subscribe-to-notifications-for-a-specific-issue-merge-request-or-epic)
- [Suivre le temps passé](../../user/project/time_tracking.md)
- [Ajouter une réunion Zoom à un incident](../../user/project/issues/associate_zoom_meeting.md) de la même façon que vous l'ajoutez à un ticket
- [Ressources liées dans les incidents](linked_resources.md)
- Créez des incidents et recevez des notifications d'incidents [directement depuis Slack](slack.md)
- Utilisez l'[API Issues](../../api/issues.md) pour interagir avec les incidents

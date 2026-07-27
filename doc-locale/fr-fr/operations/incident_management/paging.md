---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez les notifications et la pagination pour les alertes et les incidents dans GitLab, notamment les politiques Slack, e-mail et d'escalade pour les intervenants d'astreinte."
title: Pagination et notifications
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsqu'une nouvelle alerte ou un nouvel incident survient, il est important qu'un intervenant soit immédiatement notifié afin de pouvoir trier et résoudre le problème. Les intervenants peuvent recevoir des notifications en utilisant les méthodes décrites sur cette page.

## Notifications Slack {#slack-notifications}

L'application GitLab pour Slack peut être utilisée pour recevoir des notifications d'incidents importantes.

Lorsque [l'application GitLab pour Slack est configurée](slack.md), les intervenants en cas d'incident sont notifiés dans Slack chaque fois qu'un nouvel incident est déclaré. Pour ne manquer aucune notification d'incident importante sur votre appareil mobile, activez les notifications pour Slack sur votre téléphone.

## Notifications par e-mail pour les alertes {#email-notifications-for-alerts}

Les notifications par e-mail sont disponibles dans les projets pour les alertes déclenchées. Les membres du projet disposant des rôles **Propriétaire** ou **Chargé de maintenance** ont la possibilité de recevoir une seule notification par e-mail pour les nouvelles alertes.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Supervision**.
1. Développez **Alertes**.
1. Dans l'onglet **Paramètres d'alerte**, cochez la case **Send a single email notification to Owners and Maintainers for new alerts**.
1. Sélectionnez **Sauvegarder les modifications**.

[Mettez à jour le statut de l'alerte](alerts.md#change-an-alerts-status) pour gérer les notifications par e-mail d'une alerte.

## Pagination {#paging}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Dans les projets disposant d'une [politique d'escalade](escalation_policies.md) configurée, les intervenants d'astreinte peuvent être automatiquement contactés par pagination concernant les problèmes critiques par e-mail.

### Escalader une alerte {#escalating-an-alert}

Lorsqu'une alerte est déclenchée, elle commence immédiatement à être remontée aux intervenants d'astreinte. Pour chaque règle d'escalade dans la politique d'escalade du projet, les intervenants d'astreinte désignés reçoivent un e-mail lorsque la règle se déclenche. Vous pouvez répondre à une page ou arrêter les escalades d'alertes en [mettant à jour le statut de l'alerte](alerts.md#change-an-alerts-status).

### Escalader un incident {#escalating-an-incident}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/5716) dans GitLab 14.9 [avec un flag](../../administration/feature_flags/_index.md) nommé `incident_escalations`. Désactivé par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/345769) dans GitLab 14.10.
- [Le feature flag `incident_escalations`](https://gitlab.com/gitlab-org/gitlab/-/issues/345769) supprimé dans GitLab 15.1.

{{< /history >}}

Pour les incidents, la pagination des intervenants d'astreinte est facultative pour chaque incident individuel.

Pour commencer à escalader l'incident, [définissez la politique d'escalade de l'incident](manage_incidents.md#change-escalation-policy).

Pour chaque règle d'escalade, les intervenants d'astreinte désignés reçoivent un e-mail lorsque la règle se déclenche. Répondez à une page ou arrêtez les escalades d'incidents en [changeant le statut de l'incident](manage_incidents.md#change-status) ou en rétablissant la politique d'escalade de l'incident sur **No escalation policy**.

Dans GitLab 15.1 et les versions antérieures, [les incidents créés à partir d'alertes](manage_incidents.md#from-an-alert) ne prennent pas en charge l'escalade indépendante. Dans [GitLab 15.2 et les versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/356057), tous les incidents peuvent être escaladés indépendamment.

---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Gérez les incidents GitLab directement depuis Slack à l'aide de l'application GitLab pour Slack, notamment en déclarant des incidents, en utilisant des actions rapides et en recevant des notifications."
title: Gestion des incidents pour Slack
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Statut : Version bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/344856) dans GitLab 15.7 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `incident_declare_slash_command`. Désactivé par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/378072) dans GitLab 15.10 en [version bêta](../../policy/development_stages_support.md#beta).

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

De nombreuses équipes reçoivent des alertes et collaborent en temps réel lors d'incidents dans Slack. Utilisez l'application GitLab pour Slack pour :

- Créer des incidents GitLab depuis Slack.
- Recevoir des notifications d'incidents.

La gestion des incidents pour Slack est uniquement disponible pour GitLab.com.

Pour rester informé, suivez l'[epic 1211](https://gitlab.com/groups/gitlab-org/-/epics/1211).

## Gérer un incident depuis Slack {#manage-an-incident-from-slack}

Prérequis :

1. Installez l'[application GitLab pour Slack](../../user/project/integrations/gitlab_slack_application.md). Ainsi, vous pouvez utiliser des commandes slash dans Slack pour créer et mettre à jour des incidents GitLab.
1. Activez les [notifications Slack](../../user/project/integrations/gitlab_slack_application.md#slack-notifications). Veillez à activer les notifications pour les événements `Incident` et à définir un canal Slack pour recevoir les notifications pertinentes.
1. Autorisez GitLab à effectuer des actions au nom de votre utilisateur Slack. Chaque utilisateur doit effectuer cette opération avant de pouvoir utiliser l'une des commandes slash d'incidents.

   Pour démarrer le flux d'autorisation, essayez d'exécuter une [commande slash Slack](../../user/project/integrations/gitlab_slack_application.md#slash-commands) non liée aux incidents, comme `/gitlab <project-alias> issue show <id>`. Le `<project-alias>` que vous sélectionnez doit être un projet sur lequel l'application GitLab pour Slack est configurée. La boîte de dialogue de sélection a une limite stricte de 100 projets. Pour plus d'informations, consultez l'[ticket 377548](https://gitlab.com/gitlab-org/gitlab/-/issues/377548).

## Déclarer un incident {#declare-an-incident}

Pour déclarer un incident GitLab depuis Slack :

1. Dans Slack, dans n'importe quel canal ou message direct, saisissez la commande slash `/gitlab incident declare`.
1. Dans la fenêtre modale, sélectionnez les détails pertinents de l'incident, notamment :

   - Le titre et la description de l'incident.
   - Le projet dans lequel l'incident doit être créé.
   - La gravité de l'incident.

   S'il existe un [modèle d'incident](alerts.md#trigger-actions-from-alerts) pour votre projet, ce modèle est automatiquement appliqué à la zone de texte de description. Le modèle n'est appliqué que si la zone de texte de description est vide.

   Vous pouvez également inclure des [actions rapides](../../user/project/quick_actions.md) dans la zone de texte de description. Par exemple, la saisie de `/link https://example.slack.com/archives/123456789 Dedicated Slack channel` ajoute un canal Slack dédié à l'incident que vous créez. Pour obtenir la liste complète des actions rapides disponibles pour les incidents, consultez [Utiliser les actions rapides GitLab](#use-gitlab-quick-actions).
1. Facultatif. Ajoutez un lien vers une réunion Zoom existante.
1. Sélectionnez **Créer**.

Si l'incident est créé avec succès, Slack affiche une notification de confirmation.

### Utiliser les actions rapides GitLab {#use-gitlab-quick-actions}

Utilisez des [actions rapides](../../user/project/quick_actions.md) dans la zone de texte de description lors de la création d'un incident GitLab depuis Slack. Les actions rapides suivantes sont susceptibles d'être les plus pertinentes pour vous :

| Commande                  | Description                               |
| ------------------------ | ----------------------------------------- |
| `/assign @user1 @user2`  | Ajoute un responsable à l'incident GitLab.  |
| `/label ~label1 ~label2` | Ajoute des labels à l'incident GitLab.       |
| `/link <URL> <text>`     | Ajoute un lien vers un canal Slack dédié, un runbook ou toute ressource pertinente à la section `Related resources` d'un incident. |
| `/zoom <URL>`            | Ajoute un lien de réunion Zoom à l'incident. |

## Envoyer des notifications d'incidents GitLab à Slack {#send-gitlab-incident-notifications-to-slack}

Si vous avez [activé les notifications](#manage-an-incident-from-slack) pour les incidents, vous devriez recevoir des notifications dans le canal Slack sélectionné chaque fois qu'un incident est ouvert, fermé ou mis à jour.

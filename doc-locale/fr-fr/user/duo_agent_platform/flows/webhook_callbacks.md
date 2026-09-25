---
stage: Agent Foundations
group: Agent Developer
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Recevez les événements de cycle de vie des flows GitLab Duo sur un webhook de projet ou de groupe.
title: Rappels de webhook
---

{{< details >}}

- Édition : [Gratuite](../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : version expérimentale

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249145) dans GitLab 19.4 [avec un feature flag](../../../administration/feature_flags/_index.md) nommé `duo_flow_callback_hooks`. Fonctionnalité désactivée par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

Lorsque vous déclenchez un flow avec l'[API Flows](../../../api/duo_agent_platform_flows.md), GitLab peut envoyer les événements du cycle de vie du flow vers un webhook que vous spécifiez. Vous pouvez alors réagir lorsque le flow démarre, se termine ou échoue, au lieu d'interroger l'API pour connaître le statut du flow.

Vous pouvez utiliser des webhooks dans un projet ou un groupe. Les projets enfants héritent des webhooks. Cela signifie qu'un webhook sur un groupe principal sert les flows de chaque projet de ce groupe.

## Prérequis {#prerequisites}

Pour qu'un webhook reçoive des événements de flow, assurez-vous que les prérequis suivants sont remplis :

- Un webhook a été [créé](../../project/integrations/webhooks.md#create-a-webhook) pour le projet ou le groupe, et les [rappels sont activés](#turn-on-callbacks-for-a-webhook) pour ce dernier.
- Le webhook appartient au projet ou au groupe dans lequel le flow s'exécute, ou à l'un des groupes ancêtres de ce projet ou groupe.
- Le webhook n'est pas un [webhook système](../../../administration/system_hooks.md).

## Activer les rappels pour un webhook {#turn-on-callbacks-for-a-webhook}

Prérequis :

- Pour les webhooks de projet, vous devez avoir le rôle Chargé de maintenance ou Propriétaire pour le projet.
- Pour les webhooks de groupe, vous devez avoir le rôle Propriétaire pour le groupe.

Pour activer les rappels pour un webhook :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet ou votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Webhooks**.
1. Sélectionnez **Ajouter un nouveau crochet Web** ou sélectionnez **Modifier** pour un webhook existant.
1. Sous **GitLab Duo Agent Platform**, cochez la case **Envoyer les événements de flow Duo à ce webhook**.
1. Sélectionnez **Ajouter un crochet Web** ou **Enregistrer les modifications**.

Vous pouvez également définir l'attribut `duo_flow_callback_enabled` avec l'[API webhooks de projet](../../../api/project_webhooks.md) ou l'[API webhooks de groupe](../../../api/group_webhooks.md). Utilisez l'une ou l'autre des API pour lister les webhooks et trouver l'ID du webhook pour lequel vous avez activé les rappels.

Les rôles requis pour activer les rappels s'appliquent uniquement au webhook. Un utilisateur qui déclenche un flow référençant le webhook n'a pas besoin de ces rôles.

## Recevoir des rappels pour un flow {#receive-callbacks-for-a-flow}

Prérequis :

- Vous devez remplir les [prérequis pour les flows](_index.md#prerequisites).

Pour recevoir des rappels, transmettez l'ID du webhook en tant qu'attribut `callback_hook_id` lorsque vous [déclenchez un flow](../../../api/duo_agent_platform_flows.md#trigger-a-flow) :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "Fix the failing pipeline by correcting the syntax error in .gitlab-ci.yml",
    "workflow_definition": "developer/v1",
    "start_workflow": true,
    "callback_hook_id": 42,
    "client_reference": "run-abc123"
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

Pour connaître les événements que GitLab envoie et la structure de chaque charge utile, consultez [Événements de flow GitLab Duo](../../project/integrations/webhook_events.md#gitlab-duo-flow-events).

### Corréler les rappels avec une requête {#correlate-callbacks-with-a-request}

Utilisez l'attribut facultatif `client_reference` pour corréler les rappels avec la requête qui a déclenché le flow. GitLab renvoie la valeur dans chaque rappel pour ce flow et ne l'interprète pas.

## Gérer les rappels dans votre point de terminaison {#handling-callbacks-in-your-endpoint}

Vérifiez qu'un rappel provient bien de GitLab avant d'agir dessus. Les rappels transportent les mêmes en-têtes que tout autre événement webhook. Configurez donc un jeton de signature sur le webhook et [vérifiez la signature](../../project/integrations/webhooks.md#verify-the-signature).

GitLab peut livrer le même événement plusieurs fois. Assurez-vous donc que votre point de terminaison est idempotent. Si votre point de terminaison ne retourne pas une réponse de succès ou de redirection, GitLab retente la livraison jusqu'à cinq fois avec un délai exponentiel. Les nouvelles tentatives répètent le `event_id` de la charge utile d'origine. Stockez donc les valeurs `event_id` que vous avez traitées et ignorez un événement que vous avez déjà traité. Une fois les tentatives épuisées, GitLab cesse d'essayer de livrer cet événement.

Les échecs de livraison répétés sont comptabilisés dans les limites d'échec du webhook, et GitLab peut [désactiver automatiquement le webhook](../../project/integrations/webhooks.md#auto-disabled-webhooks). Lorsqu'un webhook est [temporairement désactivé](../../project/integrations/webhooks.md#temporarily-disabled-webhooks), GitLab conserve les événements de flow pour ce webhook et les livre une fois la période de désactivation terminée. GitLab conserve un événement au maximum trois fois. Si le webhook est toujours désactivé, GitLab ne livre pas l'événement. GitLab n'envoie aucun événement de flow à un webhook [définitivement désactivé](../../project/integrations/webhooks.md#permanently-disabled-webhooks). Pour recevoir à nouveau des événements de flow, [réactivez le webhook](../../project/integrations/webhooks.md#re-enable-disabled-webhooks).

Avant chaque tentative de livraison, GitLab vérifie que les [rappels sont toujours activés](#turn-on-callbacks-for-a-webhook) pour le webhook. Si vous désactivez les rappels pendant qu'un flow est en cours d'exécution, GitLab cesse d'envoyer des événements pour ce flow, y compris les événements en file d'attente et les nouvelles tentatives en attente.

Pour voir ce que GitLab a envoyé et ce que votre point de terminaison a retourné, consultez l'[historique des requêtes webhook](../../project/integrations/webhooks.md#view-webhook-request-history). La section **Événements récents** affiche toutes les requêtes effectuées vers un webhook au cours des deux derniers jours. Cette section affiche uniquement les tentatives de livraison. Elle n'inclut donc pas les événements que GitLab a conservés ou n'a pas livrés pendant que le webhook était désactivé.

## Sujets connexes {#related-topics}

- [Événements de flow GitLab Duo](../../project/integrations/webhook_events.md#gitlab-duo-flow-events)
- [API Flows](../../../api/duo_agent_platform_flows.md)
- [Webhooks](../../project/integrations/webhooks.md)

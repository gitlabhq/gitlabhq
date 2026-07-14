---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurez GitLab Duo pour votre instance GitLab.
title: Configurer GitLab Duo
---

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

GitLab Duo est un assistant natif IA qui vous aide tout au long du cycle de vie du développement logiciel.

Vous pouvez configurer GitLab Duo pour utiliser :

- AI Gateway basée sur le cloud (par défaut) : AI Gateway hébergée par GitLab avec des modèles de langage de fournisseurs.
- Modèles auto-hébergés : Votre propre AI Gateway et vos propres modèles de langage pour un contrôle total de vos données et de votre sécurité.
- Configuration hybride : Modèles auto-hébergés pour certaines fonctionnalités et modèles basés sur le cloud pour d'autres.

## Prérequis {#prerequisites}

- Le mode silencieux est [désactivé](../../silent_mode/_index.md#turn-off-silent-mode).
- [Votre instance est activée avec un code d'activation](../../license.md#activate-gitlab-ee).
  - Vous ne pouvez pas utiliser une clé de licence.
  - Vous ne pouvez pas utiliser GitLab Duo avec une licence hors ligne, à l'exception de [GitLab Duo Self-Hosted](../../gitlab_duo_self_hosted/_index.md).

## Autoriser les connexions sortantes depuis l'instance GitLab vers GitLab Duo {#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo}

- Les nœuds d'application GitLab doivent se connecter au GitLab Duo Workflow à l'adresse `https://duo-workflow-svc.runway.gitlab.net` via HTTP/2. L'application et le service communiquent via gRPC.
- Pour les fonctionnalités de GitLab Duo Agent Platform, vos pare-feux et serveurs proxy HTTP/S doivent autoriser les connexions sortantes vers `duo-workflow-svc.runway.gitlab.net` sur le port `443` avec `https://` et la prise en charge du trafic HTTP/2.

## Autoriser les connexions entrantes des clients vers l'instance GitLab {#allow-inbound-connections-from-clients-to-the-gitlab-instance}

Votre instance GitLab doit autoriser les connexions entrantes depuis les clients IDE.

1. Autoriser les demandes de mise à niveau du protocole WebSocket avec les en-têtes :
   - `Connection: upgrade`
   - `Upgrade: websocket`
   - Prise en charge du protocole `HTTP/2`
   - En-têtes de sécurité WebSocket standard : `Sec-WebSocket-*`
1. Activer la prise en charge du protocole `wss://` (WebSocket Secure).
1. Ajouter des points de terminaison spécifiques à autoriser :
   - Point de terminaison principal : `wss://<customer-instance>/-/cable`
   - Vérifier que le protocole `HTTP/2` n'est pas rétrogradé vers `HTTP/1.1`.
   - Port : `443` (HTTPS/WSS)

Si vous rencontrez des problèmes :

- Vérifiez les restrictions sur le trafic WebSocket vers `wss://gitlab.example.com/-/cable` et d'autres domaines `.com`.
- Si vous utilisez des proxys inverses comme Apache, vous pourriez voir des problèmes de connexion à GitLab Duo Chat dans vos journaux, comme **WebSocket connection to .... failures**.

Pour résoudre ce problème, modifiez vos paramètres de proxy :

```apache
# Enable WebSocket reverse Proxy
# Needs proxy_wstunnel enabled
  RewriteCond %{HTTP:Upgrade} websocket [NC]
  RewriteCond %{HTTP:Connection} upgrade [NC]
  RewriteRule ^/?(.*) "ws://127.0.0.1:8181/$1" [P,L]
```

## Autoriser les connexions depuis le runner {#allow-connections-from-the-runner}

Pour les fonctionnalités de GitLab Duo Agent Platform qui utilisent des runners, comme les flows, le runner doit pouvoir se connecter à l'instance GitLab.

Les mêmes [connexions entrantes des clients vers l'instance GitLab](#allow-inbound-connections-from-clients-to-the-gitlab-instance) doivent être autorisées en tant que connexions sortantes du runner vers l'instance GitLab.

De plus, les runners doivent pouvoir se connecter à :

| Destination | Port | Objectif |
|-------------|------|---------|
| `registry.npmjs.org` | `443` | Télécharger le package Duo CLI au moment de l'exécution |
| `registry.gitlab.com` | `443` | Télécharger l'image Docker par défaut (sauf si vous utilisez une [image personnalisée](../../../user/duo_agent_platform/flows/execution.md#change-the-default-docker-image)) |

Si votre organisation ne peut pas autoriser l'accès au registre npm public, vous pouvez utiliser une [image Docker personnalisée](../../../user/duo_agent_platform/flows/execution.md#change-the-default-docker-image) avec les dépendances requises déjà installées.

## Partager les données d'utilisation avec GitLab {#share-usage-data-with-gitlab}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/587976) dans GitLab 18.9.1.

{{< /history >}}

Pour contribuer à l'amélioration de la qualité du service, vous pouvez partager des données d'utilisation sur les fonctionnalités de GitLab Duo Agent Platform avec GitLab.

Lorsque vous activez la collecte de données, GitLab enregistre des informations sur l'utilisation des fonctionnalités GitLab Duo. Ces données sont utilisées exclusivement pour l'amélioration du service et le débogage, et non pour l'entraînement de modèles IA.

Pour plus d'informations sur les données collectées, consultez [Agent Platform usage data](../../../user/gitlab_duo/data_usage.md#agent-platform-usage-data).

Prérequis :

- Disposer de GitLab 18.9.1 ou version ultérieure

Pour activer la journalisation étendue :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Cochez la case **Collecter les données d'utilisation**.
1. Sélectionnez **Sauvegarder les modifications**.

### Utilisation des données avec les modèles auto-hébergés {#data-usage-with-self-hosted-models}

Si vous utilisez une AI Gateway auto-hébergée et des modèles auto-hébergés, les journaux détaillés sont stockés sur votre infrastructure et ne sont pas partagés avec GitLab. Pour partager des données avec GitLab, vous devez configurer votre AI Gateway auto-hébergée pour envoyer des traces vers un service d'observabilité externe.

Vous pouvez utiliser [Service Ping](../../settings/usage_statistics.md#service-ping) pour envoyer des données d'utilisation à GitLab. Ces données sont différentes des [données de télémétrie](../../../user/gitlab_duo/data_usage.md#telemetry).

## Lancer un contrôle d'intégrité pour GitLab Duo {#run-a-health-check-for-gitlab-duo}

{{< details >}}

- Statut : Bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161997) dans GitLab 17.3.
- [Ajout du téléchargement du rapport de contrôle d'intégrité](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165032) dans GitLab 17.5.

{{< /history >}}

Vous pouvez déterminer si votre instance répond aux exigences pour utiliser GitLab Duo. Lorsque le contrôle d'intégrité est terminé, il affiche un résultat de réussite ou d'échec ainsi que les types de problèmes. Si le contrôle d'intégrité échoue à l'un des tests, les utilisateurs pourraient ne pas être en mesure d'utiliser les fonctionnalités GitLab Duo dans votre instance.

Il s'agit d'une fonctionnalité en [bêta](../../../policy/development_stages_support.md).

Prérequis :

- Vous devez être administrateur.

Pour lancer un contrôle d'intégrité :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Dans le coin supérieur droit, sélectionnez **Lancer l'état des services**.
1. Facultatif. Dans GitLab 17.5 et versions ultérieures, une fois le contrôle d'intégrité terminé, vous pouvez sélectionner **Télécharger le rapport** pour enregistrer un rapport détaillé des résultats du contrôle d'intégrité.

Ces tests sont effectués :

| Test                      | Description |
|---------------------------|-------------|
| AI Gateway                | Modèles GitLab Duo Self-Hosted uniquement. Vérifie si l'URL de l'AI Gateway est configurée en tant que variable d'environnement. Cette connectivité est requise pour les déploiements de modèles auto-hébergés qui utilisent l'AI Gateway. |
| Réseau                   | Vérifie si votre instance peut se connecter à `customers.gitlab.com` et à `cloud.gitlab.com`.<br><br>Si votre instance ne peut se connecter à aucune des destinations, assurez-vous que les paramètres de votre pare-feu ou de votre serveur proxy [autorisent la connexion](#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo). |
| Synchronisation           | Vérifie si votre abonnement : <br>\- A été activé avec un code d'activation et peut être synchronisé avec `customers.gitlab.com`.<br>\- Dispose des identifiants d'accès corrects.<br>\- A été synchronisé récemment. Si ce n'est pas le cas ou si les identifiants d'accès sont manquants ou expirés, vous pouvez [synchroniser manuellement](../../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data) les données de votre abonnement. |
| Code Suggestions          | Modèles GitLab Duo Self-Hosted uniquement. Vérifie si Code Suggestions est disponible : <br>\- Votre licence inclut l'accès à Code Suggestions.<br>\- Vous disposez des autorisations nécessaires pour utiliser la fonctionnalité. |
| GitLab Duo Agent Platform | Vérifie si le service backend est opérationnel et accessible. Ce service est requis pour les fonctionnalités agentiques comme Agent Platform et GitLab Duo Agentic Chat. |
| Échange système           | Vérifie si Code Suggestions peut être utilisé dans votre instance. Si l'évaluation de l'échange système échoue, les utilisateurs pourraient ne pas être en mesure d'utiliser les fonctionnalités GitLab Duo. |

Pour les instances GitLab antérieures à la version 17.10, si vous rencontrez des problèmes avec le contrôle d'intégrité, consultez la [page de dépannage](../../../user/gitlab_duo/troubleshooting.md).

## Autres options d'hébergement {#other-hosting-options}

Par défaut, GitLab Duo utilise des modèles de langage de fournisseurs IA pris en charge et envoie les données via une AI Gateway basée sur le cloud hébergée par GitLab.

Si vous souhaitez héberger vos propres modèles de langage ou AI Gateway :

- Vous pouvez [utiliser GitLab Duo Self-Hosted pour héberger l'AI Gateway et utiliser l'un des modèles auto-hébergés pris en charge](../../gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms). Cette option offre un contrôle total sur vos données et votre sécurité.
- Utilisez une [configuration hybride](../../gitlab_duo_self_hosted/_index.md#hybrid-ai-gateway-and-model-configuration), dans laquelle vous hébergez votre propre AI Gateway et vos propres modèles pour certaines fonctionnalités, mais configurez d'autres fonctionnalités pour utiliser l'AI Gateway de GitLab et les modèles de fournisseurs.

## Sujets connexes {#related-topics}

- [Résumé des fonctionnalités GitLab Duo](../../../user/gitlab_duo/feature_summary.md)
- [Contrôler la disponibilité de GitLab Duo](../../../user/gitlab_duo/turn_on_off.md)
- [Dépannage de GitLab Duo](../../../user/gitlab_duo/troubleshooting.md)

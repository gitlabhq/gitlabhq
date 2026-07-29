---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurer GitLab Duo pour votre instance GitLab.
title: Configurer GitLab Duo
---

{{< details >}}

- Offre : GitLab Self-Managed, GitLab Dedicated for Government

{{< /details >}}

GitLab Duo est un assistant d'IA natif qui vous aide tout au long du cycle de vie du développement logiciel.

Vous pouvez configurer GitLab Duo pour qu'il utilise l'une des options suivantes :

- Une passerelle d'IA basée sur le cloud (par défaut) : une passerelle d'IA hébergée par GitLab qui utilise des modèles de langage proposés par des fournisseurs.
- Des modèles auto-hébergés : votre propre passerelle d'IA et vos propres modèles de langage, pour disposer d'un contrôle total sur vos données et votre sécurité.
- Une configuration hybride : des modèles auto-hébergés pour certaines fonctionnalités et des modèles basés sur le cloud pour d'autres.

## Prérequis {#prerequisites}

- Le mode silencieux est [désactivé](../../silent_mode/_index.md#turn-off-silent-mode).
- [Votre instance est activée au moyen d'un code d'activation](../../license.md#activate-gitlab-ee).
  - Vous ne pouvez pas utiliser de clé de licence.
  - Vous ne pouvez pas utiliser GitLab Duo avec une licence hors ligne, sauf dans le cas de [GitLab Duo Self-Hosted](../../gitlab_duo_self_hosted/_index.md).
- L'hôte sur lequel s'exécute votre instance peut résoudre les noms d'hôte publics via DNS, même lorsqu'il utilise un serveur proxy HTTP/S.

## Autoriser les connexions sortantes depuis l'instance GitLab vers GitLab Duo {#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo}

- Les nœuds d'application GitLab doivent se connecter à GitLab Duo Workflow à l'adresse `https://duo-workflow-svc.runway.gitlab.net` en HTTP/2. L'application et le service communiquent au moyen de gRPC.
- Pour les fonctionnalités de GitLab Duo Agent Platform, vos pare-feux et serveurs proxy HTTP/S doivent autoriser les connexions sortantes vers `duo-workflow-svc.runway.gitlab.net` sur le port `443` avec `https://`, et prendre en charge le trafic HTTP/2.
- Si votre instance se connecte via un serveur proxy HTTP/S, l'hôte doit tout de même pouvoir résoudre les noms d'hôte publics via DNS. Si les noms d'hôte ne peuvent être résolus que par l'intermédiaire du serveur proxy, certaines fonctionnalités GitLab Duo, comme le contrôle d'intégrité GitLab Duo, le tableau de bord GitLab Credits et GitLab Duo Agent Platform, peuvent ne pas répondre avant l'expiration du délai d'attente ou échouer. Pour plus d'informations, consultez le [ticket 602538](https://gitlab.com/gitlab-org/gitlab/-/issues/602538).
- Les fonctionnalités d'IA diffusent les réponses via des connexions HTTP de longue durée. Un serveur proxy HTTP/S ou un pare-feu qui applique une durée maximale de requête ou un délai d'inactivité peut interrompre les longues réponses sans générer d'erreur. Configurez votre proxy avec un délai d'expiration plus long que celui des autres composants dans le chemin.

## Autoriser les connexions entrantes des clients vers l'instance GitLab {#allow-inbound-connections-from-clients-to-the-gitlab-instance}

Votre instance GitLab doit autoriser les connexions entrantes depuis les clients d'environnements de développement intégrés (IDE).

1. Autorisez les demandes de mise à niveau vers le protocole WebSocket avec les en-têtes suivants :
   - `Connection: upgrade`
   - `Upgrade: websocket`
   - Prise en charge du protocole `HTTP/2`
   - En-têtes de sécurité WebSocket standard : `Sec-WebSocket-*`
1. Activez la prise en charge du protocole `wss://` (WebSocket Secure).
1. Ajoutez les points de terminaison spécifiques à autoriser :
   - Point de terminaison principal : `wss://<customer-instance>/-/cable`
   - Assurez-vous que le protocole `HTTP/2` n'est pas rétrogradé vers `HTTP/1.1`.
   - Port : `443` (HTTPS/WSS)

En cas de problème :

- Vérifiez si le trafic WebSocket vers `wss://gitlab.example.com/-/cable` et d'autres domaines `.com` est soumis à des restrictions.
- Si vous utilisez des serveurs proxy inverses tels qu'Apache, vos journaux peuvent faire état de problèmes de connexion à GitLab Duo Chat, par exemple **WebSocket connection to .... failures**.

Pour résoudre ce problème, modifiez les paramètres de votre proxy :

```apache
# Enable WebSocket reverse Proxy
# Needs proxy_wstunnel enabled
  RewriteCond %{HTTP:Upgrade} websocket [NC]
  RewriteCond %{HTTP:Connection} upgrade [NC]
  RewriteRule ^/?(.*) "ws://127.0.0.1:8181/$1" [P,L]
```

## Autoriser les connexions depuis le runner {#allow-connections-from-the-runner}

Pour les fonctionnalités de GitLab Duo Agent Platform qui s'appuient sur des runners, comme les flows, le runner doit pouvoir se connecter à l'instance GitLab.

Les mêmes [connexions entrantes des clients vers l'instance GitLab](#allow-inbound-connections-from-clients-to-the-gitlab-instance) doivent également être autorisées en sortie du runner vers l'instance GitLab.

En outre, les runners doivent pouvoir se connecter à :

| Destination | Port | Objectif |
|-------------|------|---------|
| `registry.npmjs.org` | `443` | Télécharger le paquet Duo CLI au moment de l'exécution |
| `registry.gitlab.com` | `443` | Télécharger l'image Docker par défaut (sauf si vous utilisez une [image personnalisée](../../../user/duo_agent_platform/flows/execution.md#change-the-default-docker-image)) |

Si votre organisation ne peut pas autoriser l'accès au registre npm public, vous pouvez utiliser une [image Docker personnalisée](../../../user/duo_agent_platform/flows/execution.md#change-the-default-docker-image) qui contient déjà les dépendances requises.

> [!note]
> La connexion du runner au service GitLab Duo Agent Platform est acheminée via l'instance GitLab. Les runners ne se connectent pas directement à `duo-workflow-svc.runway.gitlab.net`. L'exigence de pare-feu pour `duo-workflow-svc.runway.gitlab.net` sur le port `443` s'applique à l'instance GitLab, et non au runner. La configuration réseau de votre runner doit autoriser le trafic HTTPS sortant vers l'instance GitLab.

## Partager les données d'utilisation avec GitLab {#share-usage-data-with-gitlab}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/587976) dans GitLab 18.9.1.

{{< /history >}}

Pour contribuer à améliorer la qualité du service, vous pouvez partager avec GitLab des données sur l'utilisation des fonctionnalités GitLab Duo Agent Platform.

Lorsque vous activez la collecte de données, GitLab consigne des informations sur l'utilisation des fonctionnalités GitLab Duo. Ces données servent exclusivement à améliorer le service et à en assurer le débogage, et non à entraîner des modèles d'IA.

Pour plus d'informations sur les données collectées, consultez la section [Données d'utilisation de GitLab Duo Agent Platform](../../../user/gitlab_duo/data_usage.md#agent-platform-usage-data).

Prérequis :

- Disposer de GitLab 18.9.1 ou d'une version ultérieure

Pour activer la journalisation étendue :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Cochez la case **Collecter les données d'utilisation**.
1. Sélectionnez **Enregistrer les modifications**.

### Utilisation des données avec les modèles auto-hébergés {#data-usage-with-self-hosted-models}

Si vous utilisez une passerelle d'IA auto-hébergée et des modèles auto-hébergés, les journaux détaillés sont stockés dans votre infrastructure et ne sont pas partagés avec GitLab. Pour partager des données avec GitLab, vous devez configurer votre passerelle d'IA auto-hébergée afin qu'elle transmette des traces à un service d'observabilité externe.

Vous pouvez utiliser le [ping de service](../../settings/usage_statistics.md#service-ping) pour envoyer des données d'utilisation à GitLab. Ces données sont distinctes des [données de télémétrie](../../../user/gitlab_duo/data_usage.md#telemetry).

## Lancer un contrôle d'intégrité pour GitLab Duo {#run-a-health-check-for-gitlab-duo}

{{< details >}}

- Statut : version bêta

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161997) dans GitLab 17.3.
- [Ajout du téléchargement du rapport de contrôle d'intégrité](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165032) dans GitLab 17.5.
- Les vérifications de l'état de préparation des flows par défaut ont été [ajoutées](https://gitlab.com/gitlab-org/gitlab/-/work_items/599536) dans GitLab 19.1.

{{< /history >}}

Vous pouvez vérifier si votre instance remplit les conditions requises pour utiliser GitLab Duo. Une fois terminé, le contrôle d'intégrité affiche un résultat de réussite ou d'échec, ainsi que les types de problèmes détectés. Si le contrôle d'intégrité échoue à l'un des tests, les utilisateurs risquent de ne pas pouvoir utiliser les fonctionnalités GitLab Duo dans votre instance.

Il s'agit d'une fonctionnalité en [version bêta](../../../policy/development_stages_support.md).

Prérequis :

- Vous devez être administrateur.

Pour lancer un contrôle d'intégrité :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Dans le coin supérieur droit, sélectionnez **Lancer l'état des services**.
1. Facultatif. Dans GitLab 17.5 ou une version ultérieure, une fois le contrôle d'intégrité terminé, vous pouvez sélectionner **Télécharger le rapport** pour enregistrer un rapport détaillé des résultats du contrôle d'intégrité.

Les tests suivants sont effectués :

| Test                      | Description |
|---------------------------|-------------|
| Passerelle d'IA                | Modèles GitLab Duo Self-Hosted uniquement. Vérifie si l'URL de la passerelle d'IA est configurée comme variable d'environnement. Cette connectivité est requise pour les déploiements de modèles auto-hébergés qui utilisent la passerelle d'IA. |
| Réseau                   | Vérifie si votre instance peut se connecter à `customers.gitlab.com` et à `cloud.gitlab.com`.<br><br>Si votre instance ne peut se connecter à aucune des deux destinations, assurez-vous que les paramètres de votre pare-feu ou de votre serveur proxy [autorisent la connexion](#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo). |
| Synchronisation           | Vérifie si votre abonnement : <br>\- a été activé au moyen d'un code d'activation et peut être synchronisé avec `customers.gitlab.com`.<br>\- dispose d'identifiants d'accès valides.<br>\- a été synchronisé récemment. Si votre abonnement n'a pas été synchronisé récemment ou si ses identifiants d'accès sont manquants ou expirés, vous pouvez [synchroniser manuellement](../../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data) les données de votre abonnement. |
| Suggestions de code          | Modèles GitLab Duo Self-Hosted uniquement. Vérifie si la fonctionnalité Suggestions de code est disponible : <br>\- votre licence donne accès à la fonctionnalité Suggestions de code.<br>\- vous disposez des autorisations nécessaires pour utiliser la fonctionnalité. |
| GitLab Duo Agent Platform | Vérifie si le service backend est opérationnel et accessible. Ce service est requis pour les fonctionnalités agentiques comme GitLab Duo Agent Platform et GitLab Duo Agentic Chat.<br><br>Pour GitLab Duo Self-Hosted, ce test ne peut pas réussir tant que vous n'avez pas [sélectionné un modèle auto-hébergé pour la fonctionnalité GitLab Duo Agent Platform](../../gitlab_duo_self_hosted/configure_duo_features.md#select-a-self-hosted-model-for-a-feature).<br><br>Vérifie également si les prérequis suivants des flows par défaut sont remplis :<br>\- le paramètre d'exécution des flows au niveau de l'instance est activé.<br>\- le paramètre des flows par défaut au niveau de l'instance est activé.<br>\- au moins un runner d'instance actif portant le tag `gitlab--duo` est enregistré et connecté, et il utilise un exécuteur compatible avec Docker.|
| Échange système           | Vérifie si la fonctionnalité Suggestions de code peut être utilisée dans votre instance. Si l'évaluation de l'échange système échoue, les utilisateurs risquent de ne pas pouvoir utiliser les fonctionnalités GitLab Duo. |
| Facturation d'utilisation           | Vérifie si votre instance peut se connecter aux points de terminaison de facturation d'utilisation, notamment le portail Customers Portal, la passerelle d'IA et le service Duo Workflow Service. |

Si vous rencontrez des problèmes avec le contrôle d'intégrité sur une instance GitLab antérieure à la version 17.10, consultez la [page de dépannage](../../../user/gitlab_duo/troubleshooting.md).

## Autres options d'hébergement {#other-hosting-options}

Par défaut, GitLab Duo utilise des modèles de langage pris en charge, mis à disposition par des fournisseurs d'IA, et transmet les données par l'intermédiaire d'une passerelle d'IA basée sur le cloud et hébergée par GitLab.

Si vous souhaitez héberger vos propres modèles de langage ou votre propre passerelle d'IA :

- Vous pouvez [utiliser GitLab Duo Self-Hosted pour héberger la passerelle d'IA et utiliser l'un des modèles auto-hébergés pris en charge](../../gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms). Cette option vous donne un contrôle total sur vos données et votre sécurité.
- Utilisez une [configuration hybride](../../gitlab_duo_self_hosted/_index.md#hybrid-ai-gateway-and-model-configuration), dans laquelle vous hébergez votre propre passerelle d'IA et vos propres modèles pour certaines fonctionnalités, mais configurez d'autres fonctionnalités pour qu'elles utilisent la passerelle d'IA de GitLab et des modèles mis à disposition par des fournisseurs d'IA.

## GitLab Dedicated for Government {#gitlab-dedicated-for-government}

Pour GitLab Dedicated for Government, vous devez utiliser GitLab Duo Self-Hosted avec des modèles approuvés par FedRAMP. La passerelle d'IA basée sur le cloud et les modèles mis à disposition par des fournisseurs d'IA ne sont pas disponibles pour GitLab Dedicated for Government.

Pour plus d'informations, consultez la page [Configurer GitLab Duo sur GitLab Dedicated for Government](gitlab_dedicated_for_government.md).

## Sujets connexes {#related-topics}

- [Résumé des fonctionnalités de GitLab Duo](../../../user/gitlab_duo/feature_summary.md)
- [Contrôler la disponibilité de GitLab Duo](../../../user/gitlab_duo/turn_on_off.md)
- [Dépannage de GitLab Duo](../../../user/gitlab_duo/troubleshooting.md)

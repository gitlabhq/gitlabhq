---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Connectez des agents personnalisés dans le catalogue d'IA à des sources de données externes et à des services tiers à l'aide de serveurs MCP."
title: "Serveurs MCP dans le catalogue d'IA"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : version expérimentale

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/590708) dans GitLab 18.10 [avec le feature flag](../../../administration/feature_flags/_index.md) `ai_catalog_mcp_servers`. Fonctionnalité désactivée par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

Les agents personnalisés dans le catalogue d'IA peuvent se connecter à des sources de données externes et à des services tiers (tels que Jira ou Linear) via le [Model Context Protocol](https://modelcontextprotocol.io/) (MCP).

Cette fonctionnalité est une [version expérimentale](../../../policy/development_stages_support.md#experiment). Partagez vos commentaires dans le [ticket 593219](https://gitlab.com/gitlab-org/gitlab/-/work_items/593219).

Avec les serveurs MCP dans le catalogue d'IA, vous pouvez :

- Ajouter des serveurs MCP au catalogue de votre organisation (nom, URL et type de transport).
- Associer des serveurs MCP à des agents personnalisés.
- Voir quels serveurs MCP sont connectés à chaque agent.
- S'authentifier auprès de serveurs MCP compatibles OAuth.

Un onglet **MCP** dédié apparaît dans la navigation du catalogue d'IA aux côtés de **Agents** et de **Flux**. Les serveurs MCP associés aux agents activés dans votre espace de nommage sont également disponibles sous **IA** > **Serveurs MCP** au niveau du groupe et du projet.

## Prérequis {#prerequisites}

- Satisfaire aux [prérequis pour GitLab Duo Agent Platform](../../duo_agent_platform/_index.md#prerequisites).
- Sur GitLab.com, être membre d'un groupe principal dont les [fonctionnalités expérimentales et bêta de GitLab Duo sont activées](../turn_on_off.md#on-gitlabcom-2).
- Sur GitLab Self-Managed, votre instance a les [fonctionnalités expérimentales et bêta de GitLab Duo activées](../turn_on_off.md#on-gitlab-self-managed-2).
- Sur GitLab Self-Managed, un administrateur a activé le `mcp_client` [feature flag](../../../administration/feature_flags/_index.md).
- Le serveur MCP doit être :
  - Un serveur MCP vérifié ou partenaire. Les URL arbitraires ne sont pas autorisées.
  - Un serveur MCP distant.

## Ajouter un serveur MCP au catalogue d'IA {#add-an-mcp-server-to-the-ai-catalog}

{{< details >}}

- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- Accès administrateur pour l'instance.

Sur GitLab Self-Managed et GitLab Dedicated, les administrateurs d'instance peuvent ajouter un serveur MCP au catalogue d'IA pour leur instance à partir de la liste des [serveurs MCP disponibles](#available-mcp-servers).

> [!note]
> Sur GitLab.com, les membres du groupe principal ne peuvent pas ajouter un serveur MCP au catalogue d'IA, car cette gestion est centralisée par les administrateurs de GitLab.com.

Pour ajouter un serveur MCP au catalogue d'IA :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Sélectionnez **Version** > **Catalogue d'IA**.
1. Sélectionnez l'onglet **MCP**.
1. Sélectionnez **Nouveau serveur MCP**.
1. Remplissez les champs :
   - **Nom** : un nom descriptif pour le serveur MCP (par exemple, `Jira`).
   - **Description** (facultatif) : une brève description de ce que le serveur fournit.
   - **URL** : le point de terminaison HTTP du serveur MCP.
   - **URL de la page d'accueil** (facultatif) : L'URL de la page d'accueil ou de la documentation du serveur MCP.
   - **Transport** : sélectionnez **HTTP**. Seul le transport HTTP est pris en charge. Les transports SSE et stdio ne sont pas disponibles.
   - **Type d'authentification** : Sélectionnez l'une des options suivantes :
     - **Aucun** : aucune authentification requise.
     - **OAuth** : authentifiez-vous avec OAuth 2.0. Si le serveur prend en charge [l'enregistrement dynamique de client OAuth 2.0](https://tools.ietf.org/html/rfc7591), GitLab s'enregistre automatiquement en tant que client OAuth lors de la première connexion.
1. Sélectionnez **Créer un serveur MCP**.

Le serveur MCP est désormais disponible dans le catalogue de votre organisation et peut être associé à des agents.

## Modifier un serveur MCP {#edit-an-mcp-server}

{{< details >}}

- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- Accès administrateur pour l'instance.

Sur GitLab Self-Managed et GitLab Dedicated, les administrateurs d'instance peuvent modifier un serveur MCP dans le catalogue d'IA pour leur instance.

> [!note]
> Sur GitLab.com, les membres du groupe principal ne peuvent pas modifier un serveur MCP dans le catalogue d'IA, car cette gestion est centralisée par les administrateurs de GitLab.com.

Pour modifier un serveur MCP :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Sélectionnez **Version** > **Catalogue d'IA**.
1. Sélectionnez l'onglet **MCP**.
1. Sélectionnez le serveur MCP que vous souhaitez modifier.
1. Sélectionner **Éditer**.
1. Mettez à jour les champs selon vos besoins.
1. Sélectionnez **Enregistrer les modifications**.

## Connecter un serveur MCP à un agent personnalisé {#connect-an-mcp-server-to-a-custom-agent}

Pour connecter un serveur MCP à un agent personnalisé :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Sélectionnez **Version** > **Catalogue d'IA**.
1. Sélectionnez l'onglet **Agents**.
1. Sélectionnez l'agent que vous souhaitez configurer, puis sélectionnez **Modifier**.
1. Dans la section **Serveurs MCP**, sélectionnez les serveurs MCP à associer à cet agent.
1. Sélectionnez **Enregistrer les modifications**.

L'agent peut désormais utiliser tous les outils fournis par le serveur MCP associé lors de l'exécution.

Vous ne pouvez pas empêcher un agent d'utiliser des outils spécifiques du serveur MCP.

## Afficher les serveurs MCP connectés à un agent personnalisé {#view-mcp-servers-connected-to-a-custom-agent}

Pour voir quels serveurs MCP sont connectés à un agent personnalisé :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Sélectionnez **Version** > **Catalogue d'IA**.
1. Sélectionnez l'onglet **Agents**.
1. Sélectionnez l'agent.

La page de détail de l'agent répertorie tous les serveurs MCP connectés.

## Déconnecter un serveur MCP des agents personnalisés {#disconnect-an-mcp-server-from-custom-agents}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227157) dans GitLab 18.11.

{{< /history >}}

Vous pouvez déconnecter un serveur MCP de tous les agents personnalisés auxquels il est connecté. Vous ne pouvez pas déconnecter un serveur MCP d'un agent spécifique.

Après la déconnexion, les conversations existantes des agents personnalisés peuvent toujours référencer le contenu déjà récupéré depuis le serveur MCP. Toutefois, les agents ne sont plus en mesure de récupérer du nouveau contenu ni d'effectuer des actions.

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Sélectionnez **Version** > **Catalogue d'IA**.
1. Sélectionnez l'onglet **MCP**.
1. Pour le serveur MCP que vous souhaitez déconnecter, sélectionnez **Déconnecter**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Déconnecter**.

## Afficher les serveurs MCP pour un espace de nommage {#view-mcp-servers-for-a-namespace}

La page **IA** > **Serveurs MCP** affiche tous les serveurs MCP associés aux agents activés dans votre espace de nommage. Chaque serveur affiche le nombre d'agents qui l'utilisent, avec les noms des agents affichés dans une infobulle au survol.

Cette page est disponible au niveau du groupe et du projet :

- **Au niveau du groupe**, les serveurs MCP associés aux agents du groupe sont affichés.
- **Au niveau du projet**, les serveurs MCP associés aux agents configurés dans le projet sont affichés.

Pour afficher les serveurs MCP au niveau du groupe ou du projet :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et trouvez votre groupe ou projet.
1. Sélectionnez **IA** > **Serveurs MCP**.

Pour les serveurs compatibles OAuth avec lesquels vous ne vous êtes pas encore authentifié, une option **Connecter** s'affiche.

## S'authentifier auprès d'un serveur MCP {#authenticate-with-an-mcp-server}

Pour vous authentifier auprès d'un serveur MCP compatible OAuth :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et trouvez votre groupe ou projet.
1. Sélectionnez **IA** > **Serveurs MCP**.
1. Trouvez le serveur MCP et sélectionnez **Connecter**.
1. Examinez et approuvez la demande d'autorisation sur la page d'autorisation du serveur MCP.
1. GitLab stocke le jeton d'accès de manière sécurisée pour les demandes futures.

Si le serveur prend en charge [l'enregistrement dynamique de client OAuth 2.0](https://tools.ietf.org/html/rfc7591), GitLab s'enregistre automatiquement en tant que client OAuth lors de la première connexion. Vous n'avez pas besoin de fournir des identifiants OAuth manuellement.

## Serveurs MCP disponibles {#available-mcp-servers}

{{< details >}}

- Offre : GitLab.com

{{< /details >}}

Vous pouvez ajouter les serveurs MCP suivants depuis le catalogue d'IA à vos agents personnalisés. Pour plus de serveurs proposés pour le catalogue, consultez le [ticket 591969](https://gitlab.com/gitlab-org/gitlab/-/work_items/591969).

### Linear {#linear}

Le serveur MCP Linear permet aux agents d'IA et aux workflows d'interagir avec les données Linear en temps réel, notamment pour rechercher, créer et mettre à jour des tickets, des projets et des commentaires.

| Propriété | Valeur |
|---|---|
| URL | `https://mcp.linear.app/mcp` |
| Transport | HTTP |
| Authentification | OAuth |

### Atlassian {#atlassian}

Le serveur MCP Atlassian permet aux agents d'IA et aux workflows d'interagir avec les données Jira et Confluence en temps réel, notamment pour rechercher, créer et mettre à jour des tickets, des pages et le contenu de projets.

| Propriété | Valeur |
|---|---|
| URL | `https://mcp.atlassian.com/v1/mcp` |
| Transport | HTTP |
| Authentification | OAuth |

Avant de vous connecter, configurez votre instance Atlassian pour qu'elle fasse confiance à GitLab en tant que domaine autorisé :

1. Dans Atlassian, accédez à la page d'administration.
1. Sélectionnez **Apps** > **AI Settings** > **Rovo MCP Server**.
1. Ajoutez `https://gitlab.com/**` à la liste des domaines de confiance.

### Context7 {#context7}

Context7 MCP récupère la documentation à jour et spécifique à la version ainsi que des exemples de code depuis la source et les ajoute à votre invite.

| Propriété | Valeur |
|---|---|
| URL | `https://mcp.context7.com/mcp` |
| Transport | HTTP |
| Authentification | Aucune |

## Sujets connexes {#related-topics}

- [Serveur MCP GitLab](../../model_context_protocol/mcp_server.md)

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec des serveurs MCP dans le catalogue d'IA, vous pourriez rencontrer les problèmes suivants.

### Problèmes de serveur MCP liés aux restrictions des requêtes sortantes {#mcp-server-issues-due-to-outbound-request-restrictions}

{{< details >}}

- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab valide l'URL d'un serveur MCP de la même manière qu'il valide d'autres requêtes sortantes, telles que les webhooks et les intégrations. Si votre instance GitLab Self-Managed restreint les [requêtes sortantes](../../../security/webhooks.md), les tentatives d'ajout, de modification ou de connexion à un serveur MCP peuvent échouer, même lorsque l'URL elle-même est valide.

La manière dont vous résolvez ce problème dépend de l'endroit où le service MCP est hébergé.

Pour plus d'informations sur le dépannage, consultez [le filtrage des requêtes sortantes](../../../security/webhooks.md#troubleshooting).

#### Serveur MCP public {#public-mcp-server}

Un serveur MCP public peut être un serveur vérifié ou partenaire, ou votre propre serveur accessible via Internet.

Si votre instance [bloque toutes les requêtes sortantes à l'exception de celles figurant dans une liste d'autorisation](../../../security/webhooks.md#filter-requests), demandez à votre administrateur d'instance d'ajouter le domaine ou l'adresse IP du serveur MCP à la [liste d'autorisation des requêtes sortantes](../../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains).

Si votre instance ne fait pas cela, aucune action supplémentaire n'est requise.

#### Serveur MCP interne ou local {#internal-or-local-mcp-server}

Un serveur MCP interne ou local peut être un serveur s'exécutant sur `localhost`, ou sur un réseau privé ou interne.

Par défaut, GitLab bloque les requêtes vers les adresses réseau locales et privées pour se protéger contre la falsification de requêtes côté serveur.

Pour autoriser la requête, demandez à votre administrateur d'instance d'effectuer l'une des opérations suivantes :

- [Autoriser les requêtes vers le réseau local depuis les webhooks et les intégrations](../../../security/webhooks.md#allow-requests-to-the-local-network-from-webhooks-and-integrations). Cela autorise les requêtes vers toutes les adresses réseau locales et privées, pas seulement votre serveur MCP.
- Ajoutez uniquement le domaine ou l'adresse IP du serveur MCP (et le port, si nécessaire) à la liste d'autorisation des requêtes sortantes. Cette option est plus restrictive, car elle n'ouvre pas l'accès à l'ensemble du réseau local.

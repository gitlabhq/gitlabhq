---
stage: Software Supply Chain Security
group: AI Governance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez des politiques d'approbation au niveau des outils pour les agents d'IA afin de contrôler les actions sensibles avec une approbation humaine au moment de l'exécution."
title: "Gouvernance des outils d'agent"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/20466) dans GitLab 19.1 en [version bêta](../../policy/development_stages_support.md) avec un [feature flag](../../administration/feature_flags/_index.md) nommé `gitlab_duo_governance_settings`. Activés par défaut.
- L'application pour les flows en arrière-plan, tels que le flow par défaut Duo Developer, a été ajoutée dans GitLab 19.3 derrière un [feature flag](../../administration/feature_flags/_index.md) nommé `duo_workflow_background_tool_governance`. Fonctionnalité désactivée par défaut.
- Le feature flag `gitlab_duo_governance_settings` a été supprimé dans GitLab 19.4.

{{< /history >}}

> [!warning]
> Cette fonctionnalité est en [version bêta](../../policy/development_stages_support.md). Elle est susceptible d'être modifiée sans préavis. Pour plus d'informations, consultez la page [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

La gouvernance des outils intervient à la frontière de l'exécution. Une fois qu'un agent a été admis dans un projet, et avant qu'un outil soit appelé, la couche de gouvernance consulte les règles configurées pour le rôle de l'utilisateur et la catégorie d'action de l'outil, puis applique le mode qui en résulte.

> [!flag]
> L'application pour les flows en arrière-plan est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Les outils sont classés en trois catégories d'action :

- **Lire** : outils qui récupèrent ou affichent uniquement des informations.
- **Écrire** : outils qui créent ou modifient des ressources.
- **Supprimer** : outils qui suppriment des ressources ou les retirent de manière irréversible.

La gouvernance des outils d'agent, qui sert de garde-fou avec intervention humaine, permet aux administrateurs de définir le mode à appliquer à chaque outil d'agent au moment de l'exécution. Au lieu d'autoriser les agents à appeler tout outil sans validation, vous pouvez configurer chaque outil selon l'un des trois modes suivants :

- **Toujours autoriser** : l'outil s'exécute sans demander de confirmation à l'utilisateur.
- **Toujours demander** : une carte d'approbation intégrée s'affiche, et l'utilisateur doit approuver ou rejeter l'action avant qu'elle puisse se poursuivre.
- **Toujours refuser** : l'outil est entièrement bloqué et invisible pour l'agent. L'agent ne voit jamais l'outil et l'utilisateur n'est jamais sollicité.

Cette fonctionnalité s'applique à Agentic Chat et aux extensions IDE. Pour les flows, l'application de la gouvernance dépend de l'endroit où le flow s'exécute :

- Pour les flows qui s'exécutent dans une extension IDE, GitLab applique les règles de gouvernance.
- Pour les flows en arrière-plan, tels que le flow par défaut Duo Developer, GitLab applique les règles de gouvernance.

## Matrice de gouvernance par défaut {#default-governance-matrix}

| Classification | Mode |
|------|------|
| Lecture (ressources GitLab) | Toujours autoriser |
| Lecture (fichiers locaux) | Toujours demander |
| Écrire | Toujours demander |
| Supprimer | Toujours demander |

### Outils du serveur GitLab MCP {#gitlab-mcp-server-tools}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/606073) dans GitLab 19.4 avec un [feature flag](../../administration/feature_flags/_index.md) nommé `duo_mcp_tool_governance`. Fonctionnalité désactivée par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/work_items/607499) dans GitLab 19.4.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Les outils exposés par le serveur GitLab MCP apparaissent dans l'onglet **Gestion des outils** avec une source `mcp`, aux côtés des outils de la plateforme GitLab Duo Agent Platform. Vous définissez un mode pour ces outils de la même manière, comme décrit dans [Configurer la gouvernance des outils pour un groupe](#configure-tool-governance-for-a-group).

Chaque outil est classé dans une catégorie d'action en fonction des annotations qu'il déclare. Il n'y a pas de liste à maintenir à jour, donc un outil MCP nouvellement ajouté est automatiquement soumis à la gouvernance :

| L'outil déclare | Catégorie |
|---|---|
| `destructiveHint: true` | Supprimer |
| `readOnlyHint: true` | Lire |
| `readOnlyHint: false` | Écrire |
| Aucune annotation | Supprimer |

Un outil qui déclare à la fois `destructiveHint: true` et `readOnlyHint: true` est classé dans la catégorie Suppression. Les catégories sont résolues dans l'ordre indiqué, de sorte que la déclaration la plus restrictive l'emporte. Les outils disponibles dans l'onglet varient également selon l'édition de GitLab, la licence et les fonctionnalités activées, car ces éléments déterminent quels outils le serveur MCP expose.

De nombreuses fonctionnalités existent à la fois en tant qu'outil de la plateforme GitLab Duo Agent Platform et en tant qu'outil du serveur MCP. Un seul mode gouverne les deux, même lorsque les deux outils ont des noms différents. Par exemple, définir un mode pour `create_merge_request` s'applique également à l'outil du serveur MCP `save_merge_request`. Définissez le mode sur l'outil de la plateforme GitLab Duo Agent Platform. Vous n'avez pas besoin de rechercher et de définir l'outil du serveur MCP séparément.

Si vous ne définissez pas de mode, le comportement reste inchangé. Les outils MCP en lecture seule restent pré-approuvés. Les outils MCP en écriture et en suppression continuent de demander une approbation.

### Invite d'approbation (Toujours demander) {#approval-prompt-always-ask}

Lorsqu'un agent appelle un outil configuré en mode **Toujours demander**, l'exécution est suspendue et une carte d'approbation intégrée s'affiche. La carte affiche les éléments suivants :

- Le nom de l'outil appelé.
- La description de l'action que l'outil va effectuer.
- Les boutons **Approuver** et **Rejeter**.

Si vous approuvez, l'outil s'exécute et l'agent continue. Si vous rejetez l'action, l'outil n'est pas exécuté. L'agent reçoit un signal de rejet et peut tenter une autre approche ou s'arrêter.

### Message de refus (Toujours refuser) {#denial-message-always-deny}

Lorsqu'un agent tente d'appeler un outil configuré en mode **Toujours refuser** pour votre rôle, l'outil n'est pas mis à la disposition de l'agent. Si le plan de l'agent nécessite un outil non autorisé, l'agent reçoit un message d'erreur indiquant que l'outil est indisponible en raison de la politique de gouvernance.

## Résolution et cascade des règles {#rule-resolution-and-cascading}

Les règles sont résolues dans l'ordre suivant, de la plus spécifique à la plus générale :

1. Règle au niveau du projet, si elle est configurée
1. Règle au niveau du groupe, si elle est configurée
1. Valeur de la matrice par défaut

Pour un même outil, les règles au niveau du projet remplacent les règles au niveau du groupe, mais elles doivent être aussi strictes que la règle du groupe, ou plus strictes. Les règles au niveau du groupe remplacent les valeurs par défaut. Si aucune règle n'est configurée à quelque niveau que ce soit, l'outil utilise la valeur par défaut de la matrice de gouvernance.

Le principe de fermeture en cas d'échec s'applique. Si le service de gouvernance rencontre une erreur persistante lors de la résolution des règles, l'agent ne reçoit aucun outil, au lieu que l'exécution soit autorisée tacitement.

## Configurer la gouvernance des outils pour un groupe {#configure-tool-governance-for-a-group}

Les règles au niveau du groupe s'appliquent à tous les projets du groupe, sauf si une règle au niveau du projet les remplace.

Prérequis :

- Disposer du rôle Propriétaire pour le groupe principal.

Pour configurer les règles de gouvernance des outils pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe principal.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la gouvernance**.
1. Pour chaque outil, sélectionnez un mode dans la liste déroulante **Mode** : **Toujours autoriser**, **Toujours demander** ou **Toujours refuser**.
1. Sélectionnez **Enregistrer les modifications**.

Les modifications s'appliquent à tous les sous-groupes et projets, sauf si une règle définie au niveau du projet les remplace.

## Configurer la gouvernance des outils pour un projet {#configure-tool-governance-for-a-project}

Dans ce projet, les règles au niveau du projet remplacent les règles au niveau du groupe pour le même outil.

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.

Pour configurer les règles de gouvernance des outils pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la gouvernance**.
1. Pour chaque outil, sélectionnez un mode dans la liste déroulante : **Toujours autoriser**, **Toujours demander** ou **Toujours refuser**.
1. Sélectionnez **Enregistrer les modifications**.

## Bloquer les serveurs Model Context Protocol (MCP) {#block-model-context-protocol-mcp-servers}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/601159) dans GitLab 19.3 en tant que [version bêta](../../policy/development_stages_support.md) avec un [feature flag](../../administration/feature_flags/_index.md) nommé `mcp_server_block_enforcement`. Fonctionnalité désactivée par défaut.
- Application [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251329) pour GitLab Self-Managed et GitLab Dedicated dans GitLab 19.4, appliquée lors de la construction de la configuration des outils de la session. Activés par défaut.
- Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated dans GitLab 19.4.

{{< /history >}}

> [!warning]
> Cette fonctionnalité est en [version bêta](../../policy/development_stages_support.md). Elle est susceptible d'être modifiée sans préavis. Pour plus d'informations, consultez la page [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

En plus de la [gouvernance par outil](#default-governance-matrix), les propriétaires de groupes peuvent bloquer tous les outils d'un serveur MCP externe spécifique. Lorsqu'un serveur MCP est bloqué, aucun outil de ce serveur ne peut être invoqué, quels que soient les paramètres de gouvernance des outils individuels ou les approbations des utilisateurs.

> [!flag]
> L'application des blocages du serveur MCP est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Si l'application n'est pas activée sur votre instance, le registre MCP affiche toujours le serveur comme bloqué. Le blocage lui-même ne prend pas effet, de sorte que les outils du serveur restent disponibles pour GitLab Duo Agentic Chat.

Le blocage est appliqué lorsque les outils d'une session de chat sont assemblés, ce qui se produit à chaque message utilisateur, approbation d'outil et nouvelle session. En pratique, un blocage prend effet à la prochaine action de l'utilisateur : un appel d'outil en attente d'approbation au moment où le blocage intervient ne s'exécute pas, et à partir du message suivant, les outils du serveur bloqué ne sont plus proposés à l'agent. Un appel d'outil déjà en cours d'exécution se termine normalement.

Comme les outils sont supprimés silencieusement plutôt que refusés, l'agent ne reçoit pas de message de politique. Les agents décrivent les outils manquants dans leurs propres mots, et après qu'un serveur est de nouveau autorisé, un agent dans une conversation existante peut toujours indiquer que le serveur est bloqué sur la base de la conversation précédente. Démarrez une nouvelle conversation ou demandez à l'agent de réessayer avec l'outil.

Le blocage s'applique à GitLab Duo Agentic Chat dans l'interface utilisateur. Les clients IDE et CLI configurent les serveurs MCP via des fichiers de configuration locaux, que ce paramètre ne contrôle pas.

Cela diffère du mode de gouvernance des outils **Toujours refuser** :

- **Toujours refuser** s'applique aux outils individuels et est configuré par projet ou par groupe.
- Le blocage d'un serveur MCP s'applique à tous les outils de ce serveur et est configuré dans le registre MCP. Il remplace toute approbation utilisateur ou paramètre de gouvernance des outils.

### Bloquer un serveur MCP {#block-an-mcp-server}

Vous pouvez bloquer un serveur MCP au niveau du groupe ou du projet :

- **Niveau groupe** : bloque le serveur pour tous les projets du groupe et leurs sous-groupes. Si un serveur est bloqué au niveau du groupe, les paramètres au niveau du projet ne peuvent pas le débloquer.
- **Niveau projet** : bloque le serveur pour ce projet uniquement.

#### Bloquer un serveur MCP pour un groupe {#block-an-mcp-server-for-a-group}

Prérequis :

- Disposer du rôle Propriétaire pour le groupe principal.

Pour bloquer un serveur MCP pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe principal.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la gouvernance**.
1. Sélectionnez l'onglet **Registre MCP**.
1. Trouvez le serveur MCP que vous souhaitez bloquer et sélectionnez **Bloquer**.

Le blocage prend effet à partir du prochain message ou de la prochaine session de chat de chaque utilisateur. Les outils du serveur bloqué sont supprimés pour tous les utilisateurs du groupe, de ses sous-groupes et de ses projets.

#### Bloquer un serveur MCP pour un projet {#block-an-mcp-server-for-a-project}

Prérequis :

- Vous disposez du rôle Propriétaire pour le projet.

Pour bloquer un serveur MCP pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général** > **GitLab Duo**.
1. Sélectionnez **Modifier la gouvernance**.
1. Sélectionnez l'onglet **Registre MCP**.
1. Trouvez le serveur MCP que vous souhaitez bloquer et sélectionnez **Bloquer**.

Le blocage prend effet à partir du prochain message ou de la prochaine session de chat de chaque utilisateur. Les outils du serveur bloqué sont supprimés pour tous les utilisateurs du projet. Si le même serveur est également bloqué sur un groupe ancêtre, l'autoriser au niveau du projet n'a aucun effet tant que le blocage du groupe n'est pas supprimé. Le registre MCP affiche ces serveurs comme bloqués par un ancêtre.

## Problèmes connus {#known-issues}

- L'interface utilisateur de gouvernance comporte trois catégories d'accès : Web (sessions basées sur le navigateur), Local (IDE et CLI) et Runner (flows en arrière-plan qui s'exécutent dans des runners CI/CD). L'accès Runner ne prend en charge que Toujours autoriser et Toujours refuser. Toujours demander ne s'applique pas, car aucun utilisateur n'est présent pour répondre à une invite d'approbation dans un flow en arrière-plan. Un outil sans règle de runner configurée utilise par défaut Toujours autoriser.
- L'outil `search` servi par le serveur GitLab MCP agrège ce que la plateforme GitLab Duo Agent Platform expose sous la forme d'outils de recherche distincts et plus ciblés. Les règles configurées sur ces outils plus ciblés ne s'étendent pas à `search`. Pour restreindre la recherche MCP, configurez une règle directement sur `search`.

## Sujets connexes {#related-topics}

- [Gouvernance de l'IA](_index.md)
- [Tableau de bord de gouvernance de l'IA](governance-dashboard.md)
- [Contrôler la disponibilité de GitLab Duo Agent Platform](../duo_agent_platform/turn_on_off.md)
- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)
- [Événements d'audit](../../administration/compliance/audit_event_reports.md)

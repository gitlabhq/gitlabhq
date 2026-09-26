---
stage: Agent Foundations
group: AI Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Décrit le protocole Model Context Protocol et son utilisation
title: Clients MCP GitLab
---

{{< details >}}

- Édition : [Gratuite](../../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Informations sur le modèle" >}}

- Disponible sur GitLab Duo avec des modèles auto-hébergés, sauf avec GitLab Duo Agentic Chat dans l'interface web GitLab

{{< /collapsible >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/519938) dans GitLab 18.1 [avec le feature flag](../../../administration/feature_flags/_index.md) `duo_workflow_mcp_support`. Fonctionnalité désactivée par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/545956) dans GitLab 18.2. Le feature flag `duo_workflow_mcp_support` a été supprimé.
- [Passage](https://gitlab.com/gitlab-org/gitlab/-/issues/545956) de la version expérimentale à la version bêta dans GitLab 18.3.
- [Disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) dans GitLab 18.8.
- Disponibilité pour l'édition Gratuite sur GitLab.com avec des GitLab Credits dans GitLab 18.10.
- [Introduit](https://gitlab.com/groups/gitlab-org/-/work_items/19716) dans GitLab Duo CLI 8.81.0 lors de la release GitLab 18.11.

{{< /history >}}

Le protocole Model Context Protocol (MCP) offre un moyen standardisé pour les fonctionnalités GitLab Duo de se connecter de manière sécurisée à différentes sources de données externes et à différents outils.

MCP est pris en charge dans les environnements suivants :

- Visual Studio Code (VS Code) et VSCodium
- Les IDE JetBrains
- La ligne de commande, via le GitLab Duo CLI

Le même fichier de configuration MCP fonctionne sur tous les IDE pris en charge et sur le GitLab Duo CLI.

Les fonctionnalités suivantes peuvent agir en tant que clients MCP et se connecter à des outils externes depuis des serveurs MCP :

- [GitLab Duo Agentic Chat](../../gitlab_duo_chat/agentic_chat.md)
- Le [flow Software Development](../../duo_agent_platform/flows/foundational_flows/software_development.md)

Ces fonctionnalités peuvent ensuite accéder à du contexte et à des informations externes pour générer des réponses plus pertinentes.

> [!note]
> Les modèles auto-hébergés ne sont pas disponibles pour MCP avec GitLab Duo Agentic Chat dans l'interface web GitLab. MCP est pris en charge avec des modèles auto-hébergés dans les IDE, le GitLab Duo CLI et les flows.

Pour utiliser une fonctionnalité avec MCP :

1. Activez MCP pour votre groupe.
1. Configurez les serveurs MCP auxquels vous souhaitez que la fonctionnalité se connecte.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une présentation générale, consultez [GitLab Duo Chat (agentic) - MCP tool call approval](https://www.youtube.com/watch?v=_cHoTmG8Yj8).
<!-- Video published on 2025-06-24 -->

Pour une démonstration interactive, consultez [GitLab Duo Agent Platform - MCP client](https://gitlab.navattic.com/mcp).
<!-- Demo published on 2025-08-05 -->

## Prérequis {#prerequisites}

- Satisfaire aux [prérequis pour GitLab Duo Agent Platform](../../duo_agent_platform/_index.md#prerequisites).
- Pour Visual Studio Code (VS Code) ou VSCodium :
  - Installez et configurez [GitLab for VS Code](../../../editor_extensions/visual_studio_code/setup.md) 6.35.6 ou une version ultérieure.
- Pour les IDE JetBrains :
  - Installez et configurez le [plugin GitLab Duo pour les IDE JetBrains](../../../editor_extensions/jetbrains_ide/setup.md) 3.14.0 ou une version ultérieure.
- Pour votre ligne de commande :
  - Remplissez les [prérequis pour le GitLab Duo CLI](../../gitlab_duo_cli/set_up.md#prerequisites).
  - Installez et configurez le [GitLab Duo CLI](../../gitlab_duo_cli/set_up.md) 8.81.0 ou une version ultérieure.

Pour plus d'informations sur la prise en charge des extensions, consultez la section [compatibilité des versions](#version-compatibility).

## Autoriser les outils MCP externes {#allow-external-mcp-tools}

Autorisez l'IDE à accéder aux outils MCP externes dans le groupe principal où GitLab Duo est configuré.

> [!note]
> Les propriétaires de groupes et de projets peuvent également bloquer tous les outils d'un serveur MCP spécifique à l'aide du registre MCP. Un serveur bloqué ne peut pas être débloqué par des utilisateurs individuels, quels que soient les paramètres d'approbation des outils. Pour plus d'informations, consultez [Bloquer des serveurs MCP](../../ai-governance/tool-governance.md#block-model-context-protocol-mcp-servers). Sur GitLab Self-Managed, un administrateur doit également activer le `mcp_client` [feature flag](../../../administration/feature_flags/_index.md) pour que les agents personnalisés et les flows puissent utiliser des outils MCP externes.

### Sur GitLab.com {#on-gitlabcom}

Pour autoriser votre environnement local à accéder aux outils MCP externes sur GitLab.com :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Modifier la configuration**.
1. Sous **Outils MCP externes**, cochez la case **Autoriser les outils MCP externes**.
1. Sélectionnez **Enregistrer les modifications**.

### Sur GitLab Self-Managed {#on-gitlab-self-managed}

Pour autoriser votre environnement local à accéder aux outils MCP externes sur GitLab Self-Managed :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Fonctionnalités de GitLab Duo**.
1. Sous **Outils MCP externes**, cochez la case **Autoriser les outils MCP externes**.
1. Sélectionnez **Enregistrer les modifications**.

## Configurer les serveurs MCP {#configure-mcp-servers}

Pour intégrer MCP au serveur de langage, configurez la configuration workspace, la configuration utilisateur, ou les deux. Le serveur de langage GitLab charge et fusionne les fichiers de configuration.

> [!note]
> La configuration workspace s'applique à votre dossier de workspace IDE ou au répertoire de travail actuel lorsque vous utilisez le GitLab Duo CLI. Celle-ci est distincte des [GitLab Workspaces](../../workspace/_index.md), qui sont des environnements de développement virtuels.

### Compatibilité des versions {#version-compatibility}

| Prise en charge MCP | GitLab for VS Code | Plugin GitLab Duo <br>pour les IDE JetBrains | GitLab Duo CLI |
|------------------------|-----------------------------------|------------------------|------------------------|
| Basique (sans configuration workspace ni utilisateur) | 6.28.2 ou version ultérieure | 3.10.0 ou version ultérieure |  |
| Complète (avec configuration workspace et utilisateur) | 6.35.6 ou version ultérieure | 3.14.0 ou version ultérieure | 8.81.0 ou version ultérieure |

### Créer une configuration workspace {#create-workspace-configuration}

La configuration workspace s'applique à votre dossier de workspace IDE ou au répertoire de travail actuel, et remplace toute configuration utilisateur pour le même serveur.

Pour configurer la configuration workspace :

1. Dans votre dossier de workspace IDE ou votre répertoire de travail actuel, créez le fichier `.gitlab/duo/mcp.json`.
1. En utilisant le [format de configuration](#configuration-format), ajoutez des informations sur les serveurs MCP auxquels votre fonctionnalité se connecte.
1. Enregistrez le fichier.
1. Redémarrez votre IDE ou le GitLab Duo CLI.

### Créer une configuration utilisateur {#create-user-configuration}

Les paramètres de configuration utilisateur sont adaptés aux outils personnels et aux serveurs couramment utilisés. Ils s'appliquent à toutes les configurations workspace, mais une configuration workspace pour le même serveur est prioritaire.

Pour configurer la configuration utilisateur :

1. Créez un fichier de configuration :

   {{< tabs >}}

   {{< tab title="VS Code ou VSCodium" >}}

   1. Dans votre IDE, ouvrez la palette de commandes :
      - Pour macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
      - Pour Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   1. Exécutez la commande `GitLab MCP: Open User Settings (JSON)`.

   {{< /tab >}}

   {{< tab title="JetBrains IDEs" >}}

   - Créez un fichier `mcp.json` dans votre répertoire personnel :
     - Pour Linux ou macOS, à l'emplacement `~/.gitlab/duo/mcp.json`.
     - Pour Windows, à l'emplacement `%APPDATA%\GitLab\duo\mcp.json`.

       Par exemple, `C:\Users\<username>\AppData\Roaming\GitLab\duo\mcp.json`.

   Si vous avez défini l'une des variables d'environnement suivantes, créez le fichier à un emplacement différent :

   - Pour `GLAB_CONFIG_DIR`, à l'emplacement `$GLAB_CONFIG_DIR/duo/mcp.json`.
   - Pour `XDG_CONFIG_HOME`, à l'emplacement `$XDG_CONFIG_HOME/gitlab/duo/mcp.json`.

   {{< /tab >}}

   {{< tab title="GitLab Duo CLI" >}}

   - Créez un fichier `mcp.json` dans votre répertoire personnel :
     - Pour Linux ou macOS, à l'emplacement `~/.gitlab/duo/mcp.json`.
     - Pour Windows, à l'emplacement `%APPDATA%\GitLab\duo\mcp.json`.

       Par exemple, `C:\Users\<username>\AppData\Roaming\GitLab\duo\mcp.json`.

   Si vous avez défini l'une des variables d'environnement suivantes, créez le fichier à un emplacement différent :

   - Pour `GLAB_CONFIG_DIR`, à l'emplacement `$GLAB_CONFIG_DIR/duo/mcp.json`.
   - Pour `XDG_CONFIG_HOME`, à l'emplacement `$XDG_CONFIG_HOME/gitlab/duo/mcp.json`.

   {{< /tab >}} {{< /tabs >}}

1. En utilisant le [format de configuration](#configuration-format), ajoutez des informations sur les serveurs MCP auxquels votre fonctionnalité se connecte.
1. Enregistrez le fichier.
1. Redémarrez votre IDE ou le GitLab Duo CLI.

### Format de configuration {#configuration-format}

Les deux fichiers de configuration utilisent le même format JSON, avec les détails dans la clé `mcpServers` :

```json
{
  "mcpServers": {
    "server-name": {
      "type": "stdio",
      "command": "path/to/server",
      "args": ["--arg1", "value1"],
      "env": {
        "ENV_VAR": "value"
      },
      "approvedTools": true
    },
    "http-server": {
      "type": "http",
      "url": "http://localhost:3000/mcp",
      "approvedTools": ["read_file", "search"]
    },
    "sse-server": {
      "type": "sse",
      "url": "http://localhost:3000/mcp/sse"
    }
  }
}
```

> [!note]
> Pour les autres clients MCP, la documentation Atlassian utilise `mcp.servers` dans l'exemple de fichier de configuration. Pour GitLab, utilisez plutôt `mcpServers`.

### Configurer l'approbation des outils {#configure-tool-approval}

Par défaut, vous devez approuver manuellement chaque outil MCP de votre serveur lors de chaque session.

Vous pouvez également pré-approuver les outils MCP dans votre fichier de configuration pour ne pas avoir à approuver manuellement chaque invite.

Pour ce faire, ajoutez le champ `approvedTools` à n'importe quelle configuration de serveur :

- `"approvedTools": true` - Approuve automatiquement tous les outils actuels et futurs de ce serveur.
- `"approvedTools": ["tool1", "tool2"]` - Approuve uniquement les outils que vous avez spécifiés.

Si vous n'incluez pas ce champ, vous devez approuver manuellement chaque outil lors de la session (il s'agit du comportement par défaut).

> [!warning]
> Utilisez `"approvedTools": true` uniquement pour les serveurs auxquels vous faites entièrement confiance.

Par exemple :

```json
{
  "mcpServers": {
    "trusted-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["my-trusted-mcp-server"],
      "approvedTools": true
    },
    "selective-server": {
      "type": "http",
      "url": "http://localhost:3000/mcp",
      "approvedTools": ["read_file", "search"]
    },
    "untrusted-server": {
      "type": "sse",
      "url": "http://example.com/mcp/sse"
    }
  }
}
```

#### Fonctionnement de l'approbation des outils {#how-tool-approval-works}

GitLab utilise un système d'approbation à deux niveaux pour les outils MCP :

- Approbation basée sur la configuration (permanente) : outils approuvés dans `mcp.json` à l'aide du champ `approvedTools`. Ces approbations persistent dans toutes les sessions.
- Approbation basée sur la session (temporaire) : outils approuvés pendant l'exécution pour la session de workflow en cours. Ces approbations sont effacées lorsque vous fermez votre IDE ou terminez le workflow.

Un outil est approuvé si l'une ou l'autre des conditions est remplie.

### Exemples de configurations de serveurs MCP {#example-mcp-server-configurations}

Utilisez les exemples de code suivants pour créer votre fichier de configuration de serveur MCP.

Pour plus d'informations et des exemples, consultez la [documentation des exemples de serveurs MCP](https://modelcontextprotocol.io/examples). D'autres exemples de serveurs sont [Smithery.ai](https://smithery.ai/) et [Awesome MCP Servers](https://mcpservers.org/).

#### Serveur local {#local-server}

```json
{
  "mcpServers": {
    "enterprise-data-v2": {
      "type": "stdio",
      "command": "node",
      "args": ["src/server.js"],
      "cwd": "</path/to/your-mcp-server>",
      "approvedTools": ["query_database", "fetch_metrics"]
    }
  }
}
```

#### Serveur GitLab Knowledge Graph {#gitlab-knowledge-graph-server}

Le [graphe de connaissances GitLab](https://gitlab-org.gitlab.io/rust/knowledge-graph/) fournit de l'intelligence de code via MCP. Vous pouvez approuver tous les outils ou des outils spécifiques :

```json
{
  "mcpServers": {
    "knowledge-graph": {
      "type": "sse",
      "url": "http://localhost:27495/mcp/sse",
      "approvedTools": true
    }
  }
}
```

Ou approuver uniquement des outils spécifiques :

```json
{
  "mcpServers": {
    "knowledge-graph": {
      "type": "sse",
      "url": "http://localhost:27495/mcp/sse",
      "approvedTools": ["list_projects", "search_codebase_definitions", "get_references", "get_definition"]
    }
  }
}
```

Pour plus d'informations sur les outils disponibles, consultez la [documentation des outils MCP du graphe de connaissances](https://gitlab-org.gitlab.io/rust/knowledge-graph/mcp/tools/).

#### Serveur HTTP {#http-server}

```json
{
  "mcpServers": {
    "local-http-server": {
      "type": "http",
      "url": "http://localhost:3000/mcp",
      "approvedTools": ["read_file", "write_file"]
    }
  }
}
```

## Afficher le statut des serveurs MCP {#view-the-status-of-mcp-servers}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/work_items/2155) dans l'extension GitLab for VS Code 6.55.0.

{{< /history >}}

Prérequis :

- Extension GitLab for VS Code 6.55.0 ou une version ultérieure.
- Au moins un serveur MCP configuré dans votre configuration utilisateur ou workspace.

Pour afficher le statut de vos serveurs MCP configurés :

1. Dans VS Code ou VSCodium, ouvrez la palette de commandes :
   - Sous macOS, appuyez sur <kbd>Commande</kbd>+<kbd>Maj</kbd>+<kbd>P</kbd>.
   - Sous Windows ou Linux, appuyez sur <kbd>Ctrl</kbd>+<kbd>Maj</kbd>+<kbd>P</kbd>.
1. Saisissez `GitLab: Show MCP Dashboard` et appuyez sur <kbd>Entrée</kbd>.

Le tableau de bord MCP s'ouvre dans un nouvel onglet de l'éditeur. Utilisez le tableau de bord pour :

- Vérifier que vos serveurs MCP sont correctement configurés et en cours d'exécution.
- Identifier les problèmes de connexion avant d'utiliser les fonctionnalités GitLab Duo.
- Afficher les outils disponibles sur chaque serveur.
- Résoudre les problèmes de configuration du serveur.

### Ouvrir les fichiers de configuration MCP {#open-mcp-configuration-files}

Pour ouvrir vos fichiers de configuration MCP :

1. Dans VS Code ou VSCodium, ouvrez la palette de commandes :
   - Sous macOS, appuyez sur <kbd>Commande</kbd>+<kbd>Maj</kbd>+<kbd>P</kbd>.
   - Sous Windows ou Linux, appuyez sur <kbd>Ctrl</kbd>+<kbd>Maj</kbd>+<kbd>P</kbd>.
1. Ouvrez les fichiers de configuration :
   - Pour la configuration utilisateur, saisissez `GitLab MCP: Open User Settings (JSON)` et appuyez sur <kbd>Enter</kbd>.
   - Pour la configuration workspace, saisissez `GitLab MCP: Open Workspace Settings (JSON)` et appuyez sur <kbd>Enter</kbd>.

## Se ré-authentifier auprès des serveurs MCP {#re-authenticate-with-mcp-servers}

Après avoir mis à jour les informations d'authentification dans un fichier de configuration MCP, vous devez vous ré-authentifier auprès du serveur MCP concerné.

Pour déclencher la ré-authentification :

- Posez à GitLab Duo une question qui nécessite des données provenant de ce serveur MCP (par exemple, `What are the issues in my Jira project?` pour Atlassian). Le flux d'authentification démarre automatiquement.

## Utiliser les fonctionnalités GitLab Duo avec MCP {#use-gitlab-duo-features-with-mcp}

{{< history >}}

- L'approbation des outils externes pour toute la session [ajoutée](https://gitlab.com/gitlab-org/gitlab/-/issues/556045) dans GitLab 18.4.

{{< /history >}}

Lorsqu'une fonctionnalité GitLab Duo appelle un outil externe pour répondre à une question, vous devez examiner cet outil, sauf si vous l'avez approuvé pour toute la session :

1. Ouvrez VS Code.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}).
1. Sélectionnez l'onglet **Chat** ou **Flux**.
1. Dans la zone de texte, saisissez une question ou spécifiez une tâche de code.
1. Soumettez la question ou la tâche de code.
1. La boîte de dialogue **Autorisation d'utilisation d'outil requise** s'affiche dans les cas suivants :

   - GitLab Duo appelle cet outil pour la première fois lors de votre session.
   - Vous n'avez pas approuvé cet outil pour toute la session.

1. Approuvez ou refusez l'outil :

   - Si vous approuvez l'outil, la fonctionnalité se connecte à l'outil et génère une réponse.
     - Facultatif. Pour approuver l'outil pour toute la session, dans la liste déroulante **Approuver**, sélectionnez **Approuver pour la session**.

       Vous pouvez approuver uniquement les outils fournis par le serveur MCP pour la session. Vous ne pouvez pas approuver les commandes de terminal ou CLI.

   - Pour Chat, si vous refusez l'outil, la boîte de dialogue **Indiquer un motif du refus** s'affiche. Saisissez un motif de refus, puis sélectionnez **Envoyer le refus**.

     Chat peut prendre des mesures en fonction du motif que vous indiquez, par exemple suggérer une nouvelle approche ou créer un ticket.

## Dépannage {#troubleshooting}

### Supprimer le cache d'authentification MCP {#delete-the-mcp-authentication-cache}

GitLab met en cache l'authentification MCP localement sous `~/.mcp-auth/`. Pour éviter les faux positifs lors du dépannage, supprimez le répertoire de cache :

```shell
rm -rf ~/.mcp-auth/
```

### `Error starting server filesystem: Error: spawn ... ENOENT` {#error-starting-server-filesystem-error-spawn--enoent}

Cette erreur se produit lorsque vous spécifiez une commande à l'aide d'un chemin relatif (comme `node` au lieu de `/usr/bin/node`), et que cette commande est introuvable dans la variable d'environnement `PATH` transmise au serveur de langage GitLab.

Les améliorations concernant la résolution de `PATH` sont suivies dans le [ticket 1345](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1345).

### Dépannage de MCP dans VS Code {#troubleshooting-mcp-in-vs-code}

Pour plus d'informations sur le dépannage, consultez [Dépannage de l'extension GitLab for VS Code](../../../editor_extensions/visual_studio_code/troubleshooting.md).

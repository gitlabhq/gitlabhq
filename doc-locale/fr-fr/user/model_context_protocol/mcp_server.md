---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Connectez des outils d'IA à votre instance GitLab avec le serveur MCP GitLab."
title: Serveur MCP GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version bêta

{{< /details >}}

{{< history >}}

- Introduit en tant que [version expérimentale](../../policy/development_stages_support.md#experiment) dans GitLab 18.3 [avec des feature flags](../../administration/feature_flags/_index.md) nommés `mcp_server` et `oauth_dynamic_client_registration`. Désactivé par défaut.
- Passage de la version expérimentale à la [version bêta](../../policy/development_stages_support.md#beta) dans GitLab 18.6. Feature flags [`mcp_server`](https://gitlab.com/gitlab-org/gitlab/-/issues/556448) et [`oauth_dynamic_client_registration`](https://gitlab.com/gitlab-org/gitlab/-/issues/555942) supprimés.
- Prise en charge des spécifications du protocole MCP `2025-03-26` et `2025-06-18` [ajoutée](https://gitlab.com/gitlab-org/gitlab/-/issues/581459) dans GitLab 18.7.
- [Passage](https://gitlab.com/gitlab-org/gitlab/-/work_items/590729) à un paramètre distinct et [déplacement](https://gitlab.com/groups/gitlab-org/-/work_items/21183) de GitLab Premium vers GitLab Free dans GitLab 19.2.

{{< /history >}}

> [!warning]
> Pour donner votre avis sur cette fonctionnalité, laissez un commentaire dans le [ticket 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564).

Avec le serveur [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) de GitLab, vous pouvez connecter de manière sécurisée des outils et des applications d'IA à votre instance GitLab. Les assistants IA tels que Claude Desktop, Claude Code, Cursor et d'autres outils compatibles MCP peuvent alors accéder à vos données GitLab et effectuer des actions en votre nom.

Le serveur MCP GitLab offre aux outils d'IA un moyen standardisé de :

- Accéder aux informations des projets GitLab.
- Récupérer les données des tickets et des merge requests.
- Interagir en toute sécurité avec les API GitLab.
- Effectuer des opérations propres à GitLab via des assistants IA.

Le serveur MCP GitLab prend en charge [l'enregistrement dynamique de clients OAuth 2.0](https://tools.ietf.org/html/rfc7591), ce qui permet aux outils d'IA de s'enregistrer auprès de votre instance GitLab. Lorsqu'un outil d'IA se connecte pour la première fois à votre serveur MCP GitLab, il :

1. S'enregistre lui-même en tant qu'application OAuth.
1. Demande l'autorisation d'accéder à vos données GitLab.
1. Reçoit un jeton d'accès pour un accès sécurisé à l'API.

Pour une démonstration interactive, consultez [GitLab Duo Agent Platform - GitLab MCP server](https://gitlab.navattic.com/gitlab-mcp-server).
<!-- Demo published on 2025-09-11 -->

## Prérequis {#prerequisites}

- Définissez la disponibilité de GitLab Duo sur **Toujours activé** ou **Activé(e) par défaut** :
  - Sur GitLab.com, [pour le groupe principal](../gitlab_duo/turn_on_off.md#for-a-top-level-group).
  - Sur GitLab Self-Managed et GitLab Dedicated, [pour l'instance](../gitlab_duo/turn_on_off.md#for-an-instance).
- Activez les fonctionnalités bêta et expérimentales :
  - Sur GitLab.com, [pour le groupe principal](../gitlab_duo/turn_on_off.md#on-gitlabcom-2).
  - Sur GitLab Self-Managed et GitLab Dedicated, [pour l'instance](../gitlab_duo/turn_on_off.md#on-gitlab-self-managed-2).
- Autorisez l'accès au serveur MCP :
  - Sur GitLab.com, [pour le groupe principal](../group/access_and_permissions.md#allow-access-to-the-mcp-server).
  - Sur GitLab Self-Managed et GitLab Dedicated, [pour l'instance](../../administration/settings/visibility_and_access_controls.md#allow-access-to-the-mcp-server).

## Connecter un client au serveur MCP GitLab {#connect-a-client-to-the-gitlab-mcp-server}

Le serveur MCP GitLab prend en charge deux types de transport :

- **Transport HTTP (recommandé)** : connexion directe sans dépendances supplémentaires.
- **Transport stdio avec `mcp-remote`** : connexion via un proxy (nécessite Node.js).

Les outils d'IA courants prennent en charge le format de configuration JSON pour la clé `mcpServers` et proposent différentes méthodes pour configurer les paramètres du serveur MCP GitLab.

### Transport HTTP (recommandé) {#http-transport-recommended}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/577575) dans GitLab 18.6.
- Préfixage des outils [ajouté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230406) dans GitLab 18.11.

{{< /history >}}

Pour configurer le serveur MCP GitLab en utilisant le transport HTTP, utilisez ce format :

- Remplacez `<gitlab.example.com>` par :
  - Sur GitLab Self-Managed, l'URL de votre instance GitLab.
  - Sur GitLab.com, `gitlab.com`.

```json
{
  "mcpServers": {
    "GitLab": {
      "type": "http",
      "url": "https://<gitlab.example.com>/api/v4/mcp"
    }
  }
}
```

Vous pouvez ajouter un préfixe aux noms des outils en configurant un en-tête HTTP `X-Gitlab-Mcp-Server-Tool-Name-Prefix`. Le préfixage peut vous aider à éviter les conflits de noms d'outils avec d'autres serveurs MCP ou avec plusieurs instances GitLab dans votre configuration.

Le préfixe est tronqué aux 32 premiers caractères s'il dépasse cette limite.

```json
{
  "mcpServers": {
    "GitLab": {
      "type": "http",
      "url": "https://<gitlab.example.com>/api/v4/mcp",
      "headers": {
        "X-Gitlab-Mcp-Server-Tool-Name-Prefix": "gitlab_"
      }
    }
  }
}
```

### Transport stdio avec `mcp-remote` {#stdio-transport-with-mcp-remote}

Prérequis :

- Installez Node.js version 20 ou ultérieure.

Pour configurer le serveur MCP GitLab en utilisant le transport stdio, utilisez ce format :

- Pour le paramètre `"command":`, si `npx` est installé localement plutôt que globalement, indiquez le chemin complet vers `npx`.
- Remplacez `<gitlab.example.com>` par :
  - Sur GitLab Self-Managed, l'URL de votre instance GitLab.
  - Sur GitLab.com, `gitlab.com`.

```json
{
  "mcpServers": {
    "GitLab": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://<gitlab.example.com>/api/v4/mcp"
      ]
    }
  }
}
```

## Connecter Cursor au serveur MCP GitLab {#connect-cursor-to-the-gitlab-mcp-server}

Cursor utilise le transport HTTP pour une connexion directe sans dépendances supplémentaires. Pour configurer le serveur MCP GitLab dans Cursor :

1. Dans Cursor, accédez à **Settings** > **Cursor Settings** > **Tools & MCP**.
1. Sous **Installed MCP Servers**, sélectionnez **New MCP Server**.
1. Ajoutez cette définition à la clé `mcpServers` dans le fichier `mcp.json` ouvert :
   - Remplacez `<gitlab.example.com>` par :
     - Sur GitLab Self-Managed, l'URL de votre instance GitLab.
     - Sur GitLab.com, `gitlab.com`.

   ```json
   {
     "mcpServers": {
       "GitLab": {
          "type": "http",
          "url": "https://<gitlab.example.com>/api/v4/mcp"
       }
     }
   }
   ```

1. Enregistrez le fichier et attendez que votre navigateur ouvre la page d'autorisation OAuth.

   Si cela ne se produit pas, fermez et redémarrez Cursor.
1. Dans votre navigateur, vérifiez et approuvez la demande d'autorisation.

Vous pouvez maintenant démarrer une nouvelle conversation et poser une question en fonction des [outils disponibles](mcp_server_tools.md).

> [!warning]
> Vous êtes responsable de la protection contre l'injection de prompt lorsque vous utilisez ces outils. Faites preuve d'une extrême prudence ou utilisez les outils MCP uniquement sur des objets GitLab auxquels vous faites confiance.

## Connecter Claude Code au serveur MCP GitLab {#connect-claude-code-to-the-gitlab-mcp-server}

Claude Code utilise le transport HTTP pour une connexion directe sans dépendances supplémentaires. Pour configurer le serveur MCP GitLab dans Claude Code :

1. Dans votre terminal, ajoutez le serveur MCP GitLab avec la CLI :
   - Remplacez `<gitlab.example.com>` par :
     - Sur GitLab Self-Managed, l'URL de votre instance GitLab.
     - Sur GitLab.com, `gitlab.com`.

   ```shell
   claude mcp add --transport http GitLab https://<gitlab.example.com>/api/v4/mcp
   ```

1. Démarrez Claude Code :

   ```shell
   claude
   ```

1. Authentifiez-vous auprès du serveur MCP GitLab :
   - Dans le chat, saisissez `/mcp`.
   - Dans la liste, sélectionnez votre serveur GitLab.
   - Dans votre navigateur, vérifiez et approuvez la demande d'autorisation.

1. Facultatif. Pour vérifier la connexion, saisissez à nouveau `/mcp`. Votre serveur GitLab devrait apparaître comme connecté.

Vous pouvez maintenant démarrer une nouvelle conversation et poser une question en fonction des [outils disponibles](mcp_server_tools.md).

> [!warning]
> Vous êtes responsable de la protection contre l'injection de prompt lorsque vous utilisez ces outils. Faites preuve d'une extrême prudence ou utilisez les outils MCP uniquement sur des objets GitLab auxquels vous faites confiance.

## Connecter Claude Desktop au serveur MCP GitLab {#connect-claude-desktop-to-the-gitlab-mcp-server}

Prérequis :

- Installez Node.js version 20 ou ultérieure.
- Rendez Node.js disponible globalement dans la variable d'environnement `PATH` (`which -a node`).

Pour configurer le serveur MCP GitLab dans Claude Desktop :

1. Ouvrez Claude Desktop.
1. Modifiez le fichier de configuration. Vous pouvez effectuer l'une des opérations suivantes :
   - Dans Claude Desktop, accédez à **Paramètres** > **Développeur** > **Modifier la configuration**.
   - Sur macOS, ouvrez le fichier `~/Library/Application Support/Claude/claude_desktop_config.json`.
1. Ajoutez cette entrée pour le serveur MCP GitLab, en la modifiant selon vos besoins :
   - Pour le paramètre `"command":`, si `npx` est installé localement plutôt que globalement, indiquez le chemin complet vers `npx`.
   - Remplacez `<gitlab.example.com>` par :
     - Sur GitLab Self-Managed, l'URL de votre instance GitLab.
     - Sur GitLab.com, `GitLab.com`.

   ```json
   {
     "mcpServers": {
       "GitLab": {
         "command": "npx",
         "args": [
           "-y",
           "mcp-remote",
           "https://<gitlab.example.com>/api/v4/mcp"
         ]
       }
     }
   }
   ```

1. Enregistrez la configuration et redémarrez Claude Desktop.
1. Lors de la première connexion, Claude Desktop ouvre une fenêtre de navigateur pour OAuth. Vérifiez et approuvez la demande.
1. Accédez à **Paramètres** > **Développeur** et vérifiez la nouvelle configuration MCP GitLab.
1. Accédez à **Paramètres** > **Connecteurs** et inspectez le serveur MCP GitLab connecté.

Vous pouvez maintenant démarrer une nouvelle conversation et poser une question en fonction des [outils disponibles](mcp_server_tools.md).

> [!warning]
> Vous êtes responsable de la protection contre l'injection de prompt lorsque vous utilisez ces outils. Faites preuve d'une extrême prudence ou utilisez les outils MCP uniquement sur des objets GitLab auxquels vous faites confiance.

## Connecter Gemini Code Assist et Gemini CLI au serveur MCP GitLab {#connect-gemini-code-assist-and-gemini-cli-to-the-gitlab-mcp-server}

Gemini Code Assist et Gemini CLI utilisent le transport HTTP pour une connexion directe sans dépendances supplémentaires. Pour configurer le serveur MCP GitLab dans Gemini Code Assist ou Gemini CLI :

1. Modifiez `~/.gemini/settings.json` et ajoutez le serveur MCP GitLab.
   - Remplacez `<gitlab.example.com>` par :
     - Sur GitLab Self-Managed, l'URL de votre instance GitLab.
     - Sur GitLab.com, `gitlab.com`.

   ```json
   {
     "mcpServers": {
       "GitLab": {
         "httpUrl": "https://<gitlab.example.com>/api/v4/mcp"
       }
     }
   }
   ```

1. Dans Gemini Code Assist ou Gemini CLI, exécutez la commande `/mcp auth GitLab`.

   La page d'autorisation OAuth devrait s'afficher. Sinon, redémarrez Gemini Code Assist ou Gemini CLI.

1. Dans votre navigateur, vérifiez et approuvez la demande d'autorisation.

Vous pouvez maintenant démarrer une nouvelle conversation et poser une question en fonction des [outils disponibles](mcp_server_tools.md).

> [!warning]
> Vous êtes responsable de la protection contre l'injection de prompt lorsque vous utilisez ces outils. Faites preuve d'une extrême prudence ou utilisez les outils MCP uniquement sur des objets GitLab auxquels vous faites confiance.

## Connecter GitHub Copilot dans VS Code au serveur MCP GitLab {#connect-github-copilot-in-vs-code-to-the-gitlab-mcp-server}

GitHub Copilot utilise le transport HTTP pour une connexion directe sans dépendances supplémentaires. Pour configurer le serveur MCP GitLab dans GitHub Copilot dans VS Code :

1. Dans VS Code, ouvrez la palette de commandes :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Saisissez `MCP: Add Server` et appuyez sur <kbd>Enter</kbd>.
1. Pour le type de serveur, sélectionnez **HTTP**.
1. Pour l'URL du serveur, saisissez `https://<gitlab.example.com>/api/v4/mcp`.
   - Remplacez `<gitlab.example.com>` par :
     - Sur GitLab Self-Managed, l'URL de votre instance GitLab.
     - Sur GitLab.com, `gitlab.com`.
1. Pour l'identifiant du serveur, saisissez `GitLab`.
1. Enregistrez la configuration globalement ou dans le workspace `vscode/mcp.json`.

   La page d'autorisation OAuth devrait s'afficher. Sinon, ouvrez la palette de commandes et recherchez **MCP : List Servers** pour vérifier le statut ou redémarrer le serveur.

1. Dans votre navigateur, vérifiez et approuvez la demande d'autorisation.

Vous pouvez maintenant démarrer une nouvelle conversation et poser une question en fonction des [outils disponibles](mcp_server_tools.md).

> [!warning]
> Vous êtes responsable de la protection contre l'injection de prompt lorsque vous utilisez ces outils. Faites preuve d'une extrême prudence ou utilisez les outils MCP uniquement sur des objets GitLab auxquels vous faites confiance.

## Connecter Kiro IDE et CLI au serveur MCP GitLab {#connect-kiro-ide-and-cli-to-the-gitlab-mcp-server}

Kiro IDE et CLI utilisent le transport HTTP pour une connexion directe sans dépendances supplémentaires. Pour configurer le serveur MCP GitLab dans Kiro IDE ou CLI :

1. Modifiez `~/.kiro/settings/mcp.json` et ajoutez le serveur MCP GitLab.
   - Remplacez `<gitlab.example.com>` par :
     - Sur GitLab Self-Managed, l'URL de votre instance GitLab.
     - Sur GitLab.com, `gitlab.com`.

   ```json
   {
     "mcpServers": {
       "GitLab": {
         "type": "http",
         "url": "https://<gitlab.example.com>/api/v4/mcp"
       }
     }
   }
   ```

1. Enregistrez la configuration.

   La page d'autorisation OAuth devrait s'afficher. Sinon, ouvrez Kiro CLI et exécutez la commande `/mcp`.

1. Dans votre navigateur, vérifiez et approuvez la demande d'autorisation.

Vous pouvez maintenant démarrer une nouvelle conversation et poser une question en fonction des [outils disponibles](mcp_server_tools.md).

> [!warning]
> Vous êtes responsable de la protection contre l'injection de prompt lorsque vous utilisez ces outils. Faites preuve d'une extrême prudence ou utilisez les outils MCP uniquement sur des objets GitLab auxquels vous faites confiance.

## Connecter OpenAI Codex au serveur MCP GitLab {#connect-openai-codex-to-the-gitlab-mcp-server}

OpenAI Codex utilise le transport HTTP pour une connexion directe sans dépendances supplémentaires. Pour configurer le serveur MCP GitLab dans OpenAI Codex :

1. Dans votre terminal, ajoutez le serveur MCP GitLab avec la CLI :
   - Remplacez `<gitlab.example.com>` par :
     - Sur GitLab Self-Managed, l'URL de votre instance GitLab.
     - Sur GitLab.com, `gitlab.com`.

   ```shell
   codex mcp add GitLab --url "https://<gitlab.example.com>/api/v4/mcp"
   ```

1. Modifiez `~/.codex/config.toml` et, dans la section `[features]`, activez le feature flag `rmcp_client`.

   ```toml
   [features]
   "rmcp_client" = true

   [mcp_servers.GitLab]
   url = "https://<gitlab.example.com>/api/v4/mcp"
   ```

1. Exécutez le flux de connexion et authentifiez-vous auprès de l'instance GitLab.

   ```shell
   codex mcp login GitLab
   ```

1. Dans votre navigateur, vérifiez et approuvez la demande d'autorisation.

Vous pouvez maintenant démarrer une nouvelle conversation et poser une question en fonction des [outils disponibles](mcp_server_tools.md).

> [!warning]
> Vous êtes responsable de la protection contre l'injection de prompt lorsque vous utilisez ces outils. Faites preuve d'une extrême prudence ou utilisez les outils MCP uniquement sur des objets GitLab auxquels vous faites confiance.

## Connecter Zed au serveur MCP GitLab {#connect-zed-to-the-gitlab-mcp-server}

Prérequis :

- Installez Node.js version 20 ou ultérieure.
- Rendez Node.js disponible globalement dans la variable d'environnement `PATH` (`which -a node`).

Pour configurer le serveur MCP GitLab dans Zed :

1. Dans Zed, ouvrez la palette de commandes :
   - Sur macOS, appuyez sur <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - Sur Windows ou Linux, appuyez sur <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Saisissez `agent: open settings` et appuyez sur <kbd>Enter</kbd>.
1. Dans la section **Model Context Protocol (MCP) Servers**, sélectionnez **Add Server**.
1. Pour l'URL du serveur dans `args`, utilisez `https://<gitlab.example.com>/api/v4/mcp`.
   - Remplacez `<gitlab.example.com>` par :
     - Sur GitLab Self-Managed, l'URL de votre instance GitLab.
     - Sur GitLab.com, `gitlab.com`.

   ```json
   {
     /// The name of your MCP server
     "GitLab": {
       /// The command which runs the MCP server
       "command": "npx",
       /// The arguments to pass to the MCP server
       "args": ["-y","mcp-remote@latest","https://<gitlab.example.com>/api/v4/mcp"],
       /// The environment variables to set
       "env": {}
     }
   }
   ```

1. Enregistrez la configuration.

   La page d'autorisation OAuth devrait s'afficher. Sinon, désactivez puis réactivez le bouton **GitLab**.

1. Dans votre navigateur, vérifiez et approuvez la demande d'autorisation.

Vous pouvez maintenant démarrer une nouvelle conversation et poser une question en fonction des [outils disponibles](mcp_server_tools.md).

> [!warning]
> Vous êtes responsable de la protection contre l'injection de prompt lorsque vous utilisez ces outils. Faites preuve d'une extrême prudence ou utilisez les outils MCP uniquement sur des objets GitLab auxquels vous faites confiance.

## Réutiliser une application OAuth unique {#reuse-a-single-oauth-application}

{{< history >}}

- Création d'application OAuth via l'interface d'administration [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245979) dans GitLab 19.3.
- Création d'application OAuth via l'interface de groupe et d'utilisateur [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247698) dans GitLab 19.3.

{{< /history >}}

Lorsqu'un client MCP se connecte au serveur MCP GitLab, il utilise l'enregistrement dynamique de clients OAuth 2.0 (DCR) pour créer une nouvelle application OAuth sur votre instance GitLab.

Réutilisez une application OAuth pré-enregistrée pour éviter les problèmes suivants avec le DCR :

- Sur GitLab Self-Managed et GitLab Dedicated, un grand nombre d'utilisateurs, ou des clients qui se connectent répétitivement, peuvent créer un nombre élevé d'applications OAuth sur l'instance.
- Les adresses IP appliquent une limite de débit aux requêtes DCR à hauteur de 10 enregistrements par heure. Les utilisateurs qui partagent une adresse IP de sortie, comme un réseau d'entreprise ou un VPN, peuvent dépasser cette limite et ne pas parvenir à s'authentifier auprès du serveur MCP.

Chaque utilisateur s'autorise toujours via OAuth et reçoit son propre jeton d'accès. Une application partagée correspond à l'identité du client OAuth, et non à un identifiant partagé.

Créez l'application OAuth pour l'une des portées suivantes, selon qui la réutilise :

- Instance : partagée par tous les utilisateurs de l'instance.
- Groupe : partagée par les membres d'un groupe.
- Utilisateur : pour le compte propre d'un utilisateur.

Prérequis :

- Un client MCP qui prend en charge les éléments suivants :
  - Identifiants OAuth préconfigurés
  - Le champ `clientId` dans sa configuration
- Disposez d'un accès administrateur, si vous créez l'application pour l'instance.
- Disposez du rôle Owner pour le groupe, si vous créez l'application pour un groupe.

Pour créer l'application OAuth :

1. Créez une application OAuth pour une [instance](../../integration/oauth_provider.md#create-an-instance-wide-application), un [groupe](../../integration/oauth_provider.md#create-a-group-owned-application) ou un [utilisateur](../../integration/oauth_provider.md#create-a-user-owned-application).
1. Pour les portées, sélectionnez **mcp** et décochez la case **Confidentiel**.
1. Enregistrez l'application.
1. Configurez votre client MCP avec l'identifiant de l'application, ou communiquez cet identifiant aux utilisateurs qui réutilisent l'application. L'identifiant de l'application correspond au `clientId`. La clé de configuration varie selon le client, mais elle est généralement nommée `clientId` ou `client_id` dans la configuration OAuth du serveur MCP GitLab, généralement dans un fichier `mcp.json`.

Pour les applications d'instance et d'utilisateur, vous pouvez également utiliser l'[API REST](../../api/applications.md#create-an-application) pour créer l'application. Aucune API REST n'existe pour les applications appartenant à un groupe, vous devez donc utiliser l'interface de groupe.

> [!note]
> L'URI de redirection enregistrée sur l'application OAuth doit correspondre exactement à l'URI de redirection que votre client MCP envoie lors du flux OAuth. Consultez la documentation de votre client pour connaître l'URI de redirection qu'il utilise. Une seule application OAuth partagée ne peut pas prendre en charge des clients MCP qui utilisent des URI de redirection différentes. Si vos utilisateurs utilisent des clients MCP avec des URI de redirection différentes, créez une application OAuth partagée distincte pour chaque type de client.

### Considérations de sécurité {#security-considerations}

Les utilisateurs qui s'authentifient avec l'identifiant client doivent tout de même effectuer l'autorisation OAuth avec leurs propres identifiants GitLab. Ils peuvent uniquement accéder aux données pour lesquelles ils disposent d'une autorisation.

GitLab ne vérifie pas quelle application cliente MCP présente le `clientId`. Si vous créez une application OAuth pour un client MCP spécifique, tout autre client MCP prenant en charge la pré-inscription pourrait utiliser le même `clientId` pour s'authentifier. Le `clientId` détermine quelle application OAuth est utilisée, et non quel logiciel client est autorisé.

Les applications pré-enregistrées créées avec l'API REST n'appliquent pas le Proof Key for Code Exchange (PKCE). Le PKCE protège contre l'interception du code d'autorisation pour les clients publics.

Pour appliquer le PKCE, vérifiez que votre client MCP envoie les paramètres `code_challenge` et `code_challenge_method` lors du flux OAuth. GitLab accepte les paramètres PKCE pour les applications pré-enregistrées, mais ne les exige pas.

## Sujets connexes {#related-topics}

- [Serveurs MCP dans le catalogue d'IA](../gitlab_duo/model_context_protocol/ai_catalog_mcp_servers.md)

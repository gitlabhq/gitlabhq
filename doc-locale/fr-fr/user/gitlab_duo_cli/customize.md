---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez les hooks, les commandes slash personnalisées, les plugins et les paramètres réseau pour GitLab Duo CLI."
title: Personnaliser GitLab Duo CLI
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.83.0) de la variable d'environnement et de l'option pour activer les Agent Skills au niveau utilisateur dans GitLab Duo CLI 8.83.0 en [version expérimentale](../../policy/development_stages_support.md#experiment), lors de la release GitLab 19.0

{{< /history >}}

GitLab Duo CLI prend en charge les personnalisations suivantes :

- Utilisez des hooks pour exécuter des commandes personnalisées à des points spécifiques du cycle de vie de GitLab Duo CLI.
- Utilisez des commandes slash personnalisées pour mieux adapter la CLI à votre workflow ou à votre cas d'utilisation.
- Utilisez des plugins pour installer des Agent Skills, des commandes slash personnalisées et des serveurs Model Context Protocol (MCP) depuis une marketplace.
- Utilisez les [instructions personnalisées](../duo_agent_platform/customize/_index.md) définies pour la plateforme GitLab Duo Agent afin d'adapter votre workflow, vos normes de codage ou les exigences de votre projet.

## Hooks {#hooks}

{{< details >}}

- Statut : version expérimentale

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2209) en [version expérimentale](../../policy/development_stages_support.md#experiment) dans GitLab Duo CLI 8.95.0, lors de la release GitLab 19.1

{{< /history >}}

Utilisez des hooks pour exécuter des commandes personnalisées à des points spécifiques du cycle de vie de GitLab Duo CLI.

Par exemple, vous pouvez injecter du contexte supplémentaire dans chaque nouvelle session de chat en exécutant un script qui collecte des informations sur votre environnement.

GitLab Duo CLI prend en charge les hooks à deux niveaux :

- Niveau utilisateur (global) : s'applique à tous vos projets.
- Niveau projet : s'applique uniquement à un projet spécifique. Les hooks au niveau projet sont désactivés par défaut pour empêcher l'exécution de code arbitraire provenant de dépôts extraits.

Lorsque des fichiers `hooks.json` existent à la fois au niveau utilisateur et au niveau projet, GitLab CLI fusionne les hooks et exécute en premier ceux du niveau utilisateur.

> [!note]
> Pour des raisons de sécurité, les variables d'environnement sensibles (`GITLAB_TOKEN`, `GITLAB_OAUTH_TOKEN`, `CI_JOB_TOKEN`) sont exclues des processus de hook.

### Exécution des hooks {#hook-execution}

Lorsqu'un hook s'exécute, GitLab Duo CLI :

1. Envoie un objet JSON à l'entrée standard de la commande avec les métadonnées de session :

   ```json
   {
     "session_id": "abc-123",
     "cwd": "/path/to/project",
     "transcript_path": "",
     "hook_event_name": "SessionStart",
     "source": "startup"
   }
   ```

1. Définit les variables d'environnement `DUO_SESSION_ID` et `DUO_PROJECT_DIR` pour le processus de hook.
1. Collecte la sortie standard de la commande comme contexte supplémentaire pour la session.

Le hook peut renvoyer du texte brut sur la sortie standard, ou un objet JSON :

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Your context string here"
  }
}
```

Si le hook se termine avec un statut non nul ou expire, il est enregistré comme avertissement mais ne bloque pas le démarrage de la session.

### Créer des hooks {#create-hooks}

GitLab Duo CLI prend en charge l'événement `SessionStart`, qui s'exécute lorsqu'une nouvelle session démarre ou qu'une session existante reprend.

Pour créer un hook :

1. Créez un fichier `hooks.json` :
   - Pour un hook au niveau utilisateur :
     - Sur Linux ou macOS, créez le fichier dans `~/.gitlab/duo/hooks.json`.
     - Sur Windows, créez le fichier dans `%APPDATA%\GitLab\duo\hooks.json`.
   - Pour un hook au niveau projet, créez le fichier à la racine de votre projet : `<project>/.gitlab/duo/hooks.json`.
1. Définissez vos hooks dans le fichier.
   - Créez un groupe de correspondance pour chaque source d'événement `SessionStart` devant déclencher le hook (`startup` ou `resume`).
   - Chaque groupe de correspondance a une valeur regex `matcher` facultative et un tableau de hooks de commande :

     | Champ | Description |
     |-------|-------------|
     | `matcher` | Facultatif. Expression régulière (regex) testée par rapport à la source d'événement (`startup` ou `resume` pour `SessionStart`). Omettez pour tout faire correspondre. |
     | `hooks[].type` | Doit être `"command"`. |
     | `hooks[].command` | Une commande shell à exécuter. |
     | `hooks[].timeout` | Facultatif. Délai d'expiration en secondes. Par défaut : 30\. |

   - Par exemple :

     ```json
     {
       "hooks": {
         "SessionStart": [
           {
             "matcher": "startup",
             "hooks": [
               {
                 "type": "command",
                 "command": "cat ~/.my-coding-preferences.md",
                 "timeout": 10
               }
             ]
          }
         ]
       }
     }
     ```

1. Si vous avez des hooks au niveau projet, activez-les lorsque vous démarrez GitLab Duo CLI :

   {{< tabs >}}

   {{< tab title="glab" >}}

   ```shell
   glab duo cli --enable-project-hooks
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   ```shell
   duo --enable-project-hooks
   ```

   {{< /tab >}}

   {{< /tabs >}}

   Vous pouvez également définir la variable d'environnement :

   ```shell
   export GITLAB_ENABLE_PROJECT_HOOKS=true
   ```

## Commandes slash personnalisées {#custom-slash-commands}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3617) dans GitLab Duo CLI 9.2.0, lors de la release GitLab 19.2

{{< /history >}}

Créez des commandes slash personnalisées pour les invites que vous utilisez fréquemment.

GitLab Duo CLI prend en charge les commandes slash personnalisées à deux niveaux :

- Niveau utilisateur : s'applique à tous vos projets.
- Niveau projet : s'applique uniquement à un projet spécifique.

Si une commande au niveau utilisateur et une commande au niveau projet partagent le même nom, la commande au niveau projet est prioritaire. Les commandes slash personnalisées ne peuvent pas remplacer les commandes slash intégrées ni les [commandes slash d'Agent Skills](../duo_agent_platform/customize/agent_skills.md#expose-skills-as-slash-commands).

### Créer une commande slash personnalisée {#create-a-custom-slash-command}

Pour créer une commande slash personnalisée, vous créez un fichier Markdown.

Le nom du fichier est le nom de la commande, et le contenu du fichier est l'invite.

Par exemple, un fichier nommé `daily.md` crée la commande `/daily` :

1. Créez un répertoire `commands` :
   - Pour une commande au niveau projet, créez le répertoire à la racine de votre projet : `<project>/.agents/commands/`.
   - Pour une commande au niveau utilisateur, utilisez l'un des emplacements suivants :
     - Pour conserver vos commandes avec vos autres fichiers de personnalisation GitLab Duo :
       - Sur Linux ou macOS, créez le répertoire dans `~/.gitlab/duo/commands/`.
       - Sur Windows, créez le répertoire dans `%APPDATA%\GitLab\duo\commands\`.
       - Si vous avez défini `GLAB_CONFIG_DIR` ou `XDG_CONFIG_HOME`, utilisez `$GLAB_CONFIG_DIR/commands/` ou `$XDG_CONFIG_HOME/gitlab/duo/commands/`. Si les deux sont définis, `GLAB_CONFIG_DIR` est prioritaire.
     - Pour partager des commandes avec d'autres outils d'IA :
       - Sur Linux ou macOS, créez le répertoire dans `~/.agents/commands/`.
       - Sur Windows, créez le répertoire dans `%USERPROFILE%\.agents\commands\`.
1. Dans le répertoire, créez un fichier Markdown. Utilisez le nom de la commande comme nom de fichier. Les noms de commande doivent commencer par une lettre ou un chiffre, et ne peuvent contenir que des lettres, des chiffres, des tirets et des tirets bas.
1. Ajoutez l'invite dans le fichier.
1. Facultatif. Ajoutez un champ `description` dans le front matter YAML en haut du fichier. La description s'affiche à côté de la commande dans le menu des commandes slash.

   Par exemple, une commande `/daily` définie dans `daily.md` :

   ```markdown
   ---
   description: Prepare a daily report
   ---

   Use `glab todo list` to fetch my open TODO items. Give me a concise morning report ranked by priority.
   ```

1. Redémarrez GitLab Duo CLI. GitLab CLI détecte les commandes slash personnalisées au démarrage.

### Utiliser une commande slash personnalisée {#use-a-custom-slash-command}

En mode interactif, saisissez la commande slash à l'invite et appuyez sur <kbd>Entrée</kbd>. GitLab Duo CLI envoie le contenu du fichier comme invite.

Tout texte que vous saisissez après le nom de la commande est ajouté à la fin de l'invite.

Ajoutez du texte supplémentaire pour personnaliser ce que fait la commande slash personnalisée.

Par exemple, `/daily prioritize my milestone deliverables`.

## Plugins {#plugins}

{{< details >}}

- Statut : version expérimentale

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.10.0) en tant que [version expérimentale](../../policy/development_stages_support.md#experiment) dans GitLab Duo CLI 9.10.0, lors de la release GitLab 19.3.

{{< /history >}}

Utilisez des plugins pour étendre GitLab Duo CLI avec des fonctionnalités supplémentaires.

Un plugin est un répertoire qui regroupe des extensions pour GitLab Duo CLI. Un plugin peut regrouper des [Agent Skills](../duo_agent_platform/customize/agent_skills.md), des [commandes slash personnalisées](#custom-slash-commands) et des [serveurs MCP](../gitlab_duo/model_context_protocol/mcp_clients.md).

Une marketplace est un catalogue de plugins disponibles dans un dépôt Git ou un répertoire local. Le fichier `marketplace.json` liste les plugins disponibles et où les trouver.

Pour utiliser un plugin, vous enregistrez la marketplace qui le contient, puis vous installez le plugin depuis cette marketplace. Les plugins sont identifiés sous la forme `<plugin>@<marketplace>`.

Pour assurer la compatibilité avec l'écosystème de plugins communautaires existant, GitLab Duo CLI lit également les fichiers `.claude-plugin/marketplace.json`. Les marketplaces de plugins existantes fonctionnent avec GitLab Duo CLI sans modification.

Prérequis :

- [Configurer GitLab Duo CLI](set_up.md).
- Git, si vous souhaitez ajouter une marketplace depuis un dépôt Git.

### Enregistrer une marketplace {#register-a-marketplace}

Avant de pouvoir installer un plugin, vous devez enregistrer la marketplace qui le contient.

La première fois que vous utilisez des plugins, GitLab Duo CLI enregistre automatiquement la marketplace officielle GitLab, [`gitlab-duo-plugins`](https://gitlab.com/gitlab-org/ai/gitlab-duo-plugins). Si vous supprimez cette marketplace, GitLab Duo CLI ne l'enregistre pas à nouveau.

Pour enregistrer une marketplace :

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace add <source>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace add <source>
```

{{< /tab >}}

{{< /tabs >}}

`<source>` est l'un des éléments suivants :

| Type de source      | Format                                                                                     | Exemple                                          |
|-------------------|---------------------------------------------------------------------------------------------|---------------------------------------------------|
| Dépôt Git    | Une URL acceptée par `git clone`. Ajoutez éventuellement `#<ref>` pour épingler une branche ou un tag.          | `https://gitlab.com/group/marketplace.git#stable` |
| Répertoire local   | Un chemin absolu ou relatif. `~` est développé en répertoire personnel.                       | `~/marketplaces/internal`                        |

Par exemple :

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace add https://gitlab.com/example-group/example-marketplace.git
```

```shell
glab duo plugin marketplace add ~/marketplaces/internal
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace add https://gitlab.com/example-group/example-marketplace.git
```

```shell
duo plugin marketplace add ~/marketplaces/internal
```

{{< /tab >}}

{{< /tabs >}}

GitLab Duo CLI identifie la marketplace par le champ `name` dans son fichier `marketplace.json`.

#### Mettre à jour automatiquement les plugins depuis une marketplace {#automatically-update-plugins-from-a-marketplace}

Pour mettre à jour automatiquement les plugins que vous installez depuis une marketplace, enregistrez la marketplace avec l'option `--auto-update` :

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace add <source> --auto-update
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace add <source> --auto-update
```

{{< /tab >}}

{{< /tabs >}}

Au démarrage de GitLab Duo CLI, il met à jour en arrière-plan les plugins que vous avez installés depuis cette marketplace, sans confirmation. Lorsqu'un plugin est mis à jour, GitLab Duo CLI vous invite à redémarrer pour charger la nouvelle version.

#### Lister les marketplaces enregistrées {#list-registered-marketplaces}

Pour lister les marketplaces que vous avez enregistrées :

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace list
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace list
```

{{< /tab >}}

{{< /tabs >}}

Pour chaque marketplace, GitLab Duo CLI affiche :

- La source de la marketplace.
- La date de dernière mise à jour de la marketplace.
- Le nombre de plugins que contient la marketplace.
- Si les mises à jour automatiques sont activées pour la marketplace.

#### Lister les plugins disponibles dans la marketplace {#list-available-marketplace-plugins}

Pour lister les plugins qu'une marketplace propose :

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace show <name>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace show <name>
```

{{< /tab >}}

{{< /tabs >}}

Pour chaque plugin, GitLab Duo CLI affiche la version, la description et l'emplacement d'installation du plugin, le cas échéant.

#### Mettre à jour une marketplace {#update-a-marketplace}

Pour actualiser le catalogue d'une marketplace depuis sa source :

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace update <name>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace update <name>
```

{{< /tab >}}

{{< /tabs >}}

#### Supprimer une marketplace {#remove-a-marketplace}

Pour supprimer une marketplace enregistrée :

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace remove <name>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace remove <name>
```

{{< /tab >}}

{{< /tabs >}}

> [!warning]
> La suppression d'une marketplace désinstalle également tous les plugins que vous avez installés depuis celle-ci.

### Installer et gérer des plugins {#install-and-manage-plugins}

Lorsque vous installez un plugin, vous choisissez une portée. La portée détermine le fichier de configuration que GitLab Duo CLI met à jour, ainsi que les personnes auxquelles l'installation s'applique.

| Portée               | Fichier de configuration                          | Utiliser pour                                                            |
|----------------------|----------------------------------------------|------------------------------------------------------------------------|
| `user` (par défaut)     | `<config dir>/plugins.json`                 | Plugins pour tous vos projets.                                       |
| `project`            | `.gitlab/duo/plugins.json` dans le projet   | Plugins partagés avec l'équipe. Committez ce fichier dans votre dépôt.           |
| `local`              | `.gitlab/duo/plugins.local.json` dans le projet | Plugins personnels, par projet. Ajoutez ce fichier à votre `.gitignore`. |

`<config dir>` correspond à `~/.gitlab/duo` sur Linux et macOS, ou à `%APPDATA%\GitLab\duo` sur Windows.

Pour installer un plugin depuis une marketplace enregistrée :

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin install <plugin>@<marketplace> [--scope user|project|local]
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin install <plugin>@<marketplace> [--scope user|project|local]
```

{{< /tab >}}

{{< /tabs >}}

Si vous ne spécifiez pas `--scope`, GitLab Duo CLI utilise la portée `user`.

Par exemple :

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin install my-plugin@my-marketplace
```

```shell
glab duo plugin install my-plugin@my-marketplace --scope project
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin install my-plugin@my-marketplace
```

```shell
duo plugin install my-plugin@my-marketplace --scope project
```

{{< /tab >}}

{{< /tabs >}}

#### État activé après l'installation {#enabled-state-after-installation}

Lorsque vous installez un plugin, GitLab Duo CLI enregistre si le plugin est activé dans le fichier de configuration de la portée. Pour déterminer l'état initial, GitLab Duo CLI utilise, par ordre de priorité :

1. Tout paramètre d'activation ou de désactivation que vous avez précédemment enregistré pour le plugin dans la portée cible ou une portée plus large. Par exemple, si vous avez désactivé un plugin, puis l'avez désinstallé et réinstallé, le plugin reste désactivé.
1. La valeur `defaultEnabled` dans l'entrée du catalogue de la marketplace du plugin.
1. La valeur `defaultEnabled` dans le manifest `plugin.json` du plugin.

Si aucun de ces éléments n'est défini, le plugin est activé.

#### Lister les plugins installés {#list-installed-plugins}

Pour lister vos plugins installés :

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin list
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin list
```

{{< /tab >}}

{{< /tabs >}}

Les plugins installés sont regroupés par portée, et la liste indique si chaque plugin est activé.

#### Activer ou désactiver un plugin {#enable-or-disable-a-plugin}

Lorsque vous activez, désactivez ou désinstallez un plugin, vous pouvez l'identifier par son nom seul. Si le même nom de plugin est installé depuis plusieurs marketplaces, utilisez l'identifiant complet `<plugin>@<marketplace>`.

Pour activer ou désactiver un plugin installé :

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin enable <plugin> [--scope user|project|local]
glab duo plugin disable <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin enable <plugin> [--scope user|project|local]
duo plugin disable <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< /tabs >}}

Si vous activez ou désactivez un plugin à plusieurs portées, la portée la plus spécifique est prioritaire : `local`, puis `project`, puis `user`.

#### Mettre à jour un plugin {#update-a-plugin}

Pour mettre à jour un plugin vers la dernière version disponible depuis sa marketplace :

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin update <plugin>@<marketplace>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin update <plugin>@<marketplace>
```

{{< /tab >}}

{{< /tabs >}}

La mise à jour s'applique à toutes les portées où le plugin est installé.

#### Désinstaller un plugin {#uninstall-a-plugin}

Pour désinstaller un plugin :

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin uninstall <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin uninstall <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< /tabs >}}

La désinstallation supprime le plugin de votre configuration.

### Utiliser un plugin installé {#use-an-installed-plugin}

Après avoir installé et activé un plugin, GitLab Duo CLI découvre tout ce que le plugin regroupe au prochain démarrage :

- Les compétences deviennent disponibles de la même façon que les autres Agent Skills.
- Les commandes slash personnalisées apparaissent dans le menu des commandes slash. Les commandes slash intégrées, les commandes slash Agent Skills et vos propres commandes slash personnalisées ont la priorité sur une commande de plugin portant le même nom.
- Les serveurs MCP sont chargés aux côtés des serveurs MCP que vous avez configurés, et nécessitent une [approbation d'outil](../gitlab_duo/model_context_protocol/mcp_clients.md#configure-tool-approval) de la même manière. Pour identifier la provenance d'un serveur, GitLab Duo CLI préfixe le nom du serveur avec le nom du plugin.

### Créer une marketplace {#create-a-marketplace}

Pour créer une marketplace, ajoutez un fichier `marketplace.json` à la racine d'un dépôt Git ou d'un répertoire local. Par exemple :

```json
{
  "name": "my-marketplace",
  "owner": {
    "name": "Your Name"
  },
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./plugins/my-plugin",
      "description": "A short description of the plugin."
    }
  ]
}
```

Chaque entrée dans `plugins` doit définir `source` avec un chemin relatif à la racine de la marketplace, commençant par `./`.

### Créer un plugin {#create-a-plugin}

Un plugin est un répertoire qui contient un manifest `plugin.json` optionnel et les extensions regroupées par le plugin : compétences, commandes slash personnalisées et serveurs MCP.

Le manifest `plugin.json` prend en charge les champs suivants :

| Champ             | Obligatoire | Description                                              |
|--------------------|----------|--------------------------------------------------------------|
| `name`             | Oui      | Le nom du plugin.                                            |
| `version`          | Non       | La version du plugin.                                         |
| `description`      | Non       | Une courte description du plugin.                            |
| `defaultEnabled`   | Non       | Si le plugin est activé par défaut lors de l'installation.      |

Par exemple :

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "A short description of the plugin.",
  "defaultEnabled": true
}
```

Pour assurer la compatibilité avec les plugins communautaires existants, GitLab Duo CLI lit également le manifest depuis `.claude-plugin/plugin.json`.

Pour regrouper des extensions avec votre plugin :

- Compétences : ajoutez un fichier `SKILL.md` dans un répertoire `skills/<skill-name>/` du plugin. Pour le format du fichier `SKILL.md`, consultez [créer des compétences](../duo_agent_platform/customize/agent_skills.md#create-skills).
- Commandes slash personnalisées : ajoutez un fichier Markdown dans un répertoire `commands/` du plugin. Le nom du fichier est le nom de la commande, et le format du fichier est le même que celui d'une [commande slash personnalisée](#create-a-custom-slash-command).
- Serveurs MCP : ajoutez un fichier `.mcp.json` à la racine du plugin. Le format du fichier est le même que le [format de configuration MCP](../gitlab_duo/model_context_protocol/mcp_clients.md#configuration-format). Pour référencer des fichiers à l'intérieur du plugin, utilisez la variable `${DUO_PLUGIN_ROOT}`, qui correspond au répertoire dans lequel le plugin est installé.

Par exemple, un dépôt de marketplace contenant un plugin qui regroupe une compétence, une commande slash personnalisée et un serveur MCP :

```plaintext
my-marketplace/
├── marketplace.json
└── plugins/
    └── my-plugin/
        ├── plugin.json
        ├── .mcp.json
        ├── commands/
        │   └── my-command.md
        └── skills/
            └── my-skill/
                └── SKILL.md
```

GitLab Duo CLI détermine la version d'un plugin selon l'ordre de priorité suivant :

1. Le champ `version` dans le fichier `plugin.json` du plugin.
1. Le champ `version` dans l'entrée du plugin dans le fichier `marketplace.json` de la marketplace.

Si aucun des deux champs n'est défini, la version du plugin est `unknown`.

## Sujets connexes {#related-topics}

- [Référence complète de la CLI GitLab Duo](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [Personnaliser GitLab Duo Agent Platform](../duo_agent_platform/customize/_index.md)
- [Agent Skills](../duo_agent_platform/customize/agent_skills.md)

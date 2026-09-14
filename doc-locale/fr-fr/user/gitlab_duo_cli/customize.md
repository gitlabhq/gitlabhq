---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez les hooks, les commandes slash personnalisées et les paramètres réseau pour la CLI GitLab Duo."
title: Personnaliser la CLI GitLab Duo
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.83.0) de la variable d'environnement et de l'option pour activer les Agent Skills au niveau utilisateur dans GitLab Duo CLI 8.83.0 en [version expérimentale](../../policy/development_stages_support.md#experiment), lors de la release GitLab 19.0

{{< /history >}}

La CLI GitLab Duo prend en charge les personnalisations suivantes :

- Utilisez des hooks pour exécuter des commandes personnalisées à des points spécifiques du cycle de vie de GitLab Duo CLI.
- Utilisez des commandes slash personnalisées pour mieux adapter la CLI à votre workflow ou à votre cas d'utilisation.
- Utilisez les [instructions personnalisées](../duo_agent_platform/customize/_index.md) définies pour la plateforme GitLab Duo Agent afin d'adapter votre workflow, vos normes de codage ou les exigences de votre projet.

## Hooks {#hooks}

{{< details >}}

- Statut : version expérimentale

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
     - Sur Linux ou macOS, créez le fichier à `~/.gitlab/duo/hooks.json`.
     - Sur Windows, créez le fichier à `%APPDATA%\GitLab\duo\hooks.json`.
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
       - Sur Linux ou macOS, créez le répertoire à `~/.gitlab/duo/commands/`.
       - Sur Windows, créez le répertoire à `%APPDATA%\GitLab\duo\commands\`.
       - Si vous avez défini `GLAB_CONFIG_DIR` ou `XDG_CONFIG_HOME`, utilisez `$GLAB_CONFIG_DIR/commands/` ou `$XDG_CONFIG_HOME/gitlab/duo/commands/`. Si les deux sont définis, `GLAB_CONFIG_DIR` est prioritaire.
     - Pour partager des commandes avec d'autres outils d'IA :
       - Sur Linux ou macOS, créez le répertoire à `~/.agents/commands/`.
       - Sur Windows, créez le répertoire à `%USERPROFILE%\.agents\commands\`.
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

## Sujets connexes {#related-topics}

- [Référence complète de la CLI GitLab Duo](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [Personnaliser GitLab Duo Agent Platform](../duo_agent_platform/customize/_index.md)

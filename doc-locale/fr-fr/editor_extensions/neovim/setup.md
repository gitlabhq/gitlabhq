---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connectez-vous à GitLab Duo dans Neovim et utilisez-le.
title: Installer et configurer le plugin GitLab pour Neovim
---

{{< details >}}

- Édition : [Gratuite](../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- Pour GitLab.com et GitLab Self-Managed, vous devez disposer de GitLab version 16.1 ou ultérieure. Bien que de nombreuses fonctionnalités de l'extension puissent fonctionner avec des versions antérieures, celles-ci ne sont pas prises en charge.
  - La fonctionnalité GitLab Duo Code Suggestions nécessite GitLab version 16.8 ou ultérieure.
- Vous disposez de [Neovim](https://neovim.io/) version 0.9 ou ultérieure.
- Vous avez installé [NPM](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm). NPM est requis pour l'installation de Code Suggestions.

Pour installer l'extension, suivez les étapes d'installation correspondant au gestionnaire de plugins de votre choix :

{{< tabs >}}

{{< tab title="Pas de gestionnaire de plugins" >}}

Exécutez cette commande pour inclure ce projet avec [`packadd`](https://neovim.io/doc/user/repeat.html#%3Apackadd) au démarrage :

```shell
git clone https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim.git ~/.local/share/nvim/site/pack/gitlab/start/gitlab.vim
```

{{< /tab >}}

{{< tab title="`lazy.nvim`" >}}

Ajoutez ce plugin à votre configuration [lazy.nvim](https://github.com/folke/lazy.nvim) :

```lua
{
  'https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim.git',
  -- Activate when a file is created/opened
  event = { 'BufReadPre', 'BufNewFile' },
  -- Activate when a supported filetype is open
  ft = { 'go', 'javascript', 'python', 'ruby' },
  cond = function()
    -- Only activate if token is present in environment variable.
    -- Remove this line to use the interactive workflow.
    return vim.env.GITLAB_TOKEN ~= nil and vim.env.GITLAB_TOKEN ~= ''
  end,
  opts = {
    statusline = {
      -- Hook into the built-in statusline to indicate the status
      -- of the GitLab Duo Code Suggestions integration
      enabled = true,
    },
  },
}
```

{{< /tab >}}

{{< tab title="`packer.nvim`" >}}

Déclarez le plugin dans votre configuration [packer.nvim](https://github.com/wbthomason/packer.nvim) :

```lua
use {
  "git@gitlab.com:gitlab-org/editor-extensions/gitlab.vim.git",
}
```

{{< /tab >}}

{{< /tabs >}}

## S'authentifier avec GitLab {#authenticate-with-gitlab}

Pour connecter cette extension à votre compte GitLab, configurez vos variables d'environnement :

| Variable d'environnement | Valeur par défaut              | Description |
|----------------------|----------------------|-------------|
| `GITLAB_TOKEN`       | sans objet       | Le jeton d'accès personnel GitLab par défaut à utiliser pour les requêtes authentifiées. Si fourni, ignore l'authentification interactive. |
| `GITLAB_VIM_URL`     | `https://gitlab.com` | Remplace l'instance GitLab à laquelle se connecter. Par défaut : `https://gitlab.com`. |

Une liste complète des variables d'environnement est disponible dans le texte d'aide de l'extension à l'adresse [`doc/gitlab.txt`](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/doc/gitlab.txt).

## Configurer l'extension {#configure-the-extension}

Pour configurer cette extension :

1. Configurez les types de fichiers souhaités. Par exemple, étant donné que ce plugin prend en charge Ruby, il ajoute une auto-commande `FileType ruby`. Pour configurer ce comportement pour d'autres types de fichiers, ajoutez davantage de types de fichiers à l'option de configuration `code_suggestions.auto_filetypes` :

   ```lua
   require('gitlab').setup({
     statusline = {
       enabled = false
     },
     code_suggestions = {
       -- For the full list of default languages, see the 'auto_filetypes' array in
       -- https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/lua/gitlab/config/defaults.lua
       auto_filetypes = { 'ruby', 'javascript' }, -- Default is { 'ruby' }
       ghost_text = {
         enabled = false, -- ghost text is an experimental feature
         toggle_enabled = "<C-h>",
         accept_suggestion = "<C-l>",
         clear_suggestions = "<C-k>",
         stream = true,
       },
     }
   })
   ```

1. [Configurez Omni Completion](#configure-omni-completion) pour définir le raccourci clavier qui déclenche Code Suggestions.
1. Facultatif. [Configurer les mappages de touches `<Plug>`](#configure-plug-key-mappings).
1. Facultatif. Configurez les balises d'aide à l'aide de `:helptags ALL` pour accéder à [`:help gitlab.txt`](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/doc/gitlab.txt).

### Configurer Omni Completion {#configure-omni-completion}

Pour activer [Omni Completion](https://neovim.io/doc/user/insert.html#compl-omni-filetypes) avec Code Suggestions :

1. Créez un [jeton d'accès personnel](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) avec la portée `api`.
1. Ajoutez le jeton à votre shell en tant que variable d'environnement `GITLAB_TOKEN`.
1. Installez le [serveur de langage](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp) Code Suggestions en exécutant la commande vim `:GitLabCodeSuggestionsInstallLanguageServer`.
1. Démarrez le serveur de langage en exécutant la commande vim `:GitLabCodeSuggestionsStart`. Facultativement, [configurez les mappages de touches `<Plug>`](#configure-plug-key-mappings) pour activer ou désactiver le serveur de langage.
1. Facultatif. Envisagez de configurer la boîte de dialogue d'Omni Completion même pour une seule suggestion :

   ```lua
   vim.o.completeopt = 'menu,menuone'
   ```

Lorsque vous travaillez dans un type de fichier pris en charge, ouvrez le menu Omni Completion en appuyant sur <kbd>Control</kbd>+<kbd>x</kbd> puis <kbd>Control</kbd>+<kbd>o</kbd>.

## Configurer les mappages de touches `<Plug>` {#configure-plug-key-mappings}

Pour plus de commodité, ce plugin fournit des mappages de touches `<Plug>`. Pour utiliser le mappage de touches `<Plug>(GitLab...)`, vous devez inclure votre propre mappage de touches qui le référence :

```lua
-- Toggle Code Suggestions on/off with Control-G in normal mode:
vim.keymap.set('n', '<C-g>', '<Plug>(GitLabToggleCodeSuggestions)')
```

## Désinstaller l'extension {#uninstall-the-extension}

Pour désinstaller l'extension, supprimez ce plugin ainsi que tous les binaires du serveur de langage à l'aide de ces commandes :

```shell
rm -r ~/.local/share/nvim/site/pack/gitlab/start/gitlab.vim
rm ~/.local/share/nvim/gitlab-code-suggestions-language-server-*
```

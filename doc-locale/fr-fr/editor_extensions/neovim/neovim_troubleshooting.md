---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connectez-vous à GitLab Duo dans Neovim et utilisez-le.
title: Dépannage de Neovim
---

{{< details >}}

- Édition : [Gratuite](../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lors du dépannage du plugin GitLab pour Neovim, vous devez confirmer que le problème survient de manière isolée, indépendamment des autres plugins et paramètres Neovim. Commencez par exécuter les [étapes de test](#test-your-neovim-configuration) Neovim, puis les étapes de dépannage pour GitLab Duo Code Suggestions.

Si les étapes de cette page ne résolvent pas votre problème, consultez la [liste des tickets ouverts](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/?sort=created_date&state=opened&first_page_size=100) dans le projet du plugin Neovim. Si un ticket correspond à votre problème, mettez-le à jour. Si aucun ticket ne correspond à votre problème, [créez un nouveau ticket](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/new).

## Tester votre configuration Neovim {#test-your-neovim-configuration}

Les responsables du plugin Neovim demandent souvent les résultats de ces vérifications dans le cadre du dépannage :

1. Assurez-vous d'avoir [généré les tags d'aide](#generate-help-tags).
1. Exécutez [`:checkhealth`](#run-checkhealth).
1. Activez les [logs de débogage](#enable-debug-logs).
1. Essayez de [reproduire le problème dans un projet minimal](#reproduce-the-problem-in-a-minimal-project).

### Générer les tags d'aide {#generate-help-tags}

Si vous voyez l'erreur `E149: Sorry, no help for gitlab.txt`, vous devez générer les tags d'aide dans Neovim. Pour résoudre ce problème :

- Exécutez l'une de ces commandes :
  - `:helptags ALL`
  - `:helptags doc/` depuis le répertoire racine du plugin.

### Exécuter `:checkhealth` {#run-checkhealth}

Exécutez `:checkhealth gitlab*` pour obtenir des diagnostics sur la configuration de votre session actuelle. Ces vérifications vous aident à identifier et à résoudre les problèmes de configuration par vous-même.

## Activer les logs de débogage {#enable-debug-logs}

Activez les logs de débogage pour capturer davantage d'informations sur les problèmes. Les logs de débogage peuvent contenir des détails de configuration sensibles ; veillez donc à examiner le contenu avant de le partager avec d'autres personnes.

Pour activer la journalisation supplémentaire :

- Définissez le niveau de log `vim.lsp` dans votre buffer actuel :

  ```lua
  :lua vim.lsp.set_log_level('debug')
  ```

## Reproduire le problème dans un projet minimal {#reproduce-the-problem-in-a-minimal-project}

Pour aider les responsables du projet à comprendre et à résoudre votre ticket, créez un exemple de configuration ou de projet qui reproduit votre ticket. Par exemple, lors du dépannage d'un problème avec Code Suggestions :

1. Créez un exemple de projet :

   ```plaintext
   mkdir issue-25
   cd issue-25
   echo -e "def hello(name)\n\nend" > hello.rb
   ```

1. Créez un nouveau fichier nommé `minimal.lua`, avec le contenu suivant :

   ```lua
   -- NOTE: Do not set this in your usual configuration, as this log level
   -- could include sensitive configuration details.
   vim.lsp.set_log_level('debug')

   vim.opt.rtp:append('$HOME/.local/share/nvim/site/pack/gitlab/start/gitlab.vim')

   vim.cmd('runtime plugin/gitlab.lua')

   -- gitlab.config options overrides:
   local minimal_user_options = {}
   require('gitlab').setup(minimal_user_options)
   ```

1. Dans une session Neovim minimale, modifiez `hello.rb` :

   ```shell
   nvim --clean -u minimal.lua hello.rb
   ```

1. Essayez de reproduire le comportement que vous avez rencontré. Ajustez `minimal.lua` ou d'autres fichiers du projet selon vos besoins.
1. Consultez les entrées récentes dans `~/.local/state/nvim/lsp.log` et capturez la sortie pertinente.
1. Supprimez toute référence à des informations sensibles, telles que les jetons commençant par `glpat-`.
1. Supprimez les informations sensibles de tous les registres Vim ou fichiers de log.

### Erreur : `GCS:unavailable` {#error-gcsunavailable}

Cette erreur se produit lorsque votre projet local n'a pas défini de remote dans `.git/config`.

Pour résoudre ce problème : ajoutez un remote Git dans votre projet local à l'aide de [`git remote add`](../../topics/git/commands.md#git-remote-add).

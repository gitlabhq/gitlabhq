---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connectez-vous à GitLab Duo dans Neovim et utilisez-le.
title: Plugin GitLab pour Neovim - `gitlab.vim`
---

{{< details >}}

- Édition : [Gratuite](../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Le [plugin GitLab](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim) est un plugin basé sur Lua qui intègre GitLab à Neovim.

Le plugin vous permet d'utiliser [GitLab Duo Code Suggestions](../../user/project/repository/code_suggestions/_index.md) dans la ligne de commande.

Pour installer et configurer l'extension, consultez [Installer et configurer](setup.md).

## Désactiver `gitlab.statusline` {#disable-gitlabstatusline}

Par défaut, ce plugin active `gitlab.statusline`, qui utilise la `statusline` intégrée pour afficher le statut de l'intégration GitLab Duo Code Suggestions. Si vous souhaitez désactiver `gitlab.statusline`, ajoutez ceci à votre configuration :

```lua
require('gitlab').setup({
  statusline = {
    enabled = false
  }
})
```

## Désactiver les messages `Started Code Suggestions LSP Integration` {#disable-started-code-suggestions-lsp-integration-messages}

Pour modifier le niveau de message minimal, ajoutez ceci à votre configuration :

```lua
require('gitlab').setup({
  minimal_message_level = vim.log.levels.ERROR,
})
```

## Mettre à jour l'extension {#update-the-extension}

Pour mettre à jour le plugin `gitlab.vim`, utilisez `git pull` ou votre gestionnaire de plugins Vim spécifique.

## Signaler des problèmes liés à l'extension {#report-issues-with-the-extension}

Signalez tout problème, bug ou demande de fonctionnalité dans le [suivi des tickets `gitlab.vim`](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues).

Soumettez vos commentaires dans le [ticket 22](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/22) du dépôt `gitlab.vim`.

## Sujets connexes {#related-topics}

- [Versions du plugin GitLab pour Neovim](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/releases)
- [Considérations de sécurité pour les extensions d'éditeur](../security_considerations.md)
- [Dépannage de Neovim](neovim_troubleshooting.md)
- [Voir le code source](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim)
- [Documentation du serveur de langage GitLab](../language_server/_index.md)

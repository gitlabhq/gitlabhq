---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: En savoir plus sur le serveur de langage GitLab.
title: Serveur de langage GitLab
---

Le [serveur de langage GitLab](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp) alimente diverses extensions d'éditeur GitLab dans les IDE.

## Configurer le serveur de langage pour utiliser un proxy {#configure-the-language-server-to-use-a-proxy}

Le processus enfant `gitlab-lsp` utilise le module NPM [`proxy-from-env`](https://www.npmjs.com/package/proxy-from-env?activeTab=readme) pour déterminer les paramètres du proxy à partir de ces variables d'environnement :

- `NO_PROXY`
- `HTTPS_PROXY`
- `http_proxy` (en minuscules)

Pour configurer le serveur de langage afin d'utiliser un proxy :

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

1. Dans Visual Studio Code, ouvrez vos [paramètres utilisateur ou de workspace](https://code.visualstudio.com/docs/getstarted/settings).
1. Configurez [`http.proxy`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support) pour pointer vers votre proxy HTTP.
1. Redémarrez Visual Studio Code pour vous assurer que les connexions à GitLab utilisent les derniers paramètres de proxy.

{{< /tab >}}

{{< tab title="JetBrains IDEs" >}}

1. Dans votre IDE JetBrains, configurez les paramètres [HTTP Proxy](https://www.jetbrains.com/help/idea/settings-http-proxy.html).
1. Redémarrez votre IDE pour vous assurer que les connexions à GitLab utilisent les derniers paramètres de proxy.
1. Dans le menu **Outils** > **GitLab Duo**, sélectionnez **Verify setup**. Assurez-vous que le bilan de santé est concluant.

{{< /tab >}}

{{< /tabs >}}

## Dépannage {#troubleshooting}

### Mettre à jour votre extension d'éditeur {#update-your-editor-extension}

Le serveur de langage est fourni avec chaque extension d'éditeur pour GitLab. Pour vous assurer de disposer des dernières fonctionnalités et corrections de bugs, mettez à jour votre extension vers la dernière version :

- Instructions de mise à jour [pour Eclipse](../eclipse/_index.md#update-the-plugin)
- Instructions de mise à jour [pour les IDE JetBrains](../jetbrains_ide/_index.md#update-the-extension)
- Instructions de mise à jour [pour Neovim](../neovim/_index.md#update-the-extension)
- Instructions de mise à jour [pour Visual Studio](../visual_studio/_index.md#update-the-extension)
- Instructions de mise à jour [pour Visual Studio Code](../visual_studio_code/_index.md#update-the-extension)

### Activer l'authentification par proxy {#enable-proxy-authentication}

Vous pourriez rencontrer une erreur `407 Access Denied (authentication_failed)` lors de l'utilisation d'un proxy authentifié :

```plaintext
Request failed: Can't add GitLab account for https://gitlab.com. Check your instance URL and network connection.
Fetching resource from https://gitlab.com/api/v4/personal_access_tokens/self failed
```

Pour activer l'authentification par proxy dans le serveur de langage, suivez les étapes correspondant à votre IDE :

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

1. Dans Visual Studio Code, ouvrez vos [paramètres utilisateur ou de workspace](https://code.visualstudio.com/docs/getstarted/settings).
1. Configurez [`http.proxy`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support), en incluant le nom d'utilisateur et le mot de passe, pour vous authentifier auprès de votre proxy HTTP.
1. Redémarrez Visual Studio Code pour vous assurer que les connexions à GitLab utilisent les derniers paramètres de proxy.

> [!note]
> L'extension VS Code ne prend pas en charge le paramètre hérité [`http.proxyAuthorization`](https://code.visualstudio.com/docs/setup/network#_legacy-proxy-server-support) dans VS Code pour authentifier le serveur de langage auprès d'un proxy HTTP. La prise en charge est proposée dans le [ticket 1672](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1672).

{{< /tab >}}

{{< tab title="JetBrains IDEs" >}}

1. Configurez les paramètres [HTTP Proxy](https://www.jetbrains.com/help/idea/settings-http-proxy.html) dans votre IDE JetBrains.
   1. Si vous utilisez **Manual proxy configuration**, saisissez vos identifiants sous **Proxy authentication** et sélectionnez **Remember**.
1. Redémarrez votre IDE JetBrains pour vous assurer que les connexions à GitLab utilisent les derniers paramètres de proxy.
1. Dans le menu **Outils** > **GitLab Duo**, sélectionnez **Verify setup**. Assurez-vous que le bilan de santé est concluant.

{{< /tab >}}

{{< /tabs >}}

> [!note]
> L'authentification Bearer est proposée dans le [ticket 548](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/548).

## Sujets connexes {#related-topics}

- [Versions de release du serveur de langage GitLab](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases)

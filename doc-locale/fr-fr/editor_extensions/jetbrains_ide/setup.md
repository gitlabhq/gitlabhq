---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connectez-vous à GitLab Duo et utilisez-le dans les IDE JetBrains.
title: Installer et configurer le plugin GitLab Duo pour les IDE JetBrains
---

Téléchargez le plugin depuis le [JetBrains Plugin Marketplace](https://plugins.jetbrains.com/plugin/22325-gitlab-duo) et installez-le.

Prérequis :

- IDE JetBrains : 2025.1 et versions ultérieures.
- GitLab version 16.8 ou ultérieure.

Si vous utilisez une version plus ancienne d'un IDE JetBrains, téléchargez une version du plugin compatible avec votre IDE :

1. Sur la [page du plugin](https://plugins.jetbrains.com/plugin/22325-gitlab-duo) GitLab Duo, sélectionnez **Versions**.
1. Sélectionnez **Compatibility**, puis sélectionnez votre IDE JetBrains.
1. Sélectionnez un **Channel** pour filtrer les releases stables ou les releases alpha.
1. Dans le tableau de compatibilité, trouvez la version de votre IDE et sélectionnez **Télécharger**.

## Activer le plugin {#enable-the-plugin}

Pour activer le plugin :

1. Dans votre IDE, dans la barre supérieure, sélectionnez le nom de votre IDE, puis sélectionnez **Paramètres**.
1. Dans la barre latérale gauche, sélectionnez **Plugins**.
1. Sélectionnez le plugin **GitLab Duo**, puis sélectionnez **Installer**.
1. Sélectionnez **OK** ou **Enregistrer**.

## Se connecter à GitLab {#connect-to-gitlab}

Après avoir installé l'extension, connectez-la à votre compte GitLab.

### S'authentifier avec GitLab {#authenticate-with-gitlab}

Prérequis :

- Pour l'authentification à GitLab Self-Managed et GitLab Dedicated via OAuth :
  - Plugin GitLab Duo pour JetBrains 3.30.30 et versions ultérieures.
  - L'ID d'application pour une [application OAuth à l'échelle de l'instance pour les IDE JetBrains](../../administration/settings/editor_extensions.md#jetbrains-ides).
- Pour l'authentification à l'aide d'un PAT, un [jeton d'accès personnel](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) avec la portée `api`.
- Pour l'authentification avec 1Password, accomplissez les [étapes d'intégration avec 1Password](_index.md#integrate-with-1password-cli) et renseignez la référence secrète.

Après avoir configuré le plugin dans votre IDE, connectez-le à votre compte GitLab :

1. Dans votre IDE, dans la barre supérieure, sélectionnez le nom de votre IDE, puis sélectionnez **Paramètres**.
1. Dans la barre latérale gauche, développez **Outils**, puis sélectionnez **GitLab Duo**. Si le plugin n'apparaît pas dans la liste, redémarrez votre IDE.
1. Renseignez l'**URL to GitLab instance**. Pour GitLab.com, utilisez `https://gitlab.com`.
1. Sélectionnez une méthode d'authentification : **OAuth**, **PAT** ou **1Password CLI**.
   - Pour OAuth, suivez les instructions pour vous connecter et vous authentifier.
   - Pour le PAT, saisissez votre jeton d'accès personnel. La valeur du jeton n'est pas affichée ni accessible aux autres utilisateurs.
   - Pour 1Password, sélectionnez **Integrate with 1Password CLI**, sélectionnez votre compte et, si vous le souhaitez, saisissez la référence secrète.
1. Sélectionnez **Verify setup**.
1. Sélectionnez **OK** ou **Enregistrer**.

## Configurer GitLab Duo {#configure-gitlab-duo}

Prérequis :

- Pour les fonctionnalités agentiques, vous remplissez les prérequis pour la [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md#prerequisites).
- Vous avez [activé](../../user/gitlab_duo/turn_on_off.md) GitLab Duo.
- Pour les flows, vous avez [activé les flows par défaut](../../user/duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off).
- Pour les agents, vous avez [activé les agents par défaut](../../user/duo_agent_platform/agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off) et [activé les agents personnalisés](../../user/duo_agent_platform/agents/custom.md#enable-an-agent), selon vos besoins.
- Votre projet se trouve dans un [espace de nommage de groupe](../../user/namespace/_index.md).
- Vous avez défini un [espace de nommage GitLab Duo par défaut](../../user/profile/preferences.md#namespace-resolution-in-your-local-environment) ou vous avez ouvert un projet disposant d'un accès à GitLab Duo.

Pour activer les fonctionnalités GitLab Duo :

1. Dans votre IDE JetBrains, accédez à **Paramètres** > **Outils** > **GitLab Duo**.
1. Trouvez la fonctionnalité que vous souhaitez activer et cochez la case correspondante.
1. Redémarrez votre IDE, si vous y êtes invité.

Pour GitLab Duo Code Suggestions, [consultez les prérequis supplémentaires et les étapes de configuration](../../user/project/repository/code_suggestions/set_up.md#prerequisites).

Pour approuver les outils Agentic Chat une fois par session plutôt qu'individuellement, consultez les [approbations d'outils](../../user/gitlab_duo_chat/agentic_chat.md#tool-approvals).

## Installer les versions alpha du plugin {#install-alpha-versions-of-the-plugin}

GitLab publie des builds de pré-release (alpha) du plugin dans le [canal de release `Alpha`](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/edit/versions/alpha) du JetBrains Marketplace.

Pour installer un build de pré-release, choisissez l'une des options suivantes :

- Téléchargez le build depuis le JetBrains Marketplace et [installez-le depuis le disque](https://www.jetbrains.com/help/idea/managing-plugins.html#install_plugin_from_disk).
- [Ajoutez le dépôt de plugin `alpha`](https://www.jetbrains.com/help/idea/managing-plugins.html#add_plugin_repos) à votre IDE. Pour l'URL du dépôt, utilisez `https://plugins.jetbrains.com/plugins/alpha/list`.

  > [!note]
  > Pour voir la release alpha après avoir ajouté le dépôt de plugin `alpha`, vous devrez peut-être désinstaller puis réinstaller le plugin GitLab Duo.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour un tutoriel vidéo sur ce processus, consultez [Install alpha releases of the GitLab Duo plugin for JetBrains](https://www.youtube.com/watch?v=Z9AuKybmeRU).
<!-- Video published on 2024-04-04 -->

---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez l'extension GitLab pour VS Code pour gérer les tâches GitLab courantes directement dans VS Code."
title: Extension GitLab pour VS Code
---

L'[extension GitLab pour VS Code](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow) intègre GitLab Duo et d'autres fonctionnalités GitLab directement dans votre IDE.

Pour commencer, [installez et configurez l'extension](setup.md). Pour plus de sécurité, vous pouvez configurer l'extension dans un Dev Container Visual Studio Code.

Une fois configurée, cette extension intègre directement dans votre environnement VS Code les fonctionnalités GitLab que vous utilisez au quotidien :

- [Travailler avec des projets](projects.md) : Planifiez et suivez le travail avec des tickets, examinez et discutez des modifications avec des merge requests, et partagez des extraits de code. Utilisez GitLab Duo pour la planification et le codage natifs à l'IA.
- [Surveiller et tester les pipelines CI/CD](cicd.md) : Testez la configuration de votre pipeline. Affichez le statut du pipeline et les sorties de job.
- [Sécuriser votre application](security_scanning.md) : Examinez les résultats de sécurité et effectuez une analyse SAST pour votre projet.
- [Parcourir les dépôts](remote_urls.md#browse-a-repository-in-read-only-mode) : Accédez à un dépôt GitLab en mode lecture seule sans le cloner.

Lorsque vous affichez un projet GitLab dans VS Code, l'extension vous affiche des informations sur votre branche actuelle :

- Le statut du pipeline CI/CD le plus récent de la branche.
- Un lien vers la merge request pour cette branche.
- Si la merge request inclut un [modèle de fermeture de ticket](../../user/project/issues/managing_issues.md#closing-issues-automatically), un lien vers le ticket.

## Panneaux de l'extension GitLab {#gitlab-extension-panels}

L'extension inclut les fonctionnalités suivantes :

- Dans la barre latérale gauche, **GitLab** ({{< icon name="tanuki" >}}) : Gérez les tickets et les merge requests, exécutez des commandes CI/CD, affichez le statut du pipeline et effectuez des analyses de sécurité. Vous pouvez également étendre votre vue avec des [requêtes personnalisées](custom_queries.md).
- Dans la barre latérale gauche, **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}) :
  - L'onglet discussion : Interagissez avec GitLab Duo Agentic Chat, ou utilisez la liste déroulante **Nouvelle discussion** ({{< icon name="duo-chat-new" >}}) pour sélectionner un agent fondamental ou un agent personnalisé avec lequel travailler.
  - L'onglet flows : Utilisez le flow Software Development. En savoir plus sur la [différence entre Chat et le flow](../../user/duo_agent_platform/flows/foundational_flows/software_development.md#flow-and-chat-comparison).
- Dans la barre d'état, **Duo** ({{< icon name="tanuki-ai" >}}) : Vérifiez le statut des fonctionnalités de GitLab Duo Code Suggestions et examinez les suggestions dans votre fichier pendant que vous rédigez du code.
- Dans la barre latérale gauche, **GitLab Duo Chat** ({{< icon name="duo-chat" >}}) : Interagissez avec GitLab Duo Non-Agentic Chat.

Si ces fonctionnalités n'apparaissent pas, consultez la section [dépannage](troubleshooting.md#gitlab-duo-features-are-unavailable) pour obtenir de l'aide.

## Personnaliser les raccourcis clavier {#customize-keyboard-shortcuts}

Vous pouvez attribuer différents raccourcis clavier pour **Accept Inline Suggestion**, **Accept Next Word Of Inline Suggestion** ou **Accept Next Line Of Inline Suggestion** :

1. Dans VS Code, exécutez la commande `Preferences: Open Keyboard Shortcuts`.
1. Trouvez le raccourci que vous souhaitez modifier et sélectionnez **Change keybinding** ({{< icon name="pencil" >}}).
1. Attribuez vos raccourcis préférés à **Accept Inline Suggestion**, **Accept Next Word Of Inline Suggestion** ou **Accept Next Line Of Inline Suggestion**.
1. Appuyez sur <kbd>Enter</kbd> pour enregistrer vos modifications.

## Mettre à jour l'extension {#update-the-extension}

Pour mettre à jour votre extension vers la dernière version :

1. Dans Visual Studio Code, accédez à **Paramètres** > **Extensions**.
1. Recherchez **GitLab** publié par **GitLab (`gitlab.com`)**.
1. Depuis **Extension : GitLab**, sélectionnez **Update to {later version}**.
1. Facultatif. Pour activer les mises à jour automatiques à l'avenir, sélectionnez **Auto-Update**.

## Installer la version pré-release {#install-the-pre-release-version}

GitLab publie des versions pré-release de l'extension sur le VS Code Extension Marketplace.

Pour installer la version pré-release :

1. Ouvrez VS Code.
1. Sous **Extensions** > **GitLab**, sélectionnez **Switch to Pre-release Version**.
1. Sélectionnez **Restart Extensions**.

## Vérifier le statut de GitLab Duo {#check-gitlab-duo-status}

1. Dans Visual Studio Code, dans la barre d'état inférieure, sélectionnez l'icône GitLab ({{< icon name="tanuki" >}}).
1. Un menu s'ouvre sous la barre de recherche VS Code, et l'extension GitLab pour VS Code affiche le statut. Les erreurs éventuelles sont affichées à côté de **État :**.

Pour GitLab Duo Non-Agentic Chat, vous pouvez également vérifier le [statut du Chat](../../user/gitlab_duo_chat/_index.md#check-the-status-of-chat).

## Sujets connexes {#related-topics}

- [Versions de l'extension GitLab pour VS Code](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases)
- [Considérations de sécurité pour les extensions d'éditeur](../security_considerations.md)
- [Commandes de la palette de commandes](settings.md#command-palette-commands)
- [Dépannage de l'extension GitLab pour VS Code](troubleshooting.md)
- [Télécharger l'extension GitLab pour VS Code](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
- [Code source](https://gitlab.com/gitlab-org/gitlab-vscode-extension/) de l'extension
- [Documentation du serveur de langage GitLab](../language_server/_index.md)

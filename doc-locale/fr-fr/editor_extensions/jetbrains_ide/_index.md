---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connectez-vous à GitLab Duo et utilisez-le dans les IDE JetBrains.
title: Plugin GitLab Duo pour les IDE JetBrains
---

Le [plugin GitLab Duo](https://plugins.jetbrains.com/plugin/22325-gitlab-duo) intègre GitLab Duo aux IDE JetBrains comme IntelliJ, PyCharm, GoLand, Webstorm et Rubymine.

Le plugin inclut les fonctionnalités suivantes :

- Dans la barre des fenêtres d'outils de droite, **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}) :
  - L'onglet discussion : Interagissez avec GitLab Duo Agentic Chat, ou utilisez la liste déroulante **Nouvelle discussion** ({{< icon name="duo-chat-new" >}}) pour sélectionner un agent personnalisé ou un agent fondamental avec lequel travailler.
  - L'onglet flows : Utilisez le flow Software Development. En savoir plus sur la [différence entre le Chat et le flow](../../user/duo_agent_platform/flows/foundational_flows/software_development.md#flow-and-chat-comparison).
- Dans la barre de statut, **Duo** ({{< icon name="tanuki-ai" >}}) : Vérifiez le statut des fonctionnalités de GitLab Duo Code Suggestions et consultez les suggestions dans votre fichier pendant que vous rédigez du code.
- Dans la barre des fenêtres d'outils de droite, **GitLab Duo Non-Agentic Chat** ({{< icon name="duo-chat" >}}) : Interagissez avec GitLab Duo Non-Agentic Chat. Ou sélectionnez du code, puis, dans la barre d'outils flottante, sélectionnez **GitLab Duo Quick Chat** ({{< icon name="tanuki-ai" >}}) pour des conversations en ligne.

Pour commencer, [installez et configurez](setup.md) le plugin.

## Utilisation avec le développement à distance {#use-with-remote-development}

Le plugin GitLab Duo fonctionne avec JetBrains Remote Development lorsqu'il est installé sur la machine hôte (serveur distant).

> [!warning]
> Si vous utilisez le développement à distance, installez le plugin uniquement sur la machine hôte. Si vous installez également le plugin sur la machine cliente (locale), les fonctionnalités de GitLab Duo ne fonctionneront pas dans votre IDE. Pour obtenir des informations sur l'installation de plugins dans des environnements de développement à distance, consultez la documentation JetBrains :

- [Installer des plugins dans des projets distants](https://www.jetbrains.com/help/idea/work-inside-remote-project.html#plugins).
- [Ajouter des plugins aux Dev Containers](https://www.jetbrains.com/help/idea/customizing-devcontainer-json-file.html#add_plugins).

## Activer les fonctionnalités expérimentales ou en version bêta {#enable-experimental-or-beta-features}

Certaines fonctionnalités du plugin sont en version expérimentale ou en version bêta. Pour les utiliser, vous devez les activer explicitement :

1. Accédez à la barre de menu supérieure de votre IDE et sélectionnez **Paramètres**, ou :
   - MacOS : appuyez sur <kbd>Command</kbd>+<kbd>,</kbd>
   - Windows ou Linux : appuyez sur <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>S</kbd>
1. Dans la barre latérale gauche, développez **Outils**, puis sélectionnez **GitLab Duo**.
1. Sélectionnez **Enable Experiment or BETA features**.
1. Pour appliquer les modifications, redémarrez votre IDE.

## Mettre à jour l'extension {#update-the-extension}

Pour mettre à jour votre extension vers la dernière version :

1. Dans votre IDE JetBrains, accédez à **Paramètres** > **Plugins**.
1. Depuis **Marketplace**, sélectionnez **GitLab Duo** publié par **GitLab, Inc.**.
1. Sélectionnez **Mise à jour** pour passer à la dernière version du plugin.

## Activer la télémétrie {#enable-telemetry}

Le plugin GitLab Duo utilise les paramètres de télémétrie de votre IDE JetBrains pour envoyer des informations d'utilisation et d'erreurs à GitLab. Pour activer la télémétrie dans votre IDE JetBrains :

1. Accédez à la barre de menu supérieure de votre IDE et sélectionnez **Paramètres**. Par exemple, dans PyCharm, sélectionnez **PyCharm** > **Paramètres**.
1. Dans la barre latérale gauche, développez **Outils**, puis sélectionnez **GitLab Duo**.
1. Sous **Paramètres avancés**, cochez la case **Enable telemetry**.
1. Sélectionnez **OK** ou **Appliquer** pour enregistrer vos modifications.

## Intégration avec 1Password CLI {#integrate-with-1password-cli}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/291) dans GitLab Duo 2.1 pour GitLab 16.11 et versions ultérieures.

{{< /history >}}

Vous pouvez configurer le plugin pour utiliser des références secrètes 1Password à des fins d'authentification, plutôt que de coder en dur des jetons d'accès personnels.

Prérequis :

- L'application de bureau [1Password](https://1password.com) est installée.
- L'outil [1Password CLI](https://developer.1password.com/docs/cli/get-started/) est installé.

Pour intégrer le plugin GitLab Duo pour les IDE JetBrains avec le 1Password CLI :

1. Authentifiez-vous auprès de GitLab. L'une ou l'autre des options :
   - [Installez le `glab`](https://docs.gitlab.com/cli/#install-the-cli) CLI et configurez le [plugin shell 1Password](https://developer.1password.com/docs/cli/shell-plugins/gitlab/).
   - Suivez les [étapes de configuration](setup.md) du plugin GitLab Duo pour les IDE JetBrains.
1. Ouvrez l'élément 1Password.
1. [Copiez la référence secrète](https://developer.1password.com/docs/cli/secret-references/#step-1-copy-secret-references).

   Si vous utilisez le plugin shell 1Password `gitlab`, le jeton est stocké comme mot de passe sous `"op://Private/GitLab Personal Access Token/token"`.

Depuis l'IDE :

1. Accédez à la barre de menu supérieure de votre IDE et sélectionnez **Paramètres**.
1. Dans la barre latérale gauche, développez **Outils**, puis sélectionnez **GitLab Duo**.
1. Sous **Authentification**, sélectionnez l'onglet **1Password CLI**.
1. Sélectionnez **Integrate with 1Password CLI**.
1. Facultatif. Pour **Secret reference**, collez la référence secrète copiée depuis 1Password.
1. Facultatif. Pour vérifier vos informations d'identification, sélectionnez **Verify setup**.
1. Sélectionnez **OK** ou **Enregistrer**.

## Signaler des problèmes liés au plugin {#report-issues-with-the-plugin}

Vous pouvez signaler tout problème, bug ou demande de fonctionnalité dans le [`gitlab-jetbrains-plugin` issue tracker](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues). Utilisez le modèle `Bug` ou `Feature Proposal`.

Si vous rencontrez une erreur lors de l'utilisation de GitLab Duo, vous pouvez également la signaler avec l'outil de signalement d'erreurs intégré à votre IDE :

1. Pour accéder à l'outil, procédez de l'une des façons suivantes :
   - Lorsqu'une erreur se produit, dans le message d'erreur, sélectionnez **See details and submit report**.
   - Dans la barre de statut, en bas à droite, sélectionnez le point d'exclamation.
1. Dans la boîte de dialogue **IDE Internal Errors**, décrivez l'erreur.
1. Sélectionnez **Report and clear all**.
1. Votre navigateur ouvre un formulaire de ticket GitLab, prérempli avec des informations de débogage.
1. Suivez les instructions du modèle de ticket pour renseigner la description, en fournissant autant de contexte que possible.
1. Sélectionnez **Créer un ticket** pour déposer le rapport de bug.

## Sujets connexes {#related-topics}

- [Releases du plugin GitLab Duo pour les IDE JetBrains](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/releases)
- [Considérations de sécurité pour les extensions d'éditeur](../security_considerations.md)
- [Résolution des problèmes JetBrains](jetbrains_troubleshooting.md)
- [Documentation du serveur de langage GitLab](../language_server/_index.md)
- [Tickets ouverts pour ce plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/)
- [Documentation du plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/blob/main/README.md)
- [Voir le code source](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin)

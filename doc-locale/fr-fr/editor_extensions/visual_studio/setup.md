---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connectez-vous et utilisez GitLab Duo dans Visual Studio.
title: "Installer et configurer l'extension GitLab pour Visual Studio"
---

Pour obtenir l'extension, utilisez l'une des méthodes suivantes :

- Dans Visual Studio, sélectionnez **Extensions** dans la barre d'activité et recherchez `GitLab for Visual Studio`.
- Depuis le [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio).
- Depuis GitLab, soit depuis la [liste des releases](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/releases), soit en [téléchargeant la dernière version](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/releases/permalink/latest/downloads/GitLab.Extension.vsix) directement.

L'extension nécessite :

- Visual Studio 2022 version 17.6 ou ultérieure (AMD64 ou Arm64).
- Le composant [IntelliCode](https://visualstudio.microsoft.com/services/intellicode/) pour Visual Studio.
- GitLab version 16.1 ou ultérieure.
  - GitLab Duo Code Suggestions nécessite GitLab version 16.8 ou ultérieure.
- Vous n'utilisez pas Visual Studio pour Mac, car il n'est pas pris en charge.

Aucune nouvelle donnée supplémentaire n'est collectée pour activer cette fonctionnalité. Les données privées non publiques des clients GitLab ne sont pas utilisées comme données d'entraînement. En savoir plus sur la [gouvernance des données de Gemini Enterprise Agent Platform](https://docs.cloud.google.com/gemini-enterprise-agent-platform/resources/zero-data-retention).

## Se connecter à GitLab {#connect-to-gitlab}

Après avoir installé l'extension, connectez-la à votre compte GitLab en créant un jeton d'accès personnel et en vous authentifiant auprès de GitLab.

### Créer un jeton d'accès personnel {#create-a-personal-access-token}

Si vous utilisez GitLab Self-Managed, créez un jeton d'accès personnel.

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Jetons d'accès personnel**.
1. Sélectionnez **Ajouter un jeton**.
1. Saisissez un nom, une description et une date d'expiration.
1. Sélectionnez les portées `api` et `read_user`.
1. Sélectionnez **Create personal access token**.

### S'authentifier avec GitLab {#authenticate-with-gitlab}

Pour s'authentifier avec GitLab :

1. Dans Visual Studio, dans la barre supérieure, accédez à **Outils** > **Options** > **GitLab**.
1. Dans la zone de texte **Jeton d'accès**, collez votre jeton. Le jeton n'est pas affiché et n'est pas accessible aux autres utilisateurs.
1. Dans la zone de texte **GitLab URL**, saisissez l'URL de votre instance GitLab. Pour GitLab.com, utilisez `https://gitlab.com`.

## Activer la télémétrie {#enable-telemetry}

L'extension GitLab utilise les paramètres de télémétrie de Visual Studio pour envoyer des informations d'utilisation et d'erreur à GitLab. Pour activer la télémétrie dans GitLab pour Visual Studio :

1. Dans Visual Studio, dans la barre supérieure, accédez à **Outils** > **Options**.
1. Dans la barre latérale gauche, développez **GitLab** et sélectionnez **Général**.
1. Dans la liste déroulante **Enable telemetry**, sélectionnez **Vrai**.
1. Sélectionnez **OK**.

## Configurer l'extension {#configure-the-extension}

Cette extension fournit des commandes personnalisées que vous pouvez utiliser avec GitLab. La plupart des commandes n'ont pas de raccourcis clavier par défaut afin d'éviter les conflits avec votre configuration Visual Studio existante.

| Nom de la commande                          | Raccourci clavier par défaut                   | Description |
|---------------------------------------|---------------------------------------------|-------------|
| `GitLab.ToggleCodeSuggestions`        | Aucune                                        | Activer ou désactiver Code Suggestions. |
| `GitLab.OpenDuoChat`                  | Aucune                                        | Ouvrir GitLab Duo Chat. |
| `GitLab.GitLabDuoNextSuggestions`     | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>N</kbd> | Passer à la suggestion de code suivante. |
| `GitLab.GitLabDuoPreviousSuggestions` | Aucune                                        | Passer à la suggestion de code précédente. |
| `GitLab.GitLabExplainTerminalWithDuo` | <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>E</kbd> | Expliquer le texte sélectionné dans le terminal. |
| `GitLabDuoChat.ExplainCode`           | Aucune                                        | Expliquer le code sélectionné. |
| `GitLabDuoChat.Fix`                   | Aucune                                        | Corriger les problèmes du code sélectionné. |
| `GitLabDuoChat.GenerateTests`         | Aucune                                        | Générer des tests pour le code sélectionné. |
| `GitLabDuoChat.Refactor`              | Aucune                                        | Refactoriser le code sélectionné. |

Vous pouvez accéder aux commandes personnalisées de l'extension avec des raccourcis clavier, que vous pouvez personnaliser :

1. Dans la barre supérieure, accédez à **Outils** > **Options**.
1. Accédez à **Environnement** > **Keyboard**. Recherchez `GitLab.`.
1. Sélectionnez une commande et attribuez-lui un raccourci clavier.

### Configurer GitLab Duo {#configure-gitlab-duo}

Les fonctionnalités de GitLab Duo sont activées par défaut lorsque vous remplissez les prérequis :

- Pour les fonctionnalités agentiques, vous remplissez les prérequis pour la [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md#prerequisites).
- Vous avez [activé](../../user/gitlab_duo/turn_on_off.md) GitLab Duo.
- Pour les flows, vous avez [activé les flows par défaut](../../user/duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off).
- Votre projet se trouve dans un [espace de nommage de groupe](../../user/namespace/_index.md).
- Vous avez défini un [espace de nommage GitLab Duo par défaut](../../user/profile/preferences.md#namespace-resolution-in-your-local-environment) ou vous avez ouvert un projet disposant d'un accès à GitLab Duo.
- Pour GitLab Duo Code Suggestions, vous [remplissez les prérequis supplémentaires](../../user/project/repository/code_suggestions/set_up.md#prerequisites).

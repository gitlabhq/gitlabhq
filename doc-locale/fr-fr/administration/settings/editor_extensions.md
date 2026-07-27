---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez les extensions de l'éditeur GitLab pour Visual Studio Code, les IDE JetBrains, Visual Studio, Eclipse et Neovim."
title: "Configurer les extensions de l'éditeur"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Configurez les paramètres des extensions de l'éditeur pour votre instance GitLab.

## Créer une application OAuth {#create-an-oauth-application}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/2738) dans GitLab pour VS Code 6.47.0.

{{< /history >}}

Vous pouvez configurer les extensions de l'éditeur pour vous connecter et vous authentifier auprès de GitLab à l'aide d'un identifiant d'application OAuth. Les étapes de configuration diffèrent selon votre IDE.

### VS Code {#vs-code}

Pour créer une application OAuth pour VS Code :

1. Créez une [application à l'échelle de l'instance](../../integration/oauth_provider.md#create-an-instance-wide-application).
1. Dans **Redirect URI**, saisissez `vscode://gitlab.gitlab-workflow/authentication`.
   - Pour spécifier des IDE supplémentaires comme Code Insiders ou Cursor, ajoutez plusieurs URI de redirection séparés par des sauts de ligne.
1. Sélectionnez la portée `api`.
1. Sélectionnez **Envoyer**.
1. Développez **Limites de débit des API obsolètes**.

### IDE JetBrains {#jetbrains-ides}

Pour créer une application OAuth pour les IDE JetBrains :

1. Créez une [application à l'échelle de l'instance](../../integration/oauth_provider.md#create-an-instance-wide-application).
1. Dans **Redirect URI**, saisissez `http://127.0.0.1/api/oauth/gitlab/authorization`.
1. Sélectionnez la portée `api`.
1. Sélectionnez **Envoyer**.
1. Copiez l'**Identifiant de l'application**. Utilisez-le lors de la configuration du plugin GitLab Duo dans votre IDE JetBrains.

## Exiger une version minimale du serveur de langages {#require-a-minimum-language-server-version}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/541744) dans GitLab 18.1 [avec un flag](../feature_flags/_index.md) nommé `enforce_language_server_version`. Désactivée par défaut. Désactivé par défaut.

{{< /history >}}

> [!flag]
> Sur GitLab Self-Managed, cette fonctionnalité n'est pas disponible par défaut. Pour la rendre disponible, un administrateur peut [activer le feature flag](../feature_flags/_index.md) nommé `enforce_language_server_version`. Sur GitLab.com, cette fonctionnalité est disponible mais ne peut être configurée que par les administrateurs de GitLab.com. Sur GitLab Dedicated, cette fonctionnalité est disponible.

Par défaut, n'importe quelle version du serveur de langages GitLab peut se connecter à votre instance GitLab lorsque les jetons d'accès personnel sont activés. Pour bloquer les requêtes provenant de clients sur des versions antérieures, configurez une version minimale du serveur de langages. Les clients antérieurs à la version minimale autorisée du serveur de langages reçoivent une erreur d'API.

Prérequis :

- Vous devez être administrateur.

  ```ruby
  # For a specific user
  Feature.enable(:enforce_language_server_version, User.find(1))

  # For this GitLab instance
  Feature.enable(:enforce_language_server_version)
  ```

Pour imposer une version minimale du serveur de langages GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Extensions de l'Éditeur**.
1. Cochez **Restrictions du serveur de langages activées**.
1. Sous **Version minimale du client du serveur de langages GitLab**, saisissez une version valide du serveur de langages GitLab.

Pour autoriser tous les clients du serveur de langages GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Extensions de l'Éditeur**.
1. Décochez **Restrictions du serveur de langages activées**.
1. Sous **Version minimale du client du serveur de langages GitLab**, saisissez une version valide du serveur de langages GitLab.

> [!note]
> Autoriser toutes les requêtes n'est pas recommandé. Cela peut provoquer des incompatibilités si votre version de GitLab est en avance sur votre version d'extension. Vous devriez mettre à jour vos extensions pour bénéficier des dernières améliorations de fonctionnalités, correctifs de bogues et correctifs de sécurité.

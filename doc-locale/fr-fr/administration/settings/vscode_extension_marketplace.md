---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez la Marketplace d'extensions VS Code pour les fonctionnalités de l'instance GitLab Self-Managed."
title: "Configurer la Marketplace d'extensions VS Code"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

La Marketplace d'extensions VS Code fournit un accès aux extensions qui améliorent les fonctionnalités du Web IDE et des workspaces. Les administrateurs peuvent configurer l'accès à la marketplace pour l'ensemble de l'instance.

> [!note]
> Pour accéder à la Marketplace d'extensions VS Code, votre navigateur doit pouvoir accéder à l'hôte d'assets `*.cdn.web-ide.gitlab-static.net`. Cette exigence de sécurité garantit que les extensions tierces s'exécutent de manière isolée et ne peuvent pas accéder à votre compte.

## Accéder aux paramètres de la Marketplace d'extensions VS Code {#access-vs-code-extension-marketplace-settings}

Prérequis :

- Vous devez être administrateur.

Pour accéder aux paramètres de la Marketplace d'extensions VS Code :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Marketplace d'extensions VS Code**.

## Activer le registre d'extensions {#enable-the-extension-registry}

Par défaut, l'instance GitLab est configurée pour utiliser le registre d'extensions [Open VSX](https://open-vsx.org/). Pour activer la marketplace d'extensions avec cette configuration par défaut :

Prérequis :

- Vous devez être administrateur.

Pour activer la marketplace d'extensions :

1. Accédez aux [paramètres de la Marketplace d'extensions VS Code](#access-vs-code-extension-marketplace-settings).
1. Activez le bouton bascule **Activer la marketplace d'extensions**.

## Modifier le registre d'extensions {#modify-the-extension-registry}

Prérequis :

- Vous devez être administrateur.

Pour modifier le registre d'extensions :

1. Accédez aux [paramètres de la Marketplace d'extensions VS Code](#access-vs-code-extension-marketplace-settings).
1. Développez **Paramètres du registre d'extensions**.
1. Désactivez le bouton bascule **Utiliser le registre d'extensions Open VSX**.
1. Saisissez les URL complètes pour l'**URL du service**, l'**URL de l'élément** et le **Modèle d'URL de ressource** du registre d'extensions VS Code.
1. Sélectionnez **Sauvegarder les modifications**.

Après avoir modifié le registre d'extensions :

- Les sessions Web IDE ou workspace actives continuent d'utiliser leur registre précédent jusqu'à leur actualisation.
- Tous les utilisateurs doivent [intégrer leur compte au nouveau registre](../../user/profile/preferences.md#integrate-with-the-extension-marketplace) avant de pouvoir utiliser des extensions.

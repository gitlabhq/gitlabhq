---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
title: Personnaliser le message de la page d’aide
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Dans les grandes organisations, il est utile de disposer d'informations sur les personnes à contacter ou sur les ressources disponibles pour obtenir de l'aide. Vous pouvez personnaliser et afficher ces informations sur la page `/help` de GitLab.

## Prérequis {#prerequisites}

Vous devez disposer d'un accès administrateur.

## Ajouter un message d'aide à la page d'aide {#add-a-help-message-to-the-help-page}

Vous pouvez ajouter un message d'aide, qui s'affiche en haut de la page `/help` de GitLab (par exemple, <https://gitlab.com/help>) :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Page d'aide**.
1. Dans **Texte supplémentaire à afficher sur la page d'aide**, saisissez les informations que vous souhaitez afficher sur `/help`.
1. Sélectionnez **Sauvegarder les modifications**.

Vous pouvez maintenant voir le message sur `/help`.

> [!note]
> Par défaut, `/help` est visible par les utilisateurs non authentifiés. Cependant, si le [niveau de visibilité **Public**](visibility_and_access_controls.md#restrict-visibility-levels) est restreint, `/help` n'est visible que par les utilisateurs authentifiés.

## Ajouter un message d'aide à la page de connexion {#add-a-help-message-to-the-sign-in-page}

{{< history >}}

- Le texte supplémentaire à afficher sur la page de connexion est [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/410885) depuis GitLab 17.0.

{{< /history >}}

Pour ajouter un message d'aide à la page de connexion, [personnalisez vos pages de connexion et d'inscription](../appearance.md#customize-your-sign-in-and-register-pages).

## Masquer les entrées liées au marketing de la page d'aide {#hide-marketing-related-entries-from-the-help-page}

Les entrées liées au marketing de GitLab sont parfois affichées sur la page d'aide. Pour masquer ces entrées :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Page d'aide**.
1. Cochez la case **Masquer les entrées liées au marketing de la page d'Aide**.
1. Sélectionnez **Sauvegarder les modifications**.

## Définir une URL personnalisée pour la page de support {#set-a-custom-support-page-url}

Vous pouvez spécifier une URL personnalisée vers laquelle les utilisateurs sont redirigés lorsqu'ils :

- Sélectionnez **Aide** > **Support**.
- Sélectionnez **Consultez notre site Web pour obtenir de l'aide** sur la page d'aide.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Page d'aide**.
1. Dans la zone de texte **URL de la page de support**, saisissez l'URL.
1. Sélectionnez **Sauvegarder les modifications**.

## Rediriger les pages `/help` {#redirect-help-pages}

Vous pouvez rediriger tous les liens `/help` vers une destination répondant aux [exigences nécessaires](#destination-requirements).

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Page d'aide**.
1. Dans la zone de texte **URL des pages de documentation**, saisissez l'URL.
1. Sélectionnez **Sauvegarder les modifications**.

Si la zone de texte **URL des pages de documentation** est vide, l'instance GitLab affiche une version de base de la documentation issue du [répertoire `doc`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/doc) de GitLab.

### Exigences de destination {#destination-requirements}

Lors de la redirection de `/help`, GitLab :

- Utilise l'URL spécifiée comme URL de base pour la redirection.
- Construit l'URL complète en :
  - Ajoutant le numéro de version (`${VERSION}`).
  - Ajoutant le chemin de la documentation.
  - Supprimant toutes les extensions de fichier `.md`.

Par exemple, si l'URL est définie sur `https://docs.gitlab.com`, les requêtes pour `/help/administration/settings/help_page.md` sont redirigées vers : `https://docs.gitlab.com/${VERSION}/administration/settings/help_page`.

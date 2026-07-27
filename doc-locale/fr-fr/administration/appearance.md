---
stage: Growth
group: Engagement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: "Personnalisez l'apparence de votre instance GitLab, notamment les logos, les favicons, les pages de connexion, les paramètres d'application Web progressive, les messages système et les thèmes de couleurs."
title: Apparence de GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez mettre à jour vos paramètres pour modifier l'apparence de votre instance.

## Prérequis {#prerequisites}

Vous devez disposer d'un accès administrateur.

## Accéder aux paramètres d'apparence {#access-appearance-settings}

Pour ouvrir les paramètres **Apparence** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Apparence**.

## Personnaliser votre bouton de page d'accueil {#customize-your-homepage-button}

Personnalisez l'apparence de votre bouton de page d'accueil.

Le bouton de page d'accueil est situé dans le coin supérieur gauche de la barre latérale gauche. Remplacez le logo GitLab par défaut {{< icon name="tanuki" >}} par n'importe quelle image.

- Le fichier doit faire moins de 1 Mo.
- L'image doit faire 24 pixels de haut. Les images de plus de 24 pixels de haut sont automatiquement redimensionnées.

Pour personnaliser l'image de l'icône de votre page d'accueil :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Apparence**.
1. Sous **Barre de navigation**, sélectionnez **Choisir un fichier**.
1. En bas de la page, sélectionnez **Mettre à jour les paramètres d'apparence**.

Les e-mails de statut de pipeline affichent également votre logo personnalisé. Cependant, certaines applications de messagerie ne prennent pas en charge les images SVG. Si votre image personnalisée est au format SVG, les e-mails de pipeline affichent le logo par défaut.

## Personnaliser le favicon {#customize-the-favicon}

Personnalisez l'apparence du favicon. Un favicon est l'icône d'un site Web qui s'affiche dans les onglets de votre navigateur. Le logo GitLab {{< icon name="tanuki" >}} est le favicon par défaut du navigateur et du statut CI/CD. Remplacez l'icône par défaut par n'importe quelle image de `32 x 32` pixels et au format `.png` ou `.ico`.

Pour modifier le favicon :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Apparence**.
1. Sous **Favicon**, sélectionnez **Choisir un fichier**.
1. En bas de la page, sélectionnez **Mettre à jour les paramètres d'apparence**.

## Personnaliser le nom du site {#customize-the-site-name}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228333) dans GitLab 18.11.

{{< /history >}}

Vous pouvez ajouter votre propre nom de site personnalisé au titre de la page dans l'onglet du navigateur. Par exemple, si votre nom de site est `MyCompany`, sur la page d'accueil, le titre de la page dans l'onglet du navigateur affiche `Home · GitLab · MyCompany`.

La longueur maximale d'un nom de site est de 255 caractères.

Pour modifier le nom du site :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Apparence**.
1. Sous **Nom du site**, saisissez le nouveau nom du site.
1. En bas de la page, sélectionnez **Mettre à jour les paramètres d'apparence**.

## Ajouter des messages d'en-tête et de pied de page système {#add-system-header-and-footer-messages}

{{< history >}}

- Case à cocher **Activer l'en-tête et le pied de page dans les courriels** [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/344819) dans GitLab 15.9.

{{< /history >}}

Ajoutez un petit message d'en-tête, un petit message de pied de page, ou les deux, à l'interface de votre instance GitLab. Ces messages s'affichent sur tous les projets et toutes les pages de l'instance, tels que les pages de connexion et d'inscription.

- Vous pouvez mettre en italique, en gras ou ajouter des liens à votre message avec Markdown.
- Les listes, images et citations Markdown ne sont pas prises en charge car les messages système doivent tenir sur une seule ligne.

Pour ajouter un message d'en-tête système, un message de pied de page, ou les deux :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Apparence**.
1. Accédez à la section **En‐tête et pied de page du système**.
1. Remplissez les champs.
1. Facultatif. Cochez la case **Activer l'en-tête et le pied de page dans les courriels**. Ajoutez vos messages système à tous les e-mails envoyés par votre instance GitLab.
1. En bas de la page, sélectionnez **Mettre à jour les paramètres d'apparence**.

Par défaut, le texte de l'en-tête et du pied de page du système est du texte blanc sur fond orange. Pour personnaliser les couleurs des messages :

- Accédez à la section **En‐tête et pied de page du système** et sélectionnez **Personnaliser les couleurs**.

## Personnaliser vos pages de connexion et d'inscription {#customize-your-sign-in-and-register-pages}

<!-- vale gitlab_base.OxfordComma = NO -->
Personnalisez le titre, la description et le logo sur la page de connexion et d'inscription. Par défaut, le logo de la page d'inscription est situé à gauche de la page, entre le titre et la description.
<!-- vale gitlab_base.OxfordComma = YES -->

Pour personnaliser les titres ou descriptions de vos pages de connexion et d'inscription :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Apparence**.
1. Accédez à la section **Pages de Connexion/inscription**.
1. Remplissez les champs. Vous pouvez formater le **Titre** et la **Description** de la page avec Markdown.
1. En bas de la page, sélectionnez **Mettre à jour les paramètres d'apparence**.

Pour personnaliser le logo sur vos pages de connexion et d'inscription :

- Le fichier doit faire moins de 1 Mo.
- L'image doit faire 128 pixels de haut. Les images de plus de 128 pixels de haut sont automatiquement redimensionnées.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Apparence**.
1. Accédez à la section **Pages de Connexion/inscription**.
1. Sous **Logo**, sélectionnez **Choisir un fichier**.
1. En bas de la page, sélectionnez **Mettre à jour les paramètres d'apparence**.

Vous pouvez également ajouter un [message d'aide personnalisé](settings/help_page.md) sous le message de connexion ou ajouter [un message texte de connexion](settings/sign_in_restrictions.md#sign-in-information).

### Désactiver le sélecteur de langue basé sur les cookies {#disable-cookie-based-language-selector}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144484) dans GitLab 16.10.

{{< /history >}}

> [!flag]
> Sur GitLab Self-Managed, cette fonctionnalité n'est pas disponible par défaut. Pour la rendre disponible, un administrateur peut [activer le feature flag](feature_flags/_index.md) nommé `disable_preferred_language_cookie`. Sur GitLab.com et GitLab Dedicated, cette fonctionnalité n'est pas disponible.

Vous pouvez supprimer le sélecteur de langue basé sur les cookies du pied de page des pages de connexion et d'inscription en activant le feature flag `disable_preferred_language_cookie`.

## Personnaliser l'application Web progressive {#customize-the-progressive-web-app}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/375708) dans GitLab 15.9.

{{< /history >}}

Personnalisez l'icône, le nom d'affichage, le nom court et la description de votre application Web progressive (PWA). Pour plus d'informations, consultez [Progressive Web App](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps).

Pour ajouter un nom et un nom court à une application Web progressive :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Apparence**.
1. Accédez à la section **Application Web Progressive (PWA)**.
1. Remplissez les champs.
   - **Nom** est le nom d'affichage de votre PWA.
   - **Nom court** s'affiche sur les appareils mobiles et les petits écrans.
1. En bas de la page, sélectionnez **Mettre à jour les paramètres d'apparence**.

Pour ajouter une description à une application Web progressive :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Apparence**.
1. Accédez à la section **Application Web Progressive (PWA)**.
1. Remplissez les champs. Vous pouvez formater la **Description** avec Markdown.
1. En bas de la page, sélectionnez **Mettre à jour les paramètres d'apparence**.

Pour personnaliser l'icône de votre application Web progressive :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Apparence**.
1. Accédez à la section **Application Web Progressive (PWA)**.
1. Sous **Icône**, sélectionnez **Choisir un fichier**.
1. En bas de la page, sélectionnez **Mettre à jour les paramètres d'apparence**.

## Instructions pour les membres {#member-guidelines}

Vous pouvez ajouter des instructions pour les membres aux pages des membres de groupe et de projet dans GitLab. Vous pouvez utiliser [Markdown](../user/markdown.md) dans la description.

Les instructions pour les membres sont visibles par les utilisateurs qui disposent de l'[autorisation](../user/permissions.md) de gérer :

- Les membres d'un groupe.
- Les membres d'un projet.

Vous devriez ajouter des instructions pour les membres si vous gérez l'appartenance aux groupes et aux projets en utilisant :

- Des groupes prédéfinis plutôt qu'individuellement.
- Des outils externes.

## Ajouter des instructions à la page de nouveau projet {#add-guidelines-to-the-new-project-page}

Ajoutez un message d'instruction à la **Page de nouveau projet**. Vous pouvez formater votre message avec Markdown. Le message d'instruction s'affiche sous le message **Nouveau projet** et sur le côté gauche de la **Page de nouveau projet**.

Pour ajouter un message d'instruction à la **Page de nouveau projet** :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Apparence**.
1. Accédez à la section **Pages de nouveau projet**.
1. Remplissez les champs. Vous pouvez formater vos instructions avec Markdown.

## Ajouter des instructions pour les images de profil {#add-profile-image-guidelines}

Ajoutez des instructions pour les images de profil.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Apparence**.
1. Accédez à la section **Instructions pour les images de profil**.
1. Remplissez les champs. Vous pouvez formater votre texte avec Markdown.

## Libravatar {#libravatar}

GitLab prend en charge [Libravatar](https://www.libravatar.org) pour les images d'avatar, mais vous devez activer manuellement la prise en charge de Libravatar sur l'instance GitLab. Pour plus d'informations, consultez [Libravatar](libravatar.md) pour utiliser le service.

## Modifier le thème de couleur pour tous les nouveaux utilisateurs {#change-the-color-theme-for-all-new-users}

{{< details >}}

- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Introduit dans GitLab 17.8 : `gitlab_default_theme` peut spécifier une valeur de 1 à 10 pour définir le thème par défaut.
- Thèmes : Light Indigo, Light Blue, Light Green et Light Red [supprimés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200475) dans GitLab 18.4.

{{< /history >}}

Pour [modifier le thème de navigation par défaut](../user/profile/preferences.md#change-the-navigation-theme) pour tous les nouveaux utilisateurs :

1. Ajoutez `gitlab_rails['gitlab_default_theme']` à votre fichier de configuration GitLab situé à `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['gitlab_default_theme'] = 2
   ```

   Ces couleurs sont disponibles :
   <!-- The themes are defined in lib/gitlab/themes.rb -->

   | Valeur | Couleur  |
   | ----- | -----  |
   | 1     | Indigo |
   | 2     | Foncé   |
   | 3     | Clair  |
   | 4     | Bleu   |
   | 5     | Vert  |
   | 9     | Rouge    |

1. [Reconfigurer et redémarrer GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation).

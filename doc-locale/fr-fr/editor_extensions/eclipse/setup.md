---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connectez-vous et utilisez GitLab Duo dans Eclipse.
title: Installer et configurer GitLab pour Eclipse
---

{{< details >}}

- Édition : [Gratuite](../../subscriptions/gitlab_credits.md#for-the-free-tier), GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : Version bêta

{{< /details >}}

{{< history >}}

- [Passage](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163) de la version expérimentale à la version bêta dans GitLab 17.11.
- L'accès à GitLab Duo Non-Agentic Chat a été supprimé pour les clients GitLab Duo Core le 21 mai 2026 dans le cadre de la version GitLab 19.0, avec un feature flag nommé `no_duo_classic_for_duo_core_users`. Activé par défaut.

{{< /history >}}

> [!disclaimer]

## Installer le plug-in GitLab pour Eclipse {#install-the-gitlab-for-eclipse-plugin}

Prérequis :

- Eclipse 4.33 et versions ultérieures.
- GitLab version 16.8 ou ultérieure.

Pour installer GitLab pour Eclipse :

1. Ouvrez votre IDE Eclipse et votre navigateur web préféré.
1. Dans votre navigateur web, accédez à la page du [plug-in GitLab pour Eclipse](https://marketplace.eclipse.org/content/gitlab-eclipse) dans Eclipse Marketplace.
1. Sur la page du plug-in, sélectionnez **Installer**, puis faites glisser votre souris vers votre IDE Eclipse.
1. Dans la fenêtre **Eclipse Marketplace**, sélectionnez la catégorie **GitLab For Eclipse**.
1. Sélectionnez **Confirm >**, puis sélectionnez **Finish**.
1. Si la fenêtre **Trust Authorities** s'affiche, sélectionnez le site de mise à jour **`https://gitlab.com`** et sélectionnez **Trust Selected**.
1. Sélectionnez **Restart Now**.

Si Eclipse Marketplace n'est pas disponible, suivez les [instructions d'installation d'Eclipse](https://help.eclipse.org/latest/index.jsp?topic=%2Forg.eclipse.platform.doc.user%2Ftasks%2Ftasks-124.htm) pour ajouter un nouveau site logiciel. Pour **Work with**, utilisez `https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/releases/permalink/latest/downloads/`.

## S'authentifier avec GitLab {#authenticate-with-gitlab}

Après avoir installé le plug-in, authentifiez-vous et connectez-le à votre compte GitLab.

Prérequis :

- Un [jeton d'accès personnel](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) avec la portée `api`.

Pour s'authentifier avec GitLab :

1. Dans votre IDE, ouvrez les préférences :
   - Pour macOS, sélectionnez **Eclipse** > **Paramètres**.
   - Sur Windows ou Linux, sélectionnez **Window** > **Préférences**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sous **Connexion**, saisissez l'URL de votre instance GitLab. Pour GitLab.com, utilisez `https://gitlab.com`.
1. Sous **Authentification**, saisissez votre jeton d'accès personnel. Votre jeton est masqué et stocké à l'aide du stockage sécurisé d'Eclipse.
1. Sélectionnez **Verify Setup**.
1. Sélectionnez **Apply and Close**.

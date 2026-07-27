---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connectez-vous et utilisez GitLab Duo dans Eclipse.
title: GitLab pour Eclipse
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

Le plugin GitLab pour Eclipse s'intègre à GitLab Duo pour offrir les fonctionnalités suivantes :

- [GitLab Duo Code Suggestions](../../user/project/repository/code_suggestions/_index.md)
- [GitLab Duo Non-Agentic Chat](../../user/gitlab_duo_chat/_index.md). Disponible uniquement pour les utilisateurs de GitLab Duo Pro ou Enterprise, ou de GitLab Duo avec Amazon Q.

Pour installer et configurer le plugin, consultez [l'installation et la configuration](setup.md).

## Mettre à jour le plugin {#update-the-plugin}

Pour mettre à jour votre version du plugin :

1. Dans votre IDE Eclipse, accédez à **Aide** > **Check for Updates**.
1. Dans la boîte de dialogue **Available Updates**, assurez-vous que **GitLab for Eclipse** est sélectionné.
1. Sélectionnez **Suivant**, puis **Finish**, pour mettre à jour le plugin.

## Signaler des problèmes liés au plugin {#report-issues-with-the-plugin}

Vous pouvez signaler tout problème, bug ou demande de fonctionnalité dans le [`gitlab-eclipse-plugin` issue tracker](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues). Utilisez le modèle `Bug` ou `Feature Proposal`.

## Sujets connexes {#related-topics}

- [Releases GitLab pour Eclipse](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/releases)
- [Considérations de sécurité pour les extensions d'éditeur](../security_considerations.md)
- [Résolution des problèmes Eclipse](troubleshooting.md)
- [Documentation du serveur de langage GitLab](../language_server/_index.md)
- [Tickets ouverts pour ce plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/)
- [Voir le code source](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin)

---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Courriel
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez personnaliser une partie du contenu des courriels envoyés depuis votre instance GitLab.

## Logo personnalisé {#custom-logo}

Le logo dans l'en-tête de certains courriels peut être personnalisé ; consultez la [section de personnalisation du logo](../appearance.md#customize-your-homepage-button).

## Inclure le nom de l'auteur dans le corps de l'e-mail de notification {#include-author-name-in-email-notification-email-body}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Par défaut, GitLab remplace l'adresse courriel dans les courriels de notification par l'adresse courriel de l'auteur du ticket, du merge request ou du commentaire. Activez ce paramètre pour inclure l'adresse courriel de l'auteur dans le corps du courriel à la place.

Prérequis :

- Accès administrateur.

Pour inclure l'adresse courriel de l'auteur dans le corps du courriel :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Courriel**.
1. Cochez la case **Inclure le nom de l'auteur dans le corps de l'e-mail de notification**.
1. Sélectionnez **Sauvegarder les modifications**.

## Activer le courriel multipart {#enable-multipart-email}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab peut envoyer des courriels au format multipart (HTML et texte brut) ou en texte brut uniquement.

Pour activer le courriel multipart :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Courriel**.
1. Sélectionnez **Activer l’e-mail multipart**.
1. Sélectionnez **Sauvegarder les modifications**.

## Nom d'hôte personnalisé pour les courriels de commit privés {#custom-hostname-for-private-commit-emails}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Cette option de configuration définit le nom d'hôte du courriel pour les [courriels de commit privés](../../user/profile/_index.md#use-an-automatically-generated-private-commit-email). Par défaut, il est défini sur `users.noreply.YOUR_CONFIGURED_HOSTNAME`.

Pour modifier le nom d'hôte utilisé dans les courriels de commit privés :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Courriel**.
1. Saisissez le nom d'hôte souhaité dans le champ **Nom d'hôte personnalisé (pour les courriels de validation privés)**.
1. Sélectionnez **Sauvegarder les modifications**.

> [!note]
> Une fois le nom d'hôte configuré, chaque courriel de commit privé utilisant le nom d'hôte précédent n'est plus reconnu par GitLab. Cela peut directement entrer en conflit avec certaines [règles de push](../../user/project/repository/push_rules.md) telles que `Check whether author is a GitLab user` et `Check whether committer is the current authenticated user`.

## Texte supplémentaire personnalisé {#custom-additional-text}

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez ajouter du texte supplémentaire au bas de tout courriel envoyé par GitLab. Ce texte supplémentaire peut être utilisé à des fins juridiques, d'audit ou de conformité, par exemple.

Pour ajouter du texte supplémentaire aux courriels :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Courriel**.
1. Saisissez votre texte dans le champ **Texte supplémentaire**.
1. Sélectionnez **Sauvegarder les modifications**.

## Courriels de désactivation d'utilisateur {#user-deactivation-emails}

GitLab envoie des notifications par courriel aux utilisateurs lorsque leur compte a été désactivé.

Pour désactiver ces notifications :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Courriel**.
1. Décochez la case **Activer les courriels de désactivation d'utilisateur**.
1. Sélectionnez **Sauvegarder les modifications**.

### Texte supplémentaire personnalisé dans les courriels de désactivation {#custom-additional-text-in-deactivation-emails}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/355964) dans GitLab 15.9 [avec un feature flag](../feature_flags/_index.md) nommé `deactivation_email_additional_text`. Désactivé par défaut.
- [Activé sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111882) dans GitLab 15.9.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/392761) dans GitLab 16.5. Indicateur de feature flag `deactivation_email_additional_text` supprimé.

{{< /history >}}

Vous pouvez ajouter du texte supplémentaire au bas du courriel que GitLab envoie aux utilisateurs lorsque leur compte est désactivé. Ce texte de courriel est distinct du paramètre [texte supplémentaire personnalisé](#custom-additional-text).

Pour ajouter du texte supplémentaire aux courriels de désactivation :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Courriel**.
1. Saisissez votre texte dans le champ **Texte supplémentaire pour le courriel de désactivation**.
1. Sélectionnez **Sauvegarder les modifications**.

## Courriels d'expiration des jetons d'accès de groupe et de projet aux membres hérités {#group-and-project-access-token-expiry-emails-to-inherited-members}

{{< history >}}

- Notifications aux membres de groupe hérités [introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/463016) dans GitLab 17.7 [avec un feature flag](../feature_flags/_index.md) nommé `pat_expiry_inherited_members_notification`. Désactivé par défaut.
- Feature flag `pat_expiry_inherited_members_notification` [activé par défaut dans GitLab 17.10](https://gitlab.com/gitlab-org/gitlab/-/issues/393772).
- Feature flag `pat_expiry_inherited_members_notification` supprimé dans GitLab `17.11`

{{< /history >}}

Dans GitLab 17.7 et versions ultérieures, les membres de groupe et de projet hérités suivants peuvent recevoir des courriels concernant les jetons d'accès de groupe et de projet arrivant bientôt à expiration, en plus des membres directs de groupe et de projet :

- Pour les groupes, les membres qui héritent du rôle Propriétaire pour ces groupes.
- Pour les projets, les membres du projet qui héritent du rôle Mainteneur ou Propriétaire pour les projets appartenant à ces groupes.

Pour activer les courriels d'expiration de jeton aux membres de groupe et de projet hérités :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Courriel**.
1. Sous **Expiry notification emails about group and project access tokens should be sent to:**, sélectionnez **Tous les membres directs et hérités du groupe ou du projet**.
1. Cochez la case **Enforce this setting for all groups on this instance**.
1. Sélectionnez **Sauvegarder les modifications**.

Pour plus d'informations sur les courriels d'expiration de jeton, consultez :

- Pour les groupes, la [documentation sur les courriels d'expiration des jetons d'accès de groupe](../../user/group/settings/group_access_tokens.md#group-access-token-expiry-emails).
- Pour les projets, la [documentation sur les courriels d'expiration des jetons d'accès au projet](../../user/project/settings/project_access_tokens.md#project-access-token-expiry-emails).

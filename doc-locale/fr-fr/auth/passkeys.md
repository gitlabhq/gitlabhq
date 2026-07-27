---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Clés d'accès"
description: "Authentification sans mot de passe et authentification à deux facteurs (2FA) à l'aide de clés d'accès"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206407) dans GitLab 18.6 [avec un indicateur](../administration/feature_flags/_index.md) nommé `passkeys`. Désactivé par défaut sur GitLab Self-Managed.
- Disponible en général dans GitLab 18.9. Feature flag activé par défaut.
- [Suppression](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230536) du feature flag `passkeys` dans GitLab 19.0.

{{< /history >}}

Les clés d'accès offrent un moyen sécurisé et pratique de se connecter à votre compte GitLab sans utiliser de mots de passe. Les clés d'accès offrent une connexion résistante au hameçonnage tout en protégeant les utilisateurs contre les vulnérabilités liées aux mots de passe faibles et les violations d'informations d'identification.

## Fonctionnement des clés d'accès {#how-passkeys-work}

Les clés d'accès utilisent la cryptographie à clé publique pour vous authentifier de façon sécurisée auprès de GitLab. Lorsque vous créez une clé d'accès :

- Votre appareil génère une paire de clés cryptographiques unique.
- La clé privée reste stockée en sécurité sur votre appareil et n'est jamais partagée.
- GitLab ne stocke que la clé publique, qui ne peut pas être utilisée pour usurper votre identité.
- Lorsque vous vous connectez, votre appareil utilise l'authentification biométrique ou un code PIN pour déverrouiller la clé privée et prouver votre identité.

Cette approche garantit que si les serveurs GitLab sont compromis, les attaquants ne peuvent pas utiliser votre clé d'accès pour accéder à votre compte.

### Considérations de sécurité {#security-considerations}

- Conservez des méthodes d'authentification de sauvegarde : Maintenez toujours des moyens alternatifs pour accéder à votre compte, tels que des codes de récupération ou d'autres méthodes de 2FA.
- Assurez la sécurité de votre appareil : Assurez-vous que votre appareil est protégé par un code PIN fort, un mot de passe ou un verrou biométrique.
- Effectuez des vérifications régulières : Vérifiez régulièrement vos clés d'accès enregistrées et supprimez celles des appareils que vous n'utilisez plus.
- N'utilisez pas d'appareils partagés : Ne configurez pas de clés d'accès sur des appareils partagés ou publics.

## Afficher vos clés d'accès {#view-your-passkeys}

Pour afficher des informations sur vos clés d'accès enregistrées, notamment le nom de la clé d'accès, le type d'appareil et les détails d'utilisation :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Mot de passe et authentification**.
1. Dans la section **Connexion par clé d'accès**, affichez vos clés d'accès.

## Ajouter une clé d'accès {#add-a-passkey}

Prérequis :

- Vous devez disposer d'un appareil compatible avec la norme WebAuthn.
  - Navigateurs de bureau : Chrome, Firefox, Safari et Edge.
  - Appareils mobiles : iOS 16 et versions ultérieures, et Android 9 et versions ultérieures, avec l'authentification biométrique ou les codes PIN d'appareil activés.
  - Clés de sécurité : Clés de sécurité matérielles compatibles avec FIDO2 ou WebAuthn.
- La connexion par clé d'accès ne doit pas être désactivée pour votre [groupe](../user/group/saml_sso/_index.md#disable-password-and-passkey-authentication-for-enterprise-users) ou votre [instance](../administration/settings/sign_in_restrictions.md#password-and-passkey-authentication).

> [!note]
> Les comptes utilisateur créés via un fournisseur d'identité externe peuvent nécessiter la création d'un nouveau mot de passe GitLab. Pour plus d'informations, consultez [les mots de passe pour les comptes authentifiés de manière externe](../user/profile/user_passwords.md#passwords-for-externally-authenticated-accounts).

Pour ajouter une clé d'accès :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Mot de passe et authentification**.
1. Dans la section **Connexion par clé d'accès**, sélectionnez **Ajouter une clé d'accès**.
1. Suivez les instructions sur votre appareil ou navigateur.
1. Saisissez votre mot de passe actuel pour confirmer votre identité.
1. Saisissez un nom pour votre clé d'accès.
1. Sélectionnez **Ajouter une clé d'accès**.

## Se connecter avec une clé d'accès {#sign-in-with-a-passkey}

Pour vous connecter à GitLab avec une clé d'accès, plutôt qu'avec un mot de passe :

1. Accédez à la page de connexion GitLab.

   - Sur GitLab.com, accédez à `https://gitlab.com/users/sign_in`.
   - Sur GitLab Self-Managed, utilisez le domaine de votre instance. Par exemple, `https://gitlab.example.com/users/sign_in`.

1. Sous les options de connexion supplémentaires, sélectionnez **Clé d'accès**.
1. Suivez les instructions sur votre appareil pour vous authentifier à l'aide de votre empreinte digitale, de la reconnaissance faciale ou du code PIN de votre appareil.

## Utiliser une clé d'accès pour l'authentification à deux facteurs {#use-a-passkey-for-two-factor-authentication}

Si vous avez activé l'[authentification à deux facteurs](../user/profile/account/two_factor_authentication.md) (2FA) pour votre compte, les clés d'accès deviennent disponibles en tant qu'option de 2FA supplémentaire et par défaut.

Pour utiliser une clé d'accès comme méthode de 2FA :

1. Accédez à la page de connexion GitLab.

   - Sur GitLab.com, accédez à `https://gitlab.com/users/sign_in`.
   - Sur GitLab Self-Managed, utilisez le domaine de votre instance. Par exemple, `https://gitlab.example.com/users/sign_in`.

1. Saisissez votre nom d'utilisateur et votre mot de passe.
1. Lorsque vous y êtes invité, authentifiez-vous avec votre clé d'accès.
1. Suivez les instructions sur votre appareil pour vous authentifier à l'aide de votre empreinte digitale, de la reconnaissance faciale ou du code PIN de votre appareil.

> [!note]
> Si votre clé d'accès n'est pas disponible sur l'appareil actuel, utilisez plutôt votre méthode de 2FA de sauvegarde.

## Supprimer une clé d'accès {#delete-a-passkey}

Supprimez une clé d'accès si vous n'utilisez plus l'appareil ou si vous souhaitez la remplacer par une nouvelle clé d'accès. Si vous supprimez votre unique clé d'accès, GitLab désactivera également la connexion par clé d'accès pour votre compte.

Pour supprimer une clé d'accès :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Mot de passe et authentification**.
1. Dans la section **Connexion par clé d'accès**, trouvez la clé d'accès que vous souhaitez supprimer.
1. En regard de la clé d'accès, sélectionnez **Supprimer** ({{< icon name="remove" >}}).
1. Dans la boîte de dialogue de confirmation, confirmez la suppression.

   - Si vous avez plusieurs clés d'accès, sélectionnez **Supprimer la clé d'accès**.
   - Si vous avez une seule clé d'accès, sélectionnez **Désactiver la connexion par clé d'accès**.

> [!warning]
> Les clés d'accès supprimées ne peuvent pas être récupérées. Vous devez ajouter une nouvelle clé d'accès si vous souhaitez vous authentifier à nouveau avec l'appareil.

## Dépannage {#troubleshooting}

### Problèmes lors de l'ajout d'une clé d'accès {#problems-adding-a-passkey}

Si vous ne pouvez pas ajouter de clé d'accès :

- Vérifiez que votre appareil et votre navigateur prennent en charge WebAuthn et l'authentification biométrique.
- Assurez-vous que votre navigateur est à jour.
- Vérifiez que vous avez configuré un code PIN d'appareil, une empreinte digitale ou la reconnaissance faciale sur votre appareil.
- Essayez d'utiliser un autre navigateur ou appareil.
- Vérifiez si l'appareil est déjà enregistré en tant que méthode d'authentification à deux facteurs WebAuthn.
  - Si l'appareil est déjà enregistré en tant que méthode d'authentification à deux facteurs WebAuthn :

    1. Supprimez l'appareil WebAuthn de vos méthodes de 2FA.
    1. Enregistrez-le en tant que clé d'accès.
    1. Si vous souhaitez réactiver la 2FA, configurez une méthode de 2FA de sauvegarde (telle qu'une application d'authentification). GitLab ajoute automatiquement votre clé d'accès comme méthode d'authentification à deux facteurs par défaut.

### Impossible de se connecter avec une clé d'accès {#cannot-sign-in-with-passkey}

Si vous ne pouvez pas vous connecter avec votre clé d'accès :

- Assurez-vous d'utiliser le même appareil que celui utilisé pour créer la clé d'accès.
- Vérifiez que votre authentification biométrique ou le code PIN de votre appareil fonctionne.
- Essayez de vider le cache et les cookies de votre navigateur.
- Utilisez votre méthode de 2FA de sauvegarde ou votre mot de passe pour vous connecter, puis vérifiez vos paramètres de clé d'accès.

### Appareil perdu ou remplacé {#lost-or-replaced-device}

Si vous perdez votre appareil ou en obtenez un nouveau, connectez-vous avec votre mot de passe et configurez une nouvelle clé d'accès.

Pour configurer une clé d'accès sur votre nouvel appareil :

1. Connectez-vous à GitLab avec votre mot de passe.
1. Si vous utilisez des clés d'accès comme méthode de 2FA, connectez-vous avec votre méthode de sauvegarde.
1. Supprimez l'ancienne clé d'accès de vos paramètres de compte.
1. Configurez une nouvelle clé d'accès sur votre nouvel appareil.

## Sujets connexes {#related-topics}

- [Authentification à deux facteurs](../user/profile/account/two_factor_authentication.md)
- [Mots de passe des utilisateurs](../user/profile/user_passwords.md)

---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Imposer l'authentification à deux facteurs"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[L'authentification à deux facteurs (2FA)](../user/profile/account/two_factor_authentication.md) est une méthode d'authentification qui exige que l'utilisateur fournisse deux facteurs différents pour prouver son identité :

- Nom d'utilisateur et mot de passe.
- Une deuxième méthode d'authentification, telle qu'un code généré par une application.

La 2FA rend l'accès à un compte plus difficile pour une personne non autorisée, car celle-ci aurait besoin des deux facteurs.

> [!note]
> Si vous [utilisez et imposez l'authentification SSO](../user/group/saml_sso/_index.md#sso-enforcement), il est possible que vous appliquiez déjà la 2FA du côté du fournisseur d'identité (IdP). Imposer la 2FA sur GitLab peut s'avérer superflu.

## Imposer la 2FA à tous les utilisateurs {#enforce-2fa-for-all-users}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les administrateurs peuvent imposer la 2FA à tous les utilisateurs de deux manières différentes :

- Imposer à la prochaine connexion.
- Suggérer à la prochaine connexion, mais accorder un délai de grâce avant d'imposer.

  Une fois le délai de grâce configuré écoulé, les utilisateurs peuvent se connecter mais ne peuvent pas quitter la zone de configuration de la 2FA à l'adresse `/-/profile/two_factor_auth`.

Vous pouvez utiliser l'interface utilisateur ou l'API pour imposer la 2FA à tous les utilisateurs.

### Utiliser l'interface utilisateur {#use-the-ui}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Restrictions de connexion** :
   - Sélectionnez **Imposer l'authentification à deux facteurs** pour activer cette fonctionnalité.
   - Dans **Délai de grâce des deux facteurs**, saisissez un nombre d'heures. Si vous souhaitez imposer la 2FA à la prochaine tentative de connexion, saisissez `0`.

### Utiliser l'API {#use-the-api}

Utilisez l'[API des paramètres d'application](../api/settings.md) pour modifier les paramètres suivants :

- `require_two_factor_authentication`.
- `two_factor_grace_period`.

Pour plus d'informations, consultez la [liste des paramètres accessibles via des appels API](../api/settings.md#available-settings).

## Imposer la 2FA aux administrateurs {#enforce-2fa-for-administrators}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/427549) dans GitLab 16.8.
- La prise en charge de l'imposition de la 2FA aux utilisateurs réguliers ayant des rôles d'administrateur personnalisés a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/556110) dans GitLab 18.3.

{{< /history >}}

Les administrateurs peuvent imposer la 2FA pour les deux cas suivants :

- Les utilisateurs administrateurs.
- Les utilisateurs réguliers auxquels un [rôle d'administrateur personnalisé](../user/custom_roles/_index.md) a été attribué.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez la section **Restrictions de connexion** :
   1. Sélectionnez **Imposer l'authentification à deux facteurs pour les admins**.
   1. Dans **Délai de grâce des deux facteurs**, saisissez un nombre d'heures. Si vous souhaitez imposer la 2FA à la prochaine tentative de connexion, saisissez `0`.
1. Sélectionnez **Enregistrer les modifications**.

> [!note]
> Si vous utilisez un fournisseur externe pour vous connecter à GitLab, ce paramètre n'imposera pas la 2FA aux utilisateurs. La 2FA doit être activée sur ce fournisseur externe.

## Imposer la 2FA à tous les utilisateurs d'un groupe {#enforce-2fa-for-all-users-in-a-group}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez imposer la 2FA à tous les utilisateurs d'un groupe ou sous-groupe.

L'application de la 2FA s'applique aux [membres directs et hérités](../user/project/members/_index.md#membership-types) du groupe. Si la 2FA est imposée sur un sous-groupe, les membres hérités doivent enregistrer un facteur d'authentification. Les membres hérités sont des membres des groupes ancêtres.

> [!note]
> L'OTP par e-mail ne satisfait pas à l'exigence de 2FA. Les membres doivent configurer soit un TOTP basé sur une application, soit WebAuthn.

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

Pour imposer la 2FA à un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Permissions et fonctionnalités du groupe**.
1. Sélectionnez **Tous les utilisateurs de ce groupe doivent configurer une authentification à deux facteurs**.
1. Facultatif. Dans **Délai avant d'imposer l'A2F (heures)**, saisissez le nombre d'heures que vous souhaitez que dure le délai de grâce. S'il existe plusieurs délais de grâce différents dans un groupe principal et ses sous-groupes et projets, le délai de grâce le plus court est utilisé.
1. Sélectionnez **Enregistrer les modifications**.

Les jetons d'accès ne sont pas tenus de fournir un second facteur d'authentification car ils sont basés sur l'API. Les jetons générés avant l'imposition de la 2FA restent valides.

La fonctionnalité [e-mail entrant](../administration/incoming_email.md) de GitLab ne suit pas l'application de la 2FA. Les utilisateurs peuvent utiliser les fonctionnalités d'e-mail entrant telles que la création de tickets ou les commentaires sur les merge requests sans avoir à s'authentifier avec la 2FA au préalable. Cela s'applique même si la 2FA est imposée.

### L'A2F dans les sous-groupes {#2fa-in-subgroups}

Par défaut, chaque sous-groupe peut configurer des exigences de 2FA qui peuvent différer de celles du groupe principal.

Lorsqu'un utilisateur est membre de plusieurs groupes dans une hiérarchie, l'exigence de 2FA la plus restrictive s'applique à tous les niveaux.

Par exemple, lorsque la 2FA est imposée dans un groupe principal :

- Tous les membres du groupe principal doivent utiliser la 2FA.
- Tous les membres des sous-groupes descendants doivent utiliser la 2FA.

Lorsque la 2FA n'est pas imposée dans un groupe principal :

- Si **Autoriser une application plus restrictive de l'A2F pour les sous-groupes** est activé, chaque sous-groupe peut imposer une exigence de 2FA indépendamment. Si un sous-groupe active une exigence de 2FA :
  - Tous les membres du groupe principal doivent utiliser la 2FA.
  - Tous les membres de tout sous-groupe frère doivent utiliser la 2FA.
- Si **Autoriser une application plus restrictive de l'A2F pour les sous-groupes** est désactivé, les sous-groupes ne peuvent pas imposer une exigence de 2FA indépendamment. La 2FA n'est pas requise pour les membres de la hiérarchie.

> [!note]
> Lorsque **Tous les utilisateurs de ce groupe doivent configurer une authentification à deux facteurs** est activé, cela prend toujours le dessus sur **Autoriser une application plus restrictive de l'A2F pour les sous-groupes**.

Pour empêcher les sous-groupes de définir des exigences de 2FA individuelles :

1. Accédez aux **Paramètres** > **Général** du groupe principal.
1. Développez la section **Permissions et fonctionnalités du groupe**.
1. Décochez la case **Autoriser une application plus restrictive de l'A2F pour les sous-groupes**.

### L'A2F dans les projets {#2fa-in-projects}

Si un projet appartenant à un groupe qui active ou impose la 2FA est [partagé](../user/project/members/sharing_projects_groups.md) avec un groupe qui n'active pas ou n'impose pas la 2FA, les membres du groupe sans 2FA peuvent accéder à ce projet sans utiliser la 2FA. Par exemple :

- Le groupe A a la 2FA activée et imposée. Le groupe B n'a pas la 2FA activée.
- Si un projet P, appartenant au groupe A, est partagé avec le groupe B, les membres du groupe B peuvent accéder au projet P sans 2FA.

Pour éviter que cela ne se produise, [empêchez le partage des projets](../user/project/members/sharing_projects_groups.md#prevent-a-project-from-being-shared-with-groups) pour le groupe utilisant la 2FA.

> [!warning]
> Si vous ajoutez des membres à un projet dans un groupe ou sous-groupe pour lequel la 2FA est activée, la 2FA n'est pas requise pour ces membres ajoutés individuellement.

## Désactiver la 2FA {#disable-2fa}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez désactiver la 2FA pour un seul utilisateur ou pour tous les utilisateurs.

Cette action est permanente et irréversible. Les utilisateurs doivent réactiver la 2FA pour l'utiliser à nouveau.

> [!warning]
> La désactivation de la 2FA pour les utilisateurs ne désactive pas les paramètres [imposer la 2FA à tous les utilisateurs](#enforce-2fa-for-all-users) ou [imposer la 2FA à tous les utilisateurs d'un groupe](#enforce-2fa-for-all-users-in-a-group). Vous devez également désactiver tout paramètre de 2FA imposé afin que les utilisateurs ne soient pas invités à configurer à nouveau la 2FA lors de leur prochaine connexion à GitLab.

### Pour tous les utilisateurs {#for-all-users}

Pour désactiver la 2FA pour tous les utilisateurs même lorsque la 2FA forcée est désactivée, utilisez la tâche Rake suivante.

- Pour les installations utilisant le paquet Linux :

  ```shell
  sudo gitlab-rake gitlab:two_factor:disable_for_all_users
  ```

- Pour les installations compilées manuellement :

  ```shell
  sudo -u git -H bundle exec rake gitlab:two_factor:disable_for_all_users RAILS_ENV=production
  ```

### Pour un seul utilisateur {#for-a-single-user}

#### Administrateurs {#administrators}

Il est possible d'utiliser la [console Rails](../administration/operations/rails_console.md) pour désactiver la 2FA pour un seul administrateur :

```ruby
admin = User.find_by_username('<USERNAME>')
user_to_disable = User.find_by_username('<USERNAME>')

TwoFactor::DestroyService.new(admin, user: user_to_disable).execute
```

L'administrateur est notifié que la 2FA a été désactivée.

#### Non-administrateurs {#non-administrators}

Vous pouvez utiliser soit la console Rails, soit le [point de terminaison API](../api/users.md#disable-two-factor-authentication-for-a-user) pour désactiver la 2FA pour un non-administrateur.

Vous pouvez désactiver la 2FA pour votre propre compte.

Vous ne pouvez pas utiliser le point de terminaison API pour désactiver la 2FA pour les administrateurs.

#### Utilisateurs Enterprise {#enterprise-users}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

Les propriétaires de groupe principal peuvent désactiver l'authentification à deux facteurs (2FA) pour les [utilisateurs Enterprise](../user/enterprise_user/_index.md).

Pour désactiver la 2FA :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Gérer** > **Membres**.
1. Trouvez un utilisateur avec les badges **Enterprise** et **A2F**.
1. Sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}) et sélectionnez **Désactiver l'authentification à deux facteurs**.

Vous pouvez également [utiliser l'API](../api/group_enterprise_users.md#disable-two-factor-authentication-for-an-enterprise-user) pour désactiver la 2FA pour les utilisateurs Enterprise, y compris les utilisateurs Enterprise qui ne sont plus membres du groupe.

## L'A2F pour les opérations Git via SSH {#2fa-for-git-over-ssh-operations}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!flag]
> Par défaut, cette fonctionnalité n'est pas disponible. Pour rendre cette fonctionnalité disponible, un administrateur peut [activer le feature flag](../administration/feature_flags/_index.md) nommé `two_factor_for_cli`. Cette fonctionnalité n'est pas prête pour une utilisation en production. Ce feature flag affecte également la [durée de session pour les opérations Git lorsque la 2FA est activée](../administration/settings/account_and_limit_settings.md#customize-session-duration-for-git-operations-when-2fa-is-enabled).

Vous pouvez imposer la 2FA pour les opérations Git via SSH. Cependant, vous devriez plutôt utiliser des clés SSH `ED25519_SK` ou `ECDSA_SK`. Pour plus d'informations, consultez [les types de clés SSH pris en charge](../user/ssh.md#supported-ssh-key-types). La 2FA est imposée uniquement pour les opérations Git, et les commandes internes de GitLab Shell telles que `personal_access_token` sont exclues.

Pour effectuer une vérification par mot de passe à usage unique (OTP), exécutez :

```shell
ssh git@<hostname> 2fa_verify
```

Authentifiez-vous ensuite de l'une des manières suivantes :

- Saisir l'OTP correct.
- Répondre à une notification push de l'appareil si [FortiAuthenticator est activé](../user/profile/account/two_factor_authentication.md#add-a-fortiauthenticator-authenticator).

Après une authentification réussie, vous pouvez effectuer des opérations Git via SSH pendant 15 minutes (par défaut) avec la clé SSH associée.

### Limitation de sécurité {#security-limitation}

La 2FA ne protège pas les utilisateurs dont les clés SSH privées ont été compromises.

Une fois qu'un OTP est vérifié, n'importe qui peut exécuter Git via SSH avec cette clé SSH privée pendant la [durée de session](../administration/settings/account_and_limit_settings.md#customize-session-duration-for-git-operations-when-2fa-is-enabled) configurée.

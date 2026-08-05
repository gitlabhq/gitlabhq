---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OmniAuth
description: "Configurer l'authentification externe avec des fournisseurs d'identité tiers."

---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les utilisateurs peuvent se connecter à GitLab en utilisant leurs identifiants Google, GitHub et d'autres services populaires. [OmniAuth](https://rubygems.org/gems/omniauth/) est le framework Rack que GitLab utilise pour fournir cette authentification.

Une fois configurées, des options de connexion supplémentaires s'affichent sur la page de connexion.

## Fournisseurs pris en charge {#supported-providers}

GitLab prend en charge les fournisseurs OmniAuth suivants.

| Documentation du fournisseur                                              | Nom du fournisseur OmniAuth     |
|---------------------------------------------------------------------|----------------------------|
| [AliCloud](alicloud.md)                                             | `alicloud`                 |
| [Atlassian](../administration/auth/atlassian.md)                    | `atlassian_oauth2`         |
| [Auth0](auth0.md)                                                   | `auth0`                    |
| [AWS Cognito](../administration/auth/cognito.md)                    | `cognito`                  |
| [Azure v2](azure.md)                                                | `azure_activedirectory_v2` |
| [Bitbucket Cloud](bitbucket.md)                                     | `bitbucket`                |
| [Generic OAuth 2.0](oauth2_generic.md)                              | `oauth2_generic`           |
| [GitHub](github.md)                                                 | `github`                   |
| [GitLab.com](gitlab.md)                                             | `gitlab`                   |
| [Google](google.md)                                                 | `google_oauth2`            |
| [JWT](../administration/auth/jwt.md)                                | `jwt`                      |
| [Kerberos](kerberos.md)                                             | `kerberos`                 |
| [OpenID Connect](../administration/auth/oidc.md)                    | `openid_connect`           |
| [Salesforce](salesforce.md)                                         | `salesforce`               |
| [SAML](saml.md)                                                     | `saml`                     |
| [Shibboleth](shibboleth.md)                                         | `shibboleth`               |

## Configurer les paramètres communs {#configure-common-settings}

Avant de configurer le fournisseur OmniAuth, configurez les paramètres communs à tous les fournisseurs.

| Option | Description |
| ------ | ----------- |
| `allow_bypass_two_factor`    | Permet aux utilisateurs de se connecter avec les fournisseurs spécifiés sans authentification à deux facteurs (2FA). Peut être défini sur `true`, `false` ou un tableau de fournisseurs. Pour plus d'informations, voir [Contourner l'authentification à deux facteurs](#bypass-two-factor-authentication). |
| `allow_single_sign_on`       | Active la création automatique de comptes lors de la connexion avec OmniAuth. Peut être défini sur `true`, `false` ou un tableau de fournisseurs. Pour les noms de fournisseurs, consultez le [tableau des fournisseurs pris en charge](#supported-providers). Lorsque défini sur `false`, la connexion via votre compte de fournisseur OmniAuth sans compte GitLab préexistant n'est pas autorisée. Vous devez d'abord créer un compte GitLab, puis le connecter à votre compte de fournisseur OmniAuth via les paramètres de votre profil. |
| `auto_link_ldap_user`        | Crée une identité LDAP dans GitLab pour les utilisateurs créés via un fournisseur OmniAuth. Pour activer ce paramètre, vous devez avoir [l'intégration LDAP](../administration/auth/ldap/_index.md) activée. Requiert que le `uid` de l'utilisateur soit identique dans LDAP et dans le fournisseur OmniAuth. |
| `auto_link_saml_user`        | Permet aux utilisateurs s'authentifiant via un fournisseur SAML d'être automatiquement liés à un utilisateur GitLab existant si leurs adresses e-mail correspondent. Pour activer ce paramètre, vous devez avoir l'intégration SAML activée. |
| `auto_link_user`             | Permet aux utilisateurs s'authentifiant via un fournisseur OmniAuth d'être automatiquement liés à un utilisateur GitLab existant si leurs adresses e-mail correspondent. Peut être défini sur `true`, `false` ou un tableau de fournisseurs. Pour les noms de fournisseurs, consultez le [tableau des fournisseurs pris en charge](#supported-providers). |
| `auto_sign_in_with_provider` | Permet aux utilisateurs d'utiliser un seul nom de fournisseur pour se connecter automatiquement. Ce nom doit correspondre au nom du fournisseur, tel que `saml` ou `google_oauth2`. Pour éviter une boucle de connexion infinie, les utilisateurs doivent se déconnecter de leurs comptes de fournisseur d'identité avant de se déconnecter de GitLab. Des améliorations de fonctionnalités sont en cours, comme [SAML](https://gitlab.com/gitlab-org/gitlab/-/issues/14414), pour implémenter la déconnexion fédérée pour les fournisseurs OmniAuth pris en charge. |
| `block_auto_created_users`   | Place les utilisateurs créés automatiquement dans un état d'[approbation en attente](../administration/moderate_users.md#users-pending-approval) (impossible de se connecter) jusqu'à ce qu'ils soient approuvés par un administrateur. Lorsque défini sur `false`, assurez-vous de définir des fournisseurs que vous pouvez contrôler, comme SAML ou Google. Sinon, n'importe quel utilisateur sur Internet peut se connecter à GitLab sans l'approbation d'un administrateur. Lorsque défini sur `true`, les utilisateurs créés automatiquement sont bloqués par défaut et doivent être débloqués par un administrateur avant de pouvoir se connecter. |
| `enabled`                    | Active et désactive l'utilisation d'OmniAuth avec GitLab. Lorsque défini sur `false`, les boutons du fournisseur OmniAuth ne sont pas visibles dans l'interface utilisateur. |
| `external_providers`         | Vous permet de définir quels fournisseurs OmniAuth vous souhaitez désigner comme `external`, de sorte que tous les utilisateurs créant des comptes ou se connectant via ces fournisseurs ne puissent pas accéder aux projets internes. Vous devez utiliser le nom complet du fournisseur, comme `google_oauth2` pour Google. Pour plus d'informations, voir [Créer une liste de fournisseurs externes](#create-an-external-providers-list). |
| `providers`                  | Les noms de fournisseurs sont disponibles dans le [tableau des fournisseurs pris en charge](#supported-providers). |
| `sync_profile_attributes`    | Liste des attributs de profil à synchroniser depuis le fournisseur lors de la connexion. Pour plus d'informations, voir [Maintenir les profils utilisateur OmniAuth à jour](#keep-omniauth-user-profiles-up-to-date). |
| `sync_profile_from_provider` | Liste des noms de fournisseurs depuis lesquels GitLab doit synchroniser automatiquement les informations de profil. Les entrées doivent correspondre au nom du fournisseur, tel que `saml` ou `google_oauth2`. Pour plus d'informations, voir [Maintenir les profils utilisateur OmniAuth à jour](#keep-omniauth-user-profiles-up-to-date). |

### Configurer les paramètres initiaux {#configure-initial-settings}

Pour modifier les paramètres OmniAuth :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # CAUTION!
   # This allows users to sign in without having a user account first. Define the allowed providers
   # using an array, for example, ["saml", "google_oauth2"], or as true/false to allow all providers or none.
   # User accounts will be created automatically when authentication was successful.
   gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'google_oauth2']
   gitlab_rails['omniauth_auto_link_ldap_user'] = true
   gitlab_rails['omniauth_block_auto_created_users'] = true
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` et mettez à jour la section `omniauth` sous `globals.appConfig` :

   ```yaml
   global:
     appConfig:
       omniauth:
         enabled: true
         allowSingleSignOn: ['saml', 'google_oauth2']
         autoLinkLdapUser: false
         blockAutoCreatedUsers: true
   ```

   Pour plus de détails, consultez la [documentation globals](https://docs.gitlab.com/charts/charts/globals/#omniauth).
1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'google_oauth2']
           gitlab_rails['omniauth_auto_link_ldap_user'] = true
           gitlab_rails['omniauth_block_auto_created_users'] = true
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   ## OmniAuth settings
   omniauth:
     # Allow sign-in by using Google, GitLab, etc. using OmniAuth providers
     # Versions prior to 11.4 require this to be set to true
     # enabled: true

     # CAUTION!
     # This allows users to sign in without having a user account first. Define the allowed providers
     # using an array, for example, ["saml", "google_oauth2"], or as true/false to allow all providers or none.
     # User accounts will be created automatically when authentication was successful.
     allow_single_sign_on: ["saml", "google_oauth2"]

     auto_link_ldap_user: true

     # Locks down those users until they have been cleared by the admin (default: true).
     block_auto_created_users: true
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

Après avoir configuré ces paramètres, vous pouvez configurer le [fournisseur](#supported-providers) de votre choix.

### Configuration par fournisseur {#per-provider-configuration}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89379) dans GitLab 15.3.

{{< /history >}}

Si `allow_single_sign_on` est défini, GitLab utilise l'un des champs suivants retournés dans le `auth_hash` OmniAuth pour établir un nom d'utilisateur dans GitLab pour l'utilisateur qui se connecte, en choisissant le premier qui existe :

- `username`.
- `nickname`.
- `email`.

Vous pouvez créer une configuration GitLab par fournisseur, qui est fournie au [fournisseur](#supported-providers) à l'aide de `args`. Si vous définissez la variable `gitlab_username_claim` dans `args` pour un fournisseur, vous pouvez sélectionner une autre revendication à utiliser pour le nom d'utilisateur GitLab. La revendication choisie doit être unique pour éviter les conflits.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```ruby
gitlab_rails['omniauth_providers'] = [

  # The generic pattern for configuring a provider with name PROVIDER_NAME

  gitlab_rails['omniauth_providers'] = {
    name: "PROVIDER_NAME"
    ...
    args: { gitlab_username_claim: 'sub' } # For users signing in with the provider you configure, the GitLab username will be set to the "sub" received from the provider
  },

  # Here are examples using GitHub and Kerberos

  gitlab_rails['omniauth_providers'] = {
    name: "github"
    ...
    args: { gitlab_username_claim: 'name' } # For users signing in with GitHub, the GitLab username will be set to the "name" received from GitHub
  },
  {
    name: "kerberos"
    ...
    args: { gitlab_username_claim: 'uid' } # For users signing in with Kerberos, the GitLab username will be set to the "uid" received from Kerberos
  },
]
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```yaml
- { name: 'PROVIDER_NAME',
  # ...
  args: { gitlab_username_claim: 'sub' }
}
- { name: 'github',
  # ...
  args: { gitlab_username_claim: 'name' }
}
- { name: 'kerberos',
  # ...
  args: { gitlab_username_claim: 'uid' }
}
```

{{< /tab >}}

{{< /tabs >}}

### Mots de passe pour les utilisateurs créés via OmniAuth {#passwords-for-users-created-via-omniauth}

Le guide [Mots de passe générés pour les utilisateurs créés via l'authentification intégrée](../user/profile/user_passwords.md) fournit un aperçu de la façon dont GitLab génère et définit les mots de passe pour les utilisateurs créés avec OmniAuth.

## Activer OmniAuth pour un utilisateur existant {#enable-omniauth-for-an-existing-user}

Si vous êtes un utilisateur existant, une fois votre compte GitLab créé, vous pouvez activer un fournisseur OmniAuth. Par exemple, si vous vous êtes connecté initialement avec LDAP, vous pouvez activer un fournisseur OmniAuth comme Google.

1. Connectez-vous à GitLab avec vos identifiants GitLab, LDAP ou un autre fournisseur OmniAuth.
1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Mot de passe et authentification**.
1. Dans la section **Connexion via un service tiers**, sélectionnez le fournisseur OmniAuth, tel que Google.
1. Vous êtes redirigé vers le fournisseur. Après avoir autorisé GitLab, vous êtes redirigé vers GitLab.

Vous pouvez maintenant utiliser le fournisseur OmniAuth de votre choix pour vous connecter à GitLab.

## Activer ou désactiver la connexion avec un fournisseur OmniAuth sans désactiver les sources d'importation {#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources}

Les administrateurs peuvent activer ou désactiver la connexion pour certains fournisseurs OmniAuth.

> [!note]
> Par défaut, la connexion est activée pour tous les fournisseurs OAuth configurés dans `config/gitlab.yml`.

Pour activer ou désactiver un fournisseur OmniAuth :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Restrictions de connexion**.
1. Dans la section **Sources d'authentification OAuth activées**, cochez ou décochez la case de chaque fournisseur que vous souhaitez activer ou désactiver.

## Désactiver OmniAuth {#disable-omniauth}

OmniAuth est activé par défaut. Cependant, OmniAuth ne fonctionne que si les fournisseurs sont configurés et [activés](#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources).

Si les fournisseurs OmniAuth causent des problèmes même lorsqu'ils sont désactivés individuellement, vous pouvez désactiver l'ensemble du sous-système OmniAuth en modifiant le fichier de configuration.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```ruby
gitlab_rails['omniauth_enabled'] = false
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```yaml
omniauth:
  enabled: false
```

{{< /tab >}}

{{< /tabs >}}

## Lier des utilisateurs existants à des utilisateurs OmniAuth {#link-existing-users-to-omniauth-users}

Vous pouvez lier automatiquement des utilisateurs OmniAuth à des utilisateurs GitLab existants si leurs adresses e-mail correspondent.

L'exemple suivant active le lien automatique pour le fournisseur OpenID Connect et le fournisseur Google OAuth.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```ruby
gitlab_rails['omniauth_auto_link_user'] = ["openid_connect", "google_oauth2"]
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```yaml
omniauth:
  auto_link_user: ["openid_connect", "google_oauth2"]
```

{{< /tab >}}

{{< /tabs >}}

Cette méthode d'activation du lien automatique fonctionne pour tous les fournisseurs [sauf SAML](https://gitlab.com/gitlab-org/gitlab/-/issues/338293). Pour activer le lien automatique pour SAML, consultez les [instructions de configuration SAML](saml.md#configure-saml-support-in-gitlab).

## Créer une liste de fournisseurs externes {#create-an-external-providers-list}

Vous pouvez définir une liste de fournisseurs OmniAuth externes. Les utilisateurs qui créent des comptes ou se connectent à GitLab via les fournisseurs répertoriés n'ont pas accès aux [projets internes](../user/public_access.md#internal-projects-and-groups) et sont marqués comme [utilisateurs externes](../administration/external_users.md).

Pour définir la liste des fournisseurs externes, utilisez le nom complet du fournisseur, par exemple `google_oauth2` pour Google. Pour les noms de fournisseurs, consultez la colonne **OmniAuth provider name** dans le [tableau des fournisseurs pris en charge](#supported-providers).

> [!note]
> Si vous supprimez un fournisseur OmniAuth de la liste des fournisseurs externes, vous devez mettre à jour manuellement les utilisateurs qui utilisent cette méthode de connexion afin que leurs comptes soient convertis en comptes internes complets.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```ruby
gitlab_rails['omniauth_external_providers'] = ['saml', 'google_oauth2']
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```yaml
omniauth:
  external_providers: ['saml', 'google_oauth2']
```

{{< /tab >}}

{{< /tabs >}}

## Maintenir les profils utilisateur OmniAuth à jour {#keep-omniauth-user-profiles-up-to-date}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/505575) des attributs `job_title` et `organization` dans GitLab 17.9.

{{< /history >}}

> [!note]
> Certains fournisseurs nécessitent une configuration supplémentaire pour synchroniser ces attributs. Par exemple, les fournisseurs SAML requièrent le [mappage des attributs de profil](saml.md#map-profile-attributes).

Vous pouvez activer la synchronisation du profil depuis les fournisseurs OmniAuth sélectionnés. Vous pouvez synchroniser toute combinaison des attributs utilisateur suivants :

- `name`
- `email`
- `job_title`
- `location`
- `organization`

Lors de l'authentification via LDAP, le nom et l'adresse e-mail de l'utilisateur sont toujours synchronisés.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_sync_profile_from_provider'] = ['saml', 'google_oauth2']
   gitlab_rails['omniauth_sync_profile_attributes'] = ['name', 'email', 'job_title', 'location', 'organization']
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > values.yaml
   ```

1. Modifiez `values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         syncProfileFromProvider: ['saml', 'google_oauth2']
         syncProfileAttributes: ['name', 'email', 'job_title', 'location', 'organization']
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_sync_profile_from_provider'] = ['saml', 'google_oauth2']
           gitlab_rails['omniauth_sync_profile_attributes'] = ['name', 'email', 'job_title', 'location', 'organization']
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       sync_profile_from_provider: ['saml', 'google_oauth2']
       sync_profile_attributes: ['name', 'email', 'job_title', 'location', 'organization']
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## Contourner l'authentification à deux facteurs {#bypass-two-factor-authentication}

Avec certains fournisseurs OmniAuth, les utilisateurs peuvent se connecter sans utiliser l'authentification à deux facteurs (2FA).

Pour contourner la 2FA, vous pouvez :

- Définir les fournisseurs autorisés à l'aide d'un tableau (par exemple, `['saml', 'google_oauth2']`).
- Spécifier `true` pour autoriser tous les fournisseurs, ou `false` pour n'en autoriser aucun.

Cette option doit être configurée uniquement pour les fournisseurs qui disposent déjà de la 2FA. La valeur par défaut est `false`.

Cette configuration ne s'applique pas à SAML.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```ruby
gitlab_rails['omniauth_allow_bypass_two_factor'] = ['saml', 'google_oauth2']
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```yaml
omniauth:
  allow_bypass_two_factor: ['saml', 'google_oauth2']
```

{{< /tab >}}

{{< /tabs >}}

## Se connecter automatiquement avec un fournisseur {#sign-in-with-a-provider-automatically}

Vous pouvez ajouter le paramètre `auto_sign_in_with_provider` à votre configuration GitLab pour rediriger les demandes de connexion vers votre fournisseur OmniAuth pour l'authentification. Cela supprime la nécessité de sélectionner le fournisseur avant de se connecter.

Par exemple, pour activer la connexion automatique pour l'[intégration Azure v2](azure.md) :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```ruby
gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'azure_activedirectory_v2'
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```yaml
omniauth:
  auto_sign_in_with_provider: azure_activedirectory_v2
```

{{< /tab >}}

{{< /tabs >}}

Gardez à l'esprit que chaque tentative de connexion est redirigée vers le fournisseur OmniAuth, vous ne pouvez donc pas vous connecter avec des identifiants locaux. Assurez-vous qu'au moins l'un des utilisateurs OmniAuth est un administrateur.

Vous pouvez également contourner la connexion automatique en accédant à `https://gitlab.example.com/users/sign_in?auto_sign_in=false`.

## Utiliser une icône de fournisseur OmniAuth personnalisée {#use-a-custom-omniauth-provider-icon}

La plupart des fournisseurs pris en charge incluent une icône intégrée pour le bouton de connexion affiché.

Pour utiliser votre propre icône, assurez-vous que votre image est optimisée pour un rendu à 64 x 64 pixels, puis remplacez l'icône de l'une des deux façons suivantes :

- **Provide a custom image path** :

  1. Si vous hébergez l'image en dehors du domaine de votre serveur GitLab, assurez-vous que vos [politiques de sécurité du contenu](https://docs.gitlab.com/omnibus/settings/configuration/#set-a-content-security-policy) sont configurées pour autoriser l'accès au fichier image.
  1. Selon votre méthode d'installation de GitLab, ajoutez un paramètre `icon` personnalisé à votre fichier de configuration GitLab. Consultez [le fournisseur OmniAuth OpenID Connect](../administration/auth/oidc.md) pour un exemple avec le fournisseur OpenID Connect.
- **Embed an image directly in a configuration file** : cet exemple crée une version encodée en Base64 de votre image que vous pouvez servir via une [Data URL](https://developer.mozilla.org/en-US/docs/Web/URI/Reference/Schemes/data) :

  1. Encodez votre fichier image avec une commande GNU `base64` (telle que `base64 -w 0 <logo.png>`), qui retourne une chaîne `<base64-data>` sur une seule ligne.
  1. Ajoutez les données encodées en Base64 à un paramètre `icon` personnalisé dans votre fichier de configuration GitLab :

     ```yaml
     omniauth:
       providers:
         - { name: '...'
             icon: 'data:image/png;base64,<base64-data>'
             # Additional parameters removed for readability
           }
     ```

## Modifier les applications ou la configuration {#change-apps-or-configuration}

Étant donné qu'OAuth dans GitLab ne prend pas en charge la définition du même fournisseur d'authentification et d'autorisation externe en tant que fournisseurs multiples, la configuration GitLab et l'identification des utilisateurs doivent être mises à jour simultanément si le fournisseur ou l'application est modifié. Par exemple, vous pouvez configurer `saml` et `azure_activedirectory_v2`, mais vous ne pouvez pas ajouter un second `azure_activedirectory_v2` à la même configuration.

Ces instructions s'appliquent à toutes les méthodes d'authentification où GitLab stocke un `extern_uid` qui constitue la seule donnée utilisée pour l'authentification des utilisateurs.

Lors du changement d'applications au sein d'un fournisseur, si le `extern_uid` de l'utilisateur ne change pas, seule la configuration GitLab doit être mise à jour.

Pour intervertir les configurations :

1. Modifiez la configuration du fournisseur dans votre fichier `gitlab.rb`.
1. Mettez à jour `extern_uid` pour tous les utilisateurs qui ont une identité dans GitLab pour le fournisseur précédent.

Pour trouver le `extern_uid`, examinez le `extern_uid` actuel d'un utilisateur existant pour un identifiant correspondant au champ approprié dans votre fournisseur actuel pour le même utilisateur.

Il existe deux méthodes pour mettre à jour le `extern_uid` :

- En utilisant l'[API Users](../api/users.md#modify-a-user). Transmettez le nom du fournisseur et le nouveau `extern_uid`.
- En utilisant la [console Rails](../administration/operations/rails_console.md) :

  ```ruby
  Identity.where(extern_uid: 'old-id').update!(extern_uid: 'new-id')
  ```

## Problèmes connus {#known-issues}

La plupart des fournisseurs OmniAuth pris en charge ne prennent pas en charge l'authentification par mot de passe Git via HTTP. Pour contourner ce problème, vous pouvez vous authentifier à l'aide d'un [jeton d'accès personnel](../user/profile/personal_access_tokens.md).

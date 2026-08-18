---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SSO SAML pour GitLab Self-Managed
description: "Configurez l'authentification d'entreprise avec l'intégration SAML pour un accès par authentification unique."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!note]
> Pour GitLab.com, consultez [SSO SAML pour les groupes GitLab.com](../user/group/saml_sso/_index.md).

Cette page décrit comment configurer l'authentification unique (SSO) SAML à l'échelle de l'instance pour GitLab Self-Managed.

Vous pouvez configurer GitLab pour qu'il agisse en tant que fournisseur de services (SP) SAML. Cela permet à GitLab de consommer les assertions d'un fournisseur d'identité (IdP) SAML, tel qu'Okta, pour authentifier les utilisateurs.

Pour plus d'informations sur :

- Les paramètres du fournisseur OmniAuth, consultez la [documentation OmniAuth](omniauth.md).
- Les termes couramment utilisés, consultez le [glossaire](../auth/auth_glossary.md).

## Configurer la prise en charge SAML dans GitLab {#configure-saml-support-in-gitlab}

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Assurez-vous que GitLab est [configuré avec HTTPS](https://docs.gitlab.com/omnibus/settings/ssl/).
1. Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `saml` comme fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui n'ont pas de compte GitLab existant.
1. Pour permettre à vos utilisateurs d'utiliser SAML pour s'inscrire sans avoir à créer manuellement un compte au préalable, modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
   gitlab_rails['omniauth_block_auto_created_users'] = false
   ```

1. Facultatif. Vous devriez lier automatiquement une première connexion SAML aux utilisateurs GitLab existants si leurs adresses e-mail correspondent. Pour ce faire, ajoutez le paramètre suivant dans `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_auto_link_saml_user'] = true
   ```

   Seule l'adresse e-mail principale du compte GitLab est comparée à l'e-mail dans la réponse SAML.

   Par ailleurs, un utilisateur peut lier manuellement son identité SAML à un compte GitLab existant en [activant OmniAuth pour un utilisateur existant](omniauth.md#enable-omniauth-for-an-existing-user).
1. Configurez les attributs suivants pour que vos utilisateurs SAML ne puissent pas les modifier :

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - `Email` lorsqu'il est utilisé avec `omniauth_auto_link_saml_user`.

   Si les utilisateurs peuvent modifier ces attributs, ils peuvent se connecter en tant qu'autres utilisateurs autorisés. Consultez la documentation de votre IdP SAML pour savoir comment rendre ces attributs non modifiables.
1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez la configuration du fournisseur :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "saml", # This must be lowercase.
       label: "Provider name", # optional label for login button, defaults to "Saml"
       args: {
         assertion_consumer_service_url: "https://gitlab.example.com/users/auth/saml/callback",
         idp_cert_fingerprint: "2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6",
         idp_sso_target_url: "https://login.example.com/idp",
         issuer: "https://gitlab.example.com",
         name_identifier_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
       }
     }
   ]
   ```

   | Argument                         | Description |
   | -------------------------------- | ----------- |
   | `assertion_consumer_service_url` | Le point de terminaison HTTPS de GitLab (ajoutez `/users/auth/saml/callback` à l'URL HTTPS de votre installation GitLab). |
   | `idp_cert_fingerprint`           | Votre valeur IdP. Pour générer l'empreinte SHA256 à partir du certificat, consultez [calculer l'empreinte](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint). |
   | `idp_sso_target_url`             | Votre valeur IdP. |
   | `issuer`                         | Remplacez par un nom unique qui identifie l'application auprès de l'IdP. |
   | `name_identifier_format`         | Votre valeur IdP. |

   Pour plus d'informations sur ces valeurs, consultez la [documentation OmniAuth SAML](https://github.com/omniauth/omniauth-saml). Pour plus d'informations sur les autres paramètres de configuration, consultez [la configuration de SAML sur votre IdP](#configure-saml-on-your-idp).
1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Assurez-vous que GitLab est [configuré avec HTTPS](https://docs.gitlab.com/charts/installation/tls/).
1. Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `saml` comme fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui n'ont pas de compte GitLab existant.
1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Pour permettre à vos utilisateurs d'utiliser SAML pour s'inscrire sans avoir à créer manuellement un compte au préalable, modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         enabled: true
         allowSingleSignOn: ['saml']
         blockAutoCreatedUsers: false
   ```

1. Facultatif. Vous pouvez lier automatiquement les utilisateurs SAML aux utilisateurs GitLab existants si leurs adresses e-mail correspondent, en ajoutant le paramètre suivant dans `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         autoLinkSamlUser: true
   ```

   Par ailleurs, un utilisateur peut lier manuellement son identité SAML à un compte GitLab existant en [activant OmniAuth pour un utilisateur existant](omniauth.md#enable-omniauth-for-an-existing-user).
1. Configurez les attributs suivants pour que vos utilisateurs SAML ne puissent pas les modifier :

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - `Email` lorsqu'il est utilisé avec `omniauth_auto_link_saml_user`.

   Si les utilisateurs peuvent modifier ces attributs, ils peuvent se connecter en tant qu'autres utilisateurs autorisés. Consultez la documentation de votre IdP SAML pour savoir comment rendre ces attributs non modifiables.
1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

   ```yaml
   name: 'saml'
   label: 'Provider name' # optional label for login button, defaults to "Saml"
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

   | Argument                         | Description |
   | -------------------------------- | ----------- |
   | `assertion_consumer_service_url` | Le point de terminaison HTTPS de GitLab (ajoutez `/users/auth/saml/callback` à l'URL HTTPS de votre installation GitLab). |
   | `idp_cert_fingerprint`           | Votre valeur IdP. Pour générer l'empreinte SHA256 à partir du certificat, consultez [calculer l'empreinte](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint). |
   | `idp_sso_target_url`             | Votre valeur IdP. |
   | `issuer`                         | Remplacez par un nom unique qui identifie l'application auprès de l'IdP. |
   | `name_identifier_format`         | Votre valeur IdP. |

   Pour plus d'informations sur ces valeurs, consultez la [documentation OmniAuth SAML](https://github.com/omniauth/omniauth-saml). Pour plus d'informations sur les autres paramètres de configuration, consultez [la configuration de SAML sur votre IdP](#configure-saml-on-your-idp).
1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Modifiez `gitlab_values.yaml` et ajoutez la configuration du fournisseur :

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Assurez-vous que GitLab est [configuré avec HTTPS](https://docs.gitlab.com/omnibus/settings/ssl/).
1. Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `saml` comme fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui n'ont pas de compte GitLab existant.
1. Pour permettre à vos utilisateurs d'utiliser SAML pour s'inscrire sans avoir à créer manuellement un compte au préalable, modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
           gitlab_rails['omniauth_block_auto_created_users'] = false
   ```

1. Facultatif. Vous pouvez lier automatiquement les utilisateurs SAML aux utilisateurs GitLab existants si leurs adresses e-mail correspondent, en ajoutant le paramètre suivant dans `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_auto_link_saml_user'] = true
   ```

   Par ailleurs, un utilisateur peut lier manuellement son identité SAML à un compte GitLab existant en [activant OmniAuth pour un utilisateur existant](omniauth.md#enable-omniauth-for-an-existing-user).
1. Configurez les attributs suivants pour que vos utilisateurs SAML ne puissent pas les modifier :

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - `Email` lorsqu'il est utilisé avec `omniauth_auto_link_saml_user`.

   Si les utilisateurs peuvent modifier ces attributs, ils peuvent se connecter en tant qu'autres utilisateurs autorisés. Consultez la documentation de votre IdP SAML pour savoir comment rendre ces attributs non modifiables.
1. Modifiez `docker-compose.yml` et ajoutez la configuration du fournisseur :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
             {
               name: "saml",
               label: "Provider name", # optional label for login button, defaults to "Saml"
               args: {
                 assertion_consumer_service_url: "https://gitlab.example.com/users/auth/saml/callback",
                 idp_cert_fingerprint: "2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6",
                 idp_sso_target_url: "https://login.example.com/idp",
                 issuer: "https://gitlab.example.com",
                 name_identifier_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
               }
             }
           ]
   ```

   | Argument                         | Description |
   | -------------------------------- | ----------- |
   | `assertion_consumer_service_url` | Le point de terminaison HTTPS de GitLab (ajoutez `/users/auth/saml/callback` à l'URL HTTPS de votre installation GitLab). |
   | `idp_cert_fingerprint`           | Votre valeur IdP. Pour générer l'empreinte SHA256 à partir du certificat, consultez [calculer l'empreinte](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint). |
   | `idp_sso_target_url`             | Votre valeur IdP. |
   | `issuer`                         | Remplacez par un nom unique qui identifie l'application auprès de l'IdP. |
   | `name_identifier_format`         | Votre valeur IdP. |

   Pour plus d'informations sur ces valeurs, consultez la [documentation OmniAuth SAML](https://github.com/omniauth/omniauth-saml). Pour plus d'informations sur les autres paramètres de configuration, consultez [la configuration de SAML sur votre IdP](#configure-saml-on-your-idp).
1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Assurez-vous que GitLab est [configuré avec HTTPS](../install/self_compiled/_index.md#using-https).
1. Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `saml` comme fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui n'ont pas de compte GitLab existant.
1. Pour permettre à vos utilisateurs d'utiliser SAML pour s'inscrire sans avoir à créer manuellement un compte au préalable, modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       enabled: true
       allow_single_sign_on: ["saml"]
       block_auto_created_users: false
   ```

1. Facultatif. Vous pouvez lier automatiquement les utilisateurs SAML aux utilisateurs GitLab existants si leurs adresses e-mail correspondent, en ajoutant le paramètre suivant dans `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       auto_link_saml_user: true
   ```

   Par ailleurs, un utilisateur peut lier manuellement son identité SAML à un compte GitLab existant en [activant OmniAuth pour un utilisateur existant](omniauth.md#enable-omniauth-for-an-existing-user).
1. Configurez les attributs suivants pour que vos utilisateurs SAML ne puissent pas les modifier :

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - `Email` lorsqu'il est utilisé avec `omniauth_auto_link_saml_user`.

   Si les utilisateurs peuvent modifier ces attributs, ils peuvent se connecter en tant qu'autres utilisateurs autorisés. Consultez la documentation de votre IdP SAML pour savoir comment rendre ces attributs non modifiables.
1. Modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez la configuration du fournisseur :

   ```yaml
   omniauth:
     providers:
       - {
         name: 'saml',
         label: 'Provider name', # optional label for login button, defaults to "Saml"
         args: {
           assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
           idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
           idp_sso_target_url: 'https://login.example.com/idp',
           issuer: 'https://gitlab.example.com',
           name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
         }
       }
   ```

   | Argument                         | Description |
   | -------------------------------- | ----------- |
   | `assertion_consumer_service_url` | Le point de terminaison HTTPS de GitLab (ajoutez `/users/auth/saml/callback` à l'URL HTTPS de votre installation GitLab). |
   | `idp_cert_fingerprint`           | Votre valeur IdP. Pour générer l'empreinte SHA256 à partir du certificat, consultez [calculer l'empreinte](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint). |
   | `idp_sso_target_url`             | Votre valeur IdP. |
   | `issuer`                         | Remplacez par un nom unique qui identifie l'application auprès de l'IdP. |
   | `name_identifier_format`         | Votre valeur IdP. |

   Pour plus d'informations sur ces valeurs, consultez la [documentation OmniAuth SAML](https://github.com/omniauth/omniauth-saml). Pour plus d'informations sur les autres paramètres de configuration, consultez [la configuration de SAML sur votre IdP](#configure-saml-on-your-idp).
1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### Enregistrer GitLab dans votre IdP SAML {#register-gitlab-in-your-saml-idp}

1. Enregistrez le SP GitLab dans votre IdP SAML en utilisant le nom d'application spécifié dans `issuer`.
1. Pour fournir des informations de configuration à l'IdP, créez une URL de métadonnées pour l'application. Pour créer l'URL de métadonnées pour GitLab, ajoutez `users/auth/saml/metadata` à l'URL HTTPS de votre installation GitLab. Par exemple :

   ```plaintext
   https://gitlab.example.com/users/auth/saml/metadata
   ```

   Au minimum, l'IdP **doit** fournir une revendication contenant l'adresse e-mail de l'utilisateur en utilisant `email` ou `mail`. Pour plus d'informations sur les autres revendications disponibles, consultez [la configuration des assertions](#configure-assertions).
1. Sur la page de connexion, une icône SAML doit maintenant apparaître sous le formulaire de connexion habituel. Sélectionnez l'icône pour lancer le processus d'authentification. Si l'authentification réussit, vous êtes redirigé vers GitLab et connecté.

### Configurer SAML sur votre IdP {#configure-saml-on-your-idp}

Pour configurer une application SAML sur votre IdP, vous avez besoin d'au moins les informations suivantes :

- URL du service consommateur d'assertions.
- Émetteur.
- [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
- [Revendication d'adresse e-mail](#configure-assertions).

Pour un exemple de configuration, consultez [configurer les fournisseurs d'identité](#set-up-identity-providers).

Votre IdP peut nécessiter une configuration supplémentaire. Pour plus d'informations, consultez [la configuration supplémentaire pour les applications SAML sur votre IdP](#additional-configuration-for-saml-apps-on-your-idp).

### Configurer GitLab pour utiliser plusieurs IdPs SAML {#configure-gitlab-to-use-multiple-saml-idps}

Vous pouvez configurer GitLab pour utiliser plusieurs IdPs SAML si :

- Chaque fournisseur possède un nom unique qui correspond à un nom défini dans `args`.
- Les noms des fournisseurs sont utilisés :
  - Dans la configuration OmniAuth pour les propriétés basées sur le nom du fournisseur. Par exemple, `allowBypassTwoFactor`, `allowSingleSignOn` et `syncProfileFromProvider`.
  - Pour l'association à chaque utilisateur existant en tant qu'identité supplémentaire.
- L'`assertion_consumer_service_url` correspond au nom du fournisseur.
- L'`strategy_class` est explicitement défini car il ne peut pas être déduit du nom du fournisseur.

> [!note]
> Lorsque vous configurez plusieurs IdPs SAML, pour que les liens de groupe SAML fonctionnent, vous devez configurer tous les IdPs SAML pour qu'ils contiennent des attributs de groupe dans la réponse SAML. Pour plus d'informations, consultez [les liens de groupe SAML](../user/group/saml_sso/group_sync.md).

Pour configurer plusieurs IdPs SAML :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: 'saml', # This must match the following name configuration parameter
       label: 'Provider 1' # Differentiate the two buttons and providers in the UI
       args: {
               name: 'saml', # This is mandatory and must match the provider name
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback', # URL must match the name of the provider
               strategy_class: 'OmniAuth::Strategies::SAML',
               # Include all required arguments similar to a single provider
             },
     },
     {
       name: 'saml_2', # This must match the following name configuration parameter
       label: 'Provider 2' # Differentiate the two buttons and providers in the UI
       args: {
               name: 'saml_2', # This is mandatory and must match the provider name
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback', # URL must match the name of the provider
               strategy_class: 'OmniAuth::Strategies::SAML',
               # Include all required arguments similar to a single provider
             },
     }
   ]
   ```

   Pour permettre à vos utilisateurs d'utiliser SAML pour s'inscrire sans avoir à créer manuellement un compte depuis l'un ou l'autre des fournisseurs, ajoutez les valeurs suivantes à votre configuration :

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'saml_2']
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) pour le premier fournisseur SAML :

   ```yaml
   name: 'saml' # At least one provider must be named 'saml'
   label: 'Provider 1' # Differentiate the two buttons and providers in the UI
   args:
     name: 'saml' # This is mandatory and must match the provider name
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback' # URL must match the name of the provider
     strategy_class: 'OmniAuth::Strategies::SAML' # Mandatory
     # Include all required arguments similar to a single provider
   ```

1. Placez le contenu suivant dans un fichier nommé `saml_2.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) pour le second fournisseur SAML :

   ```yaml
   name: 'saml_2'
   label: 'Provider 2' # Differentiate the two buttons and providers in the UI
   args:
     name: 'saml_2' # This is mandatory and must match the provider name
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback' # URL must match the name of the provider
     strategy_class: 'OmniAuth::Strategies::SAML' # Mandatory
     # Include all required arguments similar to a single provider
   ```

1. Facultatif. Définissez des fournisseurs SAML supplémentaires en suivant les mêmes étapes.
1. Créez les Secrets Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml \
      --from-file=saml=saml.yaml \
      --from-file=saml_2=saml_2.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
             key: saml
           - secret: gitlab-saml
             key: saml_2
   ```

   Pour permettre à vos utilisateurs d'utiliser SAML pour s'inscrire sans avoir à créer manuellement un compte depuis l'un ou l'autre des fournisseurs, ajoutez les valeurs suivantes à votre configuration :

   ```yaml
   global:
     appConfig:
       omniauth:
         allowSingleSignOn: ['saml', 'saml_2']
   ```

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
           gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'saml1']
           gitlab_rails['omniauth_providers'] = [
             {
               name: 'saml', # This must match the following name configuration parameter
               label: 'Provider 1' # Differentiate the two buttons and providers in the UI
               args: {
                       name: 'saml', # This is mandatory and must match the provider name
                       assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback', # URL must match the name of the provider
                       strategy_class: 'OmniAuth::Strategies::SAML',
                       # Include all required arguments similar to a single provider
                     },
             },
             {
               name: 'saml_2', # This must match the following name configuration parameter
               label: 'Provider 2' # Differentiate the two buttons and providers in the UI
               args: {
                       name: 'saml_2', # This is mandatory and must match the provider name
                       assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback', # URL must match the name of the provider
                       strategy_class: 'OmniAuth::Strategies::SAML',
                       # Include all required arguments similar to a single provider
                     },
             }
           ]
   ```

   Pour permettre à vos utilisateurs d'utiliser SAML pour s'inscrire sans avoir à créer manuellement un compte depuis l'un ou l'autre des fournisseurs, ajoutez les valeurs suivantes à votre configuration :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'saml_2']
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
         - {
           name: 'saml', # This must match the following name configuration parameter
           label: 'Provider 1' # Differentiate the two buttons and providers in the UI
           args: {
             name: 'saml', # This is mandatory and must match the provider name
             assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback', # URL must match the name of the provider
             strategy_class: 'OmniAuth::Strategies::SAML',
             # Include all required arguments similar to a single provider
           },
         }
         - {
           name: 'saml_2', # This must match the following name configuration parameter
           label: 'Provider 2' # Differentiate the two buttons and providers in the UI
           args: {
             name: 'saml_2', # This is mandatory and must match the provider name
             strategy_class: 'OmniAuth::Strategies::SAML',
             assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback', # URL must match the name of the provider
             # Include all required arguments similar to a single provider
           },
         }
   ```

   Pour permettre à vos utilisateurs d'utiliser SAML pour s'inscrire sans avoir à créer manuellement un compte depuis l'un ou l'autre des fournisseurs, ajoutez les valeurs suivantes à votre configuration :

   ```yaml
   production: &base
     omniauth:
       allow_single_sign_on: ["saml", "saml_2"]
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

## Configurer les fournisseurs d'identité {#set-up-identity-providers}

La prise en charge de SAML par GitLab vous permet de vous connecter à GitLab via un large éventail d'IdPs.

GitLab fournit le contenu suivant sur la configuration des IdPs Okta et Google Workspace à titre indicatif uniquement. Si vous avez des questions sur la configuration de l'un ou l'autre de ces IdPs, contactez le support de votre fournisseur.

### Configurer Okta {#set-up-okta}

1. Dans la section administrateur Okta, choisissez **Applications**.
1. Sur l'écran de l'application, sélectionnez **Create App Integration**, puis sélectionnez **SAML 2.0** sur l'écran suivant.
1. Facultatif. Choisissez et ajoutez un logo depuis [GitLab Press](https://about.gitlab.com/press/press-kit/). Vous devez rogner et redimensionner le logo.
1. Complétez la configuration générale SAML. Saisissez :
   - `"Single sign-on URL"` : utilisez l'URL du service consommateur d'assertions.
   - `"Audience URI"` : utilisez l'émetteur.
   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - [Assertions](#configure-assertions).
1. Dans la section de commentaires, indiquez que vous êtes un client et que vous créez une application à usage interne.
1. En haut du profil de votre nouvelle application, sélectionnez **SAML 2.0 configuration instructions**.
1. Notez l'**Identity Provider Single Sign-On URL**. Utilisez cette URL pour le `idp_sso_target_url` dans votre fichier de configuration GitLab.
1. Avant de vous déconnecter d'Okta, assurez-vous d'ajouter votre utilisateur et vos groupes, le cas échéant.

### Configurer Google Workspace {#set-up-google-workspace}

Prérequis :

- Assurez-vous d'avoir accès à un [compte Super Administrateur Google Workspace](https://support.google.com/a/answer/2405986#super_admin).

Pour configurer un Google Workspace :

1. Utilisez les informations suivantes et suivez les instructions de [Set up your own custom SAML application in Google Workspace](https://support.google.com/a/answer/6087519?hl=en).

   |                  | Valeur typique                                      | Description                                                                                   |
   |:-----------------|:---------------------------------------------------|:----------------------------------------------------------------------------------------------|
   | Nom de l'application SAML | GitLab                                             | D'autres noms sont acceptés.                                                                               |
   | URL ACS          | `https://<GITLAB_DOMAIN>/users/auth/saml/callback` | URL du service consommateur d'assertions.                                                               |
   | `GITLAB_DOMAIN`  | `gitlab.example.com`                               | Le domaine de votre instance GitLab.                                                                  |
   | ID de l'entité        | `https://gitlab.example.com`                       | Une valeur unique à votre application SAML. Définissez-la sur l'`issuer` dans votre configuration GitLab. |
   | Format de l'identifiant de nom   | `EMAIL`                                            | Valeur requise. Également connu sous le nom `name_identifier_format`.                                       |
   | Identifiant de nom          | Adresse e-mail principale                              | Votre adresse e-mail. Assurez-vous que quelqu'un reçoit le contenu envoyé à cette adresse.                  |
   | Prénom       | `first_name`                                       | Prénom. Valeur requise pour communiquer avec GitLab.                                        |
   | Nom de famille        | `last_name`                                        | Nom de famille. Valeur requise pour communiquer avec GitLab.                                         |

1. Configurez les mappages d'attributs SAML suivants :

   | Attributs Google Directory       | Attributs de l'application |
   |-----------------------------------|----------------|
   | Informations de base > E-mail         | `email`        |
   | Informations de base > Prénom    | `first_name`   |
   | Informations de base > Nom de famille     | `last_name`    |

   Vous pourrez utiliser certaines de ces informations lorsque vous [configurerez la prise en charge SAML dans GitLab](#configure-saml-support-in-gitlab).

Lors de la configuration de l'application SAML Google Workspace, enregistrez les informations suivantes :

|                    | Valeur        | Description |
| ------------------ | ------------ | ----------- |
| URL SSO            | Dépend      | Détails du fournisseur d'identité Google. Définissez ce paramètre sur le paramètre GitLab `idp_sso_target_url`. |
| Certificat        | Téléchargeable | Certificat SAML Google. |
| Empreinte SHA256 | Dépend      | Disponible lorsque vous téléchargez le certificat. Pour générer l'empreinte SHA256 à partir du certificat, consultez [calculer l'empreinte](../user/group/saml_sso/troubleshooting.md#calculate-the-fingerprint). |

L'administrateur Google Workspace fournit également les métadonnées IdP, l'identifiant d'entité et l'empreinte SHA-256. Cependant, GitLab n'a pas besoin de ces informations pour se connecter à l'application SAML Google Workspace.

### Configurer Microsoft Entra ID {#set-up-microsoft-entra-id}

1. Connectez-vous au [centre d'administration Microsoft Entra](https://entra.microsoft.com/).
1. [Créez une application hors galerie](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/overview-application-gallery#create-your-own-application).
1. [Configurez l'SSO pour cette application](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal-setup-sso).

   Les paramètres suivants de votre fichier `gitlab.rb` correspondent aux champs Microsoft Entra ID :

   | Paramètre `gitlab.rb`                 | Champ Microsoft Entra ID                       |
   | ------------------------------------| ---------------------------------------------- |
   | `issuer`                           | **Identifier (Entity ID)**                     |
   | `assertion_consumer_service_url`   | **Reply URL (Assertion Consumer Service URL)** |
   | `idp_sso_target_url`               | **Login URL**                                  |
   | `idp_cert_fingerprint`             | **Thumbprint**                                 |

1. Définissez les attributs suivants :
   - **Unique User Identifier (Name ID)** sur `user.objectID`.
     - **Name identifier format** sur `persistent`. Pour plus d'informations, consultez la section [gérer l'identité SAML des utilisateurs](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - **Additional claims** sur [les attributs pris en charge](#configure-assertions).

Pour plus d'informations, consultez une [page d'exemple de configuration](../user/group/saml_sso/example_saml_config.md#azure-active-directory).

### Configurer d'autres IdPs {#set-up-other-idps}

Certains IdPs disposent d'une documentation sur la façon de les utiliser comme IdP dans des configurations SAML. Par exemple :

- [Active Directory Federation Services (ADFS)](https://learn.microsoft.com/en-us/previous-versions/windows-server/it-pro/windows-server-2012/identity/ad-fs/operations/Create-a-Relying-Party-Trust)
- [Auth0](https://auth0.com/docs/authenticate/single-sign-on/outbound-single-sign-on/configure-auth0-saml-identity-provider)

Si vous avez des questions sur la configuration de votre IdP dans une configuration SAML, contactez le support de votre fournisseur.

### Configurer les assertions {#configure-assertions}

{{< details >}}

- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Prise en charge des attributs Microsoft Azure/Entra ID [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/420766) dans GitLab 16.7.

{{< /history >}}

> [!note]
> Ces attributs sont sensibles à la casse.

| Champ           | Clés par défaut prises en charge                                                                                                                                                         |
|-----------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| E-mail (requis)| `email`, `mail`, `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress`, `http://schemas.microsoft.com/ws/2008/06/identity/claims/emailaddress`, `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/email`, `http://schemas.microsoft.com/ws/2008/06/identity/claims/email`, `urn:oid:0.9.2342.19200300.100.1.3`                  |
| Nom complet       | `name`, `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name`, `http://schemas.microsoft.com/ws/2008/06/identity/claims/name`, `urn:oid:2.16.840.1.113730.3.1.241`, `urn:oid:2.5.4.3`                                           |
| Prénom      | `first_name`, `firstname`, `firstName`, `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname`, `http://schemas.microsoft.com/ws/2008/06/identity/claims/givenname`, `urn:oid:2.5.4.42` |
| Nom de famille       | `last_name`, `lastname`, `lastName`, `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname`, `http://schemas.microsoft.com/ws/2008/06/identity/claims/surname`, `urn:oid:2.5.4.4`   |

Lorsque GitLab reçoit une réponse SAML d'un fournisseur SSO SAML, GitLab recherche les valeurs suivantes dans le champ d'attribut `name` :

- `"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"`
- `"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"`
- `"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"`
- `firstname`
- `lastname`
- `email`

Vous devez inclure ces valeurs correctement dans le champ d'attribut `Name` pour que GitLab puisse analyser la réponse SAML. Par exemple, GitLab peut analyser les extraits de réponse SAML suivants :

- Ceci est accepté car l'attribut `Name` est défini sur l'une des valeurs requises du tableau précédent.

  ```xml
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname">
               <AttributeValue>Alvin</AttributeValue>
           </Attribute>
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname">
               <AttributeValue>Test</AttributeValue>
           </Attribute>
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress">
               <AttributeValue>alvintest@example.com</AttributeValue>
           </Attribute>
  ```

- Ceci est accepté car l'attribut `Name` correspond à l'une des valeurs du tableau précédent.

  ```xml
           <Attribute Name="firstname">
               <AttributeValue>Alvin</AttributeValue>
           </Attribute>
           <Attribute Name="lastname">
               <AttributeValue>Test</AttributeValue>
           </Attribute>
           <Attribute Name="email">
               <AttributeValue>alvintest@example.com</AttributeValue>
           </Attribute>
  ```

Cependant, GitLab ne peut pas analyser les extraits de réponse SAML suivants :

- Ceci ne sera pas accepté car la valeur de l'attribut `Name` ne figure pas parmi les valeurs prises en charge dans le tableau précédent.

  ```xml
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/firstname">
               <AttributeValue>Alvin</AttributeValue>
           </Attribute>
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/lastname">
               <AttributeValue>Test</AttributeValue>
           </Attribute>
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/mail">
               <AttributeValue>alvintest@example.com</AttributeValue>
           </Attribute>
  ```

- Ceci échouera car, même si `FriendlyName` a une valeur prise en charge, l'attribut `Name` ne l'est pas.

  ```xml
           <Attribute FriendlyName="firstname" Name="urn:oid:2.5.4.42">
               <AttributeValue>Alvin</AttributeValue>
           </Attribute>
           <Attribute FriendlyName="lastname" Name="urn:oid:2.5.4.4">
               <AttributeValue>Test</AttributeValue>
           </Attribute>
           <Attribute FriendlyName="email" Name="urn:oid:0.9.2342.19200300.100.1.3">
               <AttributeValue>alvintest@example.com</AttributeValue>
           </Attribute>
  ```

Consultez [`attribute_statements`](#map-saml-response-attribute-names) pour :

- Exemples de configuration d'assertion personnalisée.
- Comment configurer des attributs de nom d'utilisateur personnalisés.

Pour une liste complète des assertions prises en charge, consultez le [gem OmniAuth SAML](https://github.com/omniauth/omniauth-saml/blob/master/lib/omniauth/strategies/saml.rb)

## Configurer les utilisateurs en fonction de l'appartenance aux groupes SAML {#configure-users-based-on-saml-group-membership}

Vous pouvez :

- Exiger que les utilisateurs soient membres d'un certain groupe.
- Attribuer aux utilisateurs des rôles [externes](../administration/external_users.md), administrateur ou [auditeur](../administration/auditor_users.md) en fonction de l'appartenance à un groupe.

GitLab vérifie ces groupes à chaque connexion SAML et met à jour les attributs des utilisateurs si nécessaire. Cette fonctionnalité ne vous permet pas d'ajouter automatiquement des utilisateurs aux [groupes](../user/group/_index.md) GitLab.

La prise en charge de ces groupes dépend de :

- Votre [abonnement](https://about.gitlab.com/pricing/).
- Si vous avez installé [GitLab Enterprise Edition (EE)](https://about.gitlab.com/install/).

| Groupe                        | Édition               | GitLab Enterprise Edition (EE) uniquement ? |
|------------------------------|--------------------|--------------------------------------|
| [Obligatoire](#required-groups) | Gratuite, GitLab Premium, GitLab Ultimate | Oui                                  |
| [Externe](#external-groups) | Gratuite, GitLab Premium, GitLab Ultimate | Non                                   |
| [Admin](#administrator-groups) | Gratuite, GitLab Premium, GitLab Ultimate | Oui                                  |
| [Auditeur](#auditor-groups)   | GitLab Premium, GitLab Ultimate | Oui                                  |

Prérequis :

- Vous devez indiquer à GitLab où rechercher les informations de groupe. Pour ce faire, assurez-vous que votre serveur IdP envoie un `AttributeStatement` spécifique avec la réponse SAML habituelle. Par exemple :

  ```xml
  <saml:AttributeStatement>
    <saml:Attribute Name="Groups">
      <saml:AttributeValue xsi:type="xs:string">Developers</saml:AttributeValue>
      <saml:AttributeValue xsi:type="xs:string">Freelancers</saml:AttributeValue>
      <saml:AttributeValue xsi:type="xs:string">Admins</saml:AttributeValue>
      <saml:AttributeValue xsi:type="xs:string">Auditors</saml:AttributeValue>
    </saml:Attribute>
  </saml:AttributeStatement>
  ```

  Le nom de l'attribut doit contenir les groupes auxquels appartient un utilisateur. Pour indiquer à GitLab où trouver ces groupes, ajoutez un élément `groups_attribute:` à vos paramètres SAML. Cet attribut est sensible à la casse.

### Groupes requis {#required-groups}

Votre IdP transmet les informations de groupe à GitLab dans la réponse SAML. Pour utiliser cette réponse, configurez GitLab pour identifier :

- Où rechercher les groupes dans la réponse SAML, en utilisant le paramètre `groups_attribute`.
- Les informations sur un groupe ou un utilisateur, en utilisant un paramètre de groupe.

Utilisez le paramètre `required_groups` pour configurer GitLab afin d'identifier quelle appartenance à un groupe est requise pour se connecter.

Si vous ne définissez pas `required_groups` ou si vous laissez le paramètre vide, toute personne disposant d'une authentification appropriée peut utiliser le service.

Si l'attribut spécifié dans `groups_attribute` est incorrect ou manquant, tous les utilisateurs seront bloqués.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
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

### Groupes externes {#external-groups}

Votre IdP transmet les informations de groupe à GitLab dans la réponse SAML. Pour utiliser cette réponse, configurez GitLab pour identifier :

- Où rechercher les groupes dans la réponse SAML, en utilisant le paramètre `groups_attribute`.
- Les informations sur un groupe ou un utilisateur, en utilisant un paramètre de groupe.

SAML peut automatiquement identifier un utilisateur comme [utilisateur externe](../administration/external_users.md), en fonction du paramètre `external_groups`.

> [!note]
> Si l'attribut spécifié dans `groups_attribute` est incorrect ou manquant, l'utilisateur accèdera en tant qu'utilisateur standard.

Exemple de configuration :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [

     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       external_groups: ['Freelancers'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               # or
               # idp_cert: '-----BEGIN CERTIFICATE-----\n ... \n-----END CERTIFICATE-----',

               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   external_groups: ['Freelancers']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     # or
     # idp_cert: '-----BEGIN CERTIFICATE-----\n ... \n-----END CERTIFICATE-----',
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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
           gitlab_rails['omniauth_providers'] = [
             { name: 'saml',
               label: 'Our SAML Provider',
               groups_attribute: 'Groups',
               external_groups: ['Freelancers'],
               args: {
                       assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                       idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                       idp_sso_target_url: 'https://login.example.com/idp',
                       issuer: 'https://gitlab.example.com',
                       name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
               }
             }
           ]
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
          - { name: 'saml',
              label: 'Our SAML Provider',
              groups_attribute: 'Groups',
              external_groups: ['Freelancers'],
              args: {
                      assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                      idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                      idp_sso_target_url: 'https://login.example.com/idp',
                      issuer: 'https://gitlab.example.com',
                      name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
              }
            }
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

### Groupes administrateurs {#administrator-groups}

Votre IdP transmet les informations de groupe à GitLab dans la réponse SAML. Pour utiliser cette réponse, configurez GitLab pour identifier :

- Où rechercher les groupes dans la réponse SAML, en utilisant le paramètre `groups_attribute`.
- Les informations sur un groupe ou un utilisateur, en utilisant un paramètre de groupe.

Utilisez le paramètre `admin_groups` pour configurer GitLab afin d'identifier quels groupes accordent à l'utilisateur un accès administrateur.

Si l'attribut spécifié dans `groups_attribute` est incorrect ou manquant, les utilisateurs perdront leur accès administrateur.

Exemple de configuration :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       admin_groups: ['Admins'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               # or
               # idp_cert: '-----BEGIN CERTIFICATE-----\n ... \n-----END CERTIFICATE-----',

               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   admin_groups: ['Admins']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                admin_groups: ['Admins'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             admin_groups: ['Admins'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
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

### Groupes auditeurs {#auditor-groups}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Votre IdP transmet les informations de groupe à GitLab dans la réponse SAML. Pour utiliser cette réponse, configurez GitLab pour identifier :

- Où rechercher les groupes dans la réponse SAML, en utilisant le paramètre `groups_attribute`.
- Les informations sur un groupe ou un utilisateur, en utilisant un paramètre de groupe.

Utilisez le paramètre `auditor_groups` pour configurer GitLab afin d'identifier quels groupes incluent des utilisateurs disposant d'un [accès auditeur](../administration/auditor_users.md).

Si l'attribut spécifié dans `groups_attribute` est incorrect ou manquant, les utilisateurs perdront leur accès auditeur.

Exemple de configuration :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       auditor_groups: ['Auditors'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   auditor_groups: ['Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                auditor_groups: ['Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             auditor_groups: ['Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
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

## Gérer automatiquement la synchronisation des groupes SAML {#automatically-manage-saml-group-sync}

Pour plus d'informations sur la gestion automatique de l'appartenance aux groupes GitLab, consultez [SAML Group Sync](../user/group/saml_sso/group_sync.md).

### Personnaliser le délai d'expiration de session SAML {#customize-saml-session-timeout}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/262074) dans GitLab 18.2 [avec un feature flag](../administration/feature_flags/_index.md) nommé `saml_timeout_supplied_by_idp_override`.
- [Activé](https://gitlab.com/gitlab-org/gitlab/-/work_items/553931) dans GitLab 18.3.

{{< /history >}}

Par défaut, GitLab met fin aux sessions SAML après 24 heures. Vous pouvez personnaliser cette durée avec l'attribut `SessionNotOnOrAfter` dans l'AuthnStatement SAML2. Cet attribut contient une valeur d'horodatage ISO 8601 qui indique quand mettre fin à la session utilisateur. Lorsqu'il est spécifié, cette valeur remplace le délai d'expiration de session SAML par défaut de 24 heures.

Si l'instance a une [durée de session](../administration/settings/account_and_limit_settings.md#session-duration) personnalisée configurée qui est antérieure à l'horodatage `SessionNotOnOrAfter`, les utilisateurs doivent se réauthentifier à la fin de leur session utilisateur GitLab.

## Contourner l'authentification à deux facteurs {#bypass-two-factor-authentication}

{{< history >}}

- Contournement de l'application de la 2FA [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122109) dans GitLab 16.1 [avec un feature flag](../administration/feature_flags/_index.md) nommé `by_pass_two_factor_current_session`.
- [Activé](https://gitlab.com/gitlab-org/gitlab/-/issues/416535) dans GitLab 17.8.

{{< /history >}}

Pour configurer une méthode d'authentification SAML afin qu'elle compte comme une authentification à deux facteurs (2FA) par session, enregistrez cette méthode dans la liste `upstream_two_factor_authn_contexts`.

1. Assurez-vous que votre IdP renvoie bien le `AuthnContext`. Par exemple :

   ```xml
   <saml:AuthnStatement>
       <saml:AuthnContext>
           <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:MediumStrongCertificateProtectedTransport</saml:AuthnContextClassRef>
       </saml:AuthnContext>
   </saml:AuthnStatement>
   ```

1. Modifiez la configuration de votre installation pour enregistrer la méthode d'authentification SAML dans la liste `upstream_two_factor_authn_contexts`. Vous devez saisir le `AuthnContext` de votre réponse SAML.

   {{< tabs >}}

   {{< tab title="Paquet Linux (Omnibus)" >}}

   1. Modifiez `/etc/gitlab/gitlab.rb` :

      ```ruby
      gitlab_rails['omniauth_providers'] = [
        { name: 'saml',
          label: 'Our SAML Provider',
          args: {
                  assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                  idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                  idp_sso_target_url: 'https://login.example.com/idp',
                  issuer: 'https://gitlab.example.com',
                  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                  upstream_two_factor_authn_contexts:
                    %w(
                      urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport
                      urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS
                      urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN
                    ),
          }
        }
      ]
      ```

   1. Enregistrez le fichier et reconfigurez GitLab :

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   {{< /tab >}}

   {{< tab title="Chart Helm (Kubernetes)" >}}

   1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

      ```yaml
      name: 'saml'
      label: 'Our SAML Provider'
      args:
        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
        idp_sso_target_url: 'https://login.example.com/idp'
        issuer: 'https://gitlab.example.com'
        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
        upstream_two_factor_authn_contexts:
          - 'urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport'
          - 'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS'
          - 'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN'
      ```

   1. Créez le Secret Kubernetes :

      ```shell
      kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
      ```

   1. Exportez les valeurs Helm :

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. Modifiez `gitlab_values.yaml` :

      ```yaml
      global:
        appConfig:
          omniauth:
            providers:
              - secret: gitlab-saml
      ```

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
              gitlab_rails['omniauth_providers'] = [
                 { name: 'saml',
                   label: 'Our SAML Provider',
                   args: {
                           assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                           idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                           idp_sso_target_url: 'https://login.example.com/idp',
                           issuer: 'https://gitlab.example.com',
                           name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                           upstream_two_factor_authn_contexts:
                             %w(
                               urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport
                               urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS
                               urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN
                             )
                   }
                 }
              ]
      ```

   1. Enregistrez le fichier et redémarrez GitLab :

      ```shell
      docker compose up -d
      ```

   {{< /tab >}}

   {{< tab title="Auto-compilée (source)" >}}

   1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

      ```yaml
      production: &base
        omniauth:
          providers:
            - { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                        upstream_two_factor_authn_contexts:
                          [
                            'urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport',
                            'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS',
                            'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN'
                          ]
                }
              }
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

## Valider les signatures de réponse {#validate-response-signatures}

Les IdPs doivent signer les réponses SAML pour garantir que les assertions n'ont pas été altérées.

Cela prévient l'usurpation d'identité des utilisateurs et l'élévation de privilèges lorsqu'une appartenance à un groupe spécifique est requise.

### Utilisation de `idp_cert_fingerprint` {#using-idp_cert_fingerprint}

Vous pouvez configurer la validation de signature de réponse en utilisant `idp_cert_fingerprint`. Exemple de configuration :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
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

### Utilisation de `idp_cert` {#using-idp_cert}

Vous pouvez également configurer GitLab directement en utilisant `idp_cert`. Exemple de configuration :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert: '-----BEGIN CERTIFICATE-----
                 <redacted>
                 -----END CERTIFICATE-----',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert: |
       -----BEGIN CERTIFICATE-----
       <redacted>
       -----END CERTIFICATE-----
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert: '-----BEGIN CERTIFICATE-----
                          <redacted>
                          -----END CERTIFICATE-----',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert: '-----BEGIN CERTIFICATE-----
                       <redacted>
                       -----END CERTIFICATE-----',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
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

Si vous avez configuré incorrectement la validation de signature de réponse, vous pourriez voir des messages d'erreur tels que :

- Une erreur de validation de clé.
- Incompatibilité de condensé.
- Incompatibilité d'empreinte.

Pour plus d'informations sur la résolution de ces erreurs, consultez le [guide de dépannage SAML](../user/group/saml_sso/troubleshooting.md).

## Personnaliser les paramètres SAML {#customize-saml-settings}

### Rediriger les utilisateurs vers le serveur SAML pour l'authentification {#redirect-users-to-saml-server-for-authentication}

Vous pouvez ajouter le paramètre `auto_sign_in_with_provider` à votre configuration GitLab pour vous rediriger automatiquement vers votre serveur SAML pour l'authentification. Cela supprime l'obligation de sélectionner un élément avant de se connecter.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'saml'
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

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         autoSignInWithProvider: 'saml'
   ```

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
           gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'saml'
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       auto_sign_in_with_provider: 'saml'
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

Chaque tentative de connexion redirige vers le serveur SAML, vous ne pouvez donc pas vous connecter avec des identifiants locaux. Assurez-vous qu'au moins un des utilisateurs SAML dispose d'un accès administrateur.

> [!note]
> Pour contourner le paramètre de connexion automatique, ajoutez `?auto_sign_in=false` à l'URL de connexion, par exemple : `https://gitlab.example.com/users/sign_in?auto_sign_in=false`.

### Mapper les noms d'attributs de la réponse SAML {#map-saml-response-attribute-names}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser `attribute_statements` pour mapper les noms d'attributs dans une réponse SAML aux entrées du [hash `info`](https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema#schema-10-and-later) OmniAuth.

> [!note]
> Utilisez ce paramètre uniquement pour mapper les attributs faisant partie du schéma de hash `info` d'OmniAuth.

Par exemple, si votre `SAMLResponse` contient un attribut nommé `EmailAddress`, spécifiez `{ email: ['EmailAddress'] }` pour mapper l'attribut à la clé correspondante dans le hash `info`. Les attributs nommés par URI sont également pris en charge, par exemple, `{ email: ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] }`.

Utilisez ce paramètre pour indiquer à GitLab où rechercher certains attributs requis pour créer un compte. Par exemple, si votre IdP envoie l'adresse e-mail de l'utilisateur sous la forme `EmailAddress` au lieu de `email`, informez GitLab en le définissant dans votre configuration :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               attribute_statements: { email: ['EmailAddress'] }
       }
     }
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     attribute_statements:
       email: ['EmailAddress']
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        attribute_statements: { email: ['EmailAddress'] }
                }
              }
           ]
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     attribute_statements: { email: ['EmailAddress'] }
             }
           }
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

#### Définir un nom d'utilisateur {#set-a-username}

Par défaut, la partie locale de l'adresse e-mail dans la réponse SAML est utilisée pour générer le nom d'utilisateur GitLab de l'utilisateur.

Configurez [`username` ou `nickname`](omniauth.md#per-provider-configuration) dans `attribute_statements` pour spécifier un ou plusieurs attributs contenant le nom d'utilisateur souhaité :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               attribute_statements: { nickname: ['username'] }
       }
     }
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     attribute_statements:
       nickname: ['username']
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        attribute_statements: { nickname: ['username'] }
                }
              }
           ]
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     attribute_statements: { nickname: ['username'] }
             }
           }
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

Cela définit également l'attribut `username` de votre réponse SAML sur le nom d'utilisateur dans GitLab.

#### Mapper les attributs de profil {#map-profile-attributes}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/505575) des attributs `job_title` et `organization` dans GitLab 17.8.

{{< /history >}}

Pour synchroniser les informations de profil depuis votre fournisseur SAML, vous devez configurer `attribute_statements` pour mapper ces attributs.

Les attributs de profil pris en charge sont :

- `job_title`
- `organization`

Ces attributs n'ont pas de mappages par défaut et ne se synchronisent pas sauf si explicitement configurés.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. [Configurez OmniAuth pour synchroniser les attributs souhaités](omniauth.md#keep-omniauth-user-profiles-up-to-date).
1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               attribute_statements: {
                 organization: ['organization'],
                 job_title: ['job_title']
               }
       }
     }
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. [Configurez OmniAuth pour synchroniser les attributs souhaités](omniauth.md#keep-omniauth-user-profiles-up-to-date).
1. Enregistrez le contenu YAML suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     attribute_statements:
       organization: ['organization']
       job_title: ['job_title']
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. [Configurez OmniAuth pour synchroniser les attributs souhaités](omniauth.md#keep-omniauth-user-profiles-up-to-date).
1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        attribute_statements: {
                          organization: ['organization'],
                          job_title: ['job_title']
                        }
                }
              }
           ]
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. [Configurez OmniAuth pour synchroniser les attributs souhaités](omniauth.md#keep-omniauth-user-profiles-up-to-date).
1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     attribute_statements: {
                       organization: ['organization'],
                       job_title: ['job_title']
                     }
             }
           }
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

### Tolérer la dérive d'horloge {#allow-for-clock-drift}

L'horloge de l'IdP peut légèrement avancer par rapport à vos horloges système. Pour tolérer une petite dérive d'horloge, utilisez `allowed_clock_drift` dans vos paramètres. Vous devez saisir la valeur du paramètre sous forme de nombre et de fraction de secondes. La valeur fournie est ajoutée à l'heure actuelle à laquelle la réponse est validée.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               allowed_clock_drift: 1  # for one second clock drift
       }
     }
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     allowed_clock_drift: 1  # for one second clock drift
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        allowed_clock_drift: 1  # for one second clock drift
                }
              }
           ]
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     allowed_clock_drift: 1  # for one second clock drift
             }
           }
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

### Désigner un attribut unique pour le `uid` (facultatif) {#designate-a-unique-attribute-for-the-uid-optional}

Par défaut, le `uid` des utilisateurs est défini comme l'attribut `NameID` dans la réponse SAML. Pour désigner un attribut différent pour le `uid`, vous pouvez définir le `uid_attribute`.

Avant de définir le `uid` sur un attribut unique, assurez-vous d'avoir configuré les attributs suivants afin que vos utilisateurs SAML ne puissent pas les modifier :

- [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
- `Email` lorsqu'il est utilisé avec `omniauth_auto_link_saml_user`.

Si les utilisateurs peuvent modifier ces attributs, ils peuvent se connecter en tant qu'autres utilisateurs autorisés. Consultez la documentation de votre IdP SAML pour savoir comment rendre ces attributs non modifiables. Dans l'exemple suivant, la valeur de l'attribut `uid` dans la réponse SAML est définie comme le `uid_attribute`.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               uid_attribute: 'uid'
       }
     }
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     uid_attribute: 'uid'
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        uid_attribute: 'uid'
                }
              }
           ]
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     uid_attribute: 'uid'
             }
           }
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

## Chiffrement des assertions (facultatif) {#assertion-encryption-optional}

Le chiffrement de l'assertion SAML est facultatif mais recommandé. Cela ajoute une couche de protection supplémentaire pour empêcher que des données non chiffrées soient enregistrées dans les journaux ou interceptées par des acteurs malveillants.

> [!note]
> Cette intégration utilise les paramètres `certificate` et `private_key` pour le chiffrement des assertions et la signature des requêtes.

Pour chiffrer vos assertions SAML, définissez la clé privée et le certificat public dans les paramètres SAML de GitLab. Votre IdP chiffre l'assertion avec le certificat public et GitLab déchiffre l'assertion avec la clé privée.

Lorsque vous définissez la clé et le certificat, remplacez tous les sauts de ligne dans le fichier de clé par `\n`. Cela rend le fichier de clé une longue chaîne sans saut de ligne.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               certificate:|
               -----BEGIN CERTIFICATE-----
               <redacted>
               -----END CERTIFICATE-----,
               private_key:|
               -----BEGIN PRIVATE KEY-----
               <redacted>
               -----END PRIVATE KEY-----
       }
     }
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     certificate:|
     -----BEGIN CERTIFICATE-----
     <redacted>
     ----END CERTIFICATE-----,
     private_key:|
     -----BEGIN PRIVATE KEY-----
     <redacted>
     -----END PRIVATE KEY-----
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

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
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        certificate:|
                        -----BEGIN CERTIFICATE-----
                        <redacted>
                        -----END CERTIFICATE-----,
                        private_key:|
                        -----BEGIN PRIVATE KEY-----
                        <redacted>
                        -----END PRIVATE KEY-----
                }
              }
           ]
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
                     private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----'
             }
           }
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

## Signer les requêtes d'authentification SAML (facultatif) {#sign-saml-authentication-requests-optional}

Vous pouvez configurer GitLab pour signer les requêtes d'authentification SAML. Cette configuration est facultative car les requêtes SAML de GitLab utilisent la liaison de redirection SAML.

Pour implémenter la signature :

1. Créez une paire clé privée/certificat public pour votre instance GitLab à utiliser avec SAML.
1. Configurez les paramètres de signature dans la section `security` de la configuration. Par exemple :

   {{< tabs >}}

   {{< tab title="Paquet Linux (Omnibus)" >}}

   1. Modifiez `/etc/gitlab/gitlab.rb` :

      ```ruby
      gitlab_rails['omniauth_providers'] = [
        { name: 'saml',
          label: 'Our SAML Provider',
          args: {
                  assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                  idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                  idp_sso_target_url: 'https://login.example.com/idp',
                  issuer: 'https://gitlab.example.com',
                  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                  certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
                  private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----',
                  security: {
                    authn_requests_signed: true,  # enable signature on AuthNRequest
                    want_assertions_signed: true,  # enable the requirement of signed assertion
                    want_assertions_encrypted: false,  # enable the requirement of encrypted assertion
                    metadata_signed: false,  # enable signature on Metadata
                    signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
                    digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256',
                  }
          }
        }
      ]
      ```

   1. Enregistrez le fichier et reconfigurez GitLab :

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   {{< /tab >}}

   {{< tab title="Chart Helm (Kubernetes)" >}}

   1. Placez le contenu suivant dans un fichier nommé `saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

      ```yaml
      name: 'saml'
      label: 'Our SAML Provider'
      args:
        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6'
        idp_sso_target_url: 'https://login.example.com/idp'
        issuer: 'https://gitlab.example.com'
        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
        certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----'
        private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----'
        security:
          authn_requests_signed: true  # enable signature on AuthNRequest
          want_assertions_signed: true  # enable the requirement of signed assertion
          want_assertions_encrypted: false  # enable the requirement of encrypted assertion
          metadata_signed: false  # enable signature on Metadata
          signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'
          digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256'
      ```

   1. Créez le Secret Kubernetes :

      ```shell
      kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
      ```

   1. Exportez les valeurs Helm :

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. Modifiez `gitlab_values.yaml` :

      ```yaml
      global:
        appConfig:
          omniauth:
            providers:
              - secret: gitlab-saml
      ```

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
              gitlab_rails['omniauth_providers'] = [
                 { name: 'saml',
                   label: 'Our SAML Provider',
                   args: {
                           assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                           idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                           idp_sso_target_url: 'https://login.example.com/idp',
                           issuer: 'https://gitlab.example.com',
                           name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                           certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
                           private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----',
                           security: {
                             authn_requests_signed: true,  # enable signature on AuthNRequest
                             want_assertions_signed: true,  # enable the requirement of signed assertion
                             want_assertions_encrypted: false,  # enable the requirement of encrypted assertion
                             metadata_signed: false,  # enable signature on Metadata
                             signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
                             digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256',
                           }
                   }
                 }
              ]
      ```

   1. Enregistrez le fichier et redémarrez GitLab :

      ```shell
      docker compose up -d
      ```

   {{< /tab >}}

   {{< tab title="Auto-compilée (source)" >}}

   1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

      ```yaml
      production: &base
        omniauth:
          providers:
            - { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '2f:cb:19:57:68:c3:9e:9a:94:ce:c2:c2:e3:2c:59:c0:aa:d7:a3:36:5c:10:89:2e:81:16:b5:d8:3d:40:96:b6',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
                        private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----',
                        security: {
                          authn_requests_signed: true,  # enable signature on AuthNRequest
                          want_assertions_signed: true,  # enable the requirement of signed assertion
                          want_assertions_encrypted: false,  # enable the requirement of encrypted assertion
                          metadata_signed: false,  # enable signature on Metadata
                          signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
                          digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256',
                        }
                }
              }
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

GitLab effectue ensuite les opérations suivantes :

- Signe la requête avec la clé privée fournie.
- Inclut le certificat public x500 configuré dans les métadonnées pour que votre IdP puisse valider la signature de la requête reçue.

Pour plus d'informations sur cette option, consultez la [documentation du gem Ruby SAML](https://github.com/SAML-Toolkits/ruby-saml/tree/v1.7.0).

Le gem Ruby SAML est utilisé par le [gem OmniAuth SAML](https://github.com/omniauth/omniauth-saml) pour implémenter le côté client de l'authentification SAML.

> [!note]
> La liaison de redirection SAML est différente de la liaison POST SAML. Dans la liaison POST, la signature est requise pour empêcher les intermédiaires de falsifier les requêtes.

## Génération de mot de passe pour les utilisateurs créés via SAML {#password-generation-for-users-created-through-saml}

GitLab [génère et définit des mots de passe pour les utilisateurs créés via SAML](../user/profile/user_passwords.md).

Les utilisateurs authentifiés via SSO ou SAML ne doivent pas utiliser de mot de passe pour les opérations Git via HTTPS. Ces utilisateurs peuvent à la place :

- Configurer un jeton d'accès [personnel](../user/profile/personal_access_tokens.md), [de projet](../user/project/settings/project_access_tokens.md) ou [de groupe](../user/group/settings/group_access_tokens.md).
- Utiliser un [assistant d'informations d'identification OAuth](../user/profile/account/two_factor_authentication.md#oauth-credential-helpers).

## Lier l'identité SAML à un utilisateur existant {#link-saml-identity-for-an-existing-user}

Un administrateur peut configurer GitLab pour lier automatiquement les utilisateurs SAML aux utilisateurs GitLab existants. Pour plus d'informations, consultez [Configurer la prise en charge SAML dans GitLab](#configure-saml-support-in-gitlab).

Un utilisateur peut lier manuellement son identité SAML à un compte GitLab existant. Pour plus d'informations, consultez [Activer OmniAuth pour un utilisateur existant](omniauth.md#enable-omniauth-for-an-existing-user).

## Configurer le SSO SAML de groupe sur GitLab Self-Managed {#configure-group-saml-sso-on-gitlab-self-managed}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez le SSO SAML de groupe si vous devez autoriser l'accès via plusieurs IdPs SAML sur votre instance GitLab Self-Managed.

Pour configurer le SSO SAML de groupe :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

1. Assurez-vous que GitLab est [configuré avec HTTPS](https://docs.gitlab.com/omnibus/settings/ssl/).
1. Modifiez `/etc/gitlab/gitlab.rb` pour activer OmniAuth et le fournisseur `group_saml` :

   ```ruby
   gitlab_rails['omniauth_enabled'] = true
   gitlab_rails['omniauth_providers'] = [{ name: 'group_saml' }]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Assurez-vous que GitLab est [configuré avec HTTPS](https://docs.gitlab.com/charts/installation/tls/).
1. Placez le contenu suivant dans un fichier nommé `group_saml.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

   ```yaml
   name: 'group_saml'
   ```

1. Créez le Secret Kubernetes :

   ```shell
   kubectl create secret generic -n <namespace> gitlab-group-saml --from-file=provider=group_saml.yaml
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` pour activer OmniAuth et le fournisseur `group_saml` :

   ```yaml
   global:
     appConfig:
       omniauth:
         enabled: true
         providers:
           - secret: gitlab-group-saml
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Assurez-vous que GitLab est [configuré avec HTTPS](https://docs.gitlab.com/omnibus/settings/ssl/).
1. Modifiez `docker-compose.yml` pour activer OmniAuth et le fournisseur `group_saml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_enabled'] = true
           gitlab_rails['omniauth_providers'] = [{ name: 'group_saml' }]
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

1. Assurez-vous que GitLab est [configuré avec HTTPS](../install/self_compiled/_index.md#using-https).
1. Modifiez `/home/git/gitlab/config/gitlab.yml` pour activer OmniAuth et le fournisseur `group_saml` :

   ```yaml
   production: &base
     omniauth:
       enabled: true
       providers:
         - { name: 'group_saml' }
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

En tant que solution multi-locataire, le SAML de groupe sur GitLab Self-Managed est limité par rapport au [SAML à l'échelle de l'instance](saml.md) recommandé. Utilisez le SAML à l'échelle de l'instance pour bénéficier de :

- [Compatibilité LDAP](../administration/auth/ldap/_index.md)
- [Synchronisation des groupes LDAP](../user/group/access_and_permissions.md#manage-group-memberships-with-ldap)
- [Groupes requis](#required-groups)
- [Groupes administrateurs](#administrator-groups)
- [Groupes auditeurs](#auditor-groups)

## Configuration supplémentaire pour les applications SAML sur votre IdP {#additional-configuration-for-saml-apps-on-your-idp}

Lors de la configuration d'une application SAML sur l'IdP, votre IdP peut nécessiter une configuration supplémentaire, telle que :

| Champ | Valeur | Notes |
|-------|-------|-------|
| Profil SAML | Profil SSO de navigateur web | GitLab utilise SAML pour connecter les utilisateurs via leur navigateur. Aucune requête n'est effectuée directement auprès de l'IdP. |
| Liaison de requête SAML | Redirection HTTP | GitLab (le SP) redirige les utilisateurs vers votre IdP avec un paramètre HTTP `SAMLRequest` encodé en base64. |
| Liaison de réponse SAML | HTTP POST | Spécifie comment le jeton SAML est envoyé par votre IdP. Inclut le `SAMLResponse`, que le navigateur d'un utilisateur soumet à GitLab. |
| Signer la réponse SAML | Obligatoire | Empêche la falsification. |
| Certificat X.509 dans la réponse | Obligatoire | Signe la réponse et la vérifie par rapport à l'empreinte fournie. |
| Algorithme d'empreinte | SHA-1 | GitLab utilise un hachage SHA-1 du certificat pour signer la réponse SAML. |
| Algorithme de signature | SHA-1/SHA-256/SHA-384/SHA-512 | Détermine la façon dont une réponse est signée. Également connu sous le nom de méthode de condensat, cet algorithme peut être spécifié dans la réponse SAML. |
| Chiffrement de l'assertion SAML | Facultatif | Utilise TLS entre votre fournisseur d'identité, le navigateur de l'utilisateur et GitLab. |
| Signature de l'assertion SAML | Facultatif | Valide l'intégrité d'une assertion SAML. Lorsqu'elle est active, signe l'ensemble de la réponse. |
| Vérification de la signature des requêtes SAML | Facultatif | Vérifie la signature de la réponse SAML. |
| RelayState par défaut | Facultatif | Spécifie les sous-chemins de l'URL de base sur lesquels les utilisateurs doivent arriver après s'être connectés via SAML auprès de votre IdP. |
| Format NameID | Persistant | Voir [les détails du format NameID](../user/group/saml_sso/_index.md#manage-user-saml-identity). |
| URL supplémentaires | Facultatif | Peut inclure l'émetteur, l'identifiant ou l'URL du service consommateur d'assertion dans d'autres champs selon les fournisseurs. |

Pour des exemples de configurations, consultez les [notes sur les fournisseurs spécifiques](#set-up-identity-providers).

## Configurer SAML avec Geo {#configure-saml-with-geo}

Pour configurer Geo avec SAML, consultez [Configuration de SAML à l'échelle de l'instance](../administration/geo/replication/single_sign_on.md#configuring-instance-wide-saml).

Pour plus d'informations, consultez [Geo avec Single Sign On (SSO)](../administration/geo/replication/single_sign_on.md).

## Dépannage {#troubleshooting}

Consultez notre [guide de dépannage SAML](../user/group/saml_sso/troubleshooting.md).

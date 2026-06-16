---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Authentification par carte à puce
description: "Authentification à l'aide de périphériques matériels pour une connexion basée sur des certificats."
---

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab prend en charge l'authentification par carte à puce.

## Authentification par mot de passe existante {#existing-password-authentication}

Par défaut, les utilisateurs existants peuvent continuer à se connecter avec un nom d'utilisateur et un mot de passe lorsque l'authentification par carte à puce est activée.

Pour forcer les utilisateurs existants à utiliser uniquement l'authentification par carte à puce, [désactivez l'authentification par nom d'utilisateur et mot de passe](../settings/sign_in_restrictions.md#password-and-passkey-authentication).

## Méthodes d'authentification {#authentication-methods}

GitLab prend en charge deux méthodes d'authentification :

- Certificats X.509 avec bases de données locales.
- Serveurs LDAP.

### Authentification auprès d'une base de données locale avec des certificats X.509 {#authentication-against-a-local-database-with-x509-certificates}

{{< details >}}

- Statut :  Expérimental

{{< /details >}}

Les cartes à puce avec certificats X.509 peuvent être utilisées pour s'authentifier auprès de GitLab.

Pour utiliser une carte à puce avec un certificat X.509 pour s'authentifier auprès d'une base de données locale avec GitLab, `CN` et `emailAddress` doivent être définis dans le certificat. Par exemple :

```plaintext
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 12856475246677808609 (0xb26b601ecdd555e1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O=Random Corp Ltd, CN=Random Corp
        Validity
            Not Before: Oct 30 12:00:00 2018 GMT
            Not After : Oct 30 12:00:00 2019 GMT
        Subject: CN=Gitlab User, emailAddress=gitlab-user@example.com
```

### Authentification auprès d'une base de données locale avec des certificats X.509 et l'extension SAN {#authentication-against-a-local-database-with-x509-certificates-and-san-extension}

{{< details >}}

- Statut :  Expérimental

{{< /details >}}

Les cartes à puce avec certificats X.509 utilisant des extensions SAN peuvent être utilisées pour s'authentifier auprès de GitLab.

Pour utiliser une carte à puce avec un certificat X.509 pour s'authentifier auprès d'une base de données locale avec GitLab :

- Au moins une des extensions `subjectAltName` (SAN) doit définir l'identité de l'utilisateur (`email`) au sein de l'instance GitLab (`URI`).
- L'`URI` doit correspondre à `Gitlab.config.host.gitlab`.
- Si votre certificat ne contient qu'**one** entrée d'e-mail SAN, vous n'avez pas besoin de l'ajouter ou de la modifier pour faire correspondre l'`email` avec l'`URI`.

Par exemple :

```plaintext
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 12856475246677808609 (0xb26b601ecdd555e1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O=Random Corp Ltd, CN=Random Corp
        Validity
            Not Before: Oct 30 12:00:00 2018 GMT
            Not After : Oct 30 12:00:00 2019 GMT
        ...
        X509v3 extensions:
            X509v3 Key Usage:
                Key Encipherment, Data Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Subject Alternative Name:
                email:gitlab-user@example.com, URI:http://gitlab.example.com/
```

### Authentification auprès d'un serveur LDAP {#authentication-against-an-ldap-server}

{{< details >}}

- Statut :  Expérimental

{{< /details >}}

GitLab met en œuvre une méthode standard de correspondance de certificats en suivant [RFC4523](https://www.rfc-editor.org/rfc/rfc4523). Il utilise la règle de correspondance de certificats `certificateExactMatch` sur l'attribut `userCertificate`. Comme prérequis, vous devez utiliser un serveur LDAP qui :

- Prend en charge la règle de correspondance `certificateExactMatch`.
- Possède le certificat stocké dans l'attribut `userCertificate`.

### Authentification auprès d'un serveur LDAP Active Directory {#authentication-against-an-active-directory-ldap-server}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/328074) dans GitLab 16.9.
- [Ajout](https://gitlab.com/gitlab-org/gitlab/-/issues/514025) des formats `reverse_issuer_and_subject` et `reverse_issuer_and_serial_number` dans GitLab 17.11.
- Les formats `issuer_and_subject`, `reverse_issuer_and_subject` et `subject` ont été [mis à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208209) dans GitLab 18.6 [avec un indicateur](../feature_flags/_index.md) nommé `smartcard_ad_formats_v2`. Activé par défaut. Désactivez cet indicateur pour rétablir ces formats aux versions précédentes.
- [Disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/577375) dans GitLab 18.9. L'indicateur de feature flag `smartcard_ad_formats_v2` a été supprimé.

{{< /history >}}

> [!flag]
> La fonctionnalité de cette fonction est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Active Directory ne prend pas en charge la règle `certificateExactMatch` ni l'attribut `userCertificate`. La plupart des outils d'authentification basée sur des certificats, tels que les cartes à puce, utilisent l'attribut `altSecurityIdentities`, qui peut contenir plusieurs certificats pour chaque utilisateur. Les données du champ doivent correspondre à [l'un des formats recommandés par Microsoft](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-certificate-based-authentication-certificateuserids#supported-patterns-for-certificate-user-ids).

Utilisez les attributs suivants pour personnaliser le champ que GitLab vérifie et le format des données de certificat :

- `smartcard_ad_cert_field` - indique le nom du champ à rechercher. Il peut s'agir de n'importe quel attribut d'un objet utilisateur.
- `smartcard_ad_cert_format` - indique le format des informations extraites du certificat. Ce format doit être l'une des valeurs suivantes. La valeur la plus courante est `issuer_and_serial_number` pour correspondre au comportement des serveurs LDAP non Active Directory.

| `smartcard_ad_cert_format` | Exemple de données                                                 |
| -------------------------- | ------------------------------------------------------------ |
| `principal_name`           | `X509:<PN>alice@example.com`                                 |
| `rfc822_name`              | `X509:<RFC822>bob@example.com`                               |
| `subject`                  | `X509:<S>CN=dennis,OU=UserAccounts,DC=example,DC=com`        |
| `issuer_and_serial_number` | `X509:<I>CN=CONTOSO-DC-CA,DC=example,DC=com<SR>1181914561`   |
| `issuer_and_subject`       | `X509:<I>CN=EXAMPLE-DC-CA,DC=example,DC=com<S>CN=cynthia,OU=UserAccounts,DC=example,DC=com` |
| `reverse_issuer_and_serial_number` | `X509:<I>DC=com,DC=example,CN=CONTOSO-DC-CA<SR>1181914561`   |
| `reverse_issuer_and_subject`   | `X509:<I>DC=com,DC=example,CN=CONTOSO-DC-CA<S>CN=cynthia,OU=UserAccounts,DC=example,DC=com` |
| `reverse_issuer_and_reverse_subject`   | `X509:<I>DC=com,DC=example,CN=CONTOSO-DC-CA<S>DC=com,DC=example,OU=UserAccounts,CN=cynthia` |

Pour `issuer_and_serial_number`, la portion `<SR>` est en ordre d'octets inversé, avec l'octet le moins significatif en premier. Pour plus d'informations, consultez [comment mapper un utilisateur à un certificat à l'aide de l'attribut altSecurityIdentities](https://learn.microsoft.com/en-us/archive/blogs/spatdsg/howto-map-a-user-to-a-certificate-via-all-the-methods-available-in-the-altsecurityidentities-attribute).

Les formats d'émetteur inversés trient la chaîne d'émetteur de la plus petite unité à la plus grande. Certains serveurs Active Directory stockent les certificats dans ce format.

> [!note]
> Si aucun `smartcard_ad_cert_format` n'est spécifié, mais qu'un serveur LDAP est configuré avec `active_directory: true` et les cartes à puce activées, GitLab adopte par défaut le comportement de la version 16.8 et antérieures, et utilise `certificateExactMatch` sur l'attribut `userCertificate`.

### Authentification auprès d'Entra ID Domain Services {#authentication-against-entra-id-domain-services}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/328074) dans GitLab 16.9.

{{< /history >}}

[Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/fundamentals/whatis), anciennement connu sous le nom d'Azure Active Directory, fournit un annuaire basé sur le cloud pour les entreprises et les organisations. [Entra Domain Services](https://learn.microsoft.com/en-us/entra/identity/domain-services/overview) fournit une interface LDAP sécurisée en lecture seule vers l'annuaire, mais n'expose qu'un sous-ensemble limité des champs disponibles dans Entra ID.

Entra ID utilise le champ `CertificateUserIds` pour gérer les certificats clients des utilisateurs, mais ce champ n'est pas exposé dans LDAP / Entra ID Domain Services. Avec une configuration cloud uniquement, il n'est pas possible pour GitLab d'authentifier les cartes à puce des utilisateurs via LDAP.

Dans un environnement hybride sur site et cloud, les entités sont synchronisées entre le contrôleur Active Directory sur site et le cloud Entra ID via [Entra Connect](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/whatis-azure-ad-connect-v2). Si vous [synchronisez votre attribut `altSecurityIdentities` avec `certificateUserIds` dans Entra ID à l'aide d'Entra ID Connect](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-certificate-based-authentication-certificateuserids#update-certificateuserids-using-microsoft-entra-connect), vous pouvez exposer ces données dans LDAP / Entra ID Domain Services afin qu'elles puissent être authentifiées par GitLab :

1. Ajoutez une règle à Entra ID Connect pour synchroniser l'`altSecurityIdentities` avec un attribut supplémentaire dans Entra ID.
1. Activez cet attribut supplémentaire en tant qu'[attribut d'extension dans Entra ID Domain Services](https://learn.microsoft.com/en-us/entra/identity/domain-services/concepts-custom-attributes).
1. Configurez le champ `smartcard_ad_cert_field` dans GitLab pour utiliser cet attribut d'extension.

## Configurer GitLab pour l'authentification par carte à puce {#configure-gitlab-for-smart-card-authentication}

Pour les installations de packages Linux :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Allow smart card authentication
   gitlab_rails['smartcard_enabled'] = true

   # Path to a file containing a CA certificate
   gitlab_rails['smartcard_ca_file'] = "/etc/ssl/certs/CA.pem"

   # Host and port where the client side certificate is requested by the
   # webserver (NGINX/Apache)
   gitlab_rails['smartcard_client_certificate_required_host'] = "smartcard.example.com"
   gitlab_rails['smartcard_client_certificate_required_port'] = 3444
   ```

   > [!note]
   > Attribuez une valeur à au moins l'une des variables suivantes : `gitlab_rails['smartcard_client_certificate_required_host']` ou `gitlab_rails['smartcard_client_certificate_required_port']`.

1. Enregistrez le fichier et [reconfigurez](../restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab pour que les modifications prennent effet.

Pour les installations compilées manuellement :

1. Configurez NGINX pour demander un certificat côté client

   Dans la configuration NGINX, un contexte serveur **additional** doit être défini avec la même configuration, à l'exception des éléments suivants :

   - Le contexte serveur NGINX supplémentaire doit être configuré pour s'exécuter sur un port différent :

     ```plaintext
     listen *:3444 ssl;
     ```

   - Il peut également être configuré pour s'exécuter sur un nom d'hôte différent :

     ```plaintext
     listen smartcard.example.com:443 ssl;
     ```

   - Le contexte serveur NGINX supplémentaire doit être configuré pour exiger le certificat côté client :

     ```plaintext
     ssl_verify_depth 2;
     ssl_client_certificate /etc/ssl/certs/CA.pem;
     ssl_verify_client on;
     ```

   - Le contexte serveur NGINX supplémentaire doit être configuré pour transmettre le certificat côté client :

     ```plaintext
     proxy_set_header    X-SSL-Client-Certificate    $ssl_client_escaped_cert;
     ```

   Par exemple, voici un exemple de contexte serveur dans un fichier de configuration NGINX (tel que `/etc/nginx/sites-available/gitlab-ssl`) :

   ```plaintext
   server {
       listen smartcard.example.com:3443 ssl;

       # certificate for configuring SSL
       ssl_certificate /path/to/example.com.crt;
       ssl_certificate_key /path/to/example.com.key;

       ssl_verify_depth 2;
       # CA certificate for client side certificate verification
       ssl_client_certificate /etc/ssl/certs/CA.pem;
       ssl_verify_client on;

       location / {
           proxy_set_header    Host                        $http_host;
           proxy_set_header    X-Real-IP                   $remote_addr;
           proxy_set_header    X-Forwarded-For             $proxy_add_x_forwarded_for;
           proxy_set_header    X-Forwarded-Proto           $scheme;
           proxy_set_header    Upgrade                     $http_upgrade;
           proxy_set_header    Connection                  $connection_upgrade;

           proxy_set_header    X-SSL-Client-Certificate    $ssl_client_escaped_cert;

           proxy_read_timeout 300;

           proxy_pass http://gitlab-workhorse;
       }
   }
   ```

1. Modifiez `config/gitlab.yml` :

   ```yaml
   ## Smart card authentication settings
   smartcard:
     # Allow smart card authentication
     enabled: true

     # Path to a file containing a CA certificate
     ca_file: '/etc/ssl/certs/CA.pem'

     # Host and port where the client side certificate is requested by the
     # webserver (NGINX/Apache)
     client_certificate_required_host: smartcard.example.com
     client_certificate_required_port: 3443
   ```

   > [!note]
   > Attribuez une valeur à au moins l'une des variables suivantes : `client_certificate_required_host` ou `client_certificate_required_port`.

1. Enregistrez le fichier et [redémarrez](../restart_gitlab.md#self-compiled-installations) GitLab pour que les modifications prennent effet.

### Recommandations de sécurité supplémentaires {#additional-security-recommendations}

Pour une sécurité renforcée, déployez GitLab derrière un pare-feu tel que CloudFlare WAF ou un serveur exécutant [ModSecurity](https://modsecurity.org/). Les URL correspondant aux modèles suivants doivent être accessibles au NGINX déployé dans le cadre de GitLab, mais pas aux clients externes :

```plaintext
/-/smartcard/extract_certificate
/-/smartcard/verify_certificate
```

Ces chemins ne doivent être accessibles de l'extérieur qu'en utilisant le nom d'hôte et le port de la carte à puce alloués à NGINX, et ne doivent pas être accessibles de l'extérieur en utilisant le nom d'hôte et le port principaux de GitLab. Cela doit être robuste contre les [attaques par en-tête d'hôte HTTP](https://portswigger.net/web-security/host-header), afin que les utilisateurs ne puissent pas soumettre leurs propres paramètres de certificat sans passer par NGINX.

### Étapes supplémentaires lors de l'utilisation des extensions SAN {#additional-steps-when-using-san-extensions}

Pour les installations de packages Linux :

1. Ajoutez à `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['smartcard_san_extensions'] = true
   ```

1. Enregistrez le fichier et [reconfigurez](../restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab pour que les modifications prennent effet.

Pour les installations compilées manuellement :

1. Ajoutez la ligne `san_extensions` dans `config/gitlab.yml` dans la section de la carte à puce :

   ```yaml
   smartcard:
      enabled: true
      ca_file: '/etc/ssl/certs/CA.pem'
      client_certificate_required_port: 3444

      # Enable the use of SAN extensions to match users with certificates
      san_extensions: true
   ```

1. Enregistrez le fichier et [redémarrez](../restart_gitlab.md#self-compiled-installations) GitLab pour que les modifications prennent effet.

### Étapes supplémentaires lors de l'authentification auprès d'un serveur LDAP {#additional-steps-when-authenticating-against-an-ldap-server}

Pour les installations de packages Linux :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_servers'] = YAML.load <<-EOS
   main:
     # snip...
     # Enable smart card authentication against the LDAP server. Valid values
     # are "false", "optional", and "required".
     smartcard_auth: optional

     # If your LDAP server is Active Directory, you can configure these two fields.
     # Specify which field contains certificate information, 'altSecurityIdentities' by default
     smartcard_ad_cert_field: altSecurityIdentities

     # Specify format of certificate information. Valid values are:
     # principal_name, rfc822_name, issuer_and_subject, subject, issuer_and_serial_number
     smartcard_ad_cert_format: issuer_and_serial_number
   EOS
   ```

1. Enregistrez le fichier et [reconfigurez](../restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab pour que les modifications prennent effet.

Pour les installations compilées manuellement :

1. Modifiez `config/gitlab.yml` :

   ```yaml
   production:
     ldap:
       servers:
         main:
           # snip...
           # Enable smart card authentication against the LDAP server. Valid values
           # are "false", "optional", and "required".
           smartcard_auth: optional

           # If your LDAP server is Active Directory, you can configure these two fields.
           # Specify which field contains certificate information, 'altSecurityIdentities' by default
           smartcard_ad_cert_field: altSecurityIdentities

           # Specify format of certificate information. Valid values are:
           # principal_name, rfc822_name, issuer_and_subject, subject, issuer_and_serial_number
           smartcard_ad_cert_format: issuer_and_serial_number
   ```

1. Enregistrez le fichier et [redémarrez](../restart_gitlab.md#self-compiled-installations) GitLab pour que les modifications prennent effet.

### Exiger une session de navigateur avec connexion par carte à puce pour l'accès Git {#require-browser-session-with-smart-card-sign-in-for-git-access}

Pour les installations de packages Linux :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['smartcard_required_for_git_access'] = true
   ```

1. Enregistrez le fichier et [reconfigurez](../restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab pour que les modifications prennent effet.

Pour les installations compilées manuellement :

1. Modifiez `config/gitlab.yml` :

   ```yaml
   ## Smart card authentication settings
   smartcard:
     # snip...
     # Browser session with smart card sign-in is required for Git access
     required_for_git_access: true
   ```

1. Enregistrez le fichier et [redémarrez](../restart_gitlab.md#self-compiled-installations) GitLab pour que les modifications prennent effet.

## Mots de passe pour les utilisateurs créés via l'authentification par carte à puce {#passwords-for-users-created-via-smart-card-authentication}

Le guide [Mots de passe générés pour les utilisateurs créés via l'authentification intégrée](../../user/profile/user_passwords.md) fournit un aperçu de la façon dont GitLab génère et définit les mots de passe pour les utilisateurs créés via l'authentification par carte à puce.

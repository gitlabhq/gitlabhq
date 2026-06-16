---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Intégrer LDAP à GitLab
description: "Intégrer les services d'annuaire pour une authentification centralisée."
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab s'intègre avec [LDAP - Lightweight Directory Access Protocol](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol) pour prendre en charge l'authentification des utilisateurs.

Cette intégration fonctionne avec la plupart des serveurs d'annuaire conformes à LDAP, notamment :

- Microsoft Active Directory.
- Apple Open Directory.
- OpenLDAP.
- 389 Server.

> [!note]
> GitLab ne prend pas en charge les [Microsoft Active Directory Trusts](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc771568(v=ws.10)).

Les utilisateurs ajoutés via LDAP :

- Utilisent généralement un [siège sous licence](../../../subscriptions/manage_seats.md#billable-users).
- Peuvent s'authentifier avec Git en utilisant leur nom d'utilisateur GitLab ou leur e-mail et leur mot de passe LDAP, même si l'authentification par mot de passe pour Git [est désactivée](../../settings/sign_in_restrictions.md#allow-password-authentication-for-git-over-https).

Le nom distinctif (DN) LDAP est associé aux utilisateurs GitLab existants lorsque :

- L'utilisateur existant se connecte à GitLab avec LDAP pour la première fois.
- L'adresse e-mail LDAP est l'adresse e-mail principale d'un utilisateur GitLab existant. Si l'attribut e-mail LDAP n'est pas trouvé dans la base de données des utilisateurs GitLab, un nouvel utilisateur est créé.

Si un utilisateur GitLab existant souhaite activer la connexion LDAP pour lui-même, il doit :

1. Vérifier que son adresse e-mail GitLab correspond à son adresse e-mail LDAP.
1. Se connecter à GitLab en utilisant ses identifiants LDAP.

> [!note]
> Après qu'un utilisateur a lié une identité LDAP à son compte GitLab, il ne peut plus utiliser le flux d'authentification standard par nom d'utilisateur et mot de passe. À la place, les utilisateurs doivent s'authentifier avec leurs identifiants LDAP. Les tentatives de connexion avec leur nom d'utilisateur et leur mot de passe renvoient une [erreur de connexion ou de mot de passe invalide](ldap-troubleshooting.md#users-see-an-error-invalid-login-or-password).

## Sécurité {#security}

GitLab vérifie si un utilisateur est toujours actif dans LDAP.

Les utilisateurs sont considérés comme inactifs dans LDAP lorsqu'ils :

- Sont entièrement supprimés de l'annuaire.
- Résident en dehors du DN `base` configuré ou de la recherche `user_filter`.
- Sont marqués comme désactivés ou désactivés dans Active Directory via l'attribut de contrôle de compte d'utilisateur. Cela signifie que l'attribut `userAccountControl:1.2.840.113556.1.4.803` a le bit 2 défini.

Pour vérifier si un utilisateur est actif ou inactif dans LDAP, utilisez la commande PowerShell suivante et le [module Active Directory](https://learn.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2022-ps) pour vérifier Active Directory :

```powershell
Get-ADUser -Identity <username> -Properties userAccountControl | Select-Object Name, userAccountControl
```

GitLab vérifie le statut des utilisateurs LDAP :

- Lors de la connexion en utilisant un fournisseur d'authentification quelconque.
- Une fois par heure pour les sessions Web actives ou les requêtes Git utilisant des jetons ou des clés SSH.
- Lors de l'exécution de requêtes Git via HTTP en utilisant le nom d'utilisateur et le mot de passe LDAP.
- Une fois par jour lors de la [synchronisation des utilisateurs](ldap_synchronization.md#user-sync).

Si l'utilisateur n'est plus actif dans LDAP, il est :

- Déconnecté.
- Placé dans un statut `ldap_blocked`.
- Incapable de se connecter en utilisant un fournisseur d'authentification quelconque jusqu'à ce qu'il soit réactivé dans LDAP.

### Risques de sécurité {#security-risks}

Vous ne devriez utiliser l'intégration LDAP que si vos utilisateurs LDAP ne peuvent pas :

- Modifier leurs attributs `mail`, `email` ou `userPrincipalName` sur le serveur LDAP. Ces utilisateurs peuvent potentiellement prendre le contrôle de n'importe quel compte sur votre serveur GitLab.
- Partager des adresses e-mail. Les utilisateurs LDAP ayant la même adresse e-mail peuvent partager le même compte GitLab.

## Configurer LDAP {#configure-ldap}

Prérequis :

- Vous devez avoir une adresse e-mail pour utiliser LDAP, que vous utilisiez ou non cette adresse e-mail pour vous connecter.

Pour configurer LDAP, vous modifiez les paramètres dans un fichier de configuration :

- Votre fichier de configuration doit contenir les [paramètres de configuration de base](#basic-configuration-settings) suivants :
  - `label`
  - `host`
  - `port`
  - `uid`
  - `base`
  - `encryption`
- Vous pouvez inclure les paramètres facultatifs suivants dans votre fichier de configuration :
  - [Paramètres de configuration de base facultatifs](#basic-configuration-settings).
  - [Paramètres SSL](#ssl-configuration-settings).
  - [Paramètres des attributs](#attribute-configuration-settings).
  - [Paramètres de synchronisation LDAP](#ldap-sync-configuration-settings).
- Vous pouvez également configurer LDAP pour :
  - [Utiliser plusieurs serveurs](#use-multiple-ldap-servers).
  - [Filtrer les utilisateurs](#set-up-ldap-user-filter).
  - [Définir automatiquement les noms d'utilisateur LDAP en minuscules](#enable-ldap-username-lowercase).
  - [Désactiver la connexion Web LDAP](#disable-ldap-web-sign-in).
  - [Fournir une authentification par carte à puce pour GitLab](#provide-smart-card-authentication-for-gitlab)
  - [Utiliser des identifiants chiffrés](#use-encrypted-credentials).

Le fichier que vous modifiez varie en fonction de votre configuration GitLab :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'label' => 'LDAP',
       'host' => 'ldap.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'bind_dn' => 'CN=Gitlab,OU=Users,DC=domain,DC=com',
       'password' => '<bind_user_password>',
       'encryption' => 'simple_tls',
       'verify_certificates' => true,
       'timeout' => 10,
       'active_directory' => false,
       'user_filter' => '(employeeType=developer)',
       'base' => 'dc=example,dc=com',
       'lowercase_usernames' => 'false',
       'retry_empty_result_with_codes' => [80],
       'allow_username_or_email_login' => false,
       'block_auto_created_users' => false
     }
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             label: 'LDAP'
             host: 'ldap.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             bind_dn: 'CN=Gitlab,OU=Users,DC=domain,DC=com'
             password: '<bind_user_password>'
             encryption: 'simple_tls'
             verify_certificates: true
             timeout: 10
             active_directory: false
             user_filter: '(employeeType=developer)'
             base: 'dc=example,dc=com'
             lowercase_usernames: false
             retry_empty_result_with_codes: [80]
             allow_username_or_email_login: false
             block_auto_created_users: false
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

Pour plus d'informations, voir [comment configurer LDAP pour une instance GitLab installée à l'aide du chart Helm](https://docs.gitlab.com/charts/charts/globals/#ldap).

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_enabled'] = true
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'label' => 'LDAP',
               'host' => 'ldap.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'bind_dn' => 'CN=Gitlab,OU=Users,DC=domain,DC=com',
               'password' => '<bind_user_password>',
               'encryption' => 'simple_tls',
               'verify_certificates' => true,
               'timeout' => 10,
               'active_directory' => false,
               'user_filter' => '(employeeType=developer)',
               'base' => 'dc=example,dc=com',
               'lowercase_usernames' => 'false',
               'retry_empty_result_with_codes' => [80],
               'allow_username_or_email_login' => false,
               'block_auto_created_users' => false
             }
           }
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
     ldap:
       enabled: true
       servers:
         main:
           label: 'LDAP'
           host: 'ldap.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           bind_dn: 'CN=Gitlab,OU=Users,DC=domain,DC=com'
           password: '<bind_user_password>'
           encryption: 'simple_tls'
           verify_certificates: true
           timeout: 10
           active_directory: false
           user_filter: '(employeeType=developer)'
           base: 'dc=example,dc=com'
           lowercase_usernames: false
           retry_empty_result_with_codes: [80]
           allow_username_or_email_login: false
           block_auto_created_users: false
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

Pour plus d'informations sur les différentes options LDAP, consultez le paramètre `ldap` dans [`gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example).

{{< /tab >}}

{{< /tabs >}}

Après avoir configuré LDAP, pour tester la configuration, utilisez la [tâche Rake de vérification LDAP](../../raketasks/ldap.md#check).

### Paramètres de configuration de base {#basic-configuration-settings}

Les paramètres de base suivants sont disponibles :

| Paramètre                         | Requis                             | Type                          | Description |
|---------------------------------|--------------------------------------|-------------------------------|-------------|
| `label`                         | {{< icon name="check-circle" >}} Oui | Chaîne                        | Un nom convivial pour votre serveur LDAP. Il est affiché sur votre page de connexion. Exemple : `'Paris'` ou `'Acme, Ltd.'` |
| `host`                          | {{< icon name="check-circle" >}} Oui | Chaîne                        | Adresse IP ou nom de domaine de votre serveur LDAP. Ignoré lorsque `hosts` est défini. Exemple : `'ldap.mydomain.com'` |
| `port`                          | {{< icon name="check-circle" >}} Oui | Entier                       | Le port de connexion à votre serveur LDAP. Ignoré lorsque `hosts` est défini. Exemple : `389` ou `636` (pour SSL) |
| `uid`                           | {{< icon name="check-circle" >}} Oui | Chaîne                        | L'attribut LDAP qui correspond au nom d'utilisateur que les utilisateurs emploient pour se connecter. Doit être l'attribut, et non la valeur correspondant au `uid`. N'affecte pas le nom d'utilisateur GitLab (voir la [section des attributs](#attribute-configuration-settings)). Exemple : `'sAMAccountName'` ou `'uid'` ou `'userPrincipalName'` |
| `base`                          | {{< icon name="check-circle" >}} Oui | Chaîne                        | Base dans laquelle nous pouvons rechercher des utilisateurs. Exemple : `'ou=people,dc=gitlab,dc=example'` ou `'DC=mydomain,DC=com'` |
| `encryption`                    | {{< icon name="check-circle" >}} Oui | Chaîne                        | Méthode de chiffrement (la clé `method` est dépréciée en faveur de `encryption`). Elle peut prendre l'une des trois valeurs suivantes : `'start_tls'`, `'simple_tls'` ou `'plain'`. `simple_tls` correspond à 'Simple TLS' dans la bibliothèque LDAP. `start_tls` correspond à StartTLS, à ne pas confondre avec le TLS classique. Si vous spécifiez `simple_tls`, il s'agit généralement du port 636, tandis que `start_tls` (StartTLS) utiliserait le port 389. `plain` fonctionne également sur le port 389. |
| `hosts`                         | {{< icon name="dotted-circle" >}} Non | Tableau de chaînes et d'entiers | Un tableau de paires hôte et port pour ouvrir des connexions. Chaque serveur configuré doit avoir un ensemble de données identique. Il ne s'agit pas de configurer plusieurs serveurs LDAP distincts, mais de configurer le basculement. Les hôtes sont essayés dans l'ordre où ils sont configurés. Exemple : `[['ldap1.mydomain.com', 636], ['ldap2.mydomain.com', 636]]` |
| `bind_dn`                       | {{< icon name="dotted-circle" >}} Non | Chaîne                        | Le DN complet de l'utilisateur avec lequel vous vous liez. Exemple : `'america\momo'` ou `'CN=Gitlab,OU=Users,DC=domain,DC=com'` |
| `password`                      | {{< icon name="dotted-circle" >}} Non | Chaîne                        | Le mot de passe de l'utilisateur de liaison. |
| `verify_certificates`           | {{< icon name="dotted-circle" >}} Non | Booléen                       | La valeur par défaut est `true`. Active la vérification du certificat SSL si la méthode de chiffrement est `start_tls` ou `simple_tls`. Si la valeur est `false`, aucune validation du certificat SSL du serveur LDAP n'est effectuée. |
| `timeout`                       | {{< icon name="dotted-circle" >}} Non | Entier                       | La valeur par défaut est `10`. Définissez un délai d'expiration, en secondes, pour les requêtes LDAP. Cela permet d'éviter de bloquer une requête si le serveur LDAP ne répond plus. Une valeur de `0` signifie qu'il n'y a pas de délai d'expiration. |
| `active_directory`              | {{< icon name="dotted-circle" >}} Non | Booléen                       | Ce paramètre indique si le serveur LDAP est un serveur LDAP Active Directory. Pour les serveurs non-AD, les requêtes spécifiques à AD sont ignorées. Si votre serveur LDAP n'est pas AD, définissez cette valeur sur false. |
| `allow_username_or_email_login` | {{< icon name="dotted-circle" >}} Non | Booléen                       | La valeur par défaut est `false`. Si activé, GitLab ignore tout ce qui suit le premier `@` dans le nom d'utilisateur LDAP soumis par l'utilisateur lors de la connexion. Si vous utilisez `uid: 'userPrincipalName'` sur ActiveDirectory, vous devez désactiver ce paramètre, car le `userPrincipalName` contient un `@`. |
| `block_auto_created_users`      | {{< icon name="dotted-circle" >}} Non | Booléen                       | La valeur par défaut est `false`. Pour maintenir un contrôle strict sur le nombre d'utilisateurs facturables sur votre installation GitLab, activez ce paramètre pour garder les nouveaux utilisateurs bloqués jusqu'à ce qu'ils aient été validés par un administrateur. |
| `user_filter`                   | {{< icon name="dotted-circle" >}} Non | Chaîne                        | Filtrer les utilisateurs LDAP. Respecte le format de la [RFC 4515](https://www.rfc-editor.org/rfc/rfc4515.html). GitLab ne prend pas en charge la syntaxe de filtre personnalisée de `omniauth-ldap`. Exemples de la syntaxe du champ `user_filter` :<br/><br/>- `'(employeeType=developer)'`<br/>- `'(&(objectclass=user)(\|(samaccountname=momo)(samaccountname=toto)))'` |
| `lowercase_usernames`           | {{< icon name="dotted-circle" >}} Non | Booléen                       | Si activé, GitLab convertit le nom en minuscules. |
| `retry_empty_result_with_codes` | {{< icon name="dotted-circle" >}} Non | Tableau                         | Un tableau de codes de réponse de requête LDAP qui tentent de réessayer l'opération si le résultat/contenu est vide. Pour Google Secure LDAP, définissez cette valeur sur `[80]`. |

> [!note]
> GitLab n'est pas affecté par les exigences de liaison plus strictes pour les services Microsoft Active Directory introduites avec le [conseil de sécurité Microsoft ADV190023](https://msrc.microsoft.com/update-guide/en-us/advisory/ADV190023). Pour plus d'informations, voir le [ticket 201894](https://gitlab.com/gitlab-org/gitlab/-/issues/201894#note_2807513217).

### Paramètres de configuration SSL {#ssl-configuration-settings}

Vous pouvez configurer les paramètres SSL sous les paires nom/valeur `tls_options`. Tous les paramètres suivants sont facultatifs :

| Paramètre       | Description | Exemples |
|---------------|-------------|----------|
| `ca_file`     | Spécifie le chemin vers un fichier contenant un certificat CA au format PEM, par exemple si vous avez besoin d'une CA interne. | `'/etc/ca.pem'` |
| `ssl_version` | Spécifie la version SSL qu'OpenSSL doit utiliser, si la valeur par défaut d'OpenSSL n'est pas appropriée. | `'TLSv1_1'` |
| `ciphers`     | Chiffrements SSL spécifiques à utiliser dans la communication avec les serveurs LDAP. | `'ALL:!EXPORT:!LOW:!aNULL:!eNULL:!SSLv2'` |
| `cert`        | Certificat client. | `'-----BEGIN CERTIFICATE----- <REDACTED> -----END CERTIFICATE -----'` |
| `key`         | Clé privée client. | `'-----BEGIN PRIVATE KEY----- <REDACTED> -----END PRIVATE KEY -----'` |

Les exemples ci-dessous illustrent comment définir `ca_file` et `ssl_version` dans `tls_options` :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'label' => 'LDAP',
       'host' => 'ldap.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
       'tls_options' => {
         'ca_file' => '/path/to/ca_file.pem',
         'ssl_version' => 'TLSv1_2'
       }
     }
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             label: 'LDAP'
             host: 'ldap.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
             tls_options:
               ca_file: '/path/to/ca_file.pem'
               ssl_version: 'TLSv1_2'
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

Pour plus d'informations, voir [comment configurer LDAP pour une instance GitLab installée à l'aide du chart Helm](https://docs.gitlab.com/charts/charts/globals/#ldap).

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_enabled'] = true
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'label' => 'LDAP',
               'host' => 'ldap.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
               'tls_options' => {
                 'ca_file' => '/path/to/ca_file.pem',
                 'ssl_version' => 'TLSv1_2'
               }
             }
           }
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
     ldap:
       enabled: true
       servers:
         main:
           label: 'LDAP'
           host: 'ldap.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           encryption: 'simple_tls'
           base: 'dc=example,dc=com'
           tls_options:
             ca_file: '/path/to/ca_file.pem'
             ssl_version: 'TLSv1_2'
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

### Paramètres de configuration des attributs {#attribute-configuration-settings}

GitLab utilise ces attributs LDAP pour créer un compte pour l'utilisateur LDAP. L'attribut spécifié peut être :

- Le nom de l'attribut sous forme de chaîne. Par exemple, `'mail'`.
- Un tableau de noms d'attributs à essayer dans l'ordre. Par exemple, `['mail', 'email']`.

La connexion LDAP de l'utilisateur est l'attribut LDAP [spécifié comme `uid`](#basic-configuration-settings).

Tous les attributs LDAP suivants sont facultatifs. Si vous définissez ces attributs, tous les attributs LDAP suivants sont facultatifs. Vous n'avez besoin de spécifier que les attributs qui diffèrent de la valeur par défaut. Si vous en spécifiez un, par exemple `username`, vous n'avez pas besoin de spécifier les autres, les valeurs par défaut s'appliquent.

Si vous en définissez un, vous devez le faire dans un hachage `attributes`.

| Paramètre      | Description | Valeurs par défaut |
|--------------|-------------|----------|
| `username`   | Le `@username` avec lequel le compte GitLab sera approvisionné. Si la valeur contient une adresse e-mail, le nom d'utilisateur GitLab est la partie de l'adresse e-mail avant le `@`. | Valeur par défaut : l'attribut LDAP [spécifié comme `uid`](#basic-configuration-settings) (`['uid', 'userid', 'sAMAccountName']`). |
| `email`      | Attribut LDAP pour l'e-mail de l'utilisateur. | `['mail', 'email', 'userPrincipalName']` |
| `name`       | Attribut LDAP pour le nom d'affichage de l'utilisateur. Si `name` est vide, le nom complet est tiré de `first_name` et `last_name`. Les attributs `'cn'` ou `'displayName'` portent généralement les noms complets. Vous pouvez également forcer l'utilisation de `first_name` et `last_name` en spécifiant un attribut absent tel que `'somethingNonExistent'`. | `'cn'` |
| `first_name` | Attribut LDAP pour le prénom de l'utilisateur. Utilisé lorsque l'attribut configuré pour `name` n'existe pas. | `'givenName'` |
| `last_name`  | Attribut LDAP pour le nom de famille de l'utilisateur. Utilisé lorsque l'attribut configuré pour `name` n'existe pas. | `'sn'` |

Exemple de configuration qui utilise `displayName` pour le nom de l'utilisateur et un tableau d'attributs pour `email` :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       # Other configuration settings ...
       'attributes' => {
         'username' => 'uid',
         'email' => ['mail', 'email', 'userPrincipalName'],
         'name' => 'displayName',
         'first_name' => 'givenName',
         'last_name' => 'sn'
       }
     }
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             # Other configuration settings ...
             attributes:
               username: 'uid'
               email:
                 - 'mail'
                 - 'email'
                 - 'userPrincipalName'
               name: 'displayName'
               first_name: 'givenName'
               last_name: 'sn'
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
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               # Other configuration settings ...
               'attributes' => {
                 'username' => 'uid',
                 'email' => ['mail', 'email', 'userPrincipalName'],
                 'name' => 'displayName',
                 'first_name' => 'givenName',
                 'last_name' => 'sn'
               }
             }
           }
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
     ldap:
       servers:
         main:
           # Other configuration settings ...
           attributes:
             username: 'uid'
             email:
               - 'mail'
               - 'email'
               - 'userPrincipalName'
             name: 'displayName'
             first_name: 'givenName'
             last_name: 'sn'
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

### Paramètres de configuration de la synchronisation LDAP {#ldap-sync-configuration-settings}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Ces paramètres de configuration de synchronisation LDAP sont facultatifs, à l'exception de `group_base` qui est requis lorsque `external_groups` est configuré :

| Paramètre           | Description | Exemples |
|-------------------|-------------|----------|
| `group_base`      | Base utilisée pour rechercher des groupes. Tous les groupes valides ont cette base dans leur DN. | `'ou=groups,dc=gitlab,dc=example'` |
| `admin_group`     | Le CN d'un groupe contenant les administrateurs GitLab. Pas `cn=administrators` ni le DN complet. | `'administrators'` |
| `external_groups` | Un tableau de CN de groupes contenant des utilisateurs devant être considérés comme externes. Pas `cn=interns` ni le DN complet. | `['interns', 'contractors']` |
| `sync_ssh_keys`   | L'attribut LDAP contenant la clé SSH publique d'un utilisateur. | `'sshPublicKey'` ou false si non défini |

> [!note]
> Si Sidekiq est configuré sur un serveur différent du serveur Rails, vous devez également ajouter la configuration LDAP à chaque serveur Sidekiq pour que la synchronisation LDAP fonctionne.

### Utiliser plusieurs serveurs LDAP {#use-multiple-ldap-servers}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Si vous avez des utilisateurs sur plusieurs serveurs LDAP, vous pouvez configurer GitLab pour les utiliser. Pour ajouter des serveurs LDAP supplémentaires :

1. Dupliquez la [configuration LDAP `main`](#configure-ldap).
1. Modifiez chaque configuration dupliquée avec les détails des serveurs supplémentaires.
   - Pour chaque serveur supplémentaire, choisissez un ID de fournisseur différent, comme `main`, `secondary` ou `tertiary`. Utilisez des caractères alphanumériques en minuscules. GitLab utilise l'ID de fournisseur pour associer chaque utilisateur à un serveur LDAP spécifique.
   - Pour chaque entrée, utilisez une valeur `label` unique. Ces valeurs sont utilisées pour les noms des onglets sur la page de connexion.

L'exemple suivant montre comment configurer trois serveurs LDAP avec une configuration minimale :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'label' => 'GitLab AD',
       'host' => 'ad.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
     },

     'secondary' => {
       'label' => 'GitLab Secondary AD',
       'host' => 'ad-secondary.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
     },

     'tertiary' => {
       'label' => 'GitLab Tertiary AD',
       'host' => 'ad-tertiary.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
     }
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             label: 'GitLab AD'
             host: 'ad.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
           secondary:
             label: 'GitLab Secondary AD'
             host: 'ad-secondary.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
           tertiary:
             label: 'GitLab Tertiary AD'
             host: 'ad-tertiary.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
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
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_enabled'] = true
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'label' => 'GitLab AD',
               'host' => 'ad.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
             },

             'secondary' => {
               'label' => 'GitLab Secondary AD',
               'host' => 'ad-secondary.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
             },

             'tertiary' => {
               'label' => 'GitLab Tertiary AD',
               'host' => 'ad-tertiary.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
             }
           }
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
     ldap:
       enabled: true
       servers:
         main:
           label: 'GitLab AD'
           host: 'ad.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           base: 'dc=example,dc=com'
           encryption: 'simple_tls'
         secondary:
           label: 'GitLab Secondary AD'
           host: 'ad-secondary.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           base: 'dc=example,dc=com'
           encryption: 'simple_tls'
         tertiary:
           label: 'GitLab Tertiary AD'
           host: 'ad-tertiary.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           base: 'dc=example,dc=com'
           encryption: 'simple_tls'
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

Pour plus d'informations sur les différentes options LDAP, consultez le paramètre `ldap` dans [`gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example).

{{< /tab >}}

{{< /tabs >}}

Cet exemple donne une page de connexion avec les onglets suivants :

- **GitLab AD**.
- **GitLab Secondary AD**.
- **GitLab Tertiary AD**.

### Configurer le filtre d'utilisateurs LDAP {#set-up-ldap-user-filter}

Pour limiter l'accès à GitLab à un sous-ensemble des utilisateurs LDAP de votre serveur LDAP, commencez par affiner la `base` configurée. Cependant, pour filtrer davantage les utilisateurs si nécessaire, vous pouvez configurer un filtre d'utilisateurs LDAP. Le filtre doit être conforme à la [RFC 4515](https://www.rfc-editor.org/rfc/rfc4515.html).

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'user_filter' => '(employeeType=developer)'
     }
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             user_filter: '(employeeType=developer)'
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
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'user_filter' => '(employeeType=developer)'
             }
           }
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
     ldap:
       servers:
         main:
           user_filter: '(employeeType=developer)'
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

Pour limiter l'accès aux membres imbriqués d'un groupe Active Directory, utilisez la syntaxe suivante :

```plaintext
(memberOf:1.2.840.113556.1.4.1941:=CN=My Group,DC=Example,DC=com)
```

Pour plus d'informations sur les filtres `LDAP_MATCHING_RULE_IN_CHAIN`, voir [Syntaxe des filtres de recherche](https://learn.microsoft.com/en-us/windows/win32/adsi/search-filter-syntax).

La prise en charge des membres imbriqués dans le filtre utilisateur ne doit pas être confondue avec la prise en charge des [groupes imbriqués dans la synchronisation de groupe](ldap_synchronization.md#supported-ldap-group-typesattributes).

GitLab ne prend pas en charge la syntaxe de filtre personnalisée utilisée par OmniAuth LDAP.

#### Échapper les caractères spéciaux dans `user_filter` {#escape-special-characters-in-user_filter}

Le DN `user_filter` peut contenir des caractères spéciaux. Par exemple :

- Une virgule :

  ```plaintext
  OU=GitLab, Inc,DC=gitlab,DC=com
  ```

- Des crochets ouvrants et fermants :

  ```plaintext
  OU=GitLab (Inc),DC=gitlab,DC=com
  ```

Ces caractères doivent être échappés comme documenté dans la [RFC 4515](https://www.rfc-editor.org/rfc/rfc4515.html#section-4).

- Échappez les virgules avec `\2C`. Par exemple :

  ```plaintext
  OU=GitLab\2C Inc,DC=gitlab,DC=com
  ```

- Échappez les crochets ouvrants avec `\28` et les crochets fermants avec `\29`. Par exemple :

  ```plaintext
  OU=GitLab \28Inc\29,DC=gitlab,DC=com
  ```

### Activer les noms d'utilisateur LDAP en minuscules {#enable-ldap-username-lowercase}

Certains serveurs LDAP, selon leur configuration, peuvent renvoyer des noms d'utilisateur en majuscules. Cela peut entraîner plusieurs problèmes confus, comme la création de liens ou d'espaces de nommage avec des noms en majuscules.

GitLab peut automatiquement mettre en minuscules les noms d'utilisateur fournis par le serveur LDAP en activant l'option de configuration `lowercase_usernames`. Par défaut, cette option de configuration est `false`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'lowercase_usernames' => true
     }
   }
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             lowercase_usernames: true
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
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'lowercase_usernames' => true
             }
           }
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `config/gitlab.yaml` :

   ```yaml
   production:
     ldap:
       servers:
         main:
           lowercase_usernames: true
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

### Désactiver la connexion Web LDAP {#disable-ldap-web-sign-in}

Il peut être utile d'empêcher l'utilisation des identifiants LDAP via l'interface Web lorsqu'une alternative telle que SAML est préférée. Cela permet d'utiliser LDAP pour la synchronisation de groupe, tout en permettant à votre fournisseur d'identité SAML de gérer des vérifications supplémentaires comme la 2FA personnalisée.

Lorsque la connexion Web LDAP est désactivée, les utilisateurs ne voient pas d'onglet **LDAP** sur la page de connexion. Cela ne désactive pas l'utilisation des identifiants LDAP pour l'accès Git.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['prevent_ldap_sign_in'] = true
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       ldap:
         preventSignin: true
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
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['prevent_ldap_sign_in'] = true
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `config/gitlab.yaml` :

   ```yaml
   production:
     ldap:
       prevent_ldap_sign_in: true
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

### Fournir une authentification par carte à puce pour GitLab {#provide-smart-card-authentication-for-gitlab}

Pour plus d'informations sur l'utilisation des cartes à puce avec les serveurs LDAP et GitLab, voir [Authentification par carte à puce](../smartcard.md).

### Utiliser des identifiants chiffrés {#use-encrypted-credentials}

Au lieu de stocker les identifiants d'intégration LDAP en texte clair dans les fichiers de configuration, vous pouvez éventuellement utiliser un fichier chiffré pour les identifiants LDAP.

Prérequis :

- Pour utiliser des identifiants chiffrés, vous devez d'abord activer la [configuration chiffrée](../../encrypted_configuration.md).

La configuration chiffrée pour LDAP existe dans un fichier YAML chiffré. Le contenu non chiffré du fichier doit être un sous-ensemble des paramètres secrets de votre bloc `servers` dans la configuration LDAP.

Les éléments de configuration pris en charge pour le fichier chiffré sont :

- `bind_dn`
- `password`

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Si votre configuration LDAP initiale dans `/etc/gitlab/gitlab.rb` ressemblait à :

   ```ruby
     gitlab_rails['ldap_servers'] = {
       'main' => {
         'bind_dn' => 'admin',
         'password' => '123'
       }
     }
   ```

1. Modifiez le secret chiffré :

   ```shell
   sudo gitlab-rake gitlab:ldap:secret:edit EDITOR=vim
   ```

1. Saisissez le contenu non chiffré du secret LDAP :

   ```yaml
   main:
     bind_dn: admin
     password: '123'
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et supprimez les paramètres pour `bind_dn` et `password`.
1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Utilisez un secret Kubernetes pour stocker le mot de passe LDAP. Pour plus d'informations, consultez [les secrets LDAP Helm](https://docs.gitlab.com/charts/installation/secrets/#ldap-password).

{{< /tab >}}

{{< tab title="Docker" >}}

1. Si votre configuration LDAP initiale dans `docker-compose.yml` ressemblait à :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'bind_dn' => 'admin',
               'password' => '123'
             }
           }
   ```

1. Entrez dans le conteneur et modifiez le secret chiffré :

   ```shell
   sudo docker exec -t <container_name> bash
   gitlab-rake gitlab:ldap:secret:edit EDITOR=vim
   ```

1. Saisissez le contenu non chiffré du secret LDAP :

   ```yaml
   main:
     bind_dn: admin
     password: '123'
   ```

1. Modifiez `docker-compose.yml` et supprimez les paramètres pour `bind_dn` et `password`.
1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Si votre configuration LDAP initiale dans `/home/git/gitlab/config/gitlab.yml` ressemblait à :

   ```yaml
   production:
     ldap:
       servers:
         main:
           bind_dn: admin
           password: '123'
   ```

1. Modifiez le secret chiffré :

   ```shell
   bundle exec rake gitlab:ldap:secret:edit EDITOR=vim RAILS_ENVIRONMENT=production
   ```

1. Saisissez le contenu non chiffré du secret LDAP :

   ```yaml
   main:
    bind_dn: admin
    password: '123'
   ```

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et supprimez les paramètres pour `bind_dn` et `password`.
1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## Mise à jour du DN et de l'e-mail LDAP {#updating-ldap-dn-and-email}

Lorsqu'un serveur LDAP crée un utilisateur dans GitLab, le DN LDAP de l'utilisateur est lié à son compte GitLab en tant qu'identifiant.

Lorsqu'un utilisateur tente de se connecter avec LDAP, GitLab tente de trouver l'utilisateur à l'aide du DN enregistré sur le compte de cet utilisateur.

- Si GitLab trouve l'utilisateur par le DN et l'adresse e-mail de l'utilisateur :
  - Correspond à l'adresse e-mail du compte GitLab, GitLab ne prend aucune mesure supplémentaire.
  - A changé, GitLab met à jour son enregistrement de l'e-mail de l'utilisateur pour correspondre à celui dans LDAP.
- Si GitLab ne peut pas trouver un utilisateur par son DN, il tente de trouver l'utilisateur par son e-mail. Si GitLab :
  - Trouve l'utilisateur par son e-mail, GitLab met à jour le DN stocké dans le compte GitLab de l'utilisateur. Les deux valeurs correspondent désormais aux informations stockées dans LDAP.
  - Ne peut pas trouver l'utilisateur par son adresse e-mail (le DN **et** l'adresse e-mail ont tous les deux changé), voir [Le DN et l'e-mail de l'utilisateur ont changé](ldap-troubleshooting.md#user-dn-and-email-have-changed).

## Désactiver l'authentification LDAP anonyme {#disable-anonymous-ldap-authentication}

GitLab ne prend pas en charge l'authentification client TLS. Effectuez ces étapes sur votre serveur LDAP.

1. Désactivez l'authentification anonyme.
1. Activez l'un des types d'authentification suivants :
   - Authentification simple.
   - Authentification SASL (Simple Authentication and Security Layer).

Le paramètre d'authentification client TLS de votre serveur LDAP ne peut pas être obligatoire et les clients ne peuvent pas être authentifiés avec le protocole TLS.

## Utilisateurs supprimés de LDAP {#users-deleted-from-ldap}

Les utilisateurs supprimés du serveur LDAP :

- Sont immédiatement bloqués pour se connecter à GitLab.
- [Ne consomment plus de licence](../../moderate_users.md).

Cependant, ces utilisateurs peuvent continuer à utiliser Git avec SSH jusqu'à la prochaine exécution du [cache de vérification LDAP](ldap_synchronization.md#adjust-ldap-sync-schedule).

Pour supprimer le compte immédiatement, vous pouvez manuellement [bloquer l'utilisateur](../../moderate_users.md#block-a-user).

## Mettre à jour les adresses e-mail des utilisateurs {#update-user-email-addresses}

Les adresses e-mail sur le serveur LDAP sont considérées comme la source de vérité pour les utilisateurs lorsque LDAP est utilisé pour se connecter.

La mise à jour des adresses e-mail des utilisateurs doit être effectuée sur le serveur LDAP qui gère l'utilisateur. L'adresse e-mail de GitLab est mise à jour soit :

- Lors de la prochaine connexion de l'utilisateur.
- Lors de la prochaine exécution de la [synchronisation des utilisateurs](ldap_synchronization.md#user-sync).

L'ancienne adresse e-mail de l'utilisateur mis à jour devient l'adresse e-mail secondaire pour préserver l'historique des commits de cet utilisateur.

Vous pouvez trouver plus de détails sur le comportement attendu des mises à jour d'utilisateurs dans notre [section de dépannage LDAP](ldap-troubleshooting.md#user-dn-and-email-have-changed).

## Google Secure LDAP {#google-secure-ldap}

[Google Cloud Identity](https://cloud.google.com/identity/) fournit un service LDAP sécurisé qui peut être configuré avec GitLab pour l'authentification et la synchronisation de groupe. Voir [Google Secure LDAP](google_secure_ldap.md) pour des instructions de configuration détaillées.

## Synchroniser les utilisateurs et les groupes {#synchronize-users-and-groups}

Pour plus d'informations sur la synchronisation des utilisateurs et des groupes entre LDAP et GitLab, voir [Synchronisation LDAP](ldap_synchronization.md).

## Passer de LDAP à SAML {#move-from-ldap-to-saml}

1. [Ajouter la configuration SAML](../../../integration/saml.md) à :
   - [`gitlab.rb` pour les installations de package Linux](../../../integration/saml.md).
   - [`values.yml` pour les installations de chart Helm](../../../integration/saml.md).

1. Facultatif. [Désactiver l'authentification LDAP depuis la page de connexion](#disable-ldap-web-sign-in).
1. Facultatif. Pour résoudre les problèmes de liaison des utilisateurs, vous pouvez d'abord [supprimer les identités LDAP de ces utilisateurs](ldap-troubleshooting.md#remove-the-identity-records-that-relate-to-the-removed-ldap-server).
1. Confirmez que les utilisateurs peuvent se connecter à leurs comptes. Si un utilisateur ne peut pas se connecter, vérifiez si le LDAP de cet utilisateur est toujours présent et supprimez-le si nécessaire. Si ce problème persiste, vérifiez les journaux pour identifier le problème.
1. Dans le fichier de configuration, modifiez :
   - `omniauth_auto_link_user` en `saml` uniquement.
   - `omniauth_auto_link_ldap_user` en false.
   - `ldap_enabled` en `false`. Vous pouvez également commenter les paramètres du fournisseur LDAP.

## Dépannage {#troubleshooting}

Consultez notre [guide de l'administrateur pour résoudre les problèmes LDAP](ldap-troubleshooting.md).

---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Intégrer GitLab à Kerberos
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab peut s'intégrer à [Kerberos](https://web.mit.edu/kerberos/) en tant que mécanisme d'authentification.

- Vous pouvez configurer GitLab pour que vos utilisateurs puissent se connecter avec leurs identifiants Kerberos.
- Vous pouvez utiliser Kerberos pour [empêcher](https://web.mit.edu/sipb/doc/working/guide/guide/node20.html) quiconque d'intercepter ou d'espionner le mot de passe transmis.

Kerberos est uniquement disponible sur les instances qui utilisent GitLab Enterprise Edition (EE). Si vous utilisez GitLab Community Edition (CE), vous pouvez [convertir GitLab CE en GitLab EE](../update/convert_to_ee/package.md).

> [!warning]
> GitLab CI/CD ne fonctionne pas avec une instance GitLab sur laquelle Kerberos est activé, sauf si l'intégration est [configurée pour utiliser un port dédié](#http-git-access-with-kerberos-token-passwordless-authentication).

## Configuration {#configuration}

Pour que GitLab propose une authentification basée sur les jetons Kerberos, effectuez les prérequis suivants. Vous devez toujours configurer votre système pour l'utilisation de Kerberos, notamment en spécifiant les royaumes. GitLab utilise les paramètres Kerberos du système.

### Keytab GitLab {#gitlab-keytab}

1. Créez un principal de service Kerberos pour le service HTTP sur votre serveur GitLab. Si votre serveur GitLab est `gitlab.example.com` et votre royaume Kerberos `EXAMPLE.COM`, créez un principal de service `HTTP/gitlab.example.com@EXAMPLE.COM` dans votre base de données Kerberos.
1. Créez un fichier keytab sur le serveur GitLab pour le principal de service. Par exemple, `/etc/http.keytab`.

Le fichier keytab est un fichier sensible qui doit être lisible par l'utilisateur GitLab. Définissez la propriété et protégez le fichier de manière appropriée :

```shell
sudo chown git /etc/http.keytab
sudo chmod 0600 /etc/http.keytab
```

### Configurer GitLab {#configure-gitlab}

#### Installations compilées manuellement {#self-compiled-installations}

> [!note]
> Pour les installations compilées manuellement, assurez-vous que le groupe de gems `kerberos` [a été installé](../install/self_compiled/_index.md#install-gems).

1. Modifiez la section `kerberos` de [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example) pour activer l'authentification par ticket Kerberos. Dans la plupart des cas, vous devez uniquement activer Kerberos et spécifier l'emplacement du fichier keytab :

   ```yaml
   omniauth:
     enabled: true
     allow_single_sign_on: ['kerberos']

   kerberos:
     # Allow the HTTP Negotiate authentication method for Git clients
     enabled: true

     # Kerberos 5 keytab file. The keytab file must be readable by the GitLab user,
     # and should be different from other keytabs in the system.
     # (default: use default keytab from Krb5 config)
     keytab: /etc/http.keytab
   ```

1. [Redémarrez GitLab](../administration/restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

#### Installations avec le package Linux {#linux-package-installations}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['kerberos']

   gitlab_rails['kerberos_enabled'] = true
   gitlab_rails['kerberos_keytab'] = "/etc/http.keytab"
   ```

   Pour éviter que GitLab crée des utilisateurs automatiquement lors de leur première connexion via Kerberos, ne définissez pas `kerberos` pour `gitlab_rails['omniauth_allow_single_sign_on']`.
1. [Reconfigurez GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

GitLab propose désormais la méthode d'authentification `negotiate` pour la connexion et l'accès HTTP Git, permettant aux clients Git qui prennent en charge ce protocole d'authentification de s'authentifier avec des jetons Kerberos.

#### Activer l'authentification unique {#enable-single-sign-on}

Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `kerberos` en tant que fournisseur d'authentification unique. Cela active le provisionnement de comptes Just-In-Time pour les utilisateurs qui ne possèdent pas encore de compte GitLab.

## Créer et lier des comptes Kerberos {#create-and-link-kerberos-accounts}

Vous pouvez soit lier un compte Kerberos à un compte GitLab existant, soit configurer GitLab pour créer un nouveau compte lorsqu'un utilisateur Kerberos tente de se connecter.

### Lier un compte Kerberos à un compte GitLab existant {#link-a-kerberos-account-to-an-existing-gitlab-account}

{{< history >}}

- Kerberos SPNEGO a été [renommé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96335) en Kerberos dans GitLab 15.4.

{{< /history >}}

Si vous êtes administrateur, vous pouvez lier un compte Kerberos à un compte GitLab existant. Pour ce faire :

1. dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Sélectionnez un utilisateur, puis sélectionnez l'onglet **Identités**.
1. Dans la liste déroulante **Fournisseur**, sélectionnez **Kerberos**.
1. Assurez-vous que l'**Identifiant** correspond au nom d'utilisateur Kerberos.
1. Sélectionnez **Enregistrer les modifications**.

Si vous n'êtes pas administrateur :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Mot de passe et authentification**.
1. Dans la section **Connexion via un service tiers**, sélectionnez **Connect Kerberos**. Si vous ne voyez pas d'option Kerberos dans **Connexion via un service tiers**, suivez les exigences décrites dans [Activer l'authentification unique](#enable-single-sign-on).

Dans l'un ou l'autre cas, vous devriez maintenant pouvoir vous connecter à votre compte GitLab avec vos identifiants Kerberos.

### Créer des comptes lors de la première connexion {#create-accounts-on-first-sign-in}

La première fois que des utilisateurs se connectent à GitLab avec leurs comptes Kerberos, GitLab crée un compte correspondant. Avant de continuer, consultez les options des [paramètres de configuration communs](omniauth.md#configure-common-settings) pour les instances avec package Linux et les instances compilées manuellement. Vous devez également inclure `kerberos`.

Avec ces informations en main :

1. Incluez `'kerberos'` avec le paramètre `allow_single_sign_on`.
1. Pour l'instant, acceptez l'option `block_auto_created_users` par défaut, true.
1. Lorsqu'un utilisateur tente de se connecter avec des identifiants Kerberos, GitLab crée un nouveau compte.
   1. Si `block_auto_created_users` est défini sur true, l'utilisateur Kerberos peut voir un message tel que :

      ```shell
      Your account has been blocked. Please contact your GitLab
      administrator if you think this is an error.
      ```

      1. En tant qu'administrateur, vous pouvez confirmer le nouveau compte bloqué :
         1. dans le coin supérieur droit, sélectionnez **Admin**.
         1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs** et consultez l'onglet **Bloqué**.
      1. Vous pouvez activer l'utilisateur.
   1. Si `block_auto_created_users` est défini sur false, l'utilisateur Kerberos est authentifié et connecté à GitLab.

> [!warning]
> Nous vous recommandons de conserver la valeur par défaut pour `block_auto_created_users`. Les utilisateurs Kerberos qui créent des comptes sur GitLab sans que l'administrateur en soit informé peuvent représenter un risque de sécurité.

## Lier les comptes Kerberos et LDAP {#link-kerberos-and-ldap-accounts-together}

Si vos utilisateurs se connectent avec Kerberos, mais que vous avez également activé l'[intégration LDAP](../administration/auth/ldap/_index.md), vos utilisateurs sont liés à leurs comptes LDAP lors de leur première connexion. Pour que cela fonctionne, certains prérequis doivent être satisfaits :

Le nom d'utilisateur Kerberos doit correspondre à l'UID de l'utilisateur LDAP. Vous pouvez choisir quel attribut LDAP est utilisé comme UID dans la [configuration LDAP](../administration/auth/ldap/_index.md#configure-ldap) de GitLab, mais pour Active Directory, il doit s'agir de `sAMAccountName`.

Le royaume Kerberos doit correspondre à la partie domaine du nom distinctif (Distinguished Name) de l'utilisateur LDAP. Par exemple, si le royaume Kerberos est `AD.EXAMPLE.COM`, le nom distinctif de l'utilisateur LDAP doit se terminer par `dc=ad,dc=example,dc=com`.

Pris ensemble, ces règles signifient que la liaison ne fonctionne que si les noms d'utilisateur Kerberos de vos utilisateurs sont de la forme `foo@AD.EXAMPLE.COM` et que leurs noms distinctifs LDAP ressemblent à `sAMAccountName=foo,dc=ad,dc=example,dc=com`.

### Royaumes autorisés personnalisés {#custom-allowed-realms}

Vous pouvez configurer des royaumes autorisés personnalisés lorsque le royaume Kerberos de l'utilisateur ne correspond pas au domaine du DN LDAP de l'utilisateur. La valeur de configuration doit spécifier tous les domaines que les utilisateurs sont susceptibles d'avoir. Tous les autres domaines sont ignorés et aucune identité LDAP n'est liée.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['kerberos_simple_ldap_linking_allowed_realms'] = ['example.com','kerberos.example.com']
   ```

1. Enregistrez le fichier et [reconfigurez](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `config/gitlab.yml` :

   ```yaml
   kerberos:
     simple_ldap_linking_allowed_realms: ['example.com','kerberos.example.com']
   ```

1. Enregistrez le fichier et [redémarrez](../administration/restart_gitlab.md#self-compiled-installations) GitLab pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

## Accès HTTP Git {#http-git-access}

Un compte Kerberos lié vous permet d'utiliser `git pull` et `git push` avec votre compte Kerberos, ainsi qu'avec vos identifiants GitLab standard.

Les utilisateurs GitLab disposant d'un compte Kerberos lié peuvent également utiliser `git pull` et `git push` à l'aide de jetons Kerberos. C'est-à-dire sans avoir à envoyer leur mot de passe à chaque opération.

> [!warning]
> Il existe un [problème connu](https://github.com/curl/curl/issues/1261) avec `libcurl` antérieur à la version 7.64.1, dans lequel les connexions ne sont pas réutilisées lors de la négociation. Cela entraîne des problèmes d'autorisation lorsque le push est plus grand que la configuration `http.postBuffer`. Assurez-vous que Git utilise au moins `libcurl` 7.64.1 pour éviter ce problème. Pour connaître la version de `libcurl` installée, exécutez `curl-config --version`.

### Accès HTTP Git avec jeton Kerberos (authentification sans mot de passe) {#http-git-access-with-kerberos-token-passwordless-authentication}

En raison d'[un bug dans les versions actuelles de Git](https://lore.kernel.org/git/YKNVop80H8xSTCjz@coredump.intra.peff.net/T/#mab47fd7dcb61fee651f7cc8710b8edc6f62983d5), la commande CLI `git` utilise uniquement la méthode d'authentification `negotiate` si le serveur HTTP la propose, même si cette méthode échoue (par exemple, lorsque le client ne possède pas de jeton Kerberos). Il n'est donc pas possible de revenir à une authentification par nom d'utilisateur et mot de passe intégrés (également connue sous le nom de `basic`) si l'authentification Kerberos échoue.

Pour permettre aux utilisateurs GitLab d'utiliser l'authentification `basic` ou `negotiate` avec les versions actuelles de Git, il est possible de proposer l'authentification basée sur les tickets Kerberos sur un port différent (par exemple, `8443`), tandis que le port standard ne propose que l'authentification `basic`.

> [!note]
> [Git 2.4 et versions ultérieures](https://github.com/git/git/blob/master/Documentation/RelNotes/2.4.0.adoc?plain=1#L225-L228) prend en charge le repli vers l'authentification `basic` si le nom d'utilisateur et le mot de passe sont transmis de manière interactive ou via un gestionnaire d'identifiants. Le repli échoue lorsque le nom d'utilisateur et le mot de passe sont transmis dans le cadre de l'URL. Par exemple, cela peut se produire dans les jobs GitLab CI/CD qui [s'authentifient avec le jeton de job CI/CD](../ci/jobs/ci_job_token.md).

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['kerberos_use_dedicated_port'] = true
   gitlab_rails['kerberos_port'] = 8443
   gitlab_rails['kerberos_https'] = true
   ```

1. [Reconfigurez GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source) with HTTPS" >}}

1. Modifiez le fichier de configuration NGINX pour GitLab (par exemple, `/etc/nginx/sites-available/gitlab-ssl`) et configurez NGINX pour écouter sur le port `8443` en plus du port HTTPS standard :

   ```conf
   server {
     listen 0.0.0.0:443 ssl;
     listen [::]:443 ipv6only=on ssl default_server;
     listen 0.0.0.0:8443 ssl;
     listen [::]:8443 ipv6only=on ssl;
   ```

1. Mettez à jour la section `kerberos` de [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example) :

   ```yaml
   kerberos:
     # Dedicated port: Git before 2.4 does not fall back to Basic authentication if Negotiate fails.
     # To support both Basic and Negotiate methods with older versions of Git, configure
     # nginx to proxy GitLab on an extra port (for example: 8443) and uncomment the following lines
     # to dedicate this port to Kerberos authentication. (default: false)
     use_dedicated_port: true
     port: 8443
     https: true
   ```

1. [Redémarrez GitLab](../administration/restart_gitlab.md#self-compiled-installations) et NGINX pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

Après cette modification, les URL distantes Git doivent être mises à jour vers `https://gitlab.example.com:8443/mygroup/myproject.git` pour utiliser l'authentification basée sur les tickets Kerberos.

## Migration de l'authentification Kerberos par mot de passe vers l'authentification par ticket {#upgrading-from-password-based-to-ticket-based-kerberos-sign-ins}

Dans les versions précédentes de GitLab, les utilisateurs devaient soumettre leur nom d'utilisateur et leur mot de passe Kerberos à GitLab lors de la connexion.

Nous avons [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/2908) les connexions Kerberos par mot de passe dans GitLab 15.0.

## Prise en charge des environnements Kerberos avec Active Directory {#support-for-active-directory-kerberos-environments}

Lors de l'utilisation de l'authentification Kerberos basée sur les tickets dans un domaine Active Directory, il peut être nécessaire d'augmenter la taille maximale des en-têtes autorisée par NGINX, car les extensions du protocole Kerberos peuvent générer des en-têtes d'authentification HTTP plus grands que la taille par défaut de 8 ko. Configurez `large_client_header_buffers` sur une valeur plus grande dans [la configuration NGINX](https://nginx.org/en/docs/http/ngx_http_core_module.html#large_client_header_buffers).

### Utiliser des fichiers keytab créés avec un chiffrement AES exclusif avec Windows AD {#use-keytabs-created-using-aes-only-encryption-with-windows-ad}

Lorsque vous créez un fichier keytab avec un chiffrement exclusivement AES (Advanced Encryption Standard), vous devez cocher la case **This account supports Kerberos AES <128/256> bit encryption** pour ce compte dans le serveur AD. Que la case soit en 128 ou 256 bits dépend de la puissance de chiffrement utilisée lors de la création du fichier keytab. Pour vérifier cela, sur le serveur Active Directory :

1. Ouvrez l'outil **Users and Groups**.
1. Localisez le compte que vous avez utilisé pour créer le fichier keytab.
1. Faites un clic droit sur le compte et sélectionnez **Properties**.
1. Dans **Account Options**, sous l'onglet **Account**, cochez la case de prise en charge du chiffrement AES appropriée.
1. Enregistrez et fermez.

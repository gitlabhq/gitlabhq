---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Prise en charge TLS de Gitaly
---

Gitaly prend en charge le chiffrement TLS. Pour communiquer avec une instance Gitaly qui écoute les connexions sécurisées, utilisez le schéma d'URL `tls://` dans le paramètre `gitaly_address` de l'entrée de stockage correspondante dans la configuration GitLab.

Gitaly fournit les mêmes certificats de serveur que les certificats client dans les connexions TLS à GitLab. Cela peut être utilisé dans le cadre d'une stratégie d'authentification TLS mutuelle, lorsqu'elle est combinée avec des proxys inverses (par exemple, NGINX) qui valident le certificat client pour accorder l'accès à GitLab.

Vous devez fournir vos propres certificats, car cela n'est pas fourni automatiquement. Le certificat correspondant à chaque serveur Gitaly doit être installé sur ce serveur Gitaly.

De plus, le certificat (ou son autorité de certification) doit être installé sur tous les éléments suivants :

- Serveurs Gitaly.
- Clients Gitaly qui communiquent avec lui.

Si vous utilisez un équilibreur de charge, il doit être capable de négocier HTTP/2 à l'aide de l'extension TLS ALPN.

## Exigences relatives aux certificats {#certificate-requirements}

- Le certificat doit spécifier l'adresse que vous utilisez pour accéder au serveur Gitaly. Vous devez ajouter le nom d'hôte ou l'adresse IP en tant que Subject Alternative Name au certificat.
- Vous pouvez configurer les serveurs Gitaly avec à la fois une adresse d'écoute non chiffrée `listen_addr` et une adresse d'écoute chiffrée `tls_listen_addr` en même temps. Cela vous permet de passer progressivement du trafic non chiffré au trafic chiffré si nécessaire.
- Le champ Common Name du certificat est ignoré.

## Configurer Gitaly avec TLS {#configure-gitaly-with-tls}

{{< history >}}

- Option de configuration de la version TLS minimale [introduite](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/7755) dans GitLab 17.11.

{{< /history >}}

[Configurez Gitaly](configure_gitaly.md) avant de configurer la prise en charge TLS.

Le processus de configuration de la prise en charge TLS dépend de votre type d'installation.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Créez des certificats pour les serveurs Gitaly.
1. Sur les clients Gitaly, copiez les certificats (ou leur autorité de certification) dans `/etc/gitlab/trusted-certs` :

   ```shell
   sudo cp cert.pem /etc/gitlab/trusted-certs/
   ```

1. Sur les clients Gitaly, modifiez `gitlab_rails['repositories_storages']` dans `/etc/gitlab/gitlab.rb` comme suit :

   ```ruby
   gitlab_rails['repositories_storages'] = {
     'default' => { 'gitaly_address' => 'tls://gitaly1.internal:9999' },
     'storage1' => { 'gitaly_address' => 'tls://gitaly1.internal:9999' },
     'storage2' => { 'gitaly_address' => 'tls://gitaly2.internal:9999' },
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. Sur les serveurs Gitaly, créez le répertoire `/etc/gitlab/ssl` et copiez-y votre clé et votre certificat :

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 /etc/gitlab/ssl/cert.pem
   sudo chmod 600 /etc/gitlab/ssl/key.pem
   # For Linux package installations, 'git' is the default username. Modify the following command if it was changed from the default
   sudo chown -R git /etc/gitlab/ssl
   ```

1. Copiez tous les certificats de serveur Gitaly (ou leur autorité de certification) dans `/etc/gitlab/trusted-certs` sur tous les serveurs et clients Gitaly, afin que les serveurs et clients Gitaly fassent confiance au certificat lorsqu'ils s'appellent eux-mêmes ou d'autres serveurs Gitaly :

   ```shell
   sudo cp cert1.pem cert2.pem /etc/gitlab/trusted-certs/
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez :

   <!-- Updates to following example must also be made at <https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-linux-package-installation> -->

   ```ruby
   gitaly['configuration'] = {
      # ...
      tls_listen_addr: '0.0.0.0:9999',
      tls: {
        certificate_path: '/etc/gitlab/ssl/cert.pem',
        key_path: '/etc/gitlab/ssl/key.pem',
        ## Optionally configure the minimum TLS version Gitaly offers to clients.
        ##
        ## Default: "TLS 1.2"
        ## Options: ["TLS 1.2", "TLS 1.3"].
        #
        # min_version: "TLS 1.2"
      },
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. Exécutez `sudo gitlab-rake gitlab:gitaly:check` sur le client Gitaly (par exemple, l'application Rails) pour confirmer qu'il peut se connecter aux serveurs Gitaly.
1. Vérifiez que le trafic Gitaly est servi via TLS en [observant les types de connexions Gitaly](#observe-type-of-gitaly-connections).
1. Facultatif. Améliorez la sécurité en :
   1. Désactivant les connexions non TLS en commentant ou en supprimant `gitaly['configuration'][:listen_addr]` dans `/etc/gitlab/gitlab.rb`.
   1. Enregistrant le fichier.
   1. [Reconfiguration de GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Créez des certificats pour les serveurs Gitaly.
1. Sur les clients Gitaly, copiez les certificats dans les certificats de confiance du système :

   ```shell
   sudo cp cert.pem /usr/local/share/ca-certificates/gitaly.crt
   sudo update-ca-certificates
   ```

1. Sur les clients Gitaly, modifiez `storages` dans `/home/git/gitlab/config/gitlab.yml` pour remplacer `gitaly_address` par une adresse TLS. Par exemple :

   ```yaml
   gitlab:
     repositories:
       storages:
         default:
           gitaly_address: tls://gitaly1.internal:9999
           gitaly_token: AUTH_TOKEN_1
         storage1:
           gitaly_address: tls://gitaly1.internal:9999
           gitaly_token: AUTH_TOKEN_1
         storage2:
           gitaly_address: tls://gitaly2.internal:9999
           gitaly_token: AUTH_TOKEN_2
   ```

1. Enregistrez le fichier et [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).
1. Sur les serveurs Gitaly, créez ou modifiez `/etc/default/gitlab` et ajoutez :

   ```shell
   export SSL_CERT_DIR=/etc/gitlab/ssl
   ```

1. Sur les serveurs Gitaly, créez le répertoire `/etc/gitlab/ssl` et copiez-y votre clé et votre certificat :

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 /etc/gitlab/ssl/cert.pem
   sudo chmod 600 /etc/gitlab/ssl/key.pem
   # Set ownership to the same user that runs Gitaly
   sudo chown -R git /etc/gitlab/ssl
   ```

1. Copiez tous les certificats de serveur Gitaly (ou leur autorité de certification) dans le dossier des certificats de confiance du système afin que le serveur Gitaly fasse confiance au certificat lorsqu'il s'appelle lui-même ou d'autres serveurs Gitaly.

   ```shell
   sudo cp cert.pem /usr/local/share/ca-certificates/gitaly.crt
   sudo update-ca-certificates
   ```

1. Modifiez `/home/git/gitaly/config.toml` et ajoutez :

   ```toml
   tls_listen_addr = '0.0.0.0:9999'

   [tls]
   certificate_path = '/etc/gitlab/ssl/cert.pem'
   key_path = '/etc/gitlab/ssl/key.pem'
   ```

1. Enregistrez le fichier et [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).
1. Vérifiez que le trafic Gitaly est servi via TLS en [observant les types de connexions Gitaly](#observe-type-of-gitaly-connections).
1. Facultatif. Améliorez la sécurité en :
   1. Désactivant les connexions non TLS en commentant ou en supprimant `listen_addr` dans `/home/git/gitaly/config.toml`.
   1. Enregistrant le fichier.
   1. [Redémarrage de GitLab](../restart_gitlab.md#self-compiled-installations).

{{< /tab >}}

{{< /tabs >}}

### Mettre à jour les certificats {#update-the-certificates}

Pour mettre à jour les certificats Gitaly après la configuration initiale :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Si le contenu de vos certificats SSL dans le répertoire `/etc/gitlab/ssl` a été mis à jour, mais qu'aucune modification de configuration n'a été apportée à `/etc/gitlab/gitlab.rb`, la reconfiguration de GitLab n'affecte pas Gitaly. À la place, vous devez redémarrer Gitaly manuellement pour que les certificats soient chargés par le processus Gitaly :

```shell
sudo gitlab-ctl restart gitaly
```

Si vous modifiez ou mettez à jour les certificats dans `/etc/gitlab/trusted-certs` sans apporter de modifications au fichier `/etc/gitlab/gitlab.rb`, vous devez :

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) afin que les liens symboliques des certificats de confiance soient mis à jour.
1. Redémarrez Gitaly manuellement pour que les certificats soient chargés par le processus Gitaly :

   ```shell
   sudo gitlab-ctl restart gitaly
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Si le contenu de vos certificats SSL dans le répertoire `/etc/gitlab/ssl` a été mis à jour, vous devez [redémarrer GitLab](../restart_gitlab.md#self-compiled-installations) pour que les certificats soient chargés par le processus Gitaly.

Si vous modifiez ou mettez à jour les certificats dans `/usr/local/share/ca-certificates`, vous devez :

1. Exécutez `sudo update-ca-certificates` pour mettre à jour le magasin de confiance du système.
1. [Redémarrez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les certificats soient chargés par le processus Gitaly.

{{< /tab >}}

{{< /tabs >}}

## Observer le type de connexions Gitaly {#observe-type-of-gitaly-connections}

Pour obtenir des informations sur l'observation du type de connexions Gitaly servies, consultez la [documentation correspondante](monitoring.md#queries).

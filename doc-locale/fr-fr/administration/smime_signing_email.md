---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Signature des e-mails sortants avec S/MIME
description: Configurer S/MIME pour les e-mails sortants.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les e-mails de notification envoyés par GitLab peuvent être signés avec S/MIME pour une sécurité améliorée.

Sachez que les certificats S/MIME et les certificats TLS/SSL ne sont pas identiques et sont utilisés à des fins différentes : TLS crée un canal sécurisé, tandis que S/MIME signe et/ou chiffre le message lui-même

## Activer la signature S/MIME {#enable-smime-signing}

Ce paramètre doit être explicitement activé et une seule paire de fichiers de clé et de certificat doit être fournie :

- Les deux fichiers doivent être encodés en PEM.
- Le fichier de clé doit être non chiffré afin que GitLab puisse le lire sans intervention de l'utilisateur.
- Seules les clés RSA sont prises en charge.

Optionnellement, vous pouvez également fournir un ensemble de certificats CA (encodés en PEM) à inclure dans chaque signature. Il s'agit généralement d'une CA intermédiaire.

> [!warning]
> Soyez attentif aux niveaux d'accès de vos clés privées et à leur visibilité par des tiers.

Pour les installations avec le package Linux :

1. Modifiez `/etc/gitlab/gitlab.rb` et adaptez les chemins de fichiers :

   ```ruby
   gitlab_rails['gitlab_email_smime_enabled'] = true
   gitlab_rails['gitlab_email_smime_key_file'] = '/etc/gitlab/ssl/gitlab_smime.key'
   gitlab_rails['gitlab_email_smime_cert_file'] = '/etc/gitlab/ssl/gitlab_smime.crt'
   # Optional
   gitlab_rails['gitlab_email_smime_ca_certs_file'] = '/etc/gitlab/ssl/gitlab_smime_cas.crt'
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

La clé doit être lisible par l'utilisateur système GitLab (`git` par défaut).

Pour les installations compilées à partir des sources :

1. Modifiez `config/gitlab.yml` :

   ```yaml
   email_smime:
     # Uncomment and set to true if you need to enable email S/MIME signing (default: false)
     enabled: true
     # S/MIME private key file in PEM format, unencrypted
     # Default is '.gitlab_smime_key' relative to Rails.root (the root of the GitLab app).
     key_file: /etc/pki/smime/private/gitlab.key
     # S/MIME public certificate key in PEM format, will be attached to signed messages
     # Default is '.gitlab_smime_cert' relative to Rails.root (the root of the GitLab app).
     cert_file: /etc/pki/smime/certs/gitlab.crt
     # S/MIME extra CA public certificates in PEM format, will be attached to signed messages
     # Optional
     ca_certs_file: /etc/pki/smime/certs/gitlab_cas.crt
   ```

1. Enregistrez le fichier et [redémarrez GitLab](restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

La clé doit être lisible par l'utilisateur système GitLab (`git` par défaut).

### Comment convertir le format S/MIME PKCS #12 en encodage PEM {#how-to-convert-smime-pkcs-12-format-to-pem-encoding}

En général, les certificats S/MIME sont gérés au format binaire Public Key Cryptography Standards (PKCS) #12 (extensions `.pfx` ou `.p12`), qui contiennent les éléments suivants dans un seul fichier chiffré :

- Certificat public
- Certificats intermédiaires (le cas échéant)
- Clé privée

Pour exporter les fichiers requis en encodage PEM à partir du fichier PKCS #12, la commande `openssl` peut être utilisée :

```shell
#-- Extract private key in PEM encoding (no password, unencrypted)
openssl pkcs12 -in gitlab.p12 -nocerts -nodes -out gitlab.key

#-- Extract certificates in PEM encoding (full certs chain including CA)
openssl pkcs12 -in gitlab.p12 -nokeys -out gitlab.crt
```

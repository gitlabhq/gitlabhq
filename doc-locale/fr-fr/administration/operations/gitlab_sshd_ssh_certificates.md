---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez l'authentification par certificat SSH au niveau de l'instance avec gitlab-sshd en utilisant des clés CA de confiance."
title: "Certificats SSH au niveau de l'instance avec `gitlab-sshd`"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-shell/-/merge_requests/1396) dans GitLab 18.11.

{{< /history >}}

Si votre instance GitLab Self-Managed utilise `gitlab-sshd`, vous pouvez configurer l'authentification par certificat SSH au niveau de l'instance.

- Utilisez des certificats d'autorité de certification (CA) pour gérer centralement l'authentification SSH.
- Aucun appel à l'API Rails ni modification de base de données n'est requis.

Cette approche est l'équivalent `gitlab-sshd` de la directive OpenSSH `TrustedUserCAKeys` et constitue une alternative à la [configuration des certificats SSH basée sur OpenSSH](ssh_certificates.md).

## Workflow d'authentification `gitlab_sshd` {#gitlab_sshd-authentication-workflow}

Le workflow d'authentification `gitlab_sshd` suit ce processus.

1. L'administrateur génère une paire de clés CA.
1. L'administrateur ajoute le chemin du fichier de clé publique CA sous `sshd.trusted_user_ca_keys` dans `config.yml`.
1. L'administrateur signe les clés publiques SSH des utilisateurs avec la clé privée CA. Le `KeyId` du certificat est défini sur le nom d'utilisateur GitLab de l'utilisateur.
1. Lorsque l'utilisateur se connecte avec un certificat :
   - `gitlab-sshd` valide la signature du certificat et sa date d'expiration.
   - `gitlab-sshd` extrait le `KeyId` et l'utilise comme nom d'utilisateur GitLab.
   - Les vérifications d'accès GitLab standard se poursuivent (existence de l'utilisateur, permissions du projet).

Le processus `gitlab-sshd` n'a pas besoin d'un appel à l'API Rails ou à la base de données pour la validation du certificat elle-même. Le point de terminaison `/allowed` est toujours appelé pour l'autorisation, comme pour toute connexion SSH.

## Comparaison avec d'autres méthodes de certificat SSH {#comparison-with-other-ssh-certificate-methods}

GitLab prend en charge plusieurs approches d'authentification par certificat SSH :

| Fonctionnalité | Au niveau de l'instance (`gitlab-sshd`) | Au niveau de l'instance (OpenSSH) | Au niveau du groupe |
|---|---|---|---|
| Emplacement de la configuration | `config.yml` | `sshd_config` | API/IU GitLab |
| Serveur SSH | `gitlab-sshd` | OpenSSH | `gitlab-sshd` |
| Offre | GitLab Self-Managed | GitLab Self-Managed | GitLab.com |
| Niveau | Free, Premium, Ultimate | Free, Premium, Ultimate | Premium, Ultimate |
| Portée | À l'échelle de l'instance (sans restriction d'espace de nommage) | À l'échelle de l'instance (sans restriction d'espace de nommage) | Groupe principal |
| Mappage du nom d'utilisateur | Certificat `KeyId` | ID de clé du certificat via `AuthorizedPrincipalsCommand` | Identité du certificat via l'API |
| Exigence d'utilisateur Enterprise | Non | Non | Oui |
| Documentation | Cette page | [OpenSSH `AuthorizedPrincipalsCommand`](ssh_certificates.md) | [Certificats SSH de groupe](../../user/group/ssh_certificates.md) |

## Prérequis {#prerequisites}

Avant de configurer les certificats SSH au niveau de l'instance :

- Votre instance GitLab Self-Managed doit avoir `gitlab-sshd` activé. Pour plus d'informations, consultez [Activer `gitlab-sshd`](gitlab_sshd.md#enable-gitlab-sshd).
- Vous devez avoir accès au système de fichiers du serveur pour créer des clés CA et modifier `config.yml`.
- Le champ `KeyId` du certificat SSH doit correspondre exactement au nom d'utilisateur GitLab.

## Configurer des clés CA de confiance {#configure-trusted-ca-keys}

Pour configurer l'authentification par certificat SSH au niveau de l'instance :

1. Générez une paire de clés CA :

   ```shell
   ssh-keygen -t ed25519 -f ssh_user_ca -C "GitLab SSH User CA"
   ```

   Lorsque vous y êtes invité, saisissez une phrase secrète robuste pour protéger la clé privée CA.

   Cette commande crée deux fichiers :

   - `ssh_user_ca` : La clé privée CA.
   - `ssh_user_ca.pub` : La clé publique CA.

   Copiez uniquement la clé publique sur le serveur GitLab :

   ```shell
   sudo cp ssh_user_ca.pub /etc/gitlab/ssh_user_ca.pub
   ```

   Stockez la clé privée CA dans un emplacement sécurisé, idéalement sur un système hors ligne qui n'est pas le serveur GitLab. La clé privée n'est nécessaire que pour signer les certificats utilisateur.

1. Ajoutez le chemin du fichier de clé publique CA à la configuration `gitlab-sshd`.

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   1. Modifiez `/etc/gitlab/gitlab.rb` :

      ```ruby
      gitlab_sshd['trusted_user_ca_keys'] = ['/etc/gitlab/ssh_user_ca.pub']
      ```

   1. Enregistrez le fichier et reconfigurez GitLab :

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   {{< /tab >}}

   {{< tab title="Helm chart (Kubernetes)" >}}

   1. Créez un Secret Kubernetes contenant la clé publique CA :

      ```shell
      kubectl create secret generic my-ssh-ca-keys \
        --from-file=ca.pub=ssh_user_ca.pub
      ```

   1. Exportez les valeurs Helm :

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. Modifiez `gitlab_values.yaml` pour référencer le secret :

      ```yaml
      gitlab:
        gitlab-shell:
          sshDaemon: gitlab-sshd
          config:
            trustedUserCAKeys:
              secret: my-ssh-ca-keys
              keys:
                - ca.pub
      ```

   1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

   Pour plus d'informations sur la configuration du chart Helm, consultez la [documentation du chart GitLab Shell](https://docs.gitlab.com/charts/charts/gitlab/gitlab-shell/#instance-level-ssh-certificates-gitlab-sshd).

   {{< /tab >}}

   {{< /tabs >}}

1. Vérifiez que `gitlab-sshd` a démarré correctement en consultant les journaux pour :

   ```plaintext
   Loaded trusted user CA keys for instance-level SSH certificates count=1
   ```

## Émettre des certificats SSH pour les utilisateurs {#issue-ssh-certificates-for-users}

Après avoir configuré les clés CA de confiance, émettez des certificats pour vos utilisateurs :

1. Obtenez la clé SSH publique de l'utilisateur (par exemple, `id_ed25519.pub`).

1. Signez la clé publique de l'utilisateur avec la CA, en définissant l'indicateur `-I` (identity/KeyId) sur le nom d'utilisateur GitLab exact de l'utilisateur :

   ```shell
   ssh-keygen -s ssh_user_ca -I <gitlab-username> -V +1d user-key.pub
   ```

   Cette commande crée un fichier de certificat (par exemple, `user-key-cert.pub`) valide pour un jour.

   Pour définir une période de validité plus longue, ajustez l'indicateur `-V`. Par exemple, `-V +30d` pour 30 jours ou `-V +52w` pour un an.

1. Distribuez le fichier de certificat à l'utilisateur.

1. L'utilisateur se connecte en utilisant son certificat :

   ```shell
   ssh git@gitlab.example.com
   ```

   Si le fichier de certificat suit la convention de nommage par défaut (`<key>-cert.pub` à côté de `<key>`), SSH l'utilise automatiquement. Sinon, spécifiez le certificat explicitement :

   ```shell
   ssh -o CertificateFile=~/.ssh/id_ed25519-cert.pub git@gitlab.example.com
   ```

## Utiliser plusieurs autorités de certification {#use-multiple-certificate-authorities}

Vous pouvez spécifier plusieurs fichiers de clé publique CA pour la rotation des CA ou les configurations multi-CA.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_sshd['trusted_user_ca_keys'] = [
     '/etc/gitlab/ssh_user_ca_current.pub',
     '/etc/gitlab/ssh_user_ca_next.pub'
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Créez un Secret Kubernetes contenant les deux clés publiques CA :

   ```shell
   kubectl create secret generic my-ssh-ca-keys \
     --from-file=ca_current.pub=ssh_user_ca_current.pub \
     --from-file=ca_next.pub=ssh_user_ca_next.pub
   ```

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` pour référencer le secret :

   ```yaml
   gitlab:
     gitlab-shell:
       sshDaemon: gitlab-sshd
       config:
         trustedUserCAKeys:
           secret: my-ssh-ca-keys
           keys:
             - ca_current.pub
             - ca_next.pub
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

Un seul fichier peut également contenir plusieurs clés publiques CA, une par ligne. `gitlab-sshd` déduplique automatiquement les clés entre les fichiers.

## Considérations de sécurité {#security-considerations}

Les certificats SSH au niveau de l'instance accordent l'autorité d'authentification à quiconque détient la clé privée CA. Examinez les considérations de sécurité suivantes avant de déployer.

> [!warning]
> Toute personne ayant accès à la clé privée CA peut signer des certificats pour **n'importe quels** utilisateurs GitLab de l'instance. Protégez la clé privée CA avec des contrôles d'accès appropriés, tels que des permissions de fichiers restrictives, des modules de sécurité matériels (HSM) ou un environnement hors ligne.

### Pas de révocation de certificat {#no-certificate-revocation}

`gitlab-sshd` n'inclut pas de mécanisme de révocation de certificat intégré. Si un certificat ou une clé CA est compromis, supprimez la CA de la configuration `trusted_user_ca_keys` et réémettez des certificats avec une nouvelle CA. Utilisez des certificats de courte durée (par exemple, 24 heures) pour minimiser la fenêtre d'exposition.

### Pas d'événements d'audit pour les modifications de configuration CA {#no-audit-events-for-ca-configuration-changes}

GitLab n'enregistre pas les modifications apportées à `trusted_user_ca_keys` dans `config.yml` comme événements d'audit. Surveillez les modifications apportées à ce fichier de configuration en utilisant vos outils de surveillance d'infrastructure.

`gitlab-sshd` journalise les tentatives d'authentification par certificat SSH réussies et échouées avec des champs incluant `ssh_user`, `public_key_fingerprint`, `signing_ca_fingerprint`, `certificate_identity` et `certificate_username`.

### Déploiements en cluster {#clustered-deployments}

Dans les environnements avec plusieurs nœuds `gitlab-sshd`, synchronisez la configuration et les fichiers de clé publique CA sur tous les nœuds. Des configurations incohérentes peuvent provoquer des échecs d'authentification intermittents. Pour les déploiements avec chart Helm, le Secret Kubernetes est partagé automatiquement entre les pods.

## Dépannage {#troubleshooting}

### `gitlab-sshd` échoue à démarrer après l'ajout de clés CA {#gitlab-sshd-fails-to-start-after-adding-ca-keys}

Si un fichier de clé CA ne peut pas être lu ou contient un contenu non valide, `gitlab-sshd` ne démarre pas. Vérifiez la sortie du journal pour les messages d'erreur tels que :

- `failed to load trusted user CA keys` :  Le fichier n'a pas pu être lu. Vérifiez que le fichier existe et dispose des permissions correctes (lisible par l'utilisateur `git`).
- `failed to parse trusted user CA key in file` :  Le contenu du fichier n'est pas une clé publique SSH valide. Vérifiez que le fichier contient une clé publique valide au format OpenSSH.
- `trusted_user_ca_keys configured but no valid CA keys were loaded` :  La configuration répertorie des fichiers de clé CA mais aucun ne contenait de clés valides.

### `certificate rejected: not a user certificate` {#certificate-rejected-not-a-user-certificate}

Le certificat a été généré en tant que certificat d'hôte au lieu d'un certificat d'utilisateur. N'utilisez pas l'indicateur `-h` lors de la signature avec `ssh-keygen`.

### `certificate KeyId does not match GitLab username format` {#certificate-keyid-does-not-match-gitlab-username-format}

Le `KeyId` dans le certificat n'est pas conforme aux règles de nom d'utilisateur GitLab. Vérifiez que la valeur `-I` utilisée lors de la signature correspond exactement au nom d'utilisateur GitLab.

### `ssh: cert has expired` {#ssh-cert-has-expired}

La période de validité du certificat est expirée. Émettez un nouveau certificat avec une fenêtre de validité appropriée en utilisant l'indicateur `-V`.

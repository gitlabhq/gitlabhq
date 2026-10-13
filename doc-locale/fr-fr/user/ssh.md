---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser des clés SSH avec GitLab
description: Utilisez des clés SSH pour une authentification et une communication sécurisées avec les dépôts GitLab.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez des clés SSH pour vous authentifier de manière sécurisée auprès de GitLab sans saisir votre nom d'utilisateur et votre mot de passe à chaque fois que vous effectuez un push ou un pull de code.

Pour utiliser des clés SSH avec GitLab, vous devez :

1. Générer une paire de clés SSH sur votre système local.
1. Ajouter votre clé SSH à votre compte GitLab.
1. Vérifier votre connexion à GitLab.

Vous pouvez ensuite [cloner un dépôt avec SSH](../topics/git/clone.md#clone-with-ssh). Une clé SSH vous authentifie auprès de chaque projet et groupe auxquels votre compte peut accéder. Vous n'avez pas besoin d'une clé distincte pour chaque projet. Pour utiliser une clé différente pour un dépôt spécifique, voir [utiliser des clés différentes pour différents dépôts](ssh_advanced.md#use-different-keys-for-different-repositories).

> [!note]
> Pour les configurations moins courantes, comme les clés de sécurité matérielles, les comptes multiples ou Microsoft Windows, voir [configuration SSH avancée des clés](ssh_advanced.md).

## Que sont les clés SSH {#what-are-ssh-keys}

SSH utilise deux clés, une clé publique et une clé privée.

- La clé publique peut être distribuée.
- La clé privée doit être protégée.

Il n'est pas possible de divulguer des données confidentielles en téléchargeant votre clé publique. Lorsque vous devez copier ou télécharger votre clé publique SSH, assurez-vous de ne pas copier ou télécharger accidentellement votre clé privée à la place.

Vous pouvez utiliser votre clé privée pour [signer des commits](project/repository/signed_commits/ssh.md), ce qui rend votre utilisation de GitLab et vos données encore plus sécurisées. Cette signature peut ensuite être vérifiée par toute personne utilisant votre clé publique.

Pour plus de détails, voir [la cryptographie asymétrique, également connue sous le nom de cryptographie à clé publique](https://en.wikipedia.org/wiki/Public-key_cryptography).

## Prérequis {#prerequisites}

Pour utiliser SSH pour communiquer avec GitLab, vous avez besoin :

- Du client OpenSSH, qui est préinstallé sur GNU/Linux, macOS et Windows 10.
- De SSH version 6.5 ou ultérieure. Les versions antérieures utilisaient une signature MD5, qui n'est pas sécurisée.

> [!note]
> Pour afficher la version de SSH installée sur votre système, exécutez `ssh -V`.

## Types de clés SSH pris en charge {#supported-ssh-key-types}

Pour communiquer avec GitLab, vous pouvez utiliser les types de clés SSH suivants :

| Algorithme           | Remarques |
| ------------------- | ----- |
| ED25519 (recommandé) | Plus sécurisé et plus performant que les clés RSA. Introduit dans OpenSSH 6.5 (2014) et disponible sur la plupart des systèmes d'exploitation. Il est possible que cette clé ne soit pas entièrement prise en charge par tous les systèmes FIPS. Pour plus d'informations, voir [ticket 367429](https://gitlab.com/gitlab-org/gitlab/-/issues/367429). |
| ED25519_SK          | Nécessite OpenSSH 8.2 ou une version ultérieure sur votre client local et sur le serveur GitLab. |
| ECDSA_SK            | Nécessite OpenSSH 8.2 ou une version ultérieure sur votre client local et sur le serveur GitLab. |
| RSA                 | Moins sécurisé qu'ED25519. Si utilisé, GitLab recommande une taille de clé d'au moins 4 096 bits. La longueur maximale de la clé est de 8 192 bits en raison des limitations de Go. La taille de clé par défaut dépend de votre version de `ssh-keygen`. |
| ECDSA               | [Les problèmes de sécurité](https://leanpub.com/gocrypto/read#leanpub-auto-ecdsa) liés à DSA s'appliquent également aux clés ECDSA. |

## Vérifier l'existence de paires de clés SSH {#check-for-existing-ssh-key-pairs}

Avant de créer une paire de clés, vérifiez si une paire de clés existe déjà.

1. Accédez à votre répertoire personnel.
1. Accédez au sous-répertoire `.ssh/`. Si le sous-répertoire `.ssh/` n'existe pas, vous n'êtes probablement pas dans le répertoire personnel ou vous n'avez pas encore utilisé `ssh`. Dans ce dernier cas, vous devez [générer une paire de clés SSH](#generate-an-ssh-key-pair).
1. Vérifiez si un fichier correspondant à l'un des formats suivants existe :

   | Algorithme             | Clé publique | Clé privée |
   |-----------------------|------------|-------------|
   |  ED25519 (recommandé)  | `id_ed25519.pub` | `id_ed25519` |
   |  ED25519_SK           | `id_ed25519_sk.pub` | `id_ed25519_sk` |
   |  ECDSA_SK             | `id_ecdsa_sk.pub` | `id_ecdsa_sk` |
   |  RSA (taille de clé d'au moins 4 096 bits) | `id_rsa.pub` | `id_rsa` |
   |  DSA (obsolète)     | `id_dsa.pub` | `id_dsa` |
   |  ECDSA                | `id_ecdsa.pub` | `id_ecdsa` |

## Générer une paire de clés SSH {#generate-an-ssh-key-pair}

Si vous ne disposez pas d'une paire de clés SSH existante, générez-en une nouvelle :

1. Ouvrez un terminal.
1. Exécutez `ssh-keygen -t` avec le type de clé et un commentaire facultatif pour identifier la clé ultérieurement. Une option courante consiste à utiliser votre adresse e-mail comme commentaire. Le commentaire est inclus dans le fichier `.pub`.

   Par exemple, pour ED25519 :

   ```shell
   ssh-keygen -t ed25519 -C "<comment>"
   ```

   Pour RSA 4 096 bits :

   ```shell
   ssh-keygen -t rsa -b 4096 -C "<comment>"
   ```

1. Appuyez sur <kbd>Entrée</kbd>. Une sortie similaire à la suivante s'affiche :

   ```plaintext
   Generating public/private ed25519 key pair.
   Enter file in which to save the key (/home/user/.ssh/id_ed25519):
   ```

1. Acceptez le nom de fichier et le répertoire suggérés, sauf si vous générez une [clé de déploiement](project/deploy_keys/_index.md) ou souhaitez enregistrer dans un répertoire spécifique où vous stockez d'autres clés.

   Vous pouvez également dédier la paire de clés SSH à un [hôte spécifique](ssh_advanced.md#use-ssh-keys-in-another-directory).

1. Spécifiez une [phrase secrète](https://www.ssh.com/academy/ssh/passphrase) :

   ```plaintext
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   ```

   Une confirmation s'affiche, incluant des informations sur l'emplacement de stockage de vos fichiers. Une clé publique et une clé privée sont générées.

1. Ajoutez la clé SSH privée à `ssh-agent`.

   Par exemple, pour ED25519 :

   ```shell
   ssh-add ~/.ssh/id_ed25519
   ```

## Ajouter une clé SSH à votre compte GitLab {#add-an-ssh-key-to-your-gitlab-account}

Pour utiliser SSH avec GitLab, copiez votre clé publique dans votre compte GitLab. GitLab ne peut pas accéder à votre clé privée.

Lorsque vous ajoutez une clé SSH, GitLab la vérifie par rapport à une liste de clés compromises connues. Vous ne pouvez pas ajouter de clés compromises car les clés privées associées sont publiquement connues et pourraient être utilisées pour accéder à des comptes. Cette restriction ne peut pas être configurée.

Si votre clé est bloquée, [générez une nouvelle paire de clés SSH](#generate-an-ssh-key-pair).

Pour ajouter une clé SSH à votre compte GitLab :

1. Copiez le contenu de votre fichier de clé publique. Vous pouvez le faire manuellement ou utiliser un script.

   Dans ces exemples, remplacez `id_ed25519.pub` par votre nom de fichier. Par exemple, pour RSA, utilisez `id_rsa.pub`.

   {{< tabs >}}

   {{< tab title="macOS" >}}

   ```shell
   tr -d '\n' < ~/.ssh/id_ed25519.pub | pbcopy
   ```

   {{< /tab >}}

   {{< tab title="Linux (nécessite le paquet xclip)" >}}

   ```shell
   xclip -sel clip < ~/.ssh/id_ed25519.pub
   ```

   {{< /tab >}}

   {{< tab title="Git Bash sur Windows" >}}

   ```shell
   cat ~/.ssh/id_ed25519.pub | clip
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Connectez-vous à GitLab.
1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Clés SSH**.
1. Sélectionnez **Ajouter une nouvelle clé**.
1. Dans la zone **Clé**, collez le contenu de votre clé publique. Si vous avez copié la clé manuellement, assurez-vous de copier la clé entière, qui commence par `ssh-rsa`, `ssh-dss`, `ecdsa-sha2-nistp256`, `ecdsa-sha2-nistp384`, `ecdsa-sha2-nistp521`, `ssh-ed25519`, `sk-ecdsa-sha2-nistp256@openssh.com` ou `sk-ssh-ed25519@openssh.com`, et peut se terminer par un commentaire.
1. Dans la zone **Titre**, saisissez une description, comme `Work Laptop` ou `Home Workstation`.
1. Facultatif. Sélectionnez le **Type d'utilisation** de la clé. Elle peut être utilisée pour `Authentication`, `Signing` ou les deux. `Authentication & Signing` est la valeur par défaut.
1. Facultatif. Mettez à jour la **Date d'expiration** pour modifier la date d'expiration par défaut. Pour plus d'informations, voir [Expiration des clés SSH](#ssh-key-expiration).
1. Sélectionnez **Ajouter une clé**.

## Vérifier votre connexion SSH {#verify-your-ssh-connection}

Vérifiez que votre clé SSH a été correctement ajoutée et que vous pouvez vous connecter à l'instance GitLab :

1. Pour vous assurer de vous connecter au bon serveur, identifiez l'empreinte de la clé d'hôte SSH :
   - Pour GitLab.com, consultez la documentation sur les [empreintes des clés d'hôte SSH](gitlab_com/_index.md#ssh-host-keys-fingerprints).
   - Pour GitLab Self-Managed ou GitLab Dedicated, consultez `https://gitlab.example.com/help/instance_configuration#ssh-host-keys-fingerprints` où `gitlab.example.com` est l'URL de l'instance GitLab.
1. Ouvrez un terminal et exécutez cette commande :
   - Pour GitLab.com, utilisez `ssh -T git@gitlab.com`.
   - Pour GitLab Self-Managed ou GitLab Dedicated, utilisez `ssh -T git@gitlab.example.com` où `gitlab.example.com` est l'URL de l'instance GitLab.

Par défaut, les connexions utilisent le nom d'utilisateur `git`, mais les administrateurs de GitLab Self-Managed ou GitLab Dedicated peuvent [modifier le nom d'utilisateur](https://docs.gitlab.com/omnibus/settings/configuration/#change-the-name-of-the-git-user-or-group).

1. Lors de votre première connexion, vous devrez peut-être vérifier l'authenticité de l'hôte GitLab. Suivez les instructions à l'écran si vous voyez un message similaire à :

   ```plaintext
   The authenticity of host 'gitlab.example.com (35.231.145.151)' can't be established.
   ECDSA key fingerprint is SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw.
   Are you sure you want to continue connecting (yes/no)?
   ```

   Vous devriez recevoir un message de bienvenue.

   ```plaintext
   Welcome to GitLab, <username>!
   ```

   Si le message n'apparaît pas, vous pouvez [dépanner votre connexion SSH](ssh_troubleshooting.md#general-ssh-troubleshooting).

## Afficher vos clés SSH {#view-your-ssh-keys}

Pour afficher les clés SSH de votre compte :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Clés SSH**.

Vos clés SSH existantes sont répertoriées au bas de la page. Les informations incluent :

- Le titre de la clé
- Empreinte publique
- Types d'utilisation autorisés
- Date de création
- Date de dernière utilisation
- Date d'expiration

## Supprimer une clé SSH {#remove-an-ssh-key}

Vous pouvez révoquer ou supprimer votre clé SSH pour la retirer définitivement de votre compte.

La suppression de votre clé SSH a des implications supplémentaires si vous signez vos commits avec cette clé. Pour plus d'informations, voir [Commits signés avec des clés SSH supprimées](project/repository/signed_commits/ssh.md#signed-commits-with-removed-ssh-keys).

### Révoquer une clé SSH {#revoke-an-ssh-key}

Si votre clé SSH est compromise, révoquez la clé.

Prérequis :

- La clé SSH doit avoir le type d'utilisation `Signing` ou `Authentication & Signing`.

Pour révoquer une clé SSH :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Clés SSH**.
1. À côté de la clé SSH que vous souhaitez révoquer, sélectionnez **Révoquer**.
1. Sélectionnez **Révoquer**.

### Supprimer une clé SSH {#delete-an-ssh-key}

Pour supprimer une clé SSH :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Clés SSH**.
1. À côté de la clé que vous souhaitez supprimer, sélectionnez **Supprimer** ({{< icon name="remove" >}}).
1. Sélectionnez **Supprimer**.

## Expiration des clés SSH {#ssh-key-expiration}

Vous pouvez définir une date d'expiration lorsque vous ajoutez une clé SSH à votre compte. Ce paramètre facultatif contribue à limiter le risque de violation de sécurité.

Après l'expiration de votre clé SSH, vous ne pouvez plus l'utiliser pour vous authentifier ou signer des commits. Vous devez [générer une nouvelle clé SSH](#generate-an-ssh-key-pair) et [l'ajouter à votre compte](#add-an-ssh-key-to-your-gitlab-account).

Sur GitLab Self-Managed et GitLab Dedicated, les administrateurs peuvent consulter les dates d'expiration et les utiliser à titre indicatif lors de la [suppression de clés](../administration/credentials_inventory.md#delete-ssh-keys).

GitLab vérifie quotidiennement les clés SSH arrivant à expiration et envoie des notifications :

- À 01h00 UTC, sept jours avant l'expiration.
- À 02h00 UTC à la date d'expiration.

## Sujets connexes {#related-topics}

- [Déplacer une clé SSH vers un autre appareil](ssh_advanced.md#move-an-ssh-key-to-another-device)
- [Clés SSH pour les comptes de service](profile/service_accounts.md)
- [Dépannage SSH](ssh_troubleshooting.md)

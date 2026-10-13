---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configuration avancée des clés SSH
description: Utilisez des clés SSH pour une authentification et une communication sécurisées avec les dépôts GitLab.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Configurez les options avancées des clés SSH pour les workflows spécialisés.
> [!note]
> Pour en savoir plus sur l'utilisation de base des clés SSH avec votre compte GitLab, consultez [Utiliser les clés SSH avec GitLab](ssh.md).

## Générer une paire de clés SSH pour une clé de sécurité matérielle FIDO2 {#generate-an-ssh-key-pair-for-a-fido2-hardware-security-key}

Pour générer des clés SSH ED25519_SK ou ECDSA_SK, vous devez utiliser OpenSSH 8.2 ou une version ultérieure :

1. Insérez une clé de sécurité matérielle dans votre ordinateur.
1. Ouvrez un terminal.
1. Exécutez `ssh-keygen -t` avec le type de clé et un commentaire facultatif pour vous aider à identifier la clé ultérieurement. Une option courante consiste à utiliser votre adresse e-mail comme commentaire. Le commentaire est inclus dans le fichier `.pub`.

   Par exemple, pour ED25519_SK :

   ```shell
   ssh-keygen -t ed25519-sk -C "<comment>"
   ```

   Pour ECDSA_SK :

   ```shell
   ssh-keygen -t ecdsa-sk -C "<comment>"
   ```

   Si votre clé de sécurité prend en charge les clés résidentes FIDO2, vous pouvez activer cette option lors de la création de votre clé SSH :

   ```shell
   ssh-keygen -t ed25519-sk -O resident -C "<comment>"
   ```

   `-O resident` indique que la clé doit être stockée sur l'authentificateur FIDO lui-même. La clé résidente est plus facile à importer sur un nouvel ordinateur, car elle peut être chargée directement depuis la clé de sécurité via [`ssh-add -K`](https://man.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man1/ssh-add.1#K) ou [`ssh-keygen -K`](https://man.openbsd.org/cgi-bin/man.cgi/OpenBSD-current/man1/ssh-keygen#K).

1. Appuyez sur <kbd>Entrée</kbd>. Une sortie similaire à la suivante s'affiche :

   ```plaintext
   Generating public/private ed25519-sk key pair.
   You may need to touch your authenticator to authorize key generation.
   ```

1. Appuyez sur le bouton de la clé de sécurité matérielle.
1. Acceptez le nom de fichier et le répertoire suggérés :

   ```plaintext
   Enter file in which to save the key (/home/user/.ssh/id_ed25519_sk):
   ```

1. Spécifiez une [phrase secrète](https://www.ssh.com/academy/ssh/passphrase) :

   ```plaintext
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   ```

   Une confirmation s'affiche, incluant des informations sur l'emplacement de stockage de vos fichiers.

Une clé publique et une clé privée sont générées. [Ajoutez la clé SSH publique à votre compte GitLab](ssh.md#add-an-ssh-key-to-your-gitlab-account).

## Générer une paire de clés SSH avec 1Password {#generate-an-ssh-key-pair-with-1password}

Vous pouvez utiliser [1Password](https://1password.com/) et l'[extension de navigateur 1Password](https://support.1password.com/getting-started-browser/) pour :

- Générer automatiquement une nouvelle clé SSH.
- Utiliser une clé SSH existante dans votre coffre-fort 1Password pour vous authentifier auprès de GitLab.

1. Connectez-vous à GitLab.
1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Clés SSH**.
1. Sélectionnez **Ajouter une nouvelle clé**.
1. Sélectionnez **Clé** ; l'assistant 1Password devrait apparaître.
1. Sélectionnez l'icône 1Password et déverrouillez 1Password.
1. Vous pouvez ensuite sélectionner **Créer une clé SSH** ou sélectionner une clé SSH existante pour renseigner la clé publique.
1. Dans la zone **Titre**, saisissez une description, comme `Work Laptop` ou `Home Workstation`.
1. Facultatif. Sélectionnez le **Type d'utilisation** de la clé. Elle peut être utilisée pour `Authentication`, `Signing` ou les deux. `Authentication & Signing` est la valeur par défaut.
1. Facultatif. Mettez à jour la **Date d'expiration** pour modifier la date d'expiration par défaut.
1. Sélectionnez **Ajouter une clé**.

Pour en savoir plus sur l'utilisation de 1Password avec les clés SSH, consultez la [documentation 1Password](https://developer.1password.com/docs/ssh/get-started/).

## Désactiver les clés SSH pour les utilisateurs et utilisatrices professionnels {#disable-ssh-keys-for-enterprise-users}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/30343) dans GitLab 18.8.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Propriétaire pour le groupe auquel appartiennent les utilisateurs et utilisatrices professionnels.

La désactivation des clés SSH des [utilisateurs et utilisatrices professionnels](enterprise_user/_index.md) d'un groupe :

- Empêche les utilisateurs et utilisatrices professionnels d'ajouter de nouvelles clés SSH.
- Désactive les clés SSH existantes des utilisateurs et utilisatrices professionnels.

Cela s'applique également aux utilisateurs et utilisatrices professionnels qui sont administrateurs du groupe.

Pour désactiver les clés SSH des utilisateurs et utilisatrices professionnels :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Permissions et fonctionnalités du groupe**.
1. Sous **Utilisateurs et utilisatrices professionnels**, sélectionnez **Désactiver les clés SSH**.
1. Sélectionnez **Enregistrer les modifications**.

## Mettre à niveau votre paire de clés RSA vers un format plus sécurisé {#upgrade-your-rsa-key-pair-to-a-more-secure-format}

Si votre version d'OpenSSH est comprise entre 6.5 et 7.8, vous pouvez enregistrer vos clés SSH RSA privées dans un format OpenSSH plus sécurisé en ouvrant un terminal et en exécutant la commande suivante :

```shell
ssh-keygen -o -f ~/.ssh/id_rsa
```

Vous pouvez également générer une nouvelle clé RSA avec le format de chiffrement plus sécurisé à l'aide de la commande suivante :

```shell
ssh-keygen -o -t rsa -b 4096 -C "<comment>"
```

## Mettre à jour la phrase secrète de votre clé SSH {#update-your-ssh-key-passphrase}

Vous pouvez mettre à jour la phrase secrète de votre clé SSH :

1. Ouvrez un terminal et exécutez la commande suivante :

   ```shell
   ssh-keygen -p -f /path/to/ssh_key
   ```

1. Aux invites, saisissez la phrase secrète, puis appuyez sur <kbd>Entrée</kbd>.

## Utiliser différents comptes sur une seule instance GitLab {#use-different-accounts-on-a-single-gitlab-instance}

Vous pouvez utiliser plusieurs comptes pour vous connecter à une seule instance de GitLab. Vous pouvez y parvenir en utilisant la commande de la [rubrique précédente](#use-different-keys-for-different-repositories). Cependant, même si vous définissez `IdentitiesOnly` sur `yes`, vous ne pouvez pas vous connecter si un `IdentityFile` existe en dehors d'un bloc `Host`.

Vous pouvez également attribuer des alias aux hôtes dans le fichier `~/.ssh/config`.

- Pour `Host`, utilisez un alias tel que `user_1.gitlab.com` et `user_2.gitlab.com`. Les configurations avancées sont plus difficiles à maintenir, et ces chaînes sont plus faciles à comprendre lorsque vous utilisez des outils comme `git remote`.
- Pour `IdentityFile`, utilisez le chemin vers la clé privée.

```conf
# User1 Account Identity
Host <user_1.gitlab.com>
  Hostname gitlab.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/<example_ssh_key1>

# User2 Account Identity
Host <user_2.gitlab.com>
  Hostname gitlab.com
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/<example_ssh_key2>
```

Maintenant, pour cloner un dépôt pour `user_1`, utilisez `user_1.gitlab.com` dans la commande `git clone` :

```shell
git clone git@<user_1.gitlab.com>:gitlab-org/gitlab.git
```

Pour mettre à jour un dépôt précédemment cloné dont l'alias est `origin` :

```shell
git remote set-url origin git@<user_1.gitlab.com>:gitlab-org/gitlab.git
```

> [!note]
> Les clés privées et publiques contiennent des données sensibles. Assurez-vous que les autorisations sur les fichiers vous permettent de les lire, mais les rendent inaccessibles aux autres.

## Utiliser des clés différentes pour différents dépôts {#use-different-keys-for-different-repositories}

Vous pouvez utiliser une clé différente pour chaque dépôt.

Ouvrez un terminal et exécutez la commande suivante :

```shell
git config core.sshCommand "ssh -o IdentitiesOnly=yes -i ~/.ssh/private-key-filename-for-this-repository -F /dev/null"
```

Cette commande n'utilise pas l'agent SSH et nécessite Git 2.10 ou une version ultérieure. Pour en savoir plus sur les options de la commande `ssh`, consultez les pages `man` pour `ssh` et `ssh_config`.

## Utiliser des clés SSH dans un autre répertoire {#use-ssh-keys-in-another-directory}

Si votre paire de clés SSH ne se trouve pas dans le répertoire par défaut, configurez votre client SSH pour qu'il pointe vers l'emplacement où vous avez stocké la clé privée.

1. Ouvrez un terminal et exécutez la commande suivante :

   ```shell
   eval $(ssh-agent -s)
   ssh-add <directory to private SSH key>
   ```

1. Enregistrez ces paramètres dans le fichier `~/.ssh/config`. Par exemple :

   ```conf
   # GitLab.com
   Host gitlab.com
     PreferredAuthentications publickey
     IdentityFile ~/.ssh/gitlab_com_rsa

   # Private GitLab instance
   Host gitlab.company.com
     PreferredAuthentications publickey
     IdentityFile ~/.ssh/example_com_rsa
   ```

Pour en savoir plus sur ces paramètres, consultez la page [`man ssh_config`](https://man.openbsd.org/ssh_config) dans le manuel de configuration SSH.

Les clés SSH publiques doivent être uniques dans GitLab, car elles sont liées à votre compte. Votre clé SSH est le seul identifiant dont vous disposez lorsque vous envoyez du code via SSH. Elle doit correspondre de manière unique à un seul utilisateur.

## Déplacer une clé SSH vers un autre appareil {#move-an-ssh-key-to-another-device}

Vous pouvez utiliser la même clé SSH sur plusieurs appareils en copiant le fichier de clé privée. Vous n'avez rien à modifier dans GitLab.

> [!note]
> Pour une meilleure sécurité, envisagez de [générer une nouvelle clé SSH](ssh.md#generate-an-ssh-key-pair) pour chaque appareil. Cela limite l'impact d'un appareil perdu ou compromis.

Pour déplacer une clé SSH vers un autre appareil :

1. Sur votre appareil d'origine, [localisez vos paires de clés SSH existantes](ssh.md#check-for-existing-ssh-key-pairs).
1. Copiez les fichiers dans le répertoire `~/.ssh/` sur le nouvel appareil.

   > [!warning]
   > N'envoyez jamais une clé privée par e-mail, via une messagerie instantanée ou via un service de synchronisation cloud non chiffré. Utilisez une méthode de transfert chiffrée, comme un gestionnaire de mots de passe ou une clé USB chiffrée.

1. Sur le nouvel appareil, ouvrez un terminal.
1. Définissez les autorisations de manière à ce que vous seul puissiez lire la clé privée. Par exemple, pour ED25519 :

   ```shell
   chmod 600 ~/.ssh/id_ed25519
   ```

1. Ajoutez la clé à l'agent SSH :

   ```shell
   eval $(ssh-agent -s)
   ssh-add ~/.ssh/id_ed25519
   ```

1. Vérifiez que la clé s'authentifie auprès de GitLab. Pour en savoir plus, consultez [vérifier votre connexion SSH](ssh.md#verify-your-ssh-connection).

Pour les clés SSH stockées sur une clé de sécurité matérielle FIDO2, ne copiez pas le fichier de clé privée. Importez plutôt la clé depuis la clé de sécurité avec `ssh-add -K`. Pour en savoir plus, consultez [générer une paire de clés SSH pour une clé de sécurité matérielle FIDO2](#generate-an-ssh-key-pair-for-a-fido2-hardware-security-key).

Sous Microsoft Windows, les environnements WSL et Git for Windows utilisent des répertoires personnels différents. Pour en savoir plus, consultez [utiliser SSH sur Microsoft Windows](#use-ssh-on-microsoft-windows).

## Utiliser SSH avec EGit sur Eclipse {#use-ssh-with-egit-on-eclipse}

Si vous utilisez [EGit](https://projects.eclipse.org/projects/technology.egit), vous pouvez [ajouter votre clé SSH à Eclipse](https://wiki.eclipse.org/EGit/User_Guide/#Eclipse_SSH_Configuration).

## Utiliser SSH sur Microsoft Windows {#use-ssh-on-microsoft-windows}

Sous Windows 10, vous pouvez utiliser le [Sous-système Windows pour Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/install) avec [WSL 2](https://learn.microsoft.com/en-us/windows/wsl/install#update-to-wsl-2), qui inclut `git` et `ssh` préinstallés, ou installer [Git for Windows](https://gitforwindows.org) pour utiliser SSH via PowerShell.

La clé SSH générée dans WSL n'est pas directement disponible pour Git for Windows, et vice versa, car les deux environnements utilisent des répertoires personnels différents :

- WSL : `/home/<user>`
- Git for Windows : `C:\Users\<user>`

Vous pouvez copier le répertoire `.ssh/` pour utiliser la même clé, ou générer une clé dans chaque environnement.

Si vous utilisez Windows 11 et [OpenSSH pour Windows](https://learn.microsoft.com/en-us/windows-server/administration/OpenSSH/openssh-overview), assurez-vous que la variable d'environnement `HOME` est correctement définie. Sinon, votre clé SSH privée pourrait ne pas être trouvée.

Les outils alternatifs comprennent :

- [Cygwin](https://www.cygwin.com)
- [PuTTYgen](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) 0.81 et versions ultérieures (les versions antérieures sont [vulnérables aux attaques de divulgation](https://www.openwall.com/lists/oss-security/2024/04/15/6))

## Utiliser l'authentification à deux facteurs pour Git via SSH {#use-two-factor-authentication-for-git-over-ssh}

Vous pouvez utiliser l'authentification à deux facteurs (2FA) pour [Git via SSH](../security/two_factor_authentication.md#2fa-for-git-over-ssh-operations). Vous devez utiliser des clés SSH `ED25519_SK` ou `ECDSA_SK`. Pour en savoir plus, consultez [les types de clés SSH pris en charge](ssh.md#supported-ssh-key-types).

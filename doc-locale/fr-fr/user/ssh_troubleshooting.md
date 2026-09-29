---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage SSH
---

Lorsque vous utilisez des clés SSH, vous pouvez rencontrer les problèmes suivants.

## TLS : le serveur a envoyé un certificat contenant une clé RSA supérieure à 8 192 bits {#tls-server-sent-certificate-containing-rsa-key-larger-than-8192-bits}

Go limite les clés RSA à un maximum de 8 192 bits. Pour vérifier la longueur d'une clé :

```shell
openssl rsa -in <your-key-file> -text -noout | grep "Key:"
```

Remplacez toute clé supérieure à 8 192 bits par une clé plus courte.

## Invite de mot de passe avec `git clone` {#password-prompt-with-git-clone}

Lorsque vous exécutez `git clone`, il est possible qu'un mot de passe vous soit demandé, tel que `git@gitlab.example.com's password:`. Cela indique qu'un problème est survenu dans votre configuration SSH.

- Assurez-vous d'avoir correctement généré votre paire de clés SSH et d'avoir ajouté la clé SSH publique à votre profil GitLab.
- Assurez-vous que le format de votre clé SSH est compatible avec la configuration du système d'exploitation de votre serveur. Par exemple, les paires de clés ED25519 peuvent ne pas fonctionner sur [certains systèmes FIPS](https://gitlab.com/gitlab-org/gitlab/-/issues/367429).
- Essayez d'enregistrer manuellement votre clé SSH privée en utilisant `ssh-agent`.
- Essayez de déboguer la connexion en exécutant `ssh -Tv git@example.com`. Remplacez `example.com` par votre URL GitLab.
- Assurez-vous d'avoir suivi toutes les instructions dans [Utiliser SSH sur Microsoft Windows](ssh_advanced.md#use-ssh-on-microsoft-windows).
- Assurez-vous d'avoir [vérifié la propriété et les autorisations SSH de GitLab](../security/ssh_keys_restrictions.md#verify-gitlab-ssh-ownership-and-permissions). Si vous avez plusieurs hôtes, assurez-vous que les autorisations sont correctes sur tous les hôtes.

## Erreur `Could not resolve hostname` {#could-not-resolve-hostname-error}

Vous pourriez recevoir l'erreur suivante lorsque vous [vérifiez votre connexion SSH](ssh.md#verify-your-ssh-connection) :

```shell
ssh: Could not resolve hostname gitlab.example.com: nodename nor servname provided, or not known
```

Si vous recevez cette erreur, SSH n'a pas pu trouver un hôte avec le nom que vous avez indiqué. Le nom que SSH a tenté de résoudre est le texte qui suit `Could not resolve hostname`. Comparez ce nom avec les causes suivantes.

| Cause | Résolution |
|-------|------------|
| Le nom inclut un chemin de dépôt, tel que `gitlab.com:alice/my-project.git`. Cela se produit lorsque vous copiez une URL de clonage dans la commande. | Utilisez l'hôte seul, tel que `ssh -T git@gitlab.com`. |
| Le nom est mal orthographié ou ne correspond pas à l'URL de votre instance GitLab. | Corrigez le nom, puis exécutez à nouveau la commande. |
| Votre réseau ne peut pas résoudre le nom. Cette cause est plus probable sur GitLab Self-Managed et GitLab Dedicated. | Vérifiez que vous pouvez accéder à l'instance et connectez-vous à tout VPN requis. |
| Votre terminal contient un cache de résolution de noms obsolète. | Redémarrez votre terminal, puis exécutez à nouveau la commande. |

## Erreur `Key enrollment failed: invalid format` {#key-enrollment-failed-invalid-format-error}

Vous pourriez recevoir l'erreur suivante lors de la [génération d'une paire de clés SSH pour une clé de sécurité matérielle FIDO2](ssh_advanced.md#generate-an-ssh-key-pair-for-a-fido2-hardware-security-key) :

```shell
Key enrollment failed: invalid format
```

Vous pouvez résoudre ce problème en essayant les actions suivantes :

- Exécutez la commande `ssh-keygen` avec `sudo`.
- Vérifiez que votre clé de sécurité matérielle FIDO2 prend en charge le type de clé fourni.
- Vérifiez que la version d'OpenSSH est 8.2 ou supérieure en exécutant `ssh -V`.

## Erreur : `Permission denied (publickey)` {#error-permission-denied-publickey}

L'erreur `Permission denied (publickey)` indique généralement un ou plusieurs des problèmes suivants :

- Clé publique non ajoutée : vérifiez que la clé publique a été [ajoutée à votre compte GitLab](ssh.md#add-an-ssh-key-to-your-gitlab-account). Ce problème est courant pour les nouveaux utilisateurs ou les nouvelles machines.
- Type de clé non pris en charge : le type de clé est [non pris en charge](ssh.md#supported-ssh-key-types) ou inclut des en-têtes que GitLab ne reconnaît pas.
- Mauvaise clé privée utilisée : si vous avez [plusieurs clés SSH locales](ssh.md#check-for-existing-ssh-key-pairs), vérifiez que la bonne clé est utilisée. SSH utilise par défaut `~/.ssh/id_rsa` ou `id_ed25519`. Vous devrez peut-être [définir la clé à utiliser](ssh_advanced.md#use-ssh-keys-in-another-directory).
- Clé privée inaccessible : [Vérifiez](ssh.md#check-for-existing-ssh-key-pairs) que la clé privée est accessible sur votre appareil local.
- Autorisations locales incorrectes : vérifiez les autorisations de vos clés. La clé privée doit utiliser `600`, et le répertoire `.ssh` doit utiliser `700`.
- Clé SSH non chargée dans `ssh-agent` : vérifiez que la clé est disponible pour votre client SSH local. Ce problème est courant après un redémarrage ou dans de nouvelles sessions de terminal.

## Erreur : `SSH host keys are not available on this system.` {#error-ssh-host-keys-are-not-available-on-this-system}

Si GitLab n'a pas accès aux clés SSH de l'hôte, lorsque vous visitez `gitlab.example/help/instance_configuration`, vous verrez le message d'erreur suivant sous l'en-tête **Empreintes de la clé SSH de l'hôte** à la place de l'empreinte SSH de l'instance :

```plaintext
SSH host keys are not available on this system. Please use ssh-keyscan command or contact your GitLab administrator for more information.
```

Pour résoudre cette erreur :

- Sur les déploiements Helm chart (Kubernetes), mettez à jour le `values.yaml` pour définir [`sshHostKeys.mount`](https://docs.gitlab.com/charts/charts/gitlab/webservice/) sur `true` dans la section `webservice`.
- Sur les instances GitLab Self-Managed, vérifiez le répertoire `/etc/ssh` pour les clés d'hôte.

## Dépannage SSH général {#general-ssh-troubleshooting}

Si les sections précédentes ne résolvent pas votre problème, exécutez la connexion SSH en mode verbeux. Le mode verbeux peut retourner des informations utiles sur la connexion.

Pour exécuter SSH en mode verbeux, utilisez la commande suivante et remplacez `gitlab.example.com` par l'URL de votre instance GitLab :

```shell
ssh -Tvvv git@gitlab.example.com
```

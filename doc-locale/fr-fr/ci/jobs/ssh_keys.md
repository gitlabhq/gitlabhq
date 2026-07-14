---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation des clés SSH avec GitLab CI/CD
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab ne dispose pas de prise en charge intégrée pour la gestion des clés SSH dans un environnement de build (là où s'exécute GitLab Runner).

Utilisez des clés SSH dans les cas suivants :

- Extraire des sous-modules internes.
- Télécharger des packages privés à l'aide de votre gestionnaire de packages. Par exemple, Bundler.
- Déployer votre application sur votre propre serveur ou, par exemple, sur Heroku.
- Exécuter des commandes SSH depuis l'environnement de build vers un serveur distant.
- Synchroniser des fichiers depuis l'environnement de build vers un serveur distant avec Rsync.

La méthode la plus largement prise en charge consiste à injecter une clé SSH dans l'environnement de build en étendant `.gitlab-ci.yml`. Cette approche fonctionne avec n'importe quel type d'[exécuteur](https://docs.gitlab.com/runner/executors/), tel que Docker ou Shell.

> [!note]
> Lorsque vous utilisez des clés SSH dans CI/CD, stockez les clés privées de manière sécurisée et évitez de réutiliser des clés SSH personnelles pour des jobs automatisés. Effectuez une rotation des clés régulièrement pour réduire le risque d'accès non autorisé.

## Créer et utiliser une clé SSH {#create-and-use-an-ssh-key}

Pour créer et utiliser une clé SSH dans GitLab CI/CD :

1. [Générer une nouvelle paire de clés SSH](../../user/ssh.md#generate-an-ssh-key-pair).
1. Ajoutez la clé privée en tant que [variable CI/CD de type fichier](#add-an-ssh-key-as-a-file-type-variable) nommée `SSH_PRIVATE_KEY`.
1. Exécutez [`ssh-agent`](https://linux.die.net/man/1/ssh-agent) dans le job, ce qui charge la clé privée.
1. Copiez la clé publique sur les serveurs auxquels vous souhaitez avoir accès (généralement dans `~/.ssh/authorized_keys`). Si vous accédez à un dépôt GitLab privé, vous devez également ajouter la clé publique en tant que [clé de déploiement](../../user/project/deploy_keys/_index.md).

Dans l'exemple suivant, la commande `ssh-add -` n'affiche pas la valeur de `$SSH_PRIVATE_KEY` dans le job log, bien qu'elle puisse être exposée si vous activez la [journalisation de débogage](../variables/variables_troubleshooting.md#enable-debug-logging). Vous pouvez également vérifier la [visibilité de vos pipelines](../pipelines/settings.md#change-which-users-can-view-your-pipelines).

### Ajouter une clé SSH en tant que variable de type fichier {#add-an-ssh-key-as-a-file-type-variable}

Pour ajouter une clé SSH à votre projet, ajoutez la clé en tant que [variable CI/CD de type fichier](../variables/_index.md#for-a-project) :

1. Définissez **Visibilité** sur **Visible**.

   > [!note]
   > Le paramètre de visibilité doit être **Visible** car les clés SSH contiennent des caractères d'espacement, et les variables **Masquée** ou **Masquée et cachée** ne peuvent pas contenir de caractères d'espacement. N'exécutez jamais une commande telle que `cat` ou `tee` sur la variable, car la clé SSH n'est pas masquée si elle apparaît dans le job log.

1. Dans le champ de texte **Clé**, saisissez le nom de la variable. Par exemple, `SSH_PRIVATE_KEY`.
1. Dans le champ de texte **Valeur**, collez le contenu de la clé privée. La valeur doit se terminer par un saut de ligne (caractère `LF`). Pour ajouter un saut de ligne, appuyez sur <kbd>Enter</kbd> ou <kbd>Return</kbd> à la fin de la dernière ligne avant d'enregistrer.

### Ajouter une clé SSH en tant que variable ordinaire {#add-an-ssh-key-as-a-regular-variable}

Si vous ne souhaitez pas utiliser une variable CI/CD de type fichier, consultez l'[exemple de projet SSH](https://gitlab.com/gitlab-examples/ssh-private-key/). Cette méthode utilise une variable CI/CD ordinaire au lieu d'une variable de type fichier. En général, les variables de type fichier sont préférables car elles préservent la mise en forme multiligne et réduisent le risque d'erreurs liées à la mise en forme.

## Clés SSH avec l'exécuteur Docker {#ssh-keys-when-using-the-docker-executor}

Lorsque vos jobs CI/CD s'exécutent dans des conteneurs Docker, l'environnement est isolé. Pour déployer votre code sur un serveur privé, vous pouvez utiliser une paire de clés SSH.

1. [Générer une nouvelle paire de clés SSH](../../user/ssh.md#generate-an-ssh-key-pair). N'ajoutez pas de phrase secrète à la clé SSH, sinon `before_script` vous la demandera.
1. Ajoutez la clé privée en tant que [variable CI/CD de type fichier](#add-an-ssh-key-as-a-file-type-variable) nommée `SSH_PRIVATE_KEY`.
1. Modifiez votre `.gitlab-ci.yml` avec une action `before_script`. L'exemple suivant suppose une image basée sur Debian et que le job s'exécute dans un conteneur disposant des autorisations nécessaires pour installer des packages.

   ```yaml
   before_script:
     ##
     ## Install ssh-agent if not already installed, it is required by Docker.
     ## (change apt-get to yum if you use an RPM-based image)
     ##
     - 'command -v ssh-agent >/dev/null || ( apt-get update -y && apt-get install openssh-client -y )'

     ##
     ## Run ssh-agent (inside the build environment)
     ##
     - eval $(ssh-agent -s)

     ##
     ## Give the right permissions, otherwise ssh-add will refuse to add files
     ## Add the SSH key stored in SSH_PRIVATE_KEY file type CI/CD variable to the agent store
     ##
     - chmod 400 "$SSH_PRIVATE_KEY"
     - ssh-add "$SSH_PRIVATE_KEY"

     ##
     ## Create the SSH directory and give it the right permissions
     ##
     - mkdir -p ~/.ssh
     - chmod 700 ~/.ssh

     ##
     ## Optionally, if you use Git commands, set the user name and email.
     ##
     # - git config --global user.email "user@example.com"
     # - git config --global user.name "User name"
   ```

   Le [`before_script`](../yaml/_index.md#before_script) peut être défini par défaut ou par job.

1. Assurez-vous que les [clés hôtes SSH du serveur privé sont vérifiées](#verifying-the-ssh-host-keys).
1. Pour finir, ajoutez la clé publique de celle que vous avez créée à la première étape aux services auxquels vous souhaitez avoir accès depuis l'environnement de build. Si vous accédez à un dépôt GitLab privé, vous devez l'ajouter en tant que [clé de déploiement](../../user/project/deploy_keys/_index.md).

C'est tout ! Vous pouvez désormais accéder à des serveurs ou dépôts privés depuis votre environnement de build.

## Clés SSH avec l'exécuteur Shell {#ssh-keys-when-using-the-shell-executor}

Si vous utilisez l'exécuteur Shell et non Docker, la configuration d'une clé SSH est plus simple.

Vous pouvez générer la clé SSH depuis la machine sur laquelle GitLab Runner est installé et utiliser cette clé pour tous les projets exécutés sur cette machine.

1. Commencez par vous connecter au serveur qui exécute vos jobs.
1. Ensuite, depuis le terminal, connectez-vous en tant qu'utilisateur `gitlab-runner` :

   ```shell
   sudo su - gitlab-runner
   ```

1. [Générer une nouvelle paire de clés SSH](../../user/ssh.md#generate-an-ssh-key-pair). N'ajoutez pas de phrase secrète à la clé SSH, sinon `before_script` vous la demandera.
1. Pour finir, ajoutez la clé publique de celle que vous avez créée précédemment aux services auxquels vous souhaitez avoir accès depuis l'environnement de build. Si vous accédez à un dépôt GitLab privé, vous devez l'ajouter en tant que [clé de déploiement](../../user/project/deploy_keys/_index.md).

Après avoir généré la clé, essayez de vous connecter au serveur distant pour accepter l'empreinte digitale :

```shell
ssh example.com
```

Pour accéder aux dépôts sur GitLab.com, utilisez `git@gitlab.com`.

## Vérification des clés hôtes SSH {#verifying-the-ssh-host-keys}

Il est recommandé de vérifier la clé publique propre au serveur privé pour s'assurer de ne pas être la cible d'une attaque de l'homme du milieu. Si quelque chose de suspect se produit, vous le remarquez car le job échoue (la connexion SSH échoue lorsque les clés publiques ne correspondent pas).

Pour connaître les clés hôtes de votre serveur, exécutez la commande `ssh-keyscan` depuis un réseau de confiance (idéalement, depuis le serveur privé lui-même) :

```shell
## Use the domain name
ssh-keyscan example.com

## Or use an IP
ssh-keyscan 10.0.2.2
```

Ajoutez les hôtes à votre projet en tant que [variable CI/CD de type fichier](#add-an-ssh-key-as-a-file-type-variable), sauf :

- Utilisez `SSH_KNOWN_HOSTS` comme **Clé**.
- Utilisez la sortie de `ssh-keyscan` comme **Valeur**.

Si vous devez vous connecter à plusieurs serveurs, toutes les clés hôtes des serveurs doivent être regroupées dans la **Valeur** de la variable, à raison d'une clé par ligne.

> [!note]
> L'utilisation d'une variable CI/CD de type fichier plutôt que `ssh-keyscan` directement dans `.gitlab-ci.yml` présente l'avantage de ne pas avoir à modifier `.gitlab-ci.yml` si le nom de domaine hôte change pour une raison quelconque. De plus, les valeurs sont prédéfinies par vous, ce qui signifie que si les clés hôtes changent soudainement, le job CI/CD n'échoue pas, ce qui indique qu'il y a un problème avec le serveur ou le réseau.
>
> N'exécutez pas `ssh-keyscan` directement dans un job CI/CD, car cela présente un risque de sécurité vulnérable aux attaques de type machine-in-the-middle.

Maintenant que la variable `SSH_KNOWN_HOSTS` est créée, en plus du [contenu de `.gitlab-ci.yml`](#ssh-keys-when-using-the-docker-executor), vous devez ajouter :

```yaml
before_script:
  ##
  ## Assuming you created the SSH_KNOWN_HOSTS file type CI/CD variable:
  ##
  - cp "$SSH_KNOWN_HOSTS" ~/.ssh/known_hosts
  - chmod 644 ~/.ssh/known_hosts
```

## Dépannage {#troubleshooting}

### Erreur : `... error in libcrypto` {#error--error-in-libcrypto}

Vous pouvez obtenir l'erreur suivante lorsque vous chargez une clé SSH dans un job CI/CD :

```plaintext
Error loading key "/builds/path/SSH_PRIVATE_KEY": error in libcrypto
```

Ce problème peut survenir lorsque la valeur de la clé SSH ne se termine pas par un saut de ligne (caractère `LF`).

Pour résoudre ce problème, modifiez la [variable CI/CD de type fichier](../variables/_index.md#use-file-type-cicd-variables) et appuyez sur <kbd>Enter</kbd> ou <kbd>Return</kbd> à la fin de la ligne `-----END OPENSSH PRIVATE KEY-----` de la clé SSH avant d'enregistrer la variable.

### Erreur : `... value cannot contain...` {#error--value-cannot-contain}

Vous pouvez obtenir une erreur lorsque vous enregistrez une clé SSH en tant que variable CI/CD :

```plaintext
Unable to create masked variable because: The value cannot contain the
following characters: whitespace characters.
```

Ce problème se produit lorsque la **Visibilité** de la variable est définie sur **Masquée** ou **Masquée et cachée**. Les variables masquées doivent tenir sur une seule ligne sans espaces, mais les clés SSH contiennent des caractères d'espacement incompatibles avec le masquage.

Pour résoudre ce problème, définissez **Visibilité** sur **Visible** lorsque vous [ajoutez la clé SSH en tant que variable de type fichier](#add-an-ssh-key-as-a-file-type-variable). Les variables de type fichier ne sont pas exposées dans les job logs, ce qui fournit une couche de protection supplémentaire pour la valeur de la clé.

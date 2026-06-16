---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez les prérequis, les stratégies et les étapes d'installation de GitLab dans un conteneur Docker."
title: Installer GitLab dans un conteneur Docker
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Pour installer GitLab dans un conteneur Docker, utilisez Docker Compose, Docker Engine ou le mode Docker Swarm.

Prérequis :

- Vous devez disposer d'une [installation Docker](https://docs.docker.com/engine/install/#server) fonctionnelle qui n'est pas Docker pour Windows. Docker pour Windows n'est pas officiellement pris en charge, car les images présentent des problèmes de compatibilité connus avec les permissions de volumes et potentiellement d'autres problèmes inconnus. Si vous essayez d'exécuter sur Docker pour Windows, consultez la [page d'aide](https://about.gitlab.com/get-help/). Cette page contient des liens vers des ressources communautaires (comme IRC ou des forums) où vous pouvez obtenir de l'aide auprès d'autres utilisateurs.
- Vous devez disposer d'un agent de transport de courrier (MTA), tel que Postfix ou Sendmail. Les images GitLab n'incluent pas de MTA. Vous pouvez installer un MTA dans un conteneur séparé. Bien que vous puissiez installer un MTA dans le même conteneur que GitLab, vous pourriez avoir besoin de réinstaller le MTA après chaque mise à niveau ou redémarrage.
- Vous ne devez pas prévoir de déployer l'image Docker GitLab dans Kubernetes, car cela crée un point de défaillance unique. Si vous souhaitez déployer GitLab dans Kubernetes, utilisez plutôt le [GitLab Helm Chart](https://docs.gitlab.com/charts/) ou l'[GitLab Operator](https://docs.gitlab.com/operator/).
- Vous devez disposer d'un nom d'hôte valide et accessible de l'extérieur pour votre installation Docker. N'utilisez pas `localhost`.

## Configurer le port SSH {#configure-the-ssh-port}

Par défaut, GitLab utilise le port `22` pour interagir avec Git via SSH. Pour utiliser le port `22`, ignorez cette section.

Pour utiliser un port différent, vous pouvez soit :

- Modifier le port SSH du serveur maintenant (recommandé). Les URL de clonage SSH n'auront alors pas besoin du nouveau numéro de port :

  ```plaintext
  ssh://git@gitlab.example.com/user/project.git
  ```

- [Modifier le port SSH de GitLab Shell](configuration.md#expose-gitlab-on-different-ports) après l'installation. Les URL de clonage SSH incluront alors le numéro de port configuré :

  ```plaintext
  ssh://git@gitlab.example.com:<portNumber>/user/project.git
  ```

Pour modifier le port SSH du serveur :

1. Ouvrez `/etc/ssh/sshd_config` avec votre éditeur et modifiez le port SSH :

   ```conf
   Port = 2424
   ```

1. Enregistrez le fichier et redémarrez le service SSH :

   ```shell
   sudo systemctl restart ssh
   ```

1. Vérifiez que vous pouvez vous connecter via SSH. Ouvrez une nouvelle session de terminal et connectez-vous au serveur via SSH en utilisant le nouveau port.

## Créer un répertoire pour les volumes {#create-a-directory-for-the-volumes}

> [!warning]
> Des recommandations spécifiques existent pour les volumes hébergeant les données Gitaly. Les systèmes de fichiers basés sur NFS peuvent entraîner des problèmes de performances, c'est pourquoi [EFS n'est pas recommandé](../aws/_index.md#elastic-file-system-efs).

Créez un répertoire pour les fichiers de configuration, les journaux et les fichiers de données. Le répertoire peut se trouver dans le répertoire personnel de votre utilisateur (par exemple `~/gitlab-docker`), ou dans un répertoire tel que `/srv/gitlab`.

1. Créez le répertoire :

   ```shell
   sudo mkdir -p /srv/gitlab
   ```

1. Si vous exécutez Docker avec un utilisateur autre que `root`, accordez les permissions appropriées à l'utilisateur pour le nouveau répertoire.

1. Configurez une nouvelle variable d'environnement `$GITLAB_HOME` qui définit le chemin d'accès au répertoire que vous avez créé :

   ```shell
   export GITLAB_HOME=/srv/gitlab
   ```

1. Vous pouvez également ajouter la variable d'environnement `GITLAB_HOME` au profil de votre shell afin qu'elle soit appliquée à toutes les futures sessions de terminal :

   - Bash : `~/.bash_profile`
   - ZSH : `~/.zshrc`

Le conteneur GitLab utilise des volumes montés sur l'hôte pour stocker les données persistantes :

| Emplacement local       | Emplacement dans le conteneur | Utilisation                                       |
|----------------------|--------------------|---------------------------------------------|
| `$GITLAB_HOME/data`  | `/var/opt/gitlab`  | Stocke les données de l'application.                    |
| `$GITLAB_HOME/logs`  | `/var/log/gitlab`  | Stocke les journaux.                                |
| `$GITLAB_HOME/config`| `/etc/gitlab`      | Stocke les fichiers de configuration GitLab.      |

## Trouver la version et l'édition GitLab à utiliser {#find-the-gitlab-version-and-edition-to-use}

Dans un environnement de production, vous devez épingler votre déploiement à une version spécifique de GitLab. Consultez les versions disponibles et choisissez la version que vous souhaitez utiliser sur la page des tags Docker :

- [Tags de GitLab Enterprise Edition](https://hub.docker.com/r/gitlab/gitlab-ee/tags/)
- [Tags de GitLab Community Edition](https://hub.docker.com/r/gitlab/gitlab-ce/tags/)

Le nom du tag se compose des éléments suivants :

```plaintext
gitlab/gitlab-ee:<version>-ee.0
```

Où `<version>` est la version de GitLab, par exemple `16.5.3`. La version inclut toujours `<major>.<minor>.<patch>` dans son nom.

À des fins de test, vous pouvez utiliser le tag `latest`, tel que `gitlab/gitlab-ee:latest`, qui pointe vers la dernière release stable.

Les exemples suivants utilisent une version stable de l'Enterprise Edition. Si vous souhaitez utiliser l'image Release Candidate (RC) ou nightly, utilisez plutôt `gitlab/gitlab-ee:rc` ou `gitlab/gitlab-ee:nightly`.

Pour installer la Community Edition, remplacez `ee` par `ce`.

## Installation {#installation}

Vous pouvez exécuter les images Docker GitLab en utilisant :

- [Docker Compose](#install-gitlab-by-using-docker-compose) (recommandé)
- [Docker Engine](#install-gitlab-by-using-docker-engine)
- [Mode Docker Swarm](#install-gitlab-by-using-docker-swarm-mode)

### Installer GitLab en utilisant Docker Compose {#install-gitlab-by-using-docker-compose}

Avec [Docker Compose](https://docs.docker.com/compose/), vous pouvez configurer, installer et mettre à niveau votre installation GitLab basée sur Docker :

1. [Installez Docker Compose](https://docs.docker.com/compose/install/linux/).
1. Créez un fichier `docker-compose.yml`. Par exemple :

   ```yaml
   services:
     gitlab:
       image: gitlab/gitlab-ee:<version>-ee.0
       container_name: gitlab
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           # Add any other gitlab.rb configuration here, each on its own line
           external_url 'https://gitlab.example.com'
       ports:
         - '80:80'
         - '443:443'
         - '22:22'
       volumes:
         - '$GITLAB_HOME/config:/etc/gitlab'
         - '$GITLAB_HOME/logs:/var/log/gitlab'
         - '$GITLAB_HOME/data:/var/opt/gitlab'
       shm_size: '256m'
   ```

   > [!note]
   > Lisez la section [Préconfigurer le conteneur Docker](configuration.md#pre-configure-docker-container) pour voir comment fonctionne la variable `GITLAB_OMNIBUS_CONFIG`.

   Voici un autre exemple de fichier `docker-compose.yml` avec GitLab s'exécutant sur un port HTTP et SSH personnalisé. Notez que les variables `GITLAB_OMNIBUS_CONFIG` correspondent à la section `ports` :

   ```yaml
   services:
     gitlab:
       image: gitlab/gitlab-ee:<version>-ee.0
       container_name: gitlab
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           external_url 'http://gitlab.example.com:8929'
           gitlab_rails['gitlab_shell_ssh_port'] = 2424
       ports:
         - '8929:8929'
         - '443:443'
         - '2424:22'
       volumes:
         - '$GITLAB_HOME/config:/etc/gitlab'
         - '$GITLAB_HOME/logs:/var/log/gitlab'
         - '$GITLAB_HOME/data:/var/opt/gitlab'
       shm_size: '256m'
   ```

   Cette configuration est identique à l'utilisation de `--publish 8929:8929 --publish 2424:22`.

1. Dans le même répertoire que `docker-compose.yml`, démarrez GitLab :

   ```shell
   docker compose up -d
   ```

### Installer GitLab en utilisant Docker Engine {#install-gitlab-by-using-docker-engine}

Vous pouvez également installer GitLab en utilisant Docker Engine.

1. Si vous avez configuré la variable `GITLAB_HOME`, ajustez les répertoires selon vos besoins et exécutez l'image :

   - Si vous n'utilisez pas SELinux, exécutez cette commande :

     ```shell
     sudo docker run --detach \
       --hostname gitlab.example.com \
       --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'" \
       --publish 443:443 --publish 80:80 --publish 22:22 \
       --name gitlab \
       --restart always \
       --volume $GITLAB_HOME/config:/etc/gitlab \
       --volume $GITLAB_HOME/logs:/var/log/gitlab \
       --volume $GITLAB_HOME/data:/var/opt/gitlab \
       --shm-size 256m \
       gitlab/gitlab-ee:<version>-ee.0
     ```

     Cette commande télécharge et démarre un conteneur GitLab, et [publie les ports](https://docs.docker.com/network/#published-ports) nécessaires pour accéder à SSH, HTTP et HTTPS. Toutes les données GitLab sont stockées en tant que sous-répertoires de `$GITLAB_HOME`. Le conteneur redémarre automatiquement après un redémarrage du système.

   - Si vous utilisez SELinux, exécutez plutôt cette commande :

     ```shell
     sudo docker run --detach \
       --hostname gitlab.example.com \
       --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'" \
       --publish 443:443 --publish 80:80 --publish 22:22 \
       --name gitlab \
       --restart always \
       --volume $GITLAB_HOME/config:/etc/gitlab:Z \
       --volume $GITLAB_HOME/logs:/var/log/gitlab:Z \
       --volume $GITLAB_HOME/data:/var/opt/gitlab:Z \
       --shm-size 256m \
       gitlab/gitlab-ee:<version>-ee.0
     ```

     Cette commande garantit que le processus Docker dispose de suffisamment de permissions pour créer les fichiers de configuration dans les volumes montés.

1. Si vous utilisez l'[intégration Kerberos](../../integration/kerberos.md), vous devez également publier votre port Kerberos (par exemple, `--publish 8443:8443`). Ne pas le faire empêche les opérations Git avec Kerberos. Le processus d'initialisation peut prendre un certain temps. Vous pouvez suivre ce processus avec :

   ```shell
   sudo docker logs -f gitlab
   ```

   Après le démarrage du conteneur, vous pouvez visiter `gitlab.example.com`. Le conteneur Docker peut mettre un certain temps avant de commencer à répondre aux requêtes.

1. Visitez l'URL GitLab et connectez-vous avec le nom d'utilisateur `root` et le mot de passe issu de la commande suivante :

   ```shell
   sudo docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
   ```

> [!note]
> Le fichier de mot de passe est automatiquement supprimé lors du premier redémarrage du conteneur après 24 heures.

### Installer GitLab en utilisant le mode Docker Swarm {#install-gitlab-by-using-docker-swarm-mode}

Avec le [mode Docker Swarm](https://docs.docker.com/engine/swarm/), vous pouvez configurer et déployer votre installation GitLab avec Docker dans un cluster swarm.

En mode swarm, vous pouvez utiliser les [secrets Docker](https://docs.docker.com/engine/swarm/secrets/) et les [configurations Docker](https://docs.docker.com/engine/swarm/configs/) pour déployer votre instance GitLab de manière efficace et sécurisée. Les secrets peuvent être utilisés pour transmettre en toute sécurité votre mot de passe root initial sans l'exposer en tant que variable d'environnement. Les configurations peuvent vous aider à maintenir votre image GitLab aussi générique que possible.

Voici un exemple qui déploie GitLab avec quatre runners en tant que [stack](https://docs.docker.com/get-started/swarm-deploy/#describe-apps-using-stack-files), en utilisant des secrets et des configurations :

1. [Configurez un Docker swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/).
1. Créez un fichier `docker-compose.yml` :

   ```yaml
   services:
     gitlab:
       image: gitlab/gitlab-ee:<version>-ee.0
       container_name: gitlab
       restart: always
       hostname: 'gitlab.example.com'
       ports:
         - "22:22"
         - "80:80"
         - "443:443"
       volumes:
         - $GITLAB_HOME/data:/var/opt/gitlab
         - $GITLAB_HOME/logs:/var/log/gitlab
         - $GITLAB_HOME/config:/etc/gitlab
       shm_size: '256m'
       environment:
         GITLAB_OMNIBUS_CONFIG: "from_file('/omnibus_config.rb')"
       configs:
         - source: gitlab
           target: /omnibus_config.rb
       secrets:
         - gitlab_root_password
     gitlab-runner:
       image: gitlab/gitlab-runner:alpine
       deploy:
         mode: replicated
         replicas: 4
   configs:
     gitlab:
       file: ./gitlab.rb
   secrets:
     gitlab_root_password:
       file: ./root_password.txt
   ```

   Pour réduire la complexité, l'exemple précédent exclut la configuration `network`. Vous pouvez trouver plus d'informations dans la [référence officielle du fichier Compose](https://docs.docker.com/compose/compose-file/).

1. Créez un fichier `gitlab.rb` :

   ```ruby
   external_url 'https://my.domain.com/'
   gitlab_rails['initial_root_password'] = File.read('/run/secrets/gitlab_root_password').gsub("\n", "")
   ```

1. Créez un fichier appelé `root_password.txt` contenant le mot de passe :

   ```plaintext
   MySuperSecretAndSecurePassw0rd!
   ```

1. Assurez-vous d'être dans le même répertoire que `docker-compose.yml` et exécutez :

   ```shell
   docker stack deploy --compose-file docker-compose.yml mystack
   ```

Après avoir installé Docker, vous devez [configurer votre instance GitLab](configuration.md).

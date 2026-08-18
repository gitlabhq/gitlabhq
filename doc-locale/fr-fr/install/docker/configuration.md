---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Comment configurer GitLab lors de son exécution dans un conteneur Docker.
title: Configurer GitLab dans un conteneur Docker
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Ce conteneur utilise le package Linux officiel, vous pouvez donc utiliser le fichier de configuration unique `/etc/gitlab/gitlab.rb` pour configurer l'instance.

## Modifier le fichier de configuration {#edit-the-configuration-file}

Pour accéder au fichier de configuration GitLab, vous pouvez démarrer une session shell dans le contexte d'un conteneur en cours d'exécution.

1. Démarrez la session :

   ```shell
   sudo docker exec -it gitlab /bin/bash
   ```

   Vous pouvez également ouvrir `/etc/gitlab/gitlab.rb` directement dans un éditeur :

   ```shell
   sudo docker exec -it gitlab editor /etc/gitlab/gitlab.rb
   ```

1. Dans l'éditeur de texte de votre choix, ouvrez `/etc/gitlab/gitlab.rb` et mettez à jour les champs suivants :

   1. Définissez le champ `external_url` sur une URL valide pour votre instance GitLab.

   1. Pour recevoir des e-mails de GitLab, configurez les [paramètres SMTP](https://docs.gitlab.com/omnibus/settings/smtp/). L'image Docker de GitLab ne dispose pas d'un serveur SMTP préinstallé.

   1. Si vous le souhaitez, [activez HTTPS](https://docs.gitlab.com/omnibus/settings/ssl/).

1. Enregistrez le fichier et redémarrez le conteneur pour reconfigurer GitLab :

   ```shell
   sudo docker restart gitlab
   ```

GitLab se reconfigure à chaque démarrage du conteneur. Pour plus d'options de configuration dans GitLab, consultez la [documentation de configuration](https://docs.gitlab.com/omnibus/settings/configuration/).

## Préconfigurer le conteneur Docker {#pre-configure-docker-container}

Vous pouvez préconfigurer l'image Docker de GitLab en ajoutant la variable d'environnement `GITLAB_OMNIBUS_CONFIG` à la commande Docker run. Cette variable peut contenir n'importe quel paramètre `gitlab.rb` et est évaluée avant le chargement du fichier `gitlab.rb` du conteneur. Ce comportement vous permet de configurer l'URL GitLab externe, d'effectuer une configuration de base de données ou toute autre option du [modèle de package Linux](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template). Les paramètres contenus dans `GITLAB_OMNIBUS_CONFIG` ne sont pas écrits dans le fichier de configuration `gitlab.rb` et sont évalués au chargement. Pour fournir plusieurs paramètres, séparez-les par un point-virgule (`;`).

L'exemple suivant définit l'URL externe, active LFS et démarre le conteneur avec une [taille shm minimale requise pour Prometheus](troubleshooting.md#devshm-mount-not-having-enough-space-in-docker-container) :

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'; gitlab_rails['lfs_enabled'] = true;" \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ee:<version>-ee.0
```

À chaque exécution d'une commande `docker run`, vous devez fournir l'option `GITLAB_OMNIBUS_CONFIG`. Le contenu de `GITLAB_OMNIBUS_CONFIG` n'est _pas_ conservé entre les exécutions successives.

### Exécuter GitLab sur une adresse IP publique {#run-gitlab-on-a-public-ip-address}

Vous pouvez configurer Docker pour utiliser votre adresse IP et transférer tout le trafic vers le conteneur GitLab en modifiant le flag `--publish`.

Pour exposer GitLab sur l'IP `198.51.100.1` :

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'" \
  --publish 198.51.100.1:443:443 \
  --publish 198.51.100.1:80:80 \
  --publish 198.51.100.1:22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ee:<version>-ee.0
```

Vous pouvez ensuite accéder à votre instance GitLab à l'adresse `http://198.51.100.1/` et `https://198.51.100.1/`.

## Exposer GitLab sur différents ports {#expose-gitlab-on-different-ports}

GitLab occupe des [ports spécifiques](../../administration/package_information/defaults.md) à l'intérieur du conteneur.

Si vous souhaitez utiliser des ports hôtes différents des ports par défaut `80` (HTTP), `443` (HTTPS) ou `22` (SSH), vous devez ajouter une directive `--publish` distincte à la commande `docker run`.

Par exemple, pour exposer l'interface web sur le port `8929` de l'hôte et le service SSH sur le port `2424` :

1. Utilisez la commande `docker run` suivante :

   ```shell
   sudo docker run --detach \
     --hostname gitlab.example.com \
     --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com:8929'; gitlab_rails['gitlab_shell_ssh_port'] = 2424" \
     --publish 8929:8929 --publish 2424:22 \
     --name gitlab \
     --restart always \
     --volume $GITLAB_HOME/config:/etc/gitlab \
     --volume $GITLAB_HOME/logs:/var/log/gitlab \
     --volume $GITLAB_HOME/data:/var/opt/gitlab \
     --shm-size 256m \
     gitlab/gitlab-ee:<version>-ee.0
   ```

   > [!note]
   > Le format pour publier les ports est `hostPort:containerPort`. Pour en savoir plus, consultez la documentation Docker sur l'[exposition des ports entrants](https://docs.docker.com/network/#published-ports).

1. Accédez au conteneur en cours d'exécution :

   ```shell
   sudo docker exec -it gitlab /bin/bash
   ```

1. Ouvrez `/etc/gitlab/gitlab.rb` avec votre éditeur et définissez `external_url` :

   ```ruby
   # For HTTP
   external_url "http://gitlab.example.com:8929"

   or

   # For HTTPS (notice the https)
   external_url "https://gitlab.example.com:8929"
   ```

   Le port spécifié dans cette URL doit correspondre au port publié vers l'hôte par Docker. De plus, si le port d'écoute NGINX n'est pas explicitement défini dans `nginx['listen_port']`, c'est `external_url` qui est utilisé à la place. Pour plus d'informations, consultez la [documentation NGINX](https://docs.gitlab.com/omnibus/settings/nginx/).

1. Définissez le port SSH :

   ```ruby
   gitlab_rails['gitlab_shell_ssh_port'] = 2424
   ```

1. Enfin, reconfigurez GitLab :

   ```shell
   gitlab-ctl reconfigure
   ```

En suivant l'exemple précédent, votre navigateur web peut accéder à votre instance GitLab à l'adresse `<hostIP>:8929` et envoyer des données via SSH sur le port `2424`.

Vous pouvez consulter un exemple de fichier `docker-compose.yml` utilisant des ports différents dans la section [Docker Compose](installation.md#install-gitlab-by-using-docker-compose).

## Configurer plusieurs connexions à la base de données {#configure-multiple-database-connections}

Depuis [GitLab 16.0](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6850), GitLab utilise par défaut deux connexions à la base de données pointant vers la même base de données PostgreSQL.

Si, pour quelque raison que ce soit, vous souhaitez revenir à une connexion unique à la base de données :

1. Modifiez `/etc/gitlab/gitlab.rb` à l'intérieur du conteneur :

   ```shell
   sudo docker exec -it gitlab editor /etc/gitlab/gitlab.rb
   ```

1. Ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['databases']['ci']['enable'] = false
   ```

1. Redémarrez le conteneur :

   ```shell
   sudo docker restart gitlab
   ```

## Étapes suivantes {#next-steps}

Après avoir configuré votre installation, envisagez de suivre les [prochaines étapes recommandées](../next_steps.md), notamment les options d'authentification et les restrictions liées aux nouveaux comptes utilisateurs.

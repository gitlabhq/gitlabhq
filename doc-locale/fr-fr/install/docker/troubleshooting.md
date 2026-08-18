---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Résolution des problèmes de GitLab s'exécutant dans un conteneur Docker"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Lors de l'installation de GitLab dans un conteneur Docker, vous pouvez rencontrer les problèmes suivants.

## Diagnostiquer les problèmes potentiels {#diagnose-potential-problems}

Les commandes suivantes sont utiles lors de la résolution des problèmes de votre instance GitLab dans un conteneur Docker :

Lire les journaux du conteneur :

```shell
sudo docker logs gitlab
```

Entrer dans le conteneur en cours d'exécution :

```shell
sudo docker exec -it gitlab /bin/bash
```

Vous pouvez administrer le conteneur GitLab depuis l'intérieur du conteneur comme vous administreriez une [installation du package Linux](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md).

## 500 Internal Error {#500-internal-error}

Lors de la mise à jour de l'image Docker, vous pouvez rencontrer un problème où tous les chemins affichent une page `500`. Si cela se produit, redémarrez le conteneur :

```shell
sudo docker restart gitlab
```

## Problèmes de permissions {#permission-problems}

Lors de la mise à jour depuis des images Docker GitLab plus anciennes, vous pourriez rencontrer des problèmes de permissions. Cela se produit lorsque les permissions utilisateur dans les images précédentes n'ont pas été préservées correctement. Il existe un script qui corrige les permissions pour tous les fichiers.

Pour corriger votre conteneur, exécutez `update-permissions` puis redémarrez le conteneur :

```shell
sudo docker exec gitlab update-permissions
sudo docker restart gitlab
```

## Erreur lors de l'exécution de l'action run sur la ressource `ruby_block` {#error-executing-action-run-on-resource-ruby_block}

Cette erreur se produit lors de l'utilisation de Docker Toolbox avec Oracle VirtualBox sur Windows ou Mac, et lors de l'utilisation de volumes Docker :

```plaintext
Error executing action run on resource ruby_block[directory resource: /data/GitLab]
```

Le volume `/c/Users` est monté en tant que dossier partagé VirtualBox et ne prend pas en charge toutes les fonctionnalités du système de fichiers POSIX. La propriété et les permissions du répertoire ne peuvent pas être modifiées sans remonter le volume, ce qui provoque l'échec de GitLab.

Passez à l'utilisation de l'installation Docker native pour votre plateforme, au lieu d'utiliser Docker Toolbox.

Si vous ne pouvez pas utiliser l'installation Docker native (Windows 10 Home Edition ou Windows 7/8), une solution alternative consiste à configurer des montages NFS à la place des partages VirtualBox pour Docker Toolbox Boot2docker.

## Problèmes Linux ACL {#linux-acl-issues}

Si vous utilisez des ACL de fichiers sur l'hôte Docker, le groupe `docker` nécessite un accès complet aux volumes pour que GitLab fonctionne :

```shell
getfacl $GITLAB_HOME

# file: $GITLAB_HOME
# owner: XXXX
# group: XXXX
user::rwx
group::rwx
group:docker:rwx
mask::rwx
default:user::rwx
default:group::rwx
default:group:docker:rwx
default:mask::rwx
default:other::r-x
```

Si ces valeurs ne sont pas correctes, définissez-les avec :

```shell
sudo setfacl -mR default:group:docker:rwx $GITLAB_HOME
```

Le groupe par défaut est nommé `docker`. Si vous avez modifié le nom du groupe, vous devez ajuster la commande.

## Le montage `/dev/shm` ne dispose pas d'assez d'espace dans le conteneur Docker {#devshm-mount-not-having-enough-space-in-docker-container}

GitLab est fourni avec un endpoint de métriques Prometheus à l'adresse `/-/metrics` pour exposer des statistiques sur l'état et les performances de GitLab. Les fichiers nécessaires à cette fonctionnalité sont écrits dans un système de fichiers temporaire (comme `/run` ou `/dev/shm`).

Par défaut, Docker alloue 64 Mo au répertoire de mémoire partagée (monté à l'emplacement `/dev/shm`). Cette capacité est insuffisante pour contenir tous les fichiers de métriques Prometheus générés, et produira des journaux d'erreurs tels que les suivants :

```plaintext
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
```

Bien que vous puissiez désactiver les métriques Prometheus dans la zone **Admin**, la solution recommandée pour résoudre ce problème est d'[installer](configuration.md#pre-configure-docker-container) le conteneur avec la mémoire partagée définie à au moins 256 Mo. Si vous utilisez `docker run`, vous pouvez passer l'option `--shm-size 256m`. Si vous utilisez un fichier `docker-compose.yml`, vous pouvez définir la clé `shm_size`.

## Les conteneurs Docker épuisent l'espace en raison du `json-file` {#docker-containers-exhausts-space-due-to-the-json-file}

Docker utilise le [pilote de journalisation par défaut `json-file`](https://docs.docker.com/config/containers/logging/configure/#configure-the-default-logging-driver), qui n'effectue aucune rotation des journaux par défaut. En raison de cette absence de rotation, les fichiers journaux stockés par le pilote `json-file` peuvent consommer une quantité significative d'espace disque pour les conteneurs qui génèrent beaucoup de données en sortie. Cela peut entraîner un épuisement de l'espace disque. Pour remédier à ce problème, utilisez [`journald`](https://docs.docker.com/engine/logging/drivers/journald/) comme pilote de journalisation lorsqu'il est disponible, ou [un autre pilote pris en charge](https://docs.docker.com/config/containers/logging/configure/#supported-logging-drivers) avec prise en charge native de la rotation.

## Erreur de dépassement de tampon lors du démarrage de Docker {#buffer-overflow-error-when-starting-docker}

Si vous recevez cette erreur de dépassement de tampon, vous devez purger les anciens fichiers journaux dans `/var/log/gitlab` :

```plaintext
buffer overflow detected : terminated
xargs: tail: terminated by signal 6
```

La suppression des anciens fichiers journaux permet de corriger l'erreur et garantit un démarrage propre de l'instance.

## Erreurs lors de la réutilisation de données d'une installation précédente {#errors-when-reusing-data-from-a-previous-installation}

Lors de la réutilisation de données d'une autre instance, vous pourriez rencontrer les problèmes suivants.

### Erreur `stat: missing operand` au démarrage {#stat-missing-operand-error-on-startup}

Cette erreur se produit lors de la migration depuis une installation de package Linux et que le répertoire `git-data/repositories` est manquant ou est un lien symbolique cassé dans le volume hôte :

```plaintext
stat: missing operand
Expected process to exit with [0], but received '1'
Ran stat --printf='%U' $(readlink -f /var/opt/gitlab/git-data/repositories) returned 1
```

Sur l'hôte, créez le répertoire manquant, puis redémarrez le conteneur :

```shell
sudo mkdir -p $GITLAB_HOME/data/git-data/repositories
sudo docker restart <container_name>
```

Pour un guide de migration complet, consultez [Migrer une instance GitLab avec package Linux vers Docker](migrate.md).

### Le conteneur se ferme immédiatement et la boucle de redémarrage bloque `docker exec` {#container-exits-immediately-and-restart-loop-blocks-docker-exec}

Si un conteneur ne parvient pas à démarrer et continue de redémarrer, vous ne pouvez pas utiliser `docker exec` pour investiguer. Démarrez directement un shell dans l'image à la place :

```shell
docker run --rm -it --entrypoint /bin/bash gitlab/gitlab-ee:<version>
```

Utilisez ce shell pour inspecter la structure de répertoires attendue et comparez-la avec les volumes montés sur l'hôte.

## ThreadError : impossible de créer un fil de discussion – Opération non autorisée {#threaderror-cant-create-thread-operation-not-permitted}

```plaintext
can't create Thread: Operation not permitted
```

Cette erreur se produit lors de l'exécution d'un conteneur construit avec des versions plus récentes de `glibc` sur un [hôte ne prenant pas en charge la fonction clone3](https://github.com/moby/moby/issues/42680). Dans GitLab 16.0 et versions ultérieures, l'image du conteneur inclut le package Linux Ubuntu 22.04, qui est construit avec des versions plus récentes de `glibc`.

Ce problème ne se produit pas avec les outils d'exécution de conteneurs plus récents comme [Docker 20.10.10](https://github.com/moby/moby/pull/42836).

Pour résoudre ce problème, mettez Docker à jour vers la version 20.10.10 ou ultérieure.

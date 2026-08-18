---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Définir et configurer le protocole Git v2 pour GitLab Self-Managed.
title: Configurer le protocole Git v2
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Le protocole Git v2 améliore le protocole filaire v1 de plusieurs façons et est activé par défaut dans GitLab pour les requêtes HTTP. Pour activer SSH, une configuration supplémentaire est requise par un administrateur.

Des informations supplémentaires sur les nouvelles fonctionnalités et améliorations sont disponibles dans le [Google Open Source Blog](https://opensource.googleblog.com/2018/05/introducing-git-protocol-version-2.html).

## Prérequis {#prerequisites}

Côté client, `git` `v2.18.0` ou une version ultérieure doit être installé.

Côté serveur, si nous souhaitons configurer SSH, nous devons paramétrer le serveur `sshd` pour qu'il accepte l'environnement `GIT_PROTOCOL`.

Dans les installations utilisant [GitLab Helm Charts](https://docs.gitlab.com/charts/) et [l'image Docker tout-en-un](../install/docker/_index.md), le service SSH est déjà configuré pour accepter l'environnement `GIT_PROTOCOL`. Les utilisateurs n'ont rien d'autre à faire.

Pour les installations à partir du paquet Linux ou les installations compilées manuellement, mettez à jour la configuration SSH de votre serveur manuellement en ajoutant cette ligne au fichier `/etc/ssh/sshd_config` :

```plaintext
AcceptEnv GIT_PROTOCOL
```

Une fois le démon SSH configuré, redémarrez-le pour que la modification prenne effet :

```shell
# CentOS 6 / RHEL 6
sudo service sshd restart

# All other supported distributions
sudo systemctl restart ssh
```

## Instructions {#instructions}

Pour utiliser le nouveau protocole, les clients doivent soit passer la configuration `-c protocol.version=2` à la commande Git, soit la définir globalement :

```shell
git config --global protocol.version 2
```

### Connexions HTTP {#http-connections}

Vérifiez que Git v2 est utilisé par le client :

```shell
GIT_TRACE_CURL=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | grep Git-Protocol
```

Vous devriez voir que l'en-tête `Git-Protocol` est envoyé :

```plaintext
16:29:44.577888 http.c:657              => Send header: Git-Protocol: version=2
```

Vérifiez que Git v2 est utilisé par le serveur :

```shell
GIT_TRACE_PACKET=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | head
```

Exemple de réponse utilisant le protocole Git v2 :

```shell
$ GIT_TRACE_PACKET=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | head
10:42:50.574485 pkt-line.c:80           packet:          git< # service=git-upload-pack
10:42:50.574653 pkt-line.c:80           packet:          git< 0000
10:42:50.574673 pkt-line.c:80           packet:          git< version 2
10:42:50.574679 pkt-line.c:80           packet:          git< agent=git/2.18.1
10:42:50.574684 pkt-line.c:80           packet:          git< ls-refs
10:42:50.574688 pkt-line.c:80           packet:          git< fetch=shallow
10:42:50.574693 pkt-line.c:80           packet:          git< server-option
10:42:50.574697 pkt-line.c:80           packet:          git< 0000
10:42:50.574817 pkt-line.c:80           packet:          git< version 2
10:42:50.575308 pkt-line.c:80           packet:          git< agent=git/2.18.1
```

### Connexions SSH {#ssh-connections}

Vérifiez que Git v2 est utilisé par le client :

```shell
GIT_SSH_COMMAND="ssh -v" git -c protocol.version=2 ls-remote ssh://git@your-gitlab-instance.com/group/repo.git 2>&1 | grep GIT_PROTOCOL
```

Vous devriez voir que la variable d'environnement `GIT_PROTOCOL` est envoyée :

```plaintext
debug1: Sending env GIT_PROTOCOL = version=2
```

Pour le côté serveur, vous pouvez utiliser les [mêmes exemples que pour HTTP](#http-connections), en modifiant l'URL pour utiliser SSH.

### Observer la version du protocole Git des connexions {#observe-git-protocol-version-of-connections}

Pour plus d'informations sur l'observation des versions du protocole Git utilisées dans un environnement de production, consultez la [documentation pertinente](gitaly/monitoring.md#queries).

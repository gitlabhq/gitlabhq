---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Comment redémarrer GitLab
description: Comment redémarrer GitLab.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Selon la façon dont vous avez installé GitLab, il existe différentes méthodes pour redémarrer ses services.

> [!note]
> Un court temps d'arrêt est prévu pour toutes les méthodes.

## Installations de packages Linux {#linux-package-installations}

Si vous avez utilisé le [package Linux](https://about.gitlab.com/install/) pour installer GitLab, vous devriez déjà avoir `gitlab-ctl` dans votre `PATH`.

`gitlab-ctl` interagit avec l'installation par package Linux et peut être utilisé pour redémarrer l'application GitLab Rails (Puma) ainsi que les autres composants, tels que :

- GitLab Workhorse
- Sidekiq
- PostgreSQL (si vous utilisez celui fourni en bundle)
- NGINX (si vous utilisez celui fourni en bundle)
- Redis (si vous utilisez celui fourni en bundle)
- [Mailroom](reply_by_email.md)
- Logrotate

### Redémarrer une installation par package Linux {#restart-a-linux-package-installation}

Il peut arriver dans la documentation que vous soyez invité à _redémarrer_ GitLab. Pour redémarrer une installation par package Linux, exécutez :

```shell
sudo gitlab-ctl restart
```

La sortie devrait ressembler à ceci :

```plaintext
ok: run: gitlab-workhorse: (pid 11291) 1s
ok: run: logrotate: (pid 11299) 0s
ok: run: mailroom: (pid 11306) 0s
ok: run: nginx: (pid 11309) 0s
ok: run: postgresql: (pid 11316) 1s
ok: run: redis: (pid 11325) 0s
ok: run: sidekiq: (pid 11331) 1s
ok: run: puma: (pid 11338) 0s
```

Pour redémarrer un composant séparément, vous pouvez ajouter son nom de service à la commande `restart`. Par exemple, pour redémarrer **uniquement** NGINX, vous devez exécuter :

```shell
sudo gitlab-ctl restart nginx
```

Pour vérifier le statut des services GitLab, exécutez :

```shell
sudo gitlab-ctl status
```

Remarquez que tous les services indiquent `ok: run`.

Parfois, des composants expirent (recherchez `timeout` dans les journaux) pendant le redémarrage et parfois ils se bloquent. Dans ce cas, vous pouvez utiliser `gitlab-ctl kill <service>` pour envoyer le signal `SIGKILL` au service, par exemple `sidekiq`. Après cela, un redémarrage devrait s'effectuer correctement.

En dernier recours, vous pouvez essayer de reconfigurer GitLab à la place.

### Reconfigurer une installation par package Linux {#reconfigure-a-linux-package-installation}

Il peut arriver dans la documentation que vous soyez invité à _reconfigurer_ GitLab. Rappellez-vous que cette méthode s'applique uniquement aux installations par package Linux.

Pour reconfigurer une installation par package Linux, exécutez :

```shell
sudo gitlab-ctl reconfigure
```

La reconfiguration de GitLab doit avoir lieu lorsque quelque chose dans sa configuration (`/etc/gitlab/gitlab.rb`) a changé.

Lorsque vous exécutez `gitlab-ctl reconfigure`, [Chef](https://www.chef.io/products/chef-infra), l'application de gestion de configuration sous-jacente qui alimente les installations par package Linux, effectue quelques vérifications. Chef s'assure que les répertoires, les permissions et les services sont en place et fonctionnent correctement.

Chef redémarre également les composants GitLab si l'un de leurs fichiers de configuration a changé.

Si vous modifiez manuellement des fichiers dans `/var/opt/gitlab` gérés par Chef, l'exécution de `reconfigure` annule les modifications et redémarre les services qui dépendent de ces fichiers.

## Installations compilées manuellement {#self-compiled-installations}

Si vous avez suivi le guide d'installation officiel pour [compiler votre installation vous-même](../install/self_compiled/_index.md), exécutez la commande suivante pour redémarrer GitLab :

```shell
# For systems running systemd
sudo systemctl restart gitlab.target

# For systems running SysV init
sudo service gitlab restart
```

Cela devrait redémarrer Puma, Sidekiq, GitLab Workhorse et [Mailroom](reply_by_email.md) (si activé).

## Installations par chart Helm {#helm-chart-installations}

Il n'existe pas de commande unique pour redémarrer l'intégralité de l'application GitLab installée via le [chart Helm cloud-native](https://docs.gitlab.com/charts/). En général, il devrait suffire de redémarrer un composant spécifique séparément (par exemple, `gitaly`, `puma`, `workhorse` ou `gitlab-shell`) en supprimant tous les pods qui lui sont associés :

```shell
kubectl delete pods -l release=<helm release name>,app=<component name>
```

Le nom de la release peut être obtenu à partir de la sortie de la commande `helm list`.

## Installation Docker {#docker-installation}

Si vous modifiez la configuration de votre [installation Docker](../install/docker/_index.md), pour que cette modification prenne effet, vous devez redémarrer :

- Le conteneur principal `gitlab`.
- Tous les conteneurs de composants séparés.

Par exemple, si vous avez déployé Sidekiq sur un conteneur séparé, pour redémarrer les conteneurs, exécutez :

```shell
sudo docker restart gitlab
sudo docker restart sidekiq
```

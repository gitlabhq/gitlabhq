---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Tâches Rake d'administration des webhooks"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab fournit des tâches Rake pour la gestion des webhooks.

Les requêtes vers le [réseau local par les webhooks](../../security/webhooks.md) peuvent être autorisées ou bloquées par un administrateur.

## Ajouter un webhook à tous les projets {#add-a-webhook-to-all-projects}

Pour ajouter un webhook à tous les projets, exécutez :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook"

# source installations
bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" RAILS_ENV=production
```

## Ajouter un webhook à des projets dans un espace de nommage {#add-a-webhook-to-projects-in-a-namespace}

Pour ajouter un webhook à tous les projets d'un espace de nommage spécifique, exécutez :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=<namespace>

# source installations
bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=<namespace> RAILS_ENV=production
```

## Supprimer un webhook de projets {#remove-a-webhook-from-projects}

Pour supprimer un webhook de tous les projets, exécutez :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook"

# source installations
bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" RAILS_ENV=production
```

## Supprimer un webhook de projets dans un espace de nommage {#remove-a-webhook-from-projects-in-a-namespace}

Pour supprimer un webhook de projets dans un espace de nommage spécifique, exécutez :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=<namespace>

# source installations
bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=<namespace> RAILS_ENV=production
```

## Lister tous les webhooks {#list-all-webhooks}

Pour lister tous les webhooks, exécutez :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:list

# source installations
bundle exec rake gitlab:web_hook:list RAILS_ENV=production
```

## Lister les webhooks pour les projets dans un espace de nommage {#list-webhooks-for-projects-in-a-namespace}

Pour lister tous les webhooks des projets dans un espace de nommage spécifié, exécutez :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:list NAMESPACE=<namespace>

# source installations
bundle exec rake gitlab:web_hook:list NAMESPACE=<namespace> RAILS_ENV=production
```

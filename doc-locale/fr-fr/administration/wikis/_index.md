---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Paramètres du Wiki
description: Configurer les paramètres du Wiki.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Ajustez les paramètres du wiki de votre instance GitLab.

## Limite de taille du contenu d'une page wiki {#wiki-page-content-size-limit}

Vous pouvez définir une limite maximale de taille du contenu pour les pages wiki. Cette limite peut empêcher les abus de la fonctionnalité. La valeur par défaut est **5242880 octets** (5 Mo).

### Comment cela fonctionne-t-il ? {#how-does-it-work}

La limite de taille du contenu est appliquée lorsqu'une page wiki est créée ou mise à jour via l'interface utilisateur ou l'API GitLab. Les modifications locales transmises avec Git ne sont pas validées.

Pour ne pas altérer les pages wiki existantes, la limite ne prend effet que lorsqu'une page wiki est de nouveau modifiée et que le contenu change.

### Configuration de la limite de taille du contenu d'une page wiki {#wiki-page-content-size-limit-configuration}

Ce paramètre n'est pas disponible via les [paramètres de la zone **Admin**](../settings/_index.md). Pour configurer ce paramètre, utilisez soit la console Rails, soit l'[API des paramètres d'application](../../api/settings.md).

> [!note]
> La valeur de la limite doit être exprimée en octets. La valeur minimale est de 1024 octets.

#### Via la console Rails {#through-the-rails-console}

Pour configurer ce paramètre via la console Rails :

1. Démarrez la console Rails :

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For installations from source
   sudo -u git -H bundle exec rails console -e production
   ```

1. Mettez à jour la taille maximale du contenu de la page wiki :

   ```ruby
   ApplicationSetting.first.update!(wiki_page_max_content_bytes: 5.megabytes)
   ```

Pour récupérer la valeur actuelle, démarrez la console Rails et exécutez :

  ```ruby
  Gitlab::CurrentSettings.wiki_page_max_content_bytes
  ```

#### Via l'API {#through-the-api}

Pour définir la limite de taille de la page wiki via l'API des paramètres d'application, utilisez une commande, comme vous le feriez pour [mettre à jour n'importe quel autre paramètre](../../api/settings.md#update-application-settings) :

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings?wiki_page_max_content_bytes=5242880"
```

Vous pouvez également utiliser l'API pour [récupérer la valeur actuelle](../../api/settings.md#retrieve-details-on-current-application-settings) :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings"
```

### Réduire la taille du dépôt wiki {#reduce-wiki-repository-size}

Le wiki est comptabilisé dans la taille de stockage de l'espace de nommage via [la taille du stockage de l'espace de nommage](../settings/account_and_limit_settings.md), vous devriez donc maintenir vos dépôts wiki aussi compacts que possible.

Pour plus d'informations sur les outils permettant de compacter les dépôts, consultez la documentation sur la [réduction de la taille du dépôt](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size).

## Autoriser les inclusions URI pour AsciiDoc {#allow-uri-includes-for-asciidoc}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/348687) dans GitLab 16.1.

{{< /history >}}

Les directives d'inclusion importent du contenu depuis des pages distinctes ou des URL externes, et l'affichent dans le contenu du document actuel. Pour activer les inclusions AsciiDoc, activez la fonctionnalité via la console Rails ou l'API.

### Via la console Rails {#through-the-rails-console-1}

Pour configurer ce paramètre via la console Rails :

1. Démarrez la console Rails :

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For installations from source
   sudo -u git -H bundle exec rails console -e production
   ```

1. Mettez à jour le wiki pour autoriser les inclusions URI pour AsciiDoc :

   ```ruby
   ApplicationSetting.first.update!(wiki_asciidoc_allow_uri_includes: true)
   ```

Pour vérifier si les inclusions sont activées, démarrez la console Rails et exécutez :

  ```ruby
  Gitlab::CurrentSettings.wiki_asciidoc_allow_uri_includes
  ```

### Via l'API {#through-the-api-1}

Pour configurer le wiki afin d'autoriser les inclusions URI pour AsciiDoc via l'[API des paramètres d'application](../../api/settings.md#update-application-settings), utilisez une commande `curl` :

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/application/settings?wiki_asciidoc_allow_uri_includes=true"
```

## Sujets connexes {#related-topics}

- [Documentation utilisateur pour les wikis](../../user/project/wiki/_index.md)
- [API des wikis de projet](../../api/wikis.md)
- [API des wikis de groupe](../../api/group_wikis.md)

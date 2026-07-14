---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurez les paramètres des extraits de code pour votre instance GitLab.
title: Extraits de code
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Pour éviter tout abus d'extraits de code sur votre instance, configurez une taille maximale d'extrait de code qui est appliquée lorsque des utilisateurs créent ou mettent à jour des extraits de code. Les extraits de code existants ne sont pas affectés par la limite, sauf si un utilisateur les met à jour et que leur contenu change.

La limite par défaut est de 52428800 octets (50 Mo).

## Configurer la limite de taille des extraits de code {#configure-the-snippet-size-limit}

Pour configurer la limite de taille des extraits de code, utilisez la console Rails ou l'[API des paramètres d'application](../../api/settings.md).

La limite doit être exprimée en octets.

Ce paramètre n'est pas disponible dans les [paramètres de la zone **Admin**](../settings/_index.md).

### Utiliser la console Rails {#use-the-rails-console}

Pour configurer ce paramètre via la console Rails :

1. [Démarrez la console Rails](../operations/rails_console.md#starting-a-rails-console-session).
1. Mettez à jour la taille de fichier maximale des extraits de code :

   ```ruby
   ApplicationSetting.first.update!(snippet_size_limit: 50.megabytes)
   ```

Pour récupérer la valeur actuelle, démarrez la console Rails et exécutez :

  ```ruby
  Gitlab::CurrentSettings.snippet_size_limit
  ```

### Utiliser l'API {#use-the-api}

Pour définir la limite à l'aide de l'API des paramètres d'application (similaire à [la mise à jour de tout autre paramètre](../../api/settings.md#update-application-settings)), utilisez cette commande :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>"
  --url "https://gitlab.example.com/api/v4/application/settings?snippet_size_limit=52428800"
```

Pour [récupérer la valeur actuelle](../../api/settings.md#retrieve-details-on-current-application-settings) depuis l'API :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/settings"
```

## Sujets connexes {#related-topics}

- [Extraits de code utilisateur](../../user/snippets.md)

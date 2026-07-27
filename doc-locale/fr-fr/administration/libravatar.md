---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez des services d'avatar pour les profils utilisateurs à l'aide de Gravatar, Libravatar ou de services personnalisés."
title: Utiliser le service Libravatar avec GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab prend en charge par défaut le service d'avatar [Gravatar](https://gravatar.com).

Libravatar est un autre service qui transmet votre avatar (photo de profil) à d'autres sites web. L'API Libravatar est [fortement basée sur Gravatar](https://wiki.libravatar.org/api/), ce qui vous permet de passer au service d'avatar Libravatar ou même à votre propre serveur Libravatar.

## Remplacer le service Libravatar par votre propre service {#change-the-libravatar-service-to-your-own-service}

Dans la [section gravatar de `gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/68dac188ec6b1b03d53365e7579422f44cbe7a1c/config/gitlab.yml.example#L469-476), définissez les options de configuration comme suit :

Pour les installations avec le package Linux :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['gravatar_enabled'] = true
   #### For HTTPS
   gitlab_rails['gravatar_ssl_url'] = "https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
   #### Use this line instead for HTTP
   # gitlab_rails['gravatar_plain_url'] = "http://cdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
   ```

1. Pour appliquer les modifications, exécutez `sudo gitlab-ctl reconfigure`.

Pour les installations compilées à partir des sources :

1. Modifiez `config/gitlab.yml` :

   ```yaml
     gravatar:
       enabled: true
       # default: https://www.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon
       plain_url: "http://cdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
       # default: https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon
       ssl_url: "https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
   ```

1. Enregistrez le fichier, puis [redémarrez](restart_gitlab.md#self-compiled-installations) GitLab pour que les modifications prennent effet.

## Définir le service Libravatar sur la valeur par défaut (Gravatar) {#set-the-libravatar-service-to-default-gravatar}

Pour les installations avec le package Linux :

1. Supprimez `gitlab_rails['gravatar_ssl_url']` ou `gitlab_rails['gravatar_plain_url']` de `/etc/gitlab/gitlab.rb`.
1. Pour appliquer les modifications, exécutez `sudo gitlab-ctl reconfigure`.

Pour les installations compilées à partir des sources :

1. Supprimez la section `gravatar:` de `config/gitlab.yml`.
1. Enregistrez le fichier, puis [redémarrez](restart_gitlab.md#self-compiled-installations) GitLab pour appliquer les modifications.

## Désactiver le service Gravatar {#disable-gravatar-service}

Pour désactiver Gravatar, par exemple pour interdire les services tiers, procédez comme suit :

Pour les installations avec le package Linux :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['gravatar_enabled'] = false
   ```

1. Pour appliquer les modifications, exécutez `sudo gitlab-ctl reconfigure`.

Pour les installations compilées à partir des sources :

1. Modifiez `config/gitlab.yml` :

   ```yaml
     gravatar:
       enabled: false
   ```

1. Enregistrez le fichier, puis [redémarrez](restart_gitlab.md#self-compiled-installations) GitLab pour appliquer les modifications.

### Votre propre serveur Libravatar {#your-own-libravatar-server}

Si vous [exécutez votre propre service Libravatar](https://wiki.libravatar.org/running_your_own/), l'URL est différente dans la configuration, mais vous devez fournir les mêmes espaces réservés pour que GitLab puisse analyser l'URL correctement.

Par exemple, si vous hébergez un service sur `https://libravatar.example.com` et que la valeur `ssl_url` que vous devez fournir dans `gitlab.yml` est :

`https://libravatar.example.com/avatar/%{hash}?s=%{size}&d=identicon`

## URL par défaut pour les images manquantes {#default-url-for-missing-images}

[Libravatar prend en charge différents ensembles](https://wiki.libravatar.org/api/) d'images de remplacement pour les adresses e-mail des utilisateurs introuvables sur le service Libravatar.

Pour utiliser un ensemble autre que `identicon`, remplacez la partie `&d=identicon` de l'URL par un autre ensemble pris en charge. Par exemple, vous pouvez utiliser l'ensemble `retro`, auquel cas l'URL ressemblerait à : `ssl_url: "https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=retro"`

## Exemples d'utilisation pour Microsoft Office 365 {#usage-examples-for-microsoft-office-365}

Si vos utilisateurs sont des utilisateurs d'Office 365, le service `GetPersonaPhoto` peut être utilisé. Ce service nécessite une connexion, ce cas d'utilisation est donc particulièrement adapté aux installations en entreprise où tous les utilisateurs ont accès à Office 365.

```ruby
gitlab_rails['gravatar_plain_url'] = 'http://outlook.office.com/owa/service.svc/s/GetPersonaPhoto?email=%{email}&size=HR120x120'
gitlab_rails['gravatar_ssl_url'] = 'https://outlook.office.com/owa/service.svc/s/GetPersonaPhoto?email=%{email}&size=HR120x120'
```

---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Indiquer le domaine générique utilisé par le Web IDE pour isoler les extensions VS Code et les vues web
title: "Domaine hôte de l'extension Web IDE"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le domaine hôte de l'extension est un nom de domaine générique utilisé par le Web IDE pour isoler le code tiers installé à l'aide de [Extension Marketplace](../../user/project/web_ide/_index.md#manage-extensions). Le Web IDE s'appuie sur la stratégie [same origin](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy) du navigateur web pour exécuter les extensions dans un environnement sandbox.

GitLab fournit un domaine hôte d'extension par défaut `*.cdn.web-ide.gitlab-static.net` disponible pour toutes les offres GitLab par défaut. Ce domaine générique pointe vers un serveur HTTP externe qui héberge les ressources statiques de VS Code. Chaque extension est servie depuis son propre sous-domaine. Dans les environnements hors ligne, le navigateur web d'un utilisateur ne peut pas se connecter à ce serveur HTTP externe, ce qui limite les capacités du Web IDE.

Pour contourner cette limitation, les administrateurs d'instances GitLab peuvent configurer un domaine hôte d'extension personnalisé. Le domaine hôte d'extension personnalisé pointe vers l'instance GitLab elle-même, qui peut également servir les ressources statiques VS Code, tout comme la solution par défaut.

> [!warning]
> Il existe de graves risques de sécurité associés à la configuration de domaines génériques trop larges dans le domaine hôte de l'extension Web IDE. Une mauvaise configuration peut entraîner la compromission de votre instance GitLab et de toutes les données associées.

## Configurer un domaine hôte d'extension personnalisé {#set-up-custom-extension-host-domain}

Prérequis :

- Vous devez être administrateur.

Ces instructions concernent une [installation via le package Linux](../../install/package/_index.md) qui utilise l'installation NGINX par défaut. Les administrateurs GitLab et les ingénieurs DevOps doivent adapter ce guide à d'autres méthodes d'installation.

1. Suivez le guide pour [insérer des paramètres personnalisés dans la configuration NGINX](https://docs.gitlab.com/omnibus/settings/nginx/#insert-custom-settings-into-the-nginx-configuration) afin d'ajouter un bloc `server`. Ce bloc configure NGINX pour gérer les requêtes destinées au domaine hôte de l'extension. L'extrait de code suivant fournit une configuration de référence. Remplacez `<extension-host-domain-placeholder>` par le nom de domaine générique de votre domaine hôte d'extension Web IDE :

   ```nginx
   server {
     listen *:443 ssl;
     server_name *.<extension-host-domain-placeholder>;

     ssl_certificate /etc/gitlab/ssl/<extension-host-domain-placeholder>.pem;
     ssl_certificate_key /etc/gitlab/ssl/<extension-host-domain-placeholder>-key.pem;

     ## Individual nginx logs for this GitLab vhost
     access_log  /var/log/gitlab/nginx/gitlab_access.log gitlab_access;
     error_log   /var/log/gitlab/nginx/gitlab_error.log;

     location /assets/ {
       client_max_body_size 0;
       gzip off;

       proxy_read_timeout      300;
       proxy_connect_timeout   300;
       proxy_redirect          off;

       proxy_http_version 1.1;

       proxy_set_header    Host                $http_host;
       proxy_set_header    X-Real-IP           $remote_addr;
       proxy_set_header    X-Forwarded-For     $remote_addr;
       proxy_set_header    X-Forwarded-Proto   $scheme;

       proxy_pass http://gitlab-workhorse;
     }
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet. Ensuite, ouvrez l'application GitLab.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Web IDE**.
1. Dans le champ de texte **Domaine hôte de l'extension**, saisissez le domaine hôte d'extension personnalisé.
1. Sélectionnez **Sauvegarder les modifications**.

Après avoir enregistré les modifications, vous pouvez ouvrir un projet dans le Web IDE pour vérifier que le domaine hôte d'extension personnalisé est utilisé par l'éditeur.

## Solution par défaut à origine unique {#single-origin-fallback}

> [!warning]
> La solution par défaut à origine unique est activée par défaut et présente des risques de sécurité. Vous devez désactiver la solution par défaut et, à la place, vous assurer que le domaine hôte de l'extension n'est pas bloqué par la configuration CORS, les politiques de sécurité du navigateur web ou un serveur proxy.

Par défaut, le Web IDE s'exécute en mode multi-origine, ce qui permet de servir les ressources statiques VS Code depuis un domaine hôte d'extension distinct. Cette isolation empêche les acteurs malveillants d'exploiter l'hôte d'extension pour effectuer des requêtes authentifiées vers l'instance GitLab.

Cependant, lorsque le domaine hôte de l'extension est inaccessible en raison de restrictions réseau ou CORS, le Web IDE bascule automatiquement en mode mono-origine. Dans ce mode, le Web IDE sert les ressources VS Code depuis la même origine que l'application GitLab, ce qui augmente la surface d'attaque et crée des vulnérabilités de sécurité.

Le paramètre **Activer une solution par défaut à origine unique** contrôle si le Web IDE peut basculer en mode mono-origine lorsque le domaine hôte de l'extension est inaccessible.

Prérequis :

- Accès administrateur.

Pour configurer ce paramètre :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Web IDE**.
1. Cochez ou décochez la case **Activer une solution par défaut à origine unique**.
1. Sélectionnez **Sauvegarder les modifications**.

---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utiliser Shibboleth comme fournisseur d'authentification"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> Utilisez l'[intégration SAML de GitLab](saml.md) pour intégrer des fournisseurs d'identité (IdP) Shibboleth spécifiques. Pour la prise en charge de la fédération Shibboleth (Discovery Service), utilisez ce document.

Pour activer la prise en charge de Shibboleth dans GitLab, utilisez Apache à la place de NGINX. Apache utilise le module `mod_shib2` pour l'authentification Shibboleth et peut transmettre des attributs en tant qu'en-têtes au fournisseur OmniAuth Shibboleth.

Vous pouvez utiliser le NGINX fourni dans le package Linux pour exécuter un fournisseur de services Shibboleth sur une instance différente à l'aide d'une configuration de proxy inverse. Cependant, si vous ne procédez pas ainsi, le NGINX fourni est difficile à configurer.

Pour activer le fournisseur OmniAuth Shibboleth, vous devez :

- [Installer le module Apache](https://shibboleth.atlassian.net/wiki/spaces/SP3/pages/2065335062/Apache)
- [Configurer le module Apache](https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache)

Pour activer Shibboleth :

1. Protégez l'URL de rappel OmniAuth Shibboleth :

   ```apache
   <Location /users/auth/shibboleth/callback>
     AuthType shibboleth
     ShibRequestSetting requireSession 1
     ShibUseHeaders On
     require valid-user
   </Location>

   Alias /shibboleth-sp /usr/share/shibboleth
   <Location /shibboleth-sp>
     Satisfy any
   </Location>

   <Location /Shibboleth.sso>
     SetHandler shib
   </Location>
   ```

1. Excluez les URL Shibboleth de la réécriture. Ajoutez `RewriteCond %{REQUEST_URI} !/Shibboleth.sso` et `RewriteCond %{REQUEST_URI} !/shibboleth-sp`. Exemple de configuration :

   ```apache
   # Apache equivalent of Nginx try files
   RewriteEngine on
   RewriteCond %{DOCUMENT_ROOT}/%{REQUEST_FILENAME} !-f
   RewriteCond %{REQUEST_URI} !/Shibboleth.sso
   RewriteCond %{REQUEST_URI} !/shibboleth-sp
   RewriteRule .* http://127.0.0.1:8080%{REQUEST_URI} [P,QSA]
   RequestHeader set X_FORWARDED_PROTO 'https'
   ```

1. Ajoutez Shibboleth à `/etc/gitlab/gitlab.rb` en tant que fournisseur OmniAuth. Les attributs utilisateur sont envoyés du proxy inverse Apache à GitLab sous forme d'en-têtes dont les noms proviennent du mappage des attributs Shibboleth. Par conséquent, les valeurs du hash `args` doivent être au format `"HTTP_ATTRIBUTE"`. Les clés du hash sont des arguments de la [classe OmniAuth::Strategies::Shibboleth](https://github.com/omniauth/omniauth-shibboleth-redux/blob/master/lib/omniauth/strategies/shibboleth.rb) et sont documentées par le gem [`omniauth-shibboleth-redux`](https://github.com/omniauth/omniauth-shibboleth-redux) (veillez à noter la version du gem incluse dans GitLab).

   Le fichier doit ressembler à ceci :

   ```ruby
   external_url 'https://gitlab.example.com'
   gitlab_rails['internal_api_url'] = 'https://gitlab.example.com'

   # disable Nginx
   nginx['enable'] = false

   gitlab_rails['omniauth_allow_single_sign_on'] = true
   gitlab_rails['omniauth_block_auto_created_users'] = false
   gitlab_rails['omniauth_providers'] = [
     {
       "name"  => "shibboleth",
       "label" => "Text for Login Button",
       "args"  => {
           "shib_session_id_field"     => "HTTP_SHIB_SESSION_ID",
           "shib_application_id_field" => "HTTP_SHIB_APPLICATION_ID",
           "uid_field"                 => 'HTTP_EPPN',
           "name_field"                => 'HTTP_CN',
           "info_fields"               => { "email" => 'HTTP_MAIL'}
       }
     }
   ]
   ```

   Si certains de vos utilisateurs semblent être authentifiés par Shibboleth et Apache, mais que GitLab rejette leur compte avec un URI contenant « e-mail is invalid », votre fournisseur d'identité Shibboleth ou votre Attribute Authority peut asserter plusieurs adresses e-mail. Dans ce cas, envisagez de définir l'argument `multi_values` sur `first`.
1. Pour que les modifications prennent effet :
   - Pour les installations à partir du package Linux, [reconfigurez](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab.
   - Pour les installations compilées depuis les sources, [redémarrez](../administration/restart_gitlab.md#self-compiled-installations) GitLab.

Sur la page de connexion, une icône **Se connecter avec : Shibboleth** devrait maintenant apparaître sous le formulaire de connexion standard. Sélectionnez l'icône pour démarrer le processus d'authentification. Vous êtes redirigé vers le serveur IdP approprié pour la configuration de votre module Shibboleth. Si tout se passe bien, vous êtes renvoyé vers GitLab et connecté.

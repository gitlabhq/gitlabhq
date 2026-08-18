---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez comment modifier les balises d'en-tête HTML de votre instance GitLab."
title: "Balises d'en-tête HTML personnalisées"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153877) dans GitLab 17.1.

{{< /history >}}

Si vous gérez vous-même une instance GitLab dans l'UE, ou dans toute juridiction qui exige une bannière de consentement aux cookies, des balises d'en-tête HTML supplémentaires sont nécessaires pour ajouter des scripts et des feuilles de style.

## Implications en matière de sécurité {#security-implications}

Avant d'activer cette fonctionnalité, vous devez comprendre les implications que cela peut avoir sur la sécurité.

Une ressource externe précédemment légitime pourrait finir par être compromise, puis utilisée pour extraire pratiquement n'importe quelle donnée de n'importe quel utilisateur de l'instance GitLab. Pour cette raison, vous ne devez jamais ajouter de ressources provenant de sources externes non fiables. Si possible, vous devez toujours utiliser des contrôles d'intégrité tels que [Subresource Integrity](https://www.w3.org/TR/SRI/) avec des ressources tierces pour confirmer l'authenticité des ressources chargées.

Limitez au minimum les fonctionnalités que vous ajoutez en utilisant des balises d'en-tête HTML. Dans le cas contraire, cela pourrait également causer des problèmes de stabilité ou de fonctionnalité si, par exemple, vous interagissez avec d'autres codes d'application de GitLab.

## Ajouter une balise d'en-tête HTML personnalisée {#add-a-custom-html-header-tag}

Vous devez ajouter les sources externes à la politique de sécurité du contenu (Content Security Policy), disponible dans l'option `content_security_policy`. Pour l'exemple suivant, vous devez étendre `script_src` et `style_src`.

Pour ajouter une balise d'en-tête HTML personnalisée :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez votre configuration. Par exemple :

   ```ruby
   gitlab_rails['custom_html_header_tags'] = <<-'EOS'
   <script src="https://example.com/cookie-consent.js" integrity="sha384-Li9vy3DqF8tnTXuiaAJuML3ky+er10rcgNR/VqsVpcw+ThHmYcwiB1pbOxEbzJr7" crossorigin="anonymous"></script>
   <link rel="stylesheet" href="https://example.com/cookie-consent.css" integrity="sha384-+/M6kredJcxdsqkczBUjMLvqyHb1K/JThDXWsBVxMEeZHEaMKEOEct339VItX1zB" crossorigin="anonymous">
   EOS

   gitlab_rails['content_security_policy'] = {
   # extend the following directives
     'directives' => {
       'script_src' => "'self' 'unsafe-eval' https://example.com https://www.google.com/recaptcha/ https://www.recaptcha.net/ https://www.gstatic.com/recaptcha/ https://apis.google.com",
       'style_src' => "'self' 'unsafe-inline' https://example.com",
     }
    }
   ```

1. Enregistrez le fichier, puis [reconfigurez](restart_gitlab.md#reconfigure-a-linux-package-installation) et [redémarrez](restart_gitlab.md#restart-a-linux-package-installation) GitLab.

{{< /tab >}}

{{< tab title="Self-compiled (Source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     gitlab:
       custom_html_header_tags: |
         <script src="https://example.com/cookie-consent.js" integrity="sha384-Li9vy3DqF8tnTXuiaAJuML3ky+er10rcgNR/VqsVpcw+ThHmYcwiB1pbOxEbzJr7"         crossorigin="anonymous"></script>
         <link rel="stylesheet" href="https://example.com/cookie-consent.css" integrity="sha384-+/M6kredJcxdsqkczBUjMLvqyHb1K/JThDXWsBVxMEeZHEaMKEOEct339VItX1zB"        crossorigin="anonymous">
       content_security_policy:
         directives:
           script_src: "'self' 'unsafe-eval' https://example.com http://localhost:* https://www.google.com/recaptcha/ https://www.recaptcha.net/ https://www.gstatic.com/recaptcha/ https://apis.google.com"
           style_src: "'self' 'unsafe-inline' https://example.com"
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

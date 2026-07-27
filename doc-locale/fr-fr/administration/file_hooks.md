---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Crochets de fichier
description: "Créez des hooks de fichier personnalisés pour intégrer votre instance GitLab Self-Managed à des services externes sans modifier le code source."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Utilisez des hooks de fichier personnalisés pour introduire des intégrations personnalisées sans modifier le code source de GitLab.

Un hook de fichier s'exécute à chaque événement. Vous pouvez filtrer les événements ou les projets dans le code d'un hook de fichier, et créer autant de hooks de fichier que nécessaire. Chaque hook de fichier est déclenché de manière asynchrone par GitLab en cas d'événement. Pour obtenir la liste des événements, consultez la documentation sur les [hooks système](system_hooks.md) et les [webhooks](../user/project/integrations/webhook_events.md).

> [!note]
> Les hooks de fichier doivent être configurés sur le système de fichiers du serveur GitLab. Seuls les administrateurs du serveur GitLab peuvent effectuer ces tâches. Explorez les [hooks système](system_hooks.md) ou les [webhooks](../user/project/integrations/webhooks.md) comme option si vous n'avez pas accès au système de fichiers.

Au lieu d'écrire et de maintenir votre propre hook de fichier, vous pouvez également apporter des modifications directement au code source de GitLab et contribuer en amont. De cette façon, nous pouvons garantir que la fonctionnalité est préservée d'une version à l'autre et couverte par des tests.

## Configurer un hook de fichier personnalisé {#set-up-a-custom-file-hook}

Les hooks de fichier doivent se trouver dans le répertoire `file_hooks`. Les sous-répertoires sont ignorés. Retrouvez des exemples dans le [répertoire `example` sous `file_hooks`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/file_hooks/examples).

Pour configurer un hook personnalisé :

1. Sur le serveur GitLab exécutant le composant Sidekiq, localisez le répertoire du plugin. Pour les installations compilées à partir des sources, le chemin est généralement `/home/git/gitlab/file_hooks/`. Pour les installations avec le package Linux, le chemin est généralement `/opt/gitlab/embedded/service/gitlab-rails/file_hooks`.

   Pour les [configurations avec plusieurs serveurs](reference_architectures/_index.md), votre fichier hook doit exister sur chaque serveur d'application GitLab (Rails) et Sidekiq.

1. Dans le répertoire `file_hooks`, créez un fichier avec le nom de votre choix, sans espaces ni caractères spéciaux.
1. Rendez le fichier hook exécutable et assurez-vous qu'il appartient à l'utilisateur Git.
1. Écrivez le code pour que le hook de fichier fonctionne comme prévu. Il peut être rédigé dans n'importe quel langage ; assurez-vous que le « shebang » en haut reflète correctement le type de langage. Par exemple, si le script est en Ruby, le shebang sera probablement `#!/usr/bin/env ruby`.
1. Les données transmises au hook de fichier sont fournies au format JSON sur `STDIN`. C'est exactement identique aux [hooks système](system_hooks.md).

En supposant que le code du hook de fichier est correctement implémenté, le hook se déclenche de manière appropriée. La liste des fichiers hooks est mise à jour pour chaque événement. Il n'est pas nécessaire de redémarrer GitLab pour appliquer un nouveau hook de fichier.

Si un hook de fichier s'exécute avec un code de sortie non nul ou échoue à s'exécuter, un message est consigné dans :

- `log/file_hook.log` pour les installations compilées à partir des sources.
- `gitlab-rails/file_hook.log` pour les installations avec le package Linux.

Ce fichier n'est créé que si le hook de fichier se termine avec un code non nul. Lorsque le hook de fichier s'exécute, une entrée est ajoutée au journal Sidekiq `gitlab/sidekiq/current` pour chaque `FileHookWorker` démarré. Cette entrée contient les détails de l'événement et du script qui a été exécuté.

## Exemple de hook de fichier {#file-hook-example}

Cet exemple répond uniquement à l'événement `project_create`, et l'instance GitLab informe les administrateurs qu'un nouveau projet a été créé.

```ruby
#!/opt/gitlab/embedded/bin/ruby
# By using the embedded ruby version we eliminate the possibility that our chosen language
# would be unavailable from
require 'json'
require 'mail'

# The incoming variables are in JSON format so we need to parse it first.
ARGS = JSON.parse($stdin.read)

# We only want to trigger this file hook on the event project_create
return unless ARGS['event_name'] == 'project_create'

# We will inform our admins of our gitlab instance that a new project is created
Mail.deliver do
  from    'info@gitlab_instance.com'
  to      'admin@gitlab_instance.com'
  subject "new project " + ARGS['name']
  body    ARGS['owner_name'] + 'created project ' + ARGS['name']
end
```

## Exemple de validation {#validation-example}

Écrire son propre hook de fichier peut s'avérer complexe, et il est plus facile de le vérifier sans modifier le système. Une tâche Rake est fournie pour vous permettre de l'utiliser dans un environnement de staging afin de tester votre hook de fichier avant de l'utiliser en production. La tâche Rake utilise des données d'exemple et exécute chaque hook de fichier. La sortie devrait être suffisante pour déterminer si le système détecte votre hook de fichier et s'il a été exécuté sans erreur.

```shell
# Omnibus installations
sudo gitlab-rake file_hooks:validate

# Installations from source
cd /home/git/gitlab
bundle exec rake file_hooks:validate RAILS_ENV=production
```

Exemple de sortie :

```plaintext
Validating file hooks from /file_hooks directory
* /home/git/gitlab/file_hooks/save_to_file.clj succeed (zero exit code)
* /home/git/gitlab/file_hooks/save_to_file.rb failure (non-zero exit code)
```

## Sujets connexes {#related-topics}

- [Hooks serveur](server_hooks.md)
- [Crochets système](system_hooks.md)

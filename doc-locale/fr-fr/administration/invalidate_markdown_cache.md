---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Cache Markdown
description: Invalider le cache Markdown.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour des raisons de performance, GitLab met en cache la version HTML du texte Markdown dans des champs tels que :

- Commentaires.
- Descriptions des tickets.
- Descriptions des merge requests.

Ces versions mises en cache peuvent devenir obsolètes, par exemple lorsque l'option de configuration `external_url` est modifiée. Les liens dans le texte mis en cache feraient toujours référence à l'ancienne URL.

## Invalider le cache {#invalidate-the-cache}

Vous pouvez invalider le cache Markdown en utilisant soit l'API, soit la console Rails.

### Utiliser l'API {#use-the-api}

Prérequis :

- Vous devez disposer d'un accès administrateur.

Pour invalider le cache existant à l'aide de l'API :

1. Augmentez le paramètre `local_markdown_version` dans les paramètres de l'application en envoyant une requête PUT :

   ```shell
   curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/application/settings?local_markdown_version=<increased_number>"
   ```

Pour plus d'informations sur ce point de terminaison API, consultez [update application settings](../api/settings.md#update-application-settings).

### Utiliser la console Rails {#use-the-rails-console}

Prérequis :

- Vous devez disposer d'un accès à la [console Rails](operations/rails_console.md).

#### Pour un groupe {#for-a-group}

Pour invalider le cache d'un groupe :

1. Démarrez une console Rails :

   ```shell
   sudo gitlab-rails console
   ```

1. Trouvez le groupe à mettre à jour :

   ```ruby
   group = Group.find(<group_id>)
   ```

1. Invalidez le cache pour tous les projets du groupe :

   ```ruby
   group.all_projects.each_slice(10) do |projects|
     projects.each do |project|
       # Invalidate issues
       project.issues.update_all(
         description_html: nil,
         title_html: nil
       )

       # Invalidate merge requests
       project.merge_requests.update_all(
         description_html: nil,
         title_html: nil
       )

       # Invalidate notes/comments
       project.notes.update_all(note_html: nil)
     end

     # Pause for one second after updating 10 projects
     sleep 1
   end
   ```

#### Pour un projet {#for-a-project}

Pour invalider le cache d'un seul projet :

1. Démarrez une console Rails :

   ```shell
   sudo gitlab-rails console
   ```

1. Trouvez le projet à mettre à jour :

   ```ruby
   project = Project.find(<project_id>)
   ```

1. Invalidez les tickets :

   ```ruby
   project.issues.update_all(
     description_html: nil,
     title_html: nil
   )
   ```

1. Invalidez les merge requests :

   ```ruby
   project.merge_requests.update_all(
     description_html: nil,
     title_html: nil
   )
   ```

1. Invalidez les notes et les commentaires :

   ```ruby
   project.notes.update_all(note_html: nil)
   ```

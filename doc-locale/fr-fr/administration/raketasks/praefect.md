---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tâches Rake Praefect
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Des tâches Rake sont disponibles pour les projets qui ont été créés sur le stockage Praefect. Consultez la [documentation Praefect](../gitaly/praefect/_index.md) pour obtenir des informations sur la configuration de Praefect.

## Sommes de contrôle des réplicas {#replica-checksums}

`gitlab:praefect:replicas` affiche les sommes de contrôle du dépôt sur :

- Le nœud Gitaly principal.
- Les nœuds Gitaly internes secondaires.

Vous pouvez vérifier les réplicas pour un projet spécifique ou pour tous les projets.

Exécutez cette tâche Rake sur le nœud sur lequel GitLab est installé et non sur le nœud sur lequel Praefect est installé.

### Vérifier les réplicas pour un projet spécifique {#check-replicas-for-a-specific-project}

- Installations avec le paquet Linux :

  ```shell
  sudo gitlab-rake "gitlab:praefect:replicas[project_id]"
  ```

- Installations auto-compilées :

  ```shell
  sudo -u git -H bundle exec rake "gitlab:praefect:replicas[project_id]" RAILS_ENV=production
  ```

### Vérifier les réplicas pour tous les projets {#check-replicas-for-all-projects}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219120) dans GitLab 18.10.

{{< /history >}}

La vérification des réplicas pour tous les projets peut être gourmande en ressources sur les grandes instances GitLab comptant des milliers de projets, car chaque projet nécessite des appels externes aux services Gitaly. Envisagez d'exécuter cette tâche pendant les heures creuses ou selon un calendrier qui n'affecte pas les performances en production.

- Installations avec le paquet Linux :

  ```shell
  sudo gitlab-rake gitlab:praefect:replicas
  ```

- Installations auto-compilées :

  ```shell
  sudo -u git -H bundle exec rake gitlab:praefect:replicas RAILS_ENV=production
  ```

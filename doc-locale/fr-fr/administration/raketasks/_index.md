---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tâches Rake
description: "Tâches Rake d'administration et d'exploitation."
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab fournit des tâches [Rake](https://ruby.github.io/rake/) pour vous aider dans les processus courants d'administration et d'exploitation.

Toutes les tâches Rake doivent être exécutées sur un nœud Rails, sauf indication contraire dans la documentation de la tâche.

Vous pouvez effectuer des tâches GitLab Rake en utilisant :

- `gitlab-rake <raketask>` pour les installations de [paquet Linux](https://docs.gitlab.com/omnibus/) et de [chart Helm GitLab](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet/#gitlab-specific-kubernetes-information).
- `bundle exec rake <raketask>` pour les installations [auto-compilées](../../install/self_compiled/_index.md).

## Tâches Rake disponibles {#available-rake-tasks}

Les tâches Rake suivantes sont disponibles pour GitLab :

| Tâches                                                                                                 | Description |
|:------------------------------------------------------------------------------------------------------|:------------|
| [Tâches d'expiration des jetons d'accès](tokens/_index.md)                                                     | Étendre ou supprimer en masse les dates d'expiration des jetons d'accès. |
| [Agents externes du catalogue d'IA](ai_catalog.md)                                                           | Amorcer les agents externes du catalogue d'IA. |
| [Sauvegarde et restauration](../backup_restore/_index.md)                                                    | Sauvegarder, restaurer et migrer des instances GitLab entre des serveurs. |
| [Nettoyage](cleanup.md)                                                                                | Nettoyer les éléments inutiles des instances GitLab. |
| Développement                                                                                           | Tâches pour les contributeurs GitLab. Pour plus d'informations, consultez la documentation de développement. |
| [Elasticsearch](../../integration/advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) | Maintenir Elasticsearch dans une instance GitLab. |
| [Maintenance générale](maintenance.md)                                                                 | Tâches de maintenance générale et d'auto-vérification. |
| [Import GitHub](../../user/project/import/github.md)                                                  | Récupérer et importer des dépôts depuis GitHub. |
| [Importer des exports de projets volumineux](project_import_export.md#import-large-projects)                        | Importer des [exports de projets](../../user/project/settings/import_export.md) GitLab volumineux. |
| [E-mail entrant](incoming_email.md)                                                                   | Tâches liées aux e-mails entrants. |
| [Vérifications d'intégrité](check.md)                                                                          | Vérifier l'intégrité des dépôts, des fichiers, de LDAP, et plus encore. |
| [Références keep-around](keep_around.md)                                                              | Trouver toutes les références keep-around orphelines pour un projet. |
| [Maintenance LDAP](ldap.md)                                                                           | Tâches liées à [LDAP](../auth/ldap/_index.md). |
| [Mot de passe](password.md)                                                                               | Tâches de gestion des mots de passe. |
| [Tâches Rake Praefect](praefect.md)                                                                    | Tâches liées à [Praefect](../gitaly/praefect/_index.md). |
| [Import/export de projets](project_import_export.md)                                                     | Se préparer pour les [exports et imports de projets](../../user/project/settings/import_export.md). |
| [Migration des jobs Sidekiq](../sidekiq/sidekiq_job_migration.md)                                          | Migrer les jobs Sidekiq planifiés pour des dates futures vers une nouvelle file d'attente. |
| [E-mail Service Desk](service_desk_email.md)                                                           | Tâches liées aux e-mails Service Desk. |
| [Maintenance SMTP](smtp.md)                                                                           | Tâches liées à SMTP. |
| [Import de la liste de licences SPDX](spdx.md)                                                                   | Importer une copie locale de la [liste de licences SPDX](https://spdx.org/licenses/) pour la correspondance avec les [politiques d'approbation de licences](../../user/compliance/license_approval_policies.md). |
| [Réinitialiser les mots de passe utilisateur](../../security/reset_user_password.md#use-a-rake-task)                         | Réinitialiser les mots de passe utilisateur avec Rake. |
| [Recherche sémantique de code](../../user/gitlab_duo/semantic_code_search.md#check-semantic-code-search-status) | Vérifier le statut de la recherche sémantique de code. |
| [Migration des téléversements](uploads/migrate.md)                                                                 | Migrer les téléversements entre le stockage local et le stockage d'objets. |
| [Nettoyage des téléversements](uploads/sanitize.md)                                                               | Supprimer les données EXIF des images téléversées dans des versions antérieures de GitLab. |
| Données de service                                                                                          | Générer et dépanner Service Ping. Pour plus d'informations, consultez la documentation de développement Service Ping. |
| [Gestion des utilisateurs](user_management.md)                                                                 | Effectuer des tâches de gestion des utilisateurs. |
| [Administration des webhooks](web_hooks.md)                                                                | Maintenir les webhooks de projet. |
| [Signatures X.509](x509_signatures.md)                                                                | Mettre à jour les signatures de commit X.509, ce qui peut être utile si le magasin de certificats a changé. |

Pour lister toutes les tâches Rake disponibles :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake -vT
```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

```shell
gitlab-rake -vT
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake -vT RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

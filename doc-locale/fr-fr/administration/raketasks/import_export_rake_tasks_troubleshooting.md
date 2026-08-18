---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépannage de l'import et de l'export de projets"
---

Si vous rencontrez des problèmes avec l'import ou l'export, utilisez une tâche Rake pour activer le mode de débogage :

```shell
# Import
IMPORT_DEBUG=true gitlab-rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file_to_import.tar.gz]"

# Export
EXPORT_DEBUG=true gitlab-rake "gitlab:import_export:export[root, group/subgroup, projectnametoexport, /tmp/export_file.tar.gz]"
```

Ensuite, consultez les détails suivants sur les messages d'erreur spécifiques.

## `Exception: undefined method 'name' for nil:NilClass` {#exception-undefined-method-name-for-nilnilclass}

L'`username` n'est pas valide.

## `Exception: undefined method 'full_path' for nil:NilClass` {#exception-undefined-method-full_path-for-nilnilclass}

Le `namespace_path` n'existe pas. Par exemple, l'un des groupes ou sous-groupes est mal orthographié ou manquant, ou vous avez spécifié le nom du projet dans le chemin.

La tâche crée uniquement le projet. Si vous souhaitez l'importer dans un nouveau groupe ou sous-groupe, créez-le d'abord.

## `Exception: No such file or directory @ rb_sysopen - (filename)` {#exception-no-such-file-or-directory--rb_sysopen---filename}

Le fichier d'exportation de projet spécifié dans `archive_path` est manquant.

## `Exception: Permission denied @ rb_sysopen - (filename)` {#exception-permission-denied--rb_sysopen---filename}

L'utilisateur `git` ne peut pas accéder au fichier d'exportation de projet spécifié.

Pour résoudre le problème :

1. Définissez le propriétaire du fichier sur `git:git`.
1. Modifiez les permissions du fichier en `0400`.
1. Déplacez le fichier vers un dossier public (par exemple `/tmp/`).

## `Name can contain only letters, digits, emoji ...` {#name-can-contain-only-letters-digits-emoji-}

```plaintext
Name can contain only letters, digits, emoji, '_', '.', '+', dashes, or spaces. It must start with a letter,
digit, emoji, or '_', and Path can contain only letters, digits, '_', '-', or '.'. It cannot start
with '-', end in '.git', or end in '.atom'.
```

Le nom du projet spécifié dans `project_path` n'est pas valide pour l'une des raisons indiquées.

Ne mettez que le nom du projet dans `project_path`. Par exemple, si vous fournissez un chemin de sous-groupes, cela échoue avec cette erreur car `/` n'est pas un caractère valide dans un nom de projet.

## `Name has already been taken and Path has already been taken` {#name-has-already-been-taken-and-path-has-already-been-taken}

Un projet portant ce nom existe déjà.

## `Exception: Error importing repository into (namespace) - No space left on device` {#exception-error-importing-repository-into-namespace---no-space-left-on-device}

Le disque ne dispose pas d'un espace suffisant pour terminer l'importation.

Lors de l'importation, l'archive tar est mise en cache dans votre répertoire `shared_path` configuré. Vérifiez que le disque dispose de suffisamment d'espace libre pour accueillir à la fois l'archive tar mise en cache et les fichiers de projet décompressés sur le disque.

## L'importation réussit avec le message `Total number of not imported relations: XX` {#import-succeeds-with-total-number-of-not-imported-relations-xx-message}

Si vous recevez un message `Total number of not imported relations: XX` et que les tickets ne sont pas créés lors de l'importation, consultez [`exceptions_json.log`](../logs/_index.md#exceptions_jsonlog). Vous pourriez voir une erreur du type `N is out of range for ActiveModel::Type::Integer with limit 4 bytes`, où `N` est l'entier dépassant la limite d'entier de 4 octets. Si c'est le cas, vous rencontrez probablement le problème lié au rééquilibrage du champ `relative_position` des tickets.

```ruby
# Check the current maximum value of relative_position
Issue.where(project_id: Project.find(ID).root_namespace.all_projects).maximum(:relative_position)

# Run the rebalancing process and check if the maximum value of relative_position has changed
Issues::RelativePositionRebalancingService.new(Project.find(ID).root_namespace.all_projects).execute
Issue.where(project_id: Project.find(ID).root_namespace.all_projects).maximum(:relative_position)
```

Répétez la tentative d'importation et vérifiez si les tickets sont importés avec succès.

## Erreur d'appels Gitaly lors de l'importation {#gitaly-calls-error-when-importing}

Si vous tentez d'importer un projet volumineux dans un environnement de développement, Gitaly peut générer une erreur concernant un trop grand nombre d'appels ou d'invocations. Par exemple :

```plaintext
Error importing repository into qa-perf-testing/gitlabhq - GitalyClient#call called 31 times from single request. Potential n+1?
```

Cette erreur est due à une limite d'appels n+1 pour les configurations de développement. Pour résoudre cette erreur, définissez `GITALY_DISABLE_REQUEST_LIMITS=1` comme variable d'environnement. Redémarrez ensuite votre environnement de développement et importez à nouveau.

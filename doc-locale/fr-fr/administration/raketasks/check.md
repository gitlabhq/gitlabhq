---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Tâche Rake de vérification de l'intégrité"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab fournit des tâches Rake pour vérifier l'intégrité de divers composants. Voir aussi la [tâche Rake de vérification de la configuration GitLab](maintenance.md#check-gitlab-configuration).

## Intégrité du dépôt {#repository-integrity}

Même si Git est très résilient et tente de prévenir les problèmes d'intégrité des données, il arrive que des problèmes surviennent. Les tâches Rake suivantes visent à aider les administrateurs GitLab à diagnostiquer les dépôts problématiques afin qu'ils puissent être corrigés.

Ces tâches Rake utilisent trois méthodes différentes pour déterminer l'intégrité des dépôts Git.

1. Vérification du système de fichiers du dépôt Git ([`git fsck`](https://git-scm.com/docs/git-fsck)). Cette étape vérifie la connectivité et la validité des objets dans le dépôt.
1. Vérifier la présence de `config.lock` dans le répertoire du dépôt.
1. Vérifier la présence de fichiers de verrouillage de branche/références dans `refs/heads`.

L'existence de `config.lock` ou de verrous de référence seuls n'indique pas nécessairement un problème. Les fichiers de verrouillage sont créés et supprimés de manière routinière lorsque Git et GitLab effectuent des opérations sur le dépôt. Ils servent à prévenir les problèmes d'intégrité des données. Cependant, si une opération Git est interrompue, ces verrous peuvent ne pas être nettoyés correctement.

Les symptômes suivants peuvent indiquer un problème d'intégrité du dépôt. Si des utilisateurs rencontrent ces symptômes, vous pouvez utiliser les tâches Rake décrites ci-dessous pour déterminer exactement quels dépôts causent le problème.

- Réception d'une erreur lors d'une tentative d'envoi de code - `remote: error: cannot lock ref`
- Une erreur 500 lors de la consultation du tableau de bord GitLab ou lors de l'accès à un projet spécifique.

### Vérifier tous les dépôts de code de projet {#check-all-project-code-repositories}

Cette tâche parcourt les dépôts de code de projet et exécute la vérification d'intégrité décrite précédemment. Si un projet utilise un dépôt de pool, celui-ci est également vérifié. Les autres types de dépôts Git [ne sont pas vérifiés](https://gitlab.com/gitlab-org/gitaly/-/issues/3643).

Pour vérifier les dépôts de code de projet :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:git:fsck
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
sudo -u git -H bundle exec rake gitlab:git:fsck RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

### Vérifier des dépôts de code de projet spécifiques {#check-specific-project-code-repositories}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197990) dans GitLab 18.3.

{{< /history >}}

Limitez la vérification aux dépôts des projets avec des ID de projet spécifiques en définissant la variable d'environnement `PROJECT_IDS` sur une liste d'ID de projet séparés par des virgules.

Par exemple, pour vérifier les dépôts des projets avec les ID de projet `1` et `3` :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo PROJECT_IDS="1,3" gitlab-rake gitlab:git:fsck
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
sudo -u git -H PROJECT_IDS="1,3" bundle exec rake gitlab:git:fsck RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## Somme de contrôle des références du dépôt {#checksum-of-repository-refs}

Un dépôt Git peut être comparé à un autre en calculant la somme de contrôle de toutes les références de chaque dépôt. Si les deux dépôts ont les mêmes références, et si les deux dépôts passent une vérification d'intégrité, nous pouvons être confiants que les deux dépôts sont identiques.

Par exemple, cela peut être utilisé pour comparer une sauvegarde d'un dépôt avec le dépôt source.

### Vérifier tous les dépôts GitLab {#check-all-gitlab-repositories}

Cette tâche parcourt tous les dépôts sur le serveur GitLab et affiche les sommes de contrôle au format `<PROJECT ID>,<CHECKSUM>`.

- Si un dépôt n'existe pas, l'ID du projet est une somme de contrôle vide.
- Si un dépôt existe mais est vide, la somme de contrôle en sortie est `0000000000000000000000000000000000000000`.
- Les projets qui n'existent pas sont ignorés.

Pour vérifier tous les dépôts GitLab :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:git:checksum_projects
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
sudo -u git -H bundle exec rake gitlab:git:checksum_projects RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

Par exemple, si :

- Le projet avec l'ID#2 n'existe pas, il est ignoré.
- Le projet avec l'ID#4 n'a pas de dépôt, sa somme de contrôle est vide.
- Le projet avec l'ID#5 a un dépôt vide, sa somme de contrôle est `0000000000000000000000000000000000000000`.

La sortie ressemblerait alors à quelque chose comme :

```plaintext
1,cfa3f06ba235c13df0bb28e079bcea62c5848af2
3,3f3fb58a8106230e3a6c6b48adc2712fb3b6ef87
4,
5,0000000000000000000000000000000000000000
6,6c6b48adc2712fb3b6ef87cfa3f06ba235c13df0
```

### Vérifier des dépôts GitLab spécifiques {#check-specific-gitlab-repositories}

Optionnellement, des ID de projet spécifiques peuvent être soumis à une somme de contrôle en définissant une variable d'environnement `CHECKSUM_PROJECT_IDS` avec une liste d'entiers séparés par des virgules, par exemple :

```shell
sudo CHECKSUM_PROJECT_IDS="1,3" gitlab-rake gitlab:git:checksum_projects
```

## Intégrité des fichiers téléversés {#uploaded-files-integrity}

Différents types de fichiers peuvent être téléversés dans une installation GitLab par les utilisateurs. Ces vérifications d'intégrité peuvent détecter les fichiers manquants. De plus, pour les fichiers stockés localement, des sommes de contrôle sont générées et stockées dans la base de données lors du téléversement, et ces vérifications les comparent aux fichiers actuels.

Les vérifications d'intégrité sont prises en charge pour les types de fichiers suivants :

- Artefacts CI
- Objets LFS
- Fichiers sécurisés au niveau du projet (introduits dans GitLab 16.1.0)
- Téléversements d'utilisateurs

Pour vérifier l'intégrité des fichiers téléversés :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:artifacts:check
sudo gitlab-rake gitlab:ci_secure_files:check
sudo gitlab-rake gitlab:lfs:check
sudo gitlab-rake gitlab:uploads:check
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
sudo -u git -H bundle exec rake gitlab:artifacts:check RAILS_ENV=production
sudo -u git -H bundle exec rake gitlab:ci_secure_files:check RAILS_ENV=production
sudo -u git -H bundle exec rake gitlab:lfs:check RAILS_ENV=production
sudo -u git -H bundle exec rake gitlab:uploads:check RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

Ces tâches acceptent également certaines variables d'environnement que vous pouvez utiliser pour remplacer certaines valeurs :

| Variable  | Type    | Description |
|-----------|---------|-------------|
| `BATCH`   | entier | Spécifie la taille du lot. La valeur par défaut est 200. |
| `ID_FROM` | entier | Spécifie l'ID à partir duquel commencer, valeur incluse. |
| `ID_TO`   | entier | Spécifie la valeur d'ID à laquelle terminer, valeur incluse. |
| `VERBOSE` | booléen | Entraîne l'affichage individuel des échecs, plutôt que leur résumé. |

```shell
sudo gitlab-rake gitlab:artifacts:check BATCH=100 ID_FROM=50 ID_TO=250
sudo gitlab-rake gitlab:ci_secure_files:check BATCH=100 ID_FROM=50 ID_TO=250
sudo gitlab-rake gitlab:lfs:check BATCH=100 ID_FROM=50 ID_TO=250
sudo gitlab-rake gitlab:uploads:check BATCH=100 ID_FROM=50 ID_TO=250
```

Exemple de sortie :

```shell
$ sudo gitlab-rake gitlab:uploads:check
Checking integrity of Uploads
- 1..1350: Failures: 0
- 1351..2743: Failures: 0
- 2745..4349: Failures: 2
- 4357..5762: Failures: 1
- 5764..7140: Failures: 2
- 7142..8651: Failures: 0
- 8653..10134: Failures: 0
- 10135..11773: Failures: 0
- 11777..13315: Failures: 0
Done!
```

Exemple de sortie détaillée :

```shell
$ sudo gitlab-rake gitlab:uploads:check VERBOSE=1
Checking integrity of Uploads
- 1..1350: Failures: 0
- 1351..2743: Failures: 0
- 2745..4349: Failures: 2
  - Upload: 3573: #<Errno::ENOENT: No such file or directory @ rb_sysopen - /opt/gitlab/embedded/service/gitlab-rails/public/uploads/user-foo/project-bar/7a77cc52947bfe188adeff42f890bb77/image.png>
  - Upload: 3580: #<Errno::ENOENT: No such file or directory @ rb_sysopen - /opt/gitlab/embedded/service/gitlab-rails/public/uploads/user-foo/project-bar/2840ba1ba3b2ecfa3478a7b161375f8a/pug.png>
- 4357..5762: Failures: 1
  - Upload: 4636: #<Google::Apis::ServerError: Server error>
- 5764..7140: Failures: 2
  - Upload: 5812: #<NoMethodError: undefined method `hashed_storage?' for nil:NilClass>
  - Upload: 5837: #<NoMethodError: undefined method `hashed_storage?' for nil:NilClass>
- 7142..8651: Failures: 0
- 8653..10134: Failures: 0
- 10135..11773: Failures: 0
- 11777..13315: Failures: 0
Done!
```

## Vérification LDAP {#ldap-check}

La tâche Rake de vérification LDAP teste les identifiants DN de liaison et de mot de passe (si configurés) et liste un échantillon d'utilisateurs LDAP. Cette tâche est également exécutée dans le cadre de la tâche `gitlab:check`, mais peut être exécutée indépendamment. Voir [LDAP Rake Tasks - LDAP Check](ldap.md#check) pour plus de détails.

## Vérifier que les valeurs de la base de données peuvent être déchiffrées à l'aide des secrets actuels {#verify-database-values-can-be-decrypted-using-the-current-secrets}

Cette tâche parcourt toutes les valeurs chiffrées possibles dans la base de données, en vérifiant qu'elles sont déchiffrables à l'aide du fichier de secrets actuel (`gitlab-secrets.json`).

La résolution automatique n'est pas encore implémentée. Si vous avez des valeurs qui ne peuvent pas être déchiffrées, vous pouvez suivre les étapes pour les réinitialiser, consultez notre documentation sur la marche à suivre [lorsque le fichier de secrets est perdu](../backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost).

Cela peut prendre très longtemps, en fonction de la taille de votre base de données, car elle vérifie toutes les lignes de toutes les tables.

Pour vérifier que les valeurs de la base de données peuvent être déchiffrées à l'aide des secrets actuels :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:doctor:secrets
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake gitlab:doctor:secrets RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

**Exemple de données de sortie**

```plaintext
I, [2020-06-11T17:17:54.951815 #27148]  INFO -- : Checking encrypted values in the database
I, [2020-06-11T17:18:12.677708 #27148]  INFO -- : - ApplicationSetting failures: 0
I, [2020-06-11T17:18:12.823692 #27148]  INFO -- : - User failures: 0
[...] other models possibly containing encrypted data
I, [2020-06-11T17:18:14.938335 #27148]  INFO -- : - Group failures: 1
I, [2020-06-11T17:18:15.559162 #27148]  INFO -- : - Operations::FeatureFlagsClient failures: 0
I, [2020-06-11T17:18:15.575533 #27148]  INFO -- : - ScimOauthAccessToken failures: 0
I, [2020-06-11T17:18:15.575678 #27148]  INFO -- : Total: 1 row(s) affected
I, [2020-06-11T17:18:15.575711 #27148]  INFO -- : Done!
```

### Mode détaillé {#verbose-mode}

Pour obtenir des informations plus détaillées sur les lignes et colonnes qui ne peuvent pas être déchiffrées, vous pouvez passer une variable d'environnement `VERBOSE`.

Pour vérifier que les valeurs de la base de données peuvent être déchiffrées à l'aide des secrets actuels avec des informations détaillées :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:doctor:secrets VERBOSE=1
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake gitlab:doctor:secrets RAILS_ENV=production VERBOSE=1
```

{{< /tab >}}

{{< /tabs >}}

**Exemple de données de sorties détaillées**

<!-- vale gitlab_base.SentenceSpacing = NO -->

```plaintext
I, [2020-06-11T17:17:54.951815 #27148]  INFO -- : Checking encrypted values in the database
I, [2020-06-11T17:18:12.677708 #27148]  INFO -- : - ApplicationSetting failures: 0
I, [2020-06-11T17:18:12.823692 #27148]  INFO -- : - User failures: 0
[...] other models possibly containing encrypted data
D, [2020-06-11T17:19:53.224344 #27351] DEBUG -- : > Something went wrong for Group[10].runners_token: Validation failed: Route can't be blank
I, [2020-06-11T17:19:53.225178 #27351]  INFO -- : - Group failures: 1
D, [2020-06-11T17:19:53.225267 #27351] DEBUG -- :   - Group[10]: runners_token
I, [2020-06-11T17:18:15.559162 #27148]  INFO -- : - Operations::FeatureFlagsClient failures: 0
I, [2020-06-11T17:18:15.575533 #27148]  INFO -- : - ScimOauthAccessToken failures: 0
I, [2020-06-11T17:18:15.575678 #27148]  INFO -- : Total: 1 row(s) affected
I, [2020-06-11T17:18:15.575711 #27148]  INFO -- : Done!
```

<!-- vale gitlab_base.SentenceSpacing = YES -->

## Réinitialiser les jetons chiffrés lorsqu'ils ne peuvent pas être récupérés {#reset-encrypted-tokens-when-they-cant-be-recovered}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131893) dans GitLab 16.6.

{{< /history >}}

> [!warning]
> Cette opération est dangereuse et peut entraîner une perte de données. Procédez avec une extrême prudence. Vous devez avoir des connaissances sur les composants internes de GitLab avant d'effectuer cette opération.

Dans certains cas, les jetons chiffrés ne peuvent plus être récupérés et causent des problèmes. Le plus souvent, les jetons d'enregistrement de runner pour les groupes et les projets peuvent être défectueux sur les très grandes instances.

Pour réinitialiser les jetons défectueux :

1. Identifiez les modèles de base de données qui ont des jetons chiffrés défectueux. Par exemple, cela peut être `Group` et `Project`.
1. Identifiez les jetons défectueux. Par exemple `runners_token`.
1. Pour réinitialiser les jetons défectueux, exécutez `gitlab:doctor:reset_encrypted_tokens` avec `VERBOSE=true MODEL_NAMES=Model1,Model2 TOKEN_NAMES=broken_token1,broken_token2`. Par exemple :

   {{< tabs >}}

   {{< tab title="Paquet Linux (Omnibus)" >}}

   ```shell
   VERBOSE=true MODEL_NAMES=Project,Group TOKEN_NAMES=runners_token gitlab-rake gitlab:doctor:reset_encrypted_tokens
   ```

   {{< /tab >}}

   {{< tab title="Auto-compilée (source)" >}}

   ```shell
   bundle exec rake gitlab:doctor:reset_encrypted_tokens RAILS_ENV=production VERBOSE=true MODEL_NAMES=Project,Group TOKEN_NAMES=runners_token
   ```

   {{< /tab >}}

   {{< /tabs >}}

   Vous verrez chaque action que cette tâche tenterait d'effectuer :

   ```plain
   I, [2023-09-26T16:20:23.230942 #88920]  INFO -- : Resetting runners_token on Project, Group if they can not be read
   I, [2023-09-26T16:20:23.230975 #88920]  INFO -- : Executing in DRY RUN mode, no records will actually be updated
   D, [2023-09-26T16:20:30.151585 #88920] DEBUG -- : > Fix Project[1].runners_token
   I, [2023-09-26T16:20:30.151617 #88920]  INFO -- : Checked 1/9 Projects
   D, [2023-09-26T16:20:30.151873 #88920] DEBUG -- : > Fix Project[3].runners_token
   D, [2023-09-26T16:20:30.152975 #88920] DEBUG -- : > Fix Project[10].runners_token
   I, [2023-09-26T16:20:30.152992 #88920]  INFO -- : Checked 11/29 Projects
   I, [2023-09-26T16:20:30.153230 #88920]  INFO -- : Checked 21/29 Projects
   I, [2023-09-26T16:20:30.153882 #88920]  INFO -- : Checked 29 Projects
   D, [2023-09-26T16:20:30.195929 #88920] DEBUG -- : > Fix Group[22].runners_token
   I, [2023-09-26T16:20:30.196125 #88920]  INFO -- : Checked 1/19 Groups
   D, [2023-09-26T16:20:30.196192 #88920] DEBUG -- : > Fix Group[25].runners_token
   D, [2023-09-26T16:20:30.197557 #88920] DEBUG -- : > Fix Group[82].runners_token
   I, [2023-09-26T16:20:30.197581 #88920]  INFO -- : Checked 11/19 Groups
   I, [2023-09-26T16:20:30.198455 #88920]  INFO -- : Checked 19 Groups
   I, [2023-09-26T16:20:30.198462 #88920]  INFO -- : Done!
   ```

1. Si vous êtes certain que cette opération réinitialise les bons jetons, désactivez le mode simulation et exécutez à nouveau l'opération :

   {{< tabs >}}

   {{< tab title="Paquet Linux (Omnibus)" >}}

   ```shell
   DRY_RUN=false VERBOSE=true MODEL_NAMES=Project,Group TOKEN_NAMES=runners_token gitlab-rake gitlab:doctor:reset_encrypted_tokens
   ```

   {{< /tab >}}

   {{< tab title="Auto-compilée (source)" >}}

   ```shell
   bundle exec rake gitlab:doctor:reset_encrypted_tokens RAILS_ENV=production DRY_RUN=false VERBOSE=true MODEL_NAMES=Project,Group TOKEN_NAMES=runners_token
   ```

   {{< /tab >}}

   {{< /tabs >}}

La tâche `gitlab:doctor:reset_encrypted_tokens` présente les limitations suivantes :

- Les attributs non-jeton, par exemple `ApplicationSetting:ci_jwt_signing_key`, ne sont pas réinitialisés.
- La présence de plus d'un attribut non déchiffrable dans un seul enregistrement de modèle entraîne l'échec de la tâche avec une erreur `TypeError: no implicit conversion of nil into String ... block in aes256_gcm_decrypt`.

## Dépannage {#troubleshooting}

Les éléments suivants sont des solutions aux problèmes que vous pourriez découvrir en utilisant les tâches Rake documentées précédemment.

### Objets suspendus {#dangling-objects}

La tâche `gitlab-rake gitlab:git:fsck` peut trouver des objets suspendus tels que :

```plaintext
dangling blob a12...
dangling commit b34...
dangling tag c56...
dangling tree d78...
```

Pour les supprimer, essayez d'[exécuter la maintenance](../housekeeping.md).

Si le problème persiste, essayez de déclencher la collecte des déchets via la [console Rails](../operations/rails_console.md#starting-a-rails-console-session) :

```ruby
p = Project.find_by_path("project-name")
Repositories::HousekeepingService.new(p, :gc).execute
```

Si les objets suspendus ont moins de 2 semaines (période de grâce par défaut) et que vous ne voulez pas attendre qu'ils expirent automatiquement, exécutez :

```ruby
Repositories::HousekeepingService.new(p, :prune).execute
```

### Supprimer les références aux téléversements distants manquants {#delete-references-to-missing-remote-uploads}

`gitlab-rake gitlab:uploads:check VERBOSE=1` détecte les objets distants qui n'existent pas car ils ont été supprimés en externe, mais leurs références existent toujours dans la base de données GitLab.

Exemple de sortie avec message d'erreur :

```shell
$ sudo gitlab-rake gitlab:uploads:check VERBOSE=1
Checking integrity of Uploads
- 100..434: Failures: 2
- Upload: 100: Remote object does not exist
- Upload: 101: Remote object does not exist
Done!
```

Pour supprimer ces références aux téléversements distants qui ont été supprimés en externe, ouvrez la [console Rails GitLab](../operations/rails_console.md#starting-a-rails-console-session) et exécutez :

```ruby
uploads_deleted=0
Upload.find_each do |upload|
  next if upload.retrieve_uploader.file.exists?
  uploads_deleted=uploads_deleted + 1
  p upload                            ### allow verification before destroy
  # p upload.destroy!                 ### uncomment to actually destroy
end
p "#{uploads_deleted} remote objects were destroyed."
```

### Supprimer les références aux artefacts manquants {#delete-references-to-missing-artifacts}

`gitlab-rake gitlab:artifacts:check VERBOSE=1` détecte lorsque des artefacts (ou des fichiers `job.log`) :

- Sont supprimés en dehors de GitLab.
- Ont des références toujours présentes dans la base de données GitLab.

Lorsque ce scénario est détecté, la tâche Rake affiche un message d'erreur. Par exemple :

```shell
Checking integrity of Job artifacts
- 1..15: Failures: 2
  - Job artifact: 9: #<Errno::ENOENT: No such file or directory @ rb_sysopen - /var/opt/gitlab/gitlab-rails/shared/artifacts/4b/22/4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a/2022_06_30/8/9/job.log>
  - Job artifact: 15: Remote object does not exist
Done!

```

Pour supprimer ces références aux artefacts locaux et/ou distants manquants (fichiers `job.log`) :

1. Ouvrez la [console Rails GitLab](../operations/rails_console.md#starting-a-rails-console-session).
1. Exécutez le code Ruby suivant :

   ```ruby
   artifacts_deleted = 0
   ::Ci::JobArtifact.find_each do |artifact|                      ### Iterate artifacts
   #  next if artifact.file.filename != "job.log"                 ### Uncomment if only `job.log` files' references are to be processed
     next if artifact.file.file.exists?                           ### Skip if the file reference is valid
     artifacts_deleted += 1
     puts "#{artifact.id}  #{artifact.file.path} is missing."     ### Allow verification before destroy
   #  artifact.destroy!                                           ### Uncomment to actually destroy
   end
   puts "Count of identified/destroyed invalid references: #{artifacts_deleted}"
   ```

### Supprimer les références aux objets LFS manquants {#delete-references-to-missing-lfs-objects}

Si `gitlab-rake gitlab:lfs:check VERBOSE=1` détecte des objets LFS qui existent dans la base de données mais pas sur le disque, [suivez la procédure dans la documentation LFS](../lfs/_index.md#missing-lfs-objects) pour supprimer les entrées de la base de données.

### Mettre à jour les références d'objets de stockage suspendus {#update-dangling-object-storage-references}

Si vous avez [migré du stockage d'objets vers le stockage local](../cicd/job_artifacts.md#migrating-from-object-storage-to-local-storage) et que des fichiers étaient manquants, des références de base de données suspendues subsistent.

Cela est visible dans les journaux de migration avec des erreurs comme les suivantes :

```shell
W, [2022-11-28T13:14:09.283833 #10025]  WARN -- : Failed to transfer Ci::JobArtifact ID 11 with error: undefined method `body' for nil:NilClass
W, [2022-11-28T13:14:09.296911 #10025]  WARN -- : Failed to transfer Ci::JobArtifact ID 12 with error: undefined method `body' for nil:NilClass
```

Tenter de [supprimer les références aux artefacts manquants](check.md#delete-references-to-missing-artifacts) après avoir désactivé le stockage d'objets entraîne l'erreur suivante :

```plaintext
RuntimeError (Object Storage is not enabled for JobArtifactUploader)
```

Pour mettre à jour ces références afin qu'elles pointent vers le stockage local :

1. Ouvrez la [console Rails GitLab](../operations/rails_console.md#starting-a-rails-console-session).
1. Exécutez le code Ruby suivant :

   ```ruby
   artifacts_updated = 0
   ::Ci::JobArtifact.find_each do |artifact|                    ### Iterate artifacts
     next if artifact.file_store != 2                           ### Skip if file_store already points to local storage
     artifacts_updated += 1
     # artifact.update(file_store: 1)                           ### Uncomment to actually update
   end
   puts "Updated file_store count: #{artifacts_updated}"
   ```

Le script pour [supprimer les références aux artefacts manquants](check.md#delete-references-to-missing-artifacts) fonctionne maintenant correctement et nettoie la base de données.

### Supprimer les références aux fichiers sécurisés manquants {#delete-references-to-missing-secure-files}

`VERBOSE=1 gitlab-rake gitlab:ci_secure_files:check` détecte lorsque des fichiers sécurisés :

- Sont supprimés en dehors de GitLab.
- Ont des références toujours présentes dans la base de données GitLab.

Lorsque ce scénario est détecté, la tâche Rake affiche un message d'erreur. Par exemple :

```shell
Checking integrity of CI Secure Files
- 1..15: Failures: 2
  - Job SecureFile: 9: #<Errno::ENOENT: No such file or directory @ rb_sysopen - /var/opt/gitlab/gitlab-rails/shared/ci_secure_files/4b/22/4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a/2022_06_30/8/9/distribution.cer>
  - Job SecureFile: 15: Remote object does not exist
Done!

```

Pour supprimer ces références aux fichiers sécurisés locaux ou distants manquants :

1. Ouvrez la [console Rails GitLab](../operations/rails_console.md#starting-a-rails-console-session).
1. Exécutez le code Ruby suivant :

   ```ruby
   secure_files_deleted = 0
   ::Ci::SecureFile.find_each do |secure_file|                    ### Iterate secure files
     next if secure_file.file.file.exists?                        ### Skip if the file reference is valid
     secure_files_deleted += 1
     puts "#{secure_file.id}  #{secure_file.file.path} is missing."     ### Allow verification before destroy
   #  secure_file.destroy!                                           ### Uncomment to actually destroy
   end
   puts "Count of identified/destroyed invalid references: #{secure_files_deleted}"
   ```

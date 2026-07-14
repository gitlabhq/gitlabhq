---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurer Git LFS pour GitLab auto-géré.
title: Administration de Git Large File Storage (LFS) pour GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Utilisez Git Large File Storage (LFS) pour stocker de grands fichiers dans un dépôt Git sans en augmenter la taille ni affecter les performances. Vous pouvez activer ou désactiver LFS, configurer un stockage local ou distant pour les objets LFS, et migrer des objets entre les types de stockage.

Pour la documentation utilisateur, consultez [Git Large File Storage (LFS)](../../topics/git/lfs/_index.md).

Prérequis :

- Les utilisateurs doivent installer [le client Git LFS](https://git-lfs.com/) en version 1.1.0 ou ultérieure, ou 1.0.2.

## Activer ou désactiver LFS {#enable-or-disable-lfs}

LFS est activé par défaut. Pour le désactiver :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Change to true to enable lfs - enabled by default if not defined
   gitlab_rails['lfs_enabled'] = false
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       lfs:
         enabled: false
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['lfs_enabled'] = false
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     lfs:
       enabled: false
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

## Modifier le chemin de stockage local {#change-local-storage-path}

Les objets Git LFS peuvent être volumineux. Par défaut, ils sont stockés sur le serveur sur lequel GitLab est installé.

> [!note]
> Pour les installations Docker, vous pouvez modifier le chemin où vos données sont montées. Pour le chart Helm, utilisez le [stockage d'objets](https://docs.gitlab.com/charts/advanced/external-object-storage/).

Pour modifier l'emplacement du chemin de stockage local par défaut :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # /var/opt/gitlab/gitlab-rails/shared/lfs-objects by default.
   gitlab_rails['lfs_storage_path'] = "/mnt/storage/lfs-objects"
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   # /home/git/gitlab/shared/lfs-objects by default.
   production: &base
     lfs:
       storage_path: /mnt/storage/lfs-objects
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

## Stockage des objets LFS dans un stockage d'objets distant {#storing-lfs-objects-in-remote-object-storage}

Vous pouvez stocker les objets LFS dans un stockage d'objets distant. Cela vous permet de réduire les lectures et écritures sur le disque local, et de libérer considérablement de l'espace disque.

Vous devriez utiliser les [paramètres de stockage d'objets consolidés](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).

### Migration vers le stockage d'objets {#migrating-to-object-storage}

Vous pouvez migrer les objets LFS du stockage local vers le stockage d'objets. Le traitement s'effectue en arrière-plan et ne nécessite aucune interruption de service.

1. [Configurez le stockage d'objets](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).
1. Migrez les objets LFS :

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo gitlab-rake gitlab:lfs:migrate
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   sudo docker exec -t <container name> gitlab-rake gitlab:lfs:migrate
   ```

   {{< /tab >}}

   {{< tab title="Self-compiled (source)" >}}

   ```shell
   sudo -u git -H bundle exec rake gitlab:lfs:migrate RAILS_ENV=production
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Facultatif. Suivez la progression et vérifiez que tous les objets LFS des jobs ont bien été migrés à l'aide de la console PostgreSQL.
   1. Ouvrez une console PostgreSQL :

      {{< tabs >}}

      {{< tab title="Linux package (Omnibus)" >}}

      ```shell
      sudo gitlab-psql
      ```

      {{< /tab >}}

      {{< tab title="Docker" >}}

      ```shell
      sudo docker exec -it <container_name> /bin/bash
      gitlab-psql
      ```

      {{< /tab >}}

      {{< tab title="Self-compiled (source)" >}}

      ```shell
      sudo -u git -H psql -d gitlabhq_production
      ```

      {{< /tab >}}

      {{< /tabs >}}

   1. Vérifiez que tous les fichiers LFS ont été migrés vers le stockage d'objets à l'aide de la requête SQL suivante. Le nombre de `objectstg` doit être identique à `total` :

      ```shell
      gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM lfs_objects;

      total | filesystem | objectstg
      ------+------------+-----------
       2409 |          0 |      2409
      ```

1. Vérifiez qu'il n'y a aucun fichier sur le disque dans le répertoire `lfs-objects` :

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/lfs-objects -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   En supposant que vous avez monté `/var/opt/gitlab` sur `/srv/gitlab` :

   ```shell
   sudo find /srv/gitlab/gitlab-rails/shared/lfs-objects -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< tab title="Self-compiled (source)" >}}

   ```shell
   sudo find /home/git/gitlab/shared/lfs-objects -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< /tabs >}}

### Retour au stockage local {#migrating-back-to-local-storage}

> [!note]
> Pour le chart Helm, vous devriez utiliser le [stockage d'objets](https://docs.gitlab.com/charts/advanced/external-object-storage/).

Pour migrer vers le stockage local :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Migrez les objets LFS :

   ```shell
   sudo gitlab-rake gitlab:lfs:migrate_to_local
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et [désactivez le stockage d'objets](../object_storage.md#disable-object-storage-for-specific-features) pour les objets LFS :

   ```ruby
   gitlab_rails['object_store']['objects']['lfs']['enabled'] = false
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Migrez les objets LFS :

   ```shell
   sudo docker exec -t <container name> gitlab-rake gitlab:lfs:migrate_to_local
   ```

1. Modifiez `docker-compose.yml` et désactivez le stockage d'objets pour les objets LFS :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['object_store']['objects']['lfs']['enabled'] = false
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Migrez les objets LFS :

   ```shell
   sudo -u git -H bundle exec rake gitlab:lfs:migrate_to_local RAILS_ENV=production
   ```

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et désactivez le stockage d'objets pour les objets LFS :

   ```yaml
   production: &base
     object_store:
       objects:
         lfs:
           enabled: false
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

## Protocole de transfert SSH pur {#pure-ssh-transfer-protocol}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/11872) dans GitLab 17.2.
- [Introduit](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3845) pour le chart Helm (Kubernetes) dans GitLab 17.3.

{{< /history >}}

> [!warning]
> Cette fonctionnalité est affectée par [un problème connu](https://github.com/git-lfs/git-lfs/issues/5880) (résolu dans [Git LFS 3.6.0](https://github.com/git-lfs/git-lfs/blob/main/CHANGELOG.md#360-20-november-2024)). Si vous clonez un dépôt comportant plusieurs objets Git LFS à l'aide du protocole SSH pur, le client peut planter en raison d'une référence de pointeur `nil`.

[`git-lfs` 3.0.0](https://github.com/git-lfs/git-lfs/blob/main/CHANGELOG.md#300-24-sep-2021) a introduit la prise en charge de SSH comme protocole de transfert à la place de HTTP. SSH est géré de manière transparente par l'outil de ligne de commande `git-lfs`.

Lorsque la prise en charge du protocole SSH pur est activée et que `git` est configuré pour utiliser SSH, toutes les opérations LFS s'effectuent via SSH. Par exemple, lorsque le remote Git est `git@gitlab.com:gitlab-org/gitlab.git`. Vous ne pouvez pas configurer `git` et `git-lfs` pour utiliser des protocoles différents. À partir de la version 3.0, `git-lfs` tente d'abord d'utiliser le protocole SSH pur et, si la prise en charge n'est pas activée ou disponible, il revient à l'utilisation de HTTP.

Prérequis :

- La version de `git-lfs` doit être [v3.5.1](https://github.com/git-lfs/git-lfs/releases/tag/v3.5.1) ou supérieure.

Pour faire basculer Git LFS vers le protocole SSH pur :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_shell['lfs_pure_ssh_protocol'] = true
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   gitlab:
     gitlab-shell:
       config:
         lfs:
           pureSSHProtocol: true
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_shell['lfs_pure_ssh_protocol'] = true
   ```

1. Enregistrez le fichier et redémarrez GitLab et ses services :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab-shell/config.yml` :

   ```yaml
   lfs:
      pure_ssh_protocol: true
   ```

1. Enregistrez le fichier et redémarrez GitLab Shell :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab-shell.target

   # For systems running SysV init
   sudo service gitlab-shell restart
   ```

{{< /tab >}}

{{< /tabs >}}

## Statistiques de stockage {#storage-statistics}

Vous pouvez consulter le stockage total utilisé pour les objets LFS pour les groupes et les projets dans :

- La zone **Admin**
- Les API [groups](../../api/groups.md) et [projects](../../api/projects.md)

> [!note]
> Les statistiques de stockage comptent chaque objet LFS pour chaque projet qui y est lié.

## Sujets connexes {#related-topics}

- Article de blog : [Prise en main de Git LFS](https://about.gitlab.com/blog/getting-started-with-git-lfs-tutorial/)
- Documentation utilisateur : [Git Large File Storage (LFS)](../../topics/git/lfs/_index.md)

## Dépannage {#troubleshooting}

### Objets LFS manquants {#missing-lfs-objects}

Une erreur concernant un objet LFS manquant peut se produire dans l'une ou l'autre des situations suivantes :

- Lors de la migration d'objets LFS du disque vers le stockage d'objets, avec des messages d'erreur tels que :

  ```plaintext
  ERROR -- : Failed to transfer LFS object
  006622269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
  with error: No such file or directory @ rb_sysopen -
  /var/opt/gitlab/gitlab-rails/shared/lfs-objects/00/66/22269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
  ```

   (Des sauts de ligne ont été ajoutés pour faciliter la lecture.)

- Lors de l'exécution de la [vérification d'intégrité des objets LFS](../raketasks/check.md#uploaded-files-integrity) avec le paramètre `VERBOSE=1`.

La base de données peut contenir des enregistrements pour des objets LFS qui ne sont pas sur le disque. L'entrée de base de données peut [empêcher l'envoi d'une nouvelle copie de l'objet](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/49241). Pour supprimer ces références :

1. [Démarrez une console Rails](../operations/rails_console.md).
1. Interrogez l'objet signalé comme manquant dans la console Rails pour obtenir un chemin de fichier :

   ```ruby
   lfs_object = LfsObject.find_by(oid: '006622269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7')
   lfs_object.file.path
   ```

1. Vérifiez s'il existe sur le disque ou dans le stockage d'objets :

   ```shell
   ls -al /var/opt/gitlab/gitlab-rails/shared/lfs-objects/00/66/22269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
   ```

1. Si le fichier n'est pas présent, supprimez les enregistrements de la base de données avec la console Rails :

   ```ruby
   # First delete the parent records and then destroy the record itself
   lfs_object.lfs_objects_projects.destroy_all
   lfs_object.destroy
   ```

#### Supprimer plusieurs objets LFS manquants {#remove-multiple-missing-lfs-objects}

Pour supprimer en une seule fois les références à plusieurs objets LFS manquants :

1. Ouvrez la [console Rails GitLab](../operations/rails_console.md#starting-a-rails-console-session).
1. Exécutez le script suivant :

   ```ruby
   lfs_files_deleted = 0
   LfsObject.find_each do |lfs_file|
     next if lfs_file.file.file.exists?
     lfs_files_deleted += 1
     p "LFS file with ID #{lfs_file.id} and path #{lfs_file.file.path} is missing."
     # lfs_file.lfs_objects_projects.destroy_all     # Uncomment to delete parent records
     # lfs_file.destroy                              # Uncomment to destroy the LFS object reference
   end
   p "Count of identified/destroyed invalid references: #{lfs_files_deleted}"
   ```

Ce script identifie tous les objets LFS manquants dans la base de données. Avant de supprimer des enregistrements :

- Il affiche d'abord des informations sur les fichiers manquants à des fins de vérification.
- Les lignes commentées évitent toute suppression accidentelle. Si vous les décommentez, le script supprime les enregistrements identifiés.
- Le script affiche automatiquement un décompte final des enregistrements supprimés à des fins de comparaison.

### Échec des commandes LFS sur un serveur TLS v1.3 {#lfs-commands-fail-on-tls-v13-server}

Si vous configurez GitLab pour [désactiver TLS v1.2](https://docs.gitlab.com/omnibus/settings/nginx/) et n'activer que les connexions TLS v1.3, les opérations LFS nécessitent un [client Git LFS](https://git-lfs.com/) en version 2.11.0 ou ultérieure. Si vous utilisez un client Git LFS antérieur à la version 2.11.0, GitLab affiche une erreur :

```plaintext
batch response: Post https://username:***@gitlab.example.com/tool/releases.git/info/lfs/objects/batch: remote error: tls: protocol version not supported
error: failed to fetch some objects from 'https://username:[MASKED]@gitlab.example.com/tool/releases.git/info/lfs'
```

Lorsque vous utilisez GitLab CI sur un serveur GitLab configuré avec TLS v1.3, vous devez [mettre à niveau vers GitLab Runner](https://docs.gitlab.com/runner/install/) 13.2.0 ou une version ultérieure pour obtenir une version mise à jour du client Git LFS avec l'[image d'assistance GitLab Runner](https://docs.gitlab.com/runner/configuration/advanced-configuration/#helper-image) incluse.

Pour vérifier la version d'un client Git LFS installé, exécutez cette commande :

```shell
git lfs version
```

### Erreurs `Connection refused` {#connection-refused-errors}

Si vous envoyez ou répliquez des objets LFS et recevez des erreurs telles que :

- `dial tcp <IP>:443: connect: connection refused`
- `Connection refused - connect(2) for \"<target-or-proxy-IP>\" port 443`

un pare-feu ou une règle de proxy peut mettre fin à la connexion.

Si les vérifications de connexion avec les outils Unix standard ou les envois Git manuels réussissent, la règle peut être liée à la taille de la requête.

### Erreur lors de l'affichage d'un fichier PDF {#error-viewing-a-pdf-file}

Lorsque LFS a été configuré avec le stockage d'objets et que `proxy_download` est défini sur `false`, il est possible que vous voyiez une erreur lors de la prévisualisation d'un fichier PDF depuis le navigateur Web :

```plaintext
An error occurred while loading the file. Please try again later.
```

Cela est dû aux restrictions de partage des ressources entre origines multiples (CORS) : le navigateur tente de charger le fichier PDF depuis le stockage d'objets, mais le fournisseur de stockage d'objets rejette la requête car le domaine GitLab diffère du domaine de stockage d'objets.

Pour résoudre ce problème, configurez les paramètres CORS de votre fournisseur de stockage d'objets afin d'autoriser le domaine GitLab. Consultez la documentation suivante pour plus de détails :

1. [AWS S3](https://repost.aws/knowledge-center/s3-configure-cors)
1. [Google Cloud Storage](https://cloud.google.com/storage/docs/using-cors)
1. [Azure Storage](https://learn.microsoft.com/en-us/rest/api/storageservices/cross-origin-resource-sharing--cors--support-for-the-azure-storage-services).

### Opération de duplication bloquée sur le message `Forking in progress` {#fork-operation-stuck-on-forking-in-progress-message}

Si vous dupliquez un projet avec plusieurs fichiers LFS, l'opération peut se bloquer avec un message `Forking in progress`. Si vous rencontrez ce problème, suivez ces étapes pour diagnostiquer et résoudre le problème :

1. Vérifiez dans votre fichier [`exceptions_json.log`](../logs/_index.md#exceptions_jsonlog) la présence du message d'erreur suivant :

   ```plaintext
   "error_message": "Unable to fork project 12345 for repository
   @hashed/11/22/encoded-path -> @hashed/33/44/encoded-new-path:
   Source project has too many LFS objects"
   ```

   Cette erreur indique que vous avez atteint la limite par défaut de 100 000 fichiers LFS, comme décrit dans le [ticket 476693](https://gitlab.com/gitlab-org/gitlab/-/issues/476693).

1. Augmentez la valeur de la variable `GITLAB_LFS_MAX_OID_TO_FETCH` :

   1. Ouvrez le fichier de configuration `/etc/gitlab/gitlab.rb`.
   1. Ajoutez ou mettez à jour la variable :

      ```ruby
      gitlab_rails['env'] = {
         "GITLAB_LFS_MAX_OID_TO_FETCH" => "NEW_VALUE"
      }
      ```

      Remplacez `NEW_VALUE` par un nombre correspondant à vos besoins.

1. Appliquez les modifications. Exécutez :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   Pour plus d'informations, consultez [reconfigurer une installation de package Linux](../restart_gitlab.md#reconfigure-a-linux-package-installation).

1. Répétez l'opération de duplication.

> [!note]
> Pour le chart Helm GitLab, utilisez [`extraEnv`](https://docs.gitlab.com/charts/charts/globals/#extraenv) pour configurer la variable d'environnement `GITLAB_LFS_MAX_OID_TO_FETCH`.

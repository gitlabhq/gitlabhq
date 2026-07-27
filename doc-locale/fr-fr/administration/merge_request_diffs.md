---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurez le stockage externe pour les diffs de merge request sur votre instance GitLab.
title: Stockage des diffs de merge request
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les diffs de merge request sont des copies de diffs associées aux merge requests, dont la taille est limitée. Lors de l'affichage d'une merge request, les diffs proviennent de ces copies dans la mesure du possible, à des fins d'optimisation des performances.

Par défaut, GitLab stocke les diffs de merge request dans la base de données, dans une table nommée `merge_request_diff_files`. Les installations de grande taille peuvent constater que cette table devient trop volumineuse. Dans ce cas, vous devez passer au stockage externe.

Les diffs de merge request peuvent être stockées :

- Entièrement [sur le disque](#using-external-storage).
- Entièrement [sur le stockage objet](#using-object-storage).
- Les diffs actuels dans la base de données, et [les diffs obsolètes dans le stockage objet](#alternative-in-database-storage).

## Utilisation du stockage externe {#using-external-storage}

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['external_diffs_enabled'] = true
   ```

1. Les diffs externes sont stockées dans `/var/opt/gitlab/gitlab-rails/shared/external-diffs`. Pour modifier le chemin, par exemple en `/mnt/storage/external-diffs`, modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['external_diffs_storage_path'] = "/mnt/storage/external-diffs"
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet. GitLab migre alors vos diffs de merge request existantes vers le stockage externe.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes :

   ```yaml
   external_diffs:
     enabled: true
   ```

1. Les diffs externes sont stockées dans `/home/git/gitlab/shared/external-diffs`. Pour modifier le chemin, par exemple en `/mnt/storage/external-diffs`, modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes :

   ```yaml
   external_diffs:
     enabled: true
     storage_path: /mnt/storage/external-diffs
   ```

1. Enregistrez le fichier et [redémarrez GitLab](restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet. GitLab migre alors vos diffs de merge request existantes vers le stockage externe.

{{< /tab >}}

{{< /tabs >}}

## Utilisation du stockage objet {#using-object-storage}

> [!warning]
> La migration vers le stockage objet est irréversible.

Au lieu de stocker les diffs externes sur disque, vous devez utiliser un stockage objet tel qu'AWS S3. Cette configuration repose sur des identifiants AWS préconfigurés et valides.

> [!note]
> La configuration du stockage objet pour les diffs externes dans les paramètres de stockage objet consolidés n'active pas automatiquement le stockage externe pour les diffs de merge request. Vous devez définir explicitement `external_diffs_enabled` sur `true`.

Pour configurer le stockage objet pour les diffs externes :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['external_diffs_enabled'] = true
   ```

1. Configurez les [paramètres de stockage objet consolidés](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).
1. Enregistrez le fichier et [reconfigurez GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes :

   ```yaml
   external_diffs:
     enabled: true
   ```

1. Configurez les [paramètres de stockage objet consolidés](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).
1. Enregistrez le fichier et [redémarrez GitLab](restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

Après avoir reconfiguré ou redémarré GitLab, vos diffs de merge request existantes sont migrées vers le stockage externe.

Pour plus d'informations, consultez [Stockage objet](object_storage.md).

## Stockage alternatif dans la base de données {#alternative-in-database-storage}

L'activation des diffs externes peut réduire les performances des merge requests, car elles doivent être récupérées lors d'une opération distincte des autres données. Un compromis peut être trouvé en ne stockant externement que les diffs obsolètes, tout en conservant les diffs actuels dans la base de données.

Pour activer cette fonctionnalité, effectuez les étapes suivantes :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['external_diffs_when'] = 'outdated'
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes :

   ```yaml
   external_diffs:
     enabled: true
     when: outdated
   ```

1. Enregistrez le fichier et [redémarrez GitLab](restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

Lorsque cette fonctionnalité est activée, les diffs sont initialement stockées dans la base de données, plutôt qu'en externe. Elles sont déplacées vers le stockage externe lorsque l'une des conditions suivantes devient vraie :

- Une version plus récente du diff de merge request existe
- La merge request a été fusionnée il y a plus de sept jours
- La merge request a été clôturée il y a plus de sept jours

Ces règles établissent un équilibre entre l'espace et les performances en ne stockant dans la base de données que les diffs fréquemment consultées. Les diffs moins susceptibles d'être consultées sont déplacées vers le stockage externe.

## Passage du stockage externe au stockage objet {#switching-from-external-storage-to-object-storage}

La migration automatique déplace les diffs stockées dans la base de données, mais ne déplace pas les diffs entre les types de stockage. Pour passer du stockage externe au stockage objet :

1. Déplacez manuellement les fichiers stockés sur un stockage local ou NFS vers le stockage objet.
1. Exécutez cette tâche Rake pour modifier leur emplacement dans la base de données.

   Pour les installations avec le package Linux :

   ```shell
   sudo gitlab-rake gitlab:external_diffs:force_object_storage
   ```

   Pour les installations compilées à partir des sources :

   ```shell
   sudo -u git -H bundle exec rake gitlab:external_diffs:force_object_storage RAILS_ENV=production
   ```

   Par défaut, `sudo` ne préserve pas les variables d'environnement existantes. Vous devez les ajouter en suffixe plutôt qu'en préfixe, comme ceci :

   ```shell
   sudo gitlab-rake gitlab:external_diffs:force_object_storage START_ID=59946109 END_ID=59946109 UPDATE_DELAY=5
   ```

Ces variables d'environnement modifient le comportement de la tâche Rake :

| Nom           | Valeur par défaut | Objectif |
|----------------|---------------|---------|
| `ANSI`         | `true`        | Utiliser des codes d'échappement ANSI pour rendre la sortie plus compréhensible. |
| `BATCH_SIZE`   | `1000`        | Itérer dans la table par lots de cette taille. |
| `START_ID`     | `nil`         | Si défini, commencer le scan à cet ID. |
| `END_ID`       | `nil`         | Si défini, arrêter le scan à cet ID. |
| `UPDATE_DELAY` | `1`           | Nombre de secondes à attendre entre les mises à jour. |

- `START_ID` et `END_ID` peuvent être utilisés pour exécuter la mise à jour en parallèle, en assignant différents processus à différentes parties de la table.
- `BATCH` et `UPDATE_DELAY` permettent d'ajuster la vitesse de migration par rapport à l'accès concurrent à la table.
- `ANSI` doit être défini sur `false` si votre terminal ne prend pas en charge les codes d'échappement ANSI.

Pour vérifier la distribution des diffs externes entre le stockage objet et le stockage local, utilisez la requête SQL suivante :

```shell
gitlabhq_production=# SELECT count(*) AS total,
  SUM(CASE
    WHEN external_diff_store = '1' THEN 1
    ELSE 0
  END) AS filesystem,
  SUM(CASE
    WHEN external_diff_store = '2' THEN 1
    ELSE 0
  END) AS objectstg
FROM merge_request_diffs;
```

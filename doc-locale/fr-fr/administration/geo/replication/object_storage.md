---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: "Geo avec le stockage d'objets"
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- La vérification des fichiers stockés dans le stockage d'objets a été [introduite](https://gitlab.com/groups/gitlab-org/-/epics/8056) dans GitLab 16.4 [avec un flag](../../feature_flags/_index.md) nommé `geo_object_storage_verification`. Activé par défaut.

{{< /history >}}

Geo peut être utilisé en combinaison avec le stockage d'objets (AWS S3 ou tout autre stockage d'objets compatible).

Les sites **Secondaire** peuvent utiliser l'un des éléments suivants :

- Le même bucket de stockage que le site **principal**.
- Un bucket de stockage répliqué.
- Le stockage local, si le site principal utilise le stockage local.

La méthode de stockage (locale ou stockage d'objets) des fichiers est enregistrée dans la base de données, et la base de données est répliquée du site Geo **principal** vers le site Geo **secondaire**.

Lors de l'accès à un objet chargé, nous obtenons sa méthode de stockage (locale ou stockage d'objets) à partir de la base de données. Le site Geo **secondaire** doit donc correspondre à la méthode de stockage du site Geo **principal**.

Par conséquent, si le site Geo **principal** utilise le stockage d'objets, le site Geo **secondaire** doit également l'utiliser.

Pour que :

- GitLab gère la réplication, suivez [Activer la réplication GitLab](#enabling-gitlab-managed-object-storage-replication).
- Des services tiers gèrent la réplication, suivez [Services de réplication tiers](#third-party-replication-services).

[En savoir plus sur l'utilisation du stockage d'objets avec GitLab](../../object_storage.md).

## Vérification du stockage d'objets {#object-storage-verification}

Geo vérifie les fichiers stockés dans le stockage d'objets pour garantir l'intégrité des données entre les sites principal et secondaires.

> [!warning]
> La désactivation de la vérification du stockage d'objets n'est pas recommandée. Lorsque vous désactivez le `geo_object_storage_verification`, GitLab supprime de façon asynchrone tous les enregistrements d'état de vérification existants.

Lorsque le `geo_object_storage_verification` est désactivé :

- Les workers de vérification Geo (`Geo::VerificationBatchWorker`) peuvent toujours apparaître dans les journaux Sidekiq, mais la vérification n'a pas lieu.
- Lors du nettoyage des enregistrements de vérification, des workers peuvent être mis en file d'attente pour traiter les enregistrements restants.

## Activation de la réplication du stockage d'objets gérée par GitLab {#enabling-gitlab-managed-object-storage-replication}

{{< history >}}

- [Introduite](https://gitlab.com/groups/gitlab-org/-/epics/5551) dans GitLab 15.1.

{{< /history >}}

> [!warning]
> En cas de problèmes, évitez de supprimer manuellement des fichiers individuels, car cela peut entraîner des [incohérences de données](#inconsistencies-after-the-migration).

Les sites **Secondaire** peuvent répliquer les fichiers stockés par le site **principal**, qu'ils soient stockés sur le système de fichiers local ou dans le stockage d'objets.

Pour activer la réplication GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Sélectionnez **Éditer** sur le site **secondaire**.
1. Dans la section **Synchronization Settings**, trouvez la case **Autoriser ce site secondaire à répliquer le contenu sur le stockage d'objets** pour l'activer.

Pour LFS, suivez la documentation pour [configurer le stockage d'objets LFS](../../lfs/_index.md#storing-lfs-objects-in-remote-object-storage).

Pour les artefacts de job CI, il existe une documentation similaire pour configurer le [stockage d'objets pour les artefacts de job](../../cicd/job_artifacts.md#using-object-storage).

Pour les chargements des utilisateurs, il existe une documentation similaire pour configurer le [stockage d'objets pour les chargements](../../uploads.md#using-object-storage).

Si vous souhaitez migrer les fichiers du site **principal** vers le stockage d'objets, vous pouvez configurer le site **secondaire** de plusieurs façons :

- Utiliser exactement le même stockage d'objets.
- Utiliser un stockage d'objets distinct mais exploiter la réplication intégrée de votre solution de stockage d'objets.
- Utiliser un stockage d'objets distinct et activer le paramètre **Autoriser ce site secondaire à répliquer le contenu sur le stockage d'objets**.

Si le paramètre **Autoriser ce site secondaire à répliquer le contenu sur le stockage d'objets** est désactivé et que vous avez migré tous vos fichiers du stockage local vers le stockage d'objets, de nombreuses barres de progression dans **Admin** > **Geo** > **Sites** affichent **Rien à synchroniser**.

> [!warning]
> Pour éviter toute perte de données, vous ne devez activer le paramètre **Autoriser ce site secondaire à répliquer le contenu sur le stockage d'objets** que si vous utilisez des stockages d'objets distincts pour les sites principal et secondaire.

GitLab ne prend pas en charge le cas où les deux conditions suivantes sont réunies :

- Le site **principal** utilise le stockage local.
- Un site **secondaire** utilise le stockage d'objets.

### Incohérences après la migration {#inconsistencies-after-the-migration}

Des incohérences de données peuvent survenir lors de la migration du stockage local vers le stockage d'objets, comme décrit plus en détail dans la [section de dépannage du stockage d'objets](../../object_storage.md#inconsistencies-after-migrating-to-object-storage).

## Services de réplication tiers {#third-party-replication-services}

Lorsque vous utilisez Amazon S3, vous pouvez utiliser la [réplication inter-régions (CRR)](https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html) pour disposer d'une réplication automatique entre le bucket utilisé par le site **principal** et le bucket utilisé par les sites **secondaire**.

Si vous utilisez Google Cloud Storage, envisagez d'utiliser le [stockage multi-régional](https://cloud.google.com/storage/docs/storage-classes#multi-regional). Vous pouvez également utiliser le [Storage Transfer Service](https://cloud.google.com/storage-transfer/docs/overview), bien que celui-ci ne prenne en charge que la synchronisation quotidienne.

Pour une synchronisation manuelle ou planifiée par `cron`, voir :

- [`s3cmd sync`](https://s3tools.org/s3cmd-sync)
- [`gsutil rsync`](https://cloud.google.com/storage/docs/gsutil/commands/rsync)

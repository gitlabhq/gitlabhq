---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tâches Rake de nettoyage des téléversements
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Les données EXIF sont automatiquement supprimées des téléversements d'images JPG ou TIFF.

Les données EXIF peuvent contenir des informations sensibles (par exemple, la localisation GPS). Vous pouvez donc supprimer les données EXIF des images existantes qui ont été téléversées dans une version antérieure de GitLab.

## Prérequis {#prerequisite}

Pour exécuter cette tâche Rake, vous devez avoir `exiftool` installé sur votre système. Si vous avez installé GitLab :

- En utilisant le package Linux, vous êtes prêt.
- En utilisant l'installation compilée manuellement, assurez-vous que `exiftool` est installé :

  ```shell
  # Debian/Ubuntu
  sudo apt-get install libimage-exiftool-perl

  # RHEL/CentOS
  sudo yum install perl-Image-ExifTool
  ```

## Supprimer les données EXIF des téléversements existants {#remove-exif-data-from-existing-uploads}

Pour supprimer les données EXIF des téléversements existants, exécutez la commande suivante :

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif
```

Par défaut, cette commande s'exécute en mode « dry run » et ne supprime pas les données EXIF. Elle peut être utilisée pour vérifier si (et combien d') images doivent être nettoyées.

La tâche Rake accepte les paramètres suivants.

| Paramètre    | Type    | Description                                                                                                                 |
|:-------------|:--------|:----------------------------------------------------------------------------------------------------------------------------|
| `start_id`   | entier | Seuls les téléversements dont l'ID est égal ou supérieur sont traités                                                                     |
| `stop_id`    | entier | Seuls les téléversements dont l'ID est égal ou inférieur sont traités                                                                     |
| `dry_run`    | booléen | Ne pas supprimer les données EXIF, vérifier uniquement si des données EXIF sont présentes ou non. Par défaut : `true`                                     |
| `sleep_time` | flottant   | Mettre en pause pendant un nombre de secondes après le traitement de chaque image. Par défaut : 0,3 seconde                                            |
| `uploader`   | chaîne  | Exécuter le nettoyage uniquement pour les téléversements de l'uploader donné : `FileUploader`, `PersonalFileUploader` ou `NamespaceFileUploader` |
| `since`      | date    | Exécuter le nettoyage uniquement pour les téléversements plus récents que la date donnée. Par exemple, `2019-05-01`                                          |

Si vous avez trop de téléversements, vous pouvez accélérer le nettoyage en :

- Définissant `sleep_time` sur une valeur inférieure.
- Exécutant plusieurs tâches Rake en parallèle, chacune avec une plage distincte d'ID de téléversement (en définissant `start_id` et `stop_id`).

Pour supprimer les données EXIF de tous les téléversements, utilisez :

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif[,,false,] 2>&1 | tee exif.log
```

Pour supprimer les données EXIF des téléversements dont l'ID est compris entre 100 et 5 000 et marquer une pause de 0,1 seconde après chaque fichier, utilisez :

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif[100,5000,false,0.1] 2>&1 | tee exif.log
```

La sortie est écrite dans un fichier `exif.log` car elle est souvent longue.

Si le nettoyage échoue pour un téléversement, un message d'erreur devrait apparaître dans la sortie de la tâche Rake. Les raisons habituelles incluent l'absence du fichier dans le stockage ou le fait qu'il ne s'agit pas d'une image valide.

[Signalez](https://gitlab.com/gitlab-org/gitlab/-/issues/new) tout problème et utilisez le préfixe 'EXIF' dans le titre du ticket avec la sortie d'erreur et (si possible) l'image.

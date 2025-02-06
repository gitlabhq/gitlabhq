---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Uploads sanitize Rake tasks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

EXIF data is automatically stripped from JPG or TIFF image uploads.

EXIF data may contain sensitive information (for example, GPS location), so you
can remove EXIF data from existing images that were uploaded to an earlier version of GitLab.

## Prerequisite

To run this Rake task, you need `exiftool` installed on your system. If you installed GitLab:

- By using the Linux package, you're all set.
- By using the self-compiled installation, make sure `exiftool` is installed:

  ```shell
  # Debian/Ubuntu
  sudo apt-get install libimage-exiftool-perl

  # RHEL/CentOS
  sudo yum install perl-Image-ExifTool
  ```

## Remove EXIF data from existing uploads

To remove EXIF data from existing uploads, run the following command:

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif
```

By default, this command runs in "dry run" mode and doesn't remove EXIF data. It can be used for
checking if (and how many) images should be sanitized.

The Rake task accepts following parameters.

| Parameter    | Type    | Description                                                                                                                 |
|:-------------|:--------|:----------------------------------------------------------------------------------------------------------------------------|
| `start_id`   | integer | Only uploads with equal or greater ID are processed                                                                     |
| `stop_id`    | integer | Only uploads with equal or smaller ID are processed                                                                     |
| `dry_run`    | boolean | Do not remove EXIF data, only check if EXIF data are present or not. Defaults to `true`                                     |
| `sleep_time` | float   | Pause for number of seconds after processing each image. Defaults to 0.3 seconds                                            |
| `uploader`   | string  | Run sanitization only for uploads of the given uploader: `FileUploader`, `PersonalFileUploader`, or `NamespaceFileUploader` |
| `since`      | date    | Run sanitization only for uploads newer than given date. For example, `2019-05-01`                                          |

If you have too many uploads, you can speed up sanitization by:

- Setting `sleep_time` to a lower value.
- Running multiple Rake tasks in parallel, each with a separate range of upload IDs (by setting
  `start_id` and `stop_id`).

To remove EXIF data from all uploads, use:

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif[,,false,] 2>&1 | tee exif.log
```

To remove EXIF data on uploads with an ID between 100 and 5000 and pause for 0.1 second after each file, use:

```shell
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif[100,5000,false,0.1] 2>&1 | tee exif.log
```

The output is written into an `exif.log` file because it is often long.

If sanitization fails for an upload, an error message should be in the output of the Rake task.
Typical reasons include that the file is missing in the storage or it's not a valid image.

[Report](https://gitlab.com/gitlab-org/gitlab/-/issues/new) any issues and use the prefix 'EXIF' in
the issue title with the error output and (if possible) the image.

# Uploads Sanitize tasks

## Requirements

You need `exiftool` installed on your system. If you installed GitLab:

- Using the Omnibus package, you're all set.
- From source, make sure `exiftool` is installed:

  ```sh
  # Debian/Ubuntu
  sudo apt-get install libimage-exiftool-perl

  # RHEL/CentOS
  sudo yum install perl-Image-ExifTool
  ```

## Remove EXIF data from existing uploads

Since 11.9 EXIF data are automatically stripped from JPG or TIFF image uploads.
Because EXIF data may contain sensitive information (e.g. GPS location), you
can remove EXIF data also from existing images which were uploaded before
with the following command:

```bash
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif
```

This command by default runs in dry mode and it doesn't remove EXIF data. It can be used for
checking if (and how many) images should be sanitized.

The rake task accepts following parameters.

Parameter | Type | Description
--------- | ---- | -----------
`start_id` | integer | Only uploads with equal or greater ID will be processed
`stop_id` | integer | Only uploads with equal or smaller ID will be processed
`dry_run` | boolean | Do not remove EXIF data, only check if EXIF data are present or not, default: true
`sleep_time` | float | Pause for number of seconds after processing each image, default: 0.3 seconds
`uploader` | string | Run sanitization only for uploads of the given uploader (`FileUploader`, `PersonalFileUploader`, `NamespaceFileUploader`)
`since` | date | Run sanitization only for uploads newer than given date (e.g. `2019-05-01`)

If you have too many uploads, you can speed up sanitization by setting
`sleep_time` to a lower value or by running multiple rake tasks in parallel,
each with a separate range of upload IDs (by setting `start_id` and `stop_id`).

To run the command without dry mode and remove EXIF data from all uploads, you can use:

```bash
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif[,,false,] 2>&1 | tee exif.log
```

To run the command without dry mode on uploads with ID between 100 and 5000 and pause for 0.1 second, you can use:

```bash
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:uploads:sanitize:remove_exif[100,5000,false,0.1] 2>&1 | tee exif.log
```

Because the output of commands will be probably long, the output is written also into exif.log file.

If sanitization fails for an upload, an error message should be in the output of the rake task (typical reasons may
be that the file is missing in the storage or it's not a valid image). Please
[report](https://gitlab.com/gitlab-org/gitlab-ce/issues/new) any issues at `gitlab.com` and use
prefix 'EXIF' in issue title with the error output and (if possible) the image.

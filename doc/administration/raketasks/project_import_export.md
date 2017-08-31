# Project import/export

>**Note:**
>
>  - [Introduced][ce-3050] in GitLab 8.9.
>  - Importing will not be possible if the import instance version is lower
>    than that of the exporter.
>  - For existing installations, the project import option has to be enabled in
>    application settings (`/admin/application_settings`) under 'Import sources'.
>  - The exports are stored in a temporary [shared directory][tmp] and are deleted
>    every 24 hours by a specific worker.

The GitLab Import/Export version can be checked by using:

```bash
# Omnibus installations
sudo gitlab-rake gitlab:import_export:version

# Installations from source
bundle exec rake gitlab:import_export:version RAILS_ENV=production
```

The current list of DB tables that will get exported can be listed by using:

```bash
# Omnibus installations
sudo gitlab-rake gitlab:import_export:data

# Installations from source
bundle exec rake gitlab:import_export:data RAILS_ENV=production
```

A new project export can be scheduled using the following task:

```bash
bundle exec rake gitlab:import_export:export['namespace/test_project_export', gitlab_username]
```

An existing exported project file can be scheduled to be imported using the following task:

```bash
bundle exec rake gitlab:import_export:import['namespace/test_project_export',root,'/path/to/project_export.tar.gz']
```

The status of any import or export can be checked at any time using the following task:

```bash
bundle exec rake gitlab:import_export:status['namespace/test_project_export']
```

[ce-3050]: https://gitlab.com/gitlab-org/gitlab-ce/issues/3050
[tmp]: ../../development/shared_files.md

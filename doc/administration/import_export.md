# Project import/export

Existing projects running on any GitLab instance or GitLab.com can be exported
with all its related data and moved into a new GitLab instance.

## Requirements

- You will need at least GitLab version 8.9 running on both instances
- Importing may not be possible if the import instance version is lower
 than the exporter.
 
## Exported contents
 
* The following items will be exported:
  * Project and wiki repositories
  * Project uploads
  * Project configuration including web hooks and services
  * Issues with comments, merge requests with diffs and comments, labels, milestones, snippets,
   and other project entities
* The following items will NOT be exported:
  * Build traces and artifacts
  * LFS objects

## Exporting a project and its data 

1. Go to the project settings page and find the Export button.

    ![export_1](./img/export_1.png)

2. Once the export is generated, you should receive an e-mail with a link to download the file.

    ![export_3](./img/export_3.png)

3. You can come back to project settings and download the file from there, or delete it so it
can be generated again.

    ![export_4](./img/export_4.png)

## Import

1. The new GitLab project import feature is at the far right of the import options on New Project.

    ![import_1](./img/import_1.png)

2. After choosing a namespace or path, you can then select the file prevoiusly exported.

    ![import_2](./img/import_2.png)
    

3. Click on Import and the import now begins and you will see your newly imported project page soon.

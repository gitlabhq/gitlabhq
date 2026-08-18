---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Importer la liste de licences SPDX dans GitLab, permettant une correspondance précise des licences pour les politiques de conformité"
title: "Tâche Rake d'importation de la liste de licences SPDX"
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab fournit une tâche Rake pour téléverser une nouvelle copie de la [liste de licences SPDX](https://spdx.org/licenses/) vers une instance GitLab. Cette liste est nécessaire pour faire correspondre les noms des [politiques d'approbation de licences](../../user/compliance/license_approval_policies.md).

Pour importer une nouvelle copie de la liste de licences SPDX, exécutez :

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:spdx:import

# source installations
bundle exec rake gitlab:spdx:import RAILS_ENV=production
```

Pour effectuer cette tâche dans l'[environnement hors ligne](../../user/application_security/offline_deployments/_index.md#defining-offline-environments), une connexion sortante vers [`licenses.json`](https://spdx.org/licenses/licenses.json) doit être autorisée.

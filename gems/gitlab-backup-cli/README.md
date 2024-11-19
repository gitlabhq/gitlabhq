# GitLab Backup CLI

## Overview

The GitLab Backup CLI is the new Backup tool for all GitLab installations.

The previous implementation relied on a couple of different approaches to implement backup.

Some relied on rake tasks shipped along with the main codebase. Extra functionality was implemented as part of Omnibus GitLab, and a different implementation was done for Kubernetes.

In this new implementation, we have a Unified approach:

- All the Backup logic is implemented in a single tool.
- The same tool works across the different installation types.
- It provides a similar UX no matter which installation type it is running from.

It aims to eventually supersede the previous backup mechanisms:

- [gitlab-backup](https://docs.gitlab.com/ee/administration/backup_restore/backup_gitlab.html#command-line-interface)
- [backup-utility](https://docs.gitlab.com/charts/backup-restore/backup.html)
- [alternative strategies](https://docs.gitlab.com/ee/administration/backup_restore/backup_gitlab.html#alternative-backup-strategies)

In addition, the new tool will add a new way of performing Backups when used with supported Cloud providers:

- It will rely on Cloud providers' APIs to perform Backups at scale.
- It will provide a Unified UX across different Cloud providers' backup capability.

Please check the Blueprint for additional information:
https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/backup_and_restore/

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

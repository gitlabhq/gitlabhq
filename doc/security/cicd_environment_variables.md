---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# CI/CD Environment Variables

Environment variables are applied to environments via the runner and can be set from the project's **Settings > CI/CD** page.

The values are encrypted using [aes-256-cbc](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) and stored in the database.

This data can only be decrypted with a valid [secrets file](../raketasks/backup_restore.md#when-the-secrets-file-is-lost).

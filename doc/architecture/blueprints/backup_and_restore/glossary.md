---
stage: systems
group: Geo
description: 'Unified Backups: Glossary'
---
[[_TOC_]]

# Unified Backups: Glossary

## archive

- The directory or archive file that is produced by a backup creation command. It will always contain a backup metadata file, and it may or may not contain actual captured data from the application, depending on the software environment

## archive metadata

- The record of a backup creation session stored in a JSON file inside every archive created by the `gitlab-backup-cli` command

## backup home

- The base directory that a user has configured as the default location to store archives produced by backup creation commands. This should always be treated as distinct from any actual archive directory or other significant path on the system.

## backup context

- When you execute a backup creation or restoration operation, you are running a backup session. It encompasses the operation, command line arguments, and the parameters of the operation as derived from the system configuration, command line arguments, environment variable, application context data, and archive metadata.

## data type

- One of the five abstract categories of data used by the GitLab application – Git repositories, databases, blobs, secrets/configurations, and transient data.

- This is distinct from the individual feature data backups contained in an archive. For example, “artifacts” or “packages” are two types of blob-based file backups in an archive, but they are not data families. “Blob” is the general data family to which these feature backups belong.

## installation types

- An installation type is the result of using one of [the installation methods](../../../install/install_methods.md).

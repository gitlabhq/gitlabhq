# Shared files

Historically, GitLab has been storing shared files in many different
directories: `public/uploads`, `builds`, `tmp/repositories`, `tmp/rebase` (EE),
etc. Having so many shared directories makes it difficult to deploy GitLab on
shared storage (e.g. NFS). Working towards GitLab 9.0 we are consolidating
these different directories under the `shared` directory.

This means that if GitLab will start storing puppies in some future version
then we should put them in `shared/puppies`. Temporary puppy files should be
stored in `shared/tmp`.

In the GitLab application code you can get the full path to the `shared`
directory with `Gitlab.config.shared.path`.

## What is not a 'shared file'

Files that belong to only one process, or on only one server, should not go in
`shared`. Examples include PID files and sockets.

## Temporary files and shared storage

Sometimes you create a temporary file on disk with the intention of it becoming
'official'. For example you might be first streaming an upload from a user to
disk in a temporary file so you can perform some checks on it. When the checks
pass, you make the file official. In scenarios like this please follow these
rules:

- Store the temporary file under `shared/tmp`, i.e. on the same filesystem you
  want the official file to be on.
- Use move/rename operations when operating on the file instead of copy
  operations where possible, because renaming a file is much faster than
  copying it.

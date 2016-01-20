# Build artifacts

Since version 8.2 of GitLab and version 0.7.0 of GitLab Runner, build artifacts
created by GitLab Runner are uploaded to GitLab, and then you can download
artifacts archive using GitLab UI.

Since version 8.4 of GitLab and version 1.0 of GitLab Runner artifacts are
compressed using ZIP format and it is possible to browse content of such an
archive using GitLab UI, and then download a single file from inside it.

## Artifacts in .gitlab-ci.yml

Please look into `.gitlab-ci.yml` [documentation](../yaml/README.md).

## Artifacts archive format

Prior to version 8.4 of GitLab and 1.0 of GitLab Runner, build artifacts were
compressed using `tar.gz` format.

Since then, we use a ZIP format.

## How build artifacts are stored

After a successful build, GitLab Runner uploads an archive containing build
artifacts to GitLab. This archive is not extracted after that, so its save a
storage space.

## How do we access content of an artifacts archive

When GitLab receives an artifacts archive, archive metadata file is being
generated. Metadata file describes all entries that are located in artifacts
archive. This file is in a binary format, with additional GZIP compression.

It is possible then to browse artifacts using GitLab UI and artifacts browser.

TODO IMG

GitLab does not extract artifacts archive to make it possible to browse it. We
use artifacts metadata file instead that contains are relevant information.
This is especially important when there is a lot of artifacts, or an archive is
a very large file.

## How do we make files downloadable

When user clicks a regular file, then download of this particular file starts.
GitLab does not extract entire artifacts archive to send a single file to user.

Instead of extracting entire file, only one file is being extracted. It is not
necessary to extract large archive, just to download a small file that is
inside.

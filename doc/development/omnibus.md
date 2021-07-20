---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# What you should know about Omnibus packages

Most users install GitLab using our Omnibus packages. As a developer it can be
good to know how the Omnibus packages differ from what you have on your laptop
when you are coding.

## Files are owned by root by default

All the files in the Rails tree (`app/`, `config/`, and so on) are owned by `root` in
Omnibus installations. This makes the installation simpler and it provides
extra security. The Omnibus reconfigure script contains commands that give
write access to the `git` user only where needed.

For example, the `git` user is allowed to write in the `log/` directory, in
`public/uploads`, and they are allowed to rewrite the `db/structure.sql` file.

In other cases, the reconfigure script tricks GitLab into not trying to write a
file. For instance, GitLab will generate a `.secret` file if it cannot find one
and write it to the Rails root. In the Omnibus packages, reconfigure writes the
`.secret` file first, so that GitLab never tries to write it.

## Code, data and logs are in separate directories

The Omnibus design separates code (read-only, under `/opt/gitlab`) from data
(read/write, under `/var/opt/gitlab`) and logs (read/write, under
`/var/log/gitlab`). To make this happen the reconfigure script sets custom
paths where it can in GitLab configuration files, and where there are no path
settings, it uses symlinks.

For example, `config/gitlab.yml` is treated as data so that file is a symlink.
The same goes for `public/uploads`. The `log/` directory is replaced by Omnibus
with a symlink to `/var/log/gitlab/gitlab-rails`.

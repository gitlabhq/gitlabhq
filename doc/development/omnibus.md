# What you should know about omnibus packages

Most users install GitLab using our omnibus packages. As a developer it can be
good to know how the omnibus packages differ from what you have on your laptop
when you are coding.

## Files are owned by root by default

All the files in the Rails tree (`app/`, `config/` etc.) are owned by 'root' in
omnibus installations. This makes the installation simpler and it provides
extra security. The omnibus reconfigure script contains commands that give
write access to the 'git' user only where needed.

For example, the 'git' user is allowed to write in the `log/` directory, in
`public/uploads`, and they are allowed to rewrite the `db/schema.rb` file.

In other cases, the reconfigure script tricks GitLab into not trying to write a
file. For instance, GitLab will generate a `.secret` file if it cannot find one
and write it to the Rails root. In the omnibus packages, reconfigure writes the
`.secret` file first, so that GitLab never tries to write it.

## Code, data and logs are in separate directories

The omnibus design separates code (read-only, under `/opt/gitlab`) from data
(read/write, under `/var/opt/gitlab`) and logs (read/write, under
`/var/log/gitlab`). To make this happen the reconfigure script sets custom
paths where it can in GitLab config files, and where there are no path
settings, it uses symlinks.

For example, `config/gitlab.yml` is treated as data so that file is a symlink.
The same goes for `public/uploads`. The `log/` directory is replaced by omnibus
with a symlink to `/var/log/gitlab/gitlab-rails`.

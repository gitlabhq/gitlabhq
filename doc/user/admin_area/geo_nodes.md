# Geo nodes admin area

For more information about setting up GitLab Geo, read the
[Geo documentation](../../gitlab-geo/README.md).

When you're done, you can navigate to **Admin area ➔ Geo nodes** (`/admin/geo_nodes`).

In the following table you can see what all these settings mean:

| Setting   | Description |
| --------- | ----------- |
| Primary   | This marks a Geo Node as primary. There can be only one primary, make sure that you first add the primary node and then all the others. |
| URL       | Your instance's full URL, in the same way it is configured in  `/etc/gitlab/gitlab.rb` (Omnibus GitLab installations) or `gitlab.yml` (source based installations). |
| Public Key | The SSH public key of the user that your GitLab instance runs on (unless changed, should be the user `git`). |

A primary node will have a star right next to it to distinguish from the
secondaries.

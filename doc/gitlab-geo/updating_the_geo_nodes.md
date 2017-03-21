# Updating the Geo nodes

In order to update the GitLab Geo nodes when a new GitLab version is released,
all you need to do is update GitLab itself:

1. Log into each node (primary and secondaries)
1. Upgrade GitLab
1. Test primary and secondary nodes, and check version in each.

---

For Omnibus GitLab installations it's a matter of updating the package:

```
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install gitlab-ee

# Centos/RHEL
sudo yum install gitlab-ee
```

For installations from source, [follow the instructions for your GitLab version]
(https://gitlab.com/gitlab-org/gitlab-ee/tree/master/doc/update).

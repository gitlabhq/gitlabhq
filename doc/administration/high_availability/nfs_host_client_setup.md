---
type: reference
---

# Configuring NFS for GitLab HA

Setting up NFS for a GitLab HA setup allows all applications nodes in a cluster
to share the same files and maintain data consistency. Application nodes in an HA
setup act as clients while the NFS server plays host.

> Note: The instructions provided in this documentation allow for setting a quick
proof of concept but will leave NFS as potential single point of failure and
therefore not recommended for use in production. Explore options such as [Pacemaker
and Corosync](http://clusterlabs.org/) for highly available NFS in production.

Below are instructions for setting up an application node(client) in an HA cluster
to read from and write to a central NFS server(host).

NOTE: **Note:**
Using EFS may negatively impact performance. Please review the [relevant documentation](nfs.md#avoid-using-awss-elastic-file-system-efs) for additional details.

## NFS Server Setup

> Follow the instructions below to set up and configure your NFS server.

### Step 1 - Install NFS Server on Host

Installing the nfs-kernel-server package allows you to share directories with the clients running the GitLab application.

```sh
apt-get update
apt-get install nfs-kernel-server
```

### Step 2 - Export Host's Home Directory to Client

In this setup we will share the home directory on the host with the client. Edit the exports file as below to share the host's home directory with the client. If you have multiple clients running GitLab you must enter the client IP addresses in line in the `/etc/exports` file.

```text
#/etc/exports for one client
/home <client-ip-address>(rw,sync,no_root_squash,no_subtree_check)

#/etc/exports for three clients
/home <client-ip-address>(rw,sync,no_root_squash,no_subtree_check) <client-2-ip-address>(rw,sync,no_root_squash,no_subtree_check) <client-3-ip-address>(rw,sync,no_root_squash,no_subtree_check)
```

Restart the NFS server after making changes to the `exports` file for the changes
to take effect.

```sh
systemctl restart nfs-kernel-server
```

NOTE: **Note:**
You may need to update your server's firewall. See the [firewall section](#nfs-in-a-firewalled-environment) at the end of this guide.

## Client/ GitLab application node Setup

> Follow the instructions below to connect any GitLab rails application node running
inside your HA environment to the NFS server configured above.

### Step 1 - Install NFS Common on Client

The nfs-common provides NFS functionality without installing server components which
we don't need running on the application nodes.

```sh
apt-get update
apt-get install nfs-common
```

### Step 2 - Create Mount Points on Client

Create a directory on the client that we can mount the shared directory from the host.
Please note that if your mount point directory contains any files they will be hidden
once the remote shares are mounted. An empty/new directory on the client is recommended
for this purpose.

```sh
mkdir -p /nfs/home
```

Confirm that the mount point works by mounting it on the client and checking that
it is mounted with the command below:

```sh
mount <host_ip_address>:/home
df -h
```

### Step 3 - Set up Automatic Mounts on Boot

Edit `/etc/fstab` on client as below to mount the remote shares automatically at boot.
Note that GitLab requires advisory file locking, which is only supported natively in
NFS version 4. NFSv3 also supports locking as long as Linux Kernel 2.6.5+ is used.
We recommend using version 4 and do not specifically test NFSv3.

```text
#/etc/fstab
165.227.159.85:/home       /nfs/home      nfs4 defaults,soft,rsize=1048576,wsize=1048576,noatime,nofail,lookupcache=positive 0 2
```

Reboot the client and confirm that the mount point is mounted automatically.

### Step 4 - Set up GitLab to Use NFS mounts

When using the default Omnibus configuration you will need to share 5 data locations
between all GitLab cluster nodes. No other locations should be shared. Changing the
default file locations in `gitlab.rb` on the client allows you to have one main mount
point and have all the required locations as subdirectories to use the NFS mount for
git-data.

```text
git_data_dirs({"default" => {"path" => "/nfs/home/var/opt/gitlab-data/git-data"}})
gitlab_rails['uploads_directory'] = '/nfs/home/var/opt/gitlab-data/uploads'
gitlab_rails['shared_path'] = '/nfs/home/var/opt/gitlab-data/shared'
gitlab_ci['builds_directory'] = '/nfs/home/var/opt/gitlab-data/builds'
```

Save the changes in `gitlab.rb` and run `gitlab-ctl reconfigure`.

## NFS in a Firewalled Environment

If the traffic between your NFS server and NFS client(s) is subject to port filtering
by a firewall, then you will need to reconfigure that firewall to allow NFS communication.

[This guide from TDLP](http://tldp.org/HOWTO/NFS-HOWTO/security.html#FIREWALLS)
covers the basics of using NFS in a firewalled environment. Additionally, we encourage you to
search for and review the specific documentation for your OS/distro and your firewall software.

Example for Ubuntu:

Check that NFS traffic from the client is allowed by the firewall on the host by running
the command: `sudo ufw status`. If it's being blocked, then you can allow traffic from a specific
client with the command below.

```sh
sudo ufw allow from <client-ip-address> to any port nfs
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

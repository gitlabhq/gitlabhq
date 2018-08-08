# Configuring NFS for GitLab HA

Setting up NFS for a GitLab HA setup allows all applications nodes in a cluster 
to share the same files and maintain data consistency. Application nodes in an HA
setup act as clients while the NFS server plays host.

> Note: The instructions provided in this documentation allow for setting a quick
proof of concept but will leave NFS as potential single point of failure and 
therefore not recommended for use in porduction. Explore options such as [Pacemaker 
and Corosync](http://clusterlabs.org/) for highly available NFS in production.

Below are instructions for setting up an application node(client) in an HA cluster
to read from and write to a central NFS server(host).


## NFS Server Setup
> Follow  the instructions below to setup and confire your NFS server.

#### Step 1 - Install NFS Server on Host

Installing the nfs-kernel-server package allows you to share directories with the clients running the GitLab application.

```
$ apt-get update
$ apt-get install nfs-kernel-server
```

#### Step 2 - Export Host's Home Directory to Client

In this setup we will share the home directory on the host with the client. Edit the exports file as below to share the host's home directory with the client. If you have multiple clients running GitLab you must enter the client IP addresses in line in the `/etc/exports` file.

```
#/etc/exports for one client
/home <client-ip-address>(rw,sync,no_root_squash,no_subtree_check)

#/etc/exports for three clients
/home <client-ip-address>(rw,sync,no_root_squash,no_subtree_check) <client-2-ip-address>(rw,sync,no_root_squash,no_subtree_check) <client-3-ip-address>(rw,sync,no_root_squash,no_subtree_check)
```

Restart the NFS server after making changes to the `exports` file for the changes 
to take effect.
```
$ systemctl restart nfs-kernel-server
```

Check that traffic from the client is allowed by the firewall on the host by running 
the command: `sudo ufw status`. If blocked you can allow traffic from between a specific 
client with the command below.

```
$ sudo ufw allow from <client-ip-address> to any port nfs
```



## Client/ GitLab application node Setup
> Follow the instructions below to connect any GitLab rails application node running
inside your HA environment to the NFS server configured above.

#### Step 1 - Install NFS Common on Client

The nfs-common provides NFS functionality without installing server components which 
we don't need running on the application nodes.

```
$ apt-get update
$ apt-get install nfs-common
```


#### Step 2 - Create Mount Points on Client

Create a directroy on the client that we can mount the shared directory from the host. 
Please note that if your mount point directory contains any files they will be hidden
once the remote shares are mounted. An empty/new directory on the client is recommended
for this purpose.
```
$ mkdir -p /nfs/home
```

Confirm that the mount point works by mounting it on the client and checking that
it is mounted with the command below:

```
$ mount <host_ip_address>:/home
$ df -h
```

#### Step 3 - Setup Automatic Mounts on Boot

Edit /etc/fstab on client as below to mount the remote shares automatically at boot. 
Note that GitLab requires advisory file locking, which is only supported natively in
NFS version 4. NFSv3 also supports locking as long as Linux Kernel 2.6.5+ is used.
We recommend using version 4 and do not specifically test NFSv3.

```
#/etc/fstab
165.227.159.85:/home       /nfs/home      nfs4 defaults,soft,rsize=1048576,wsize=1048576,noatime,nofail,lookupcache=positive 0 2
```
Reboot the client and confirm that the mount point is mounted automatically.

#### Step 4 - Setup Gitlab to Use NFS mounts

When using the default Omnibus configuration you will need to share 5 data locations
between all GitLab cluster nodes. No other locations should be shared. Changing the
default file locations in `gitlab.rb` on the client allows you to have one main mount
point and have all the required locations as subdirectories to use the NFS mount for
git-data.

```
git_data_dirs({"default" => "/nfs/home/var/opt/gitlab-data/git-data"})
user['home'] = '/nfs/home/var/opt/gitlab-data/home'
gitlab_rails['uploads_directory'] = '/nfs/home/var/opt/gitlab-data/uploads'
gitlab_rails['shared_path'] = '/nfs/home/var/opt/gitlab-data/shared'
gitlab_ci['builds_directory'] = '/nfs/home/var/opt/gitlab-data/builds'
```

Save the changes in `gitlab.rb` and run `gitlab-ctl reconfigure`.

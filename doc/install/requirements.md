# Requirements

## Operating Systems

### Supported Unix distributions

- Ubuntu
- Debian
- CentOS
- Red Hat Enterprise Linux (please use the CentOS packages and instructions)
- Scientific Linux (please use the CentOS packages and instructions)
- Oracle Linux (please use the CentOS packages and instructions)

For the installations options please see [the installation page on the GitLab website](https://about.gitlab.com/installation/).

### Unsupported Unix distributions

- OS X
- Arch Linux
- Fedora
- Gentoo
- FreeBSD

On the above unsupported distributions is still possible to install GitLab yourself.
Please see the [installation from source guide](https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/installation.md) and the [unofficial installation guides](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Unofficial-Installation-Guides) on the public wiki for more information.

### Non-Unix operating systems such as Windows

GitLab is developed for Unix operating systems.
GitLab does **not** run on Windows and we have no plans of supporting it in the near future.
Please consider using a virtual machine to run GitLab.

## Ruby versions

GitLab requires Ruby (MRI) 2.1
You will have to use the standard MRI implementation of Ruby.
We love [JRuby](http://jruby.org/) and [Rubinius](http://rubini.us/) but GitLab needs several Gems that have native extensions.

## Hardware requirements

### Storage

The necessary hard drive space largely depends on the size of the repos you want to store in GitLab but as a *rule of thumb* you should have at least as much free space as all your repos combined take up. 

If you want to be flexible about growing your hard drive space in the future consider mounting it using LVM so you can add more hard drives when you need them.

Apart from a local hard drive you can also mount a volume that supports the network file system (NFS) protocol. This volume might be located on a file server, a network attached storage (NAS) device, a storage area network (SAN) or on an Amazon Web Services (AWS) Elastic Block Store (EBS) volume.

If you have enough RAM memory and a recent CPU the speed of GitLab is mainly limited by hard drive seek times. Having a fast drive (7200 RPM and up) or a solid state drive (SSD) will improve the responsiveness of GitLab.

### CPU

- 1 core works supports up to 100 users but the application can be a bit slower due to having all workers and background jobs running on the same core
- **2 cores** is the **recommended** number of cores and supports up to 500 users
- 4 cores supports up to 2,000 users
- 8 cores supports up to 5,000 users
- 16 cores supports up to 10,000 users
- 32 cores supports up to 20,000 users
- 64 cores supports up to 40,000 users
- More users? Run it on [multiple application servers](https://about.gitlab.com/high-availability/)

### Memory

You need at least 2GB of addressable memory (RAM + swap) to install and use GitLab!
With less memory GitLab will give strange errors during the reconfigure run and 500 errors during usage.

- 512MB RAM + 1.5GB of swap is the absolute minimum but we strongly **advise against** this amount of memory. See the unicorn worker section below for more advise.
- 1GB RAM + 1GB swap supports up to 100 users but it will be slow
- **2GB RAM** is the **recommended** memory size and supports up to 100 users
- 4GB RAM supports up to 1,000 users
- 8GB RAM supports up to 2,000 users
- 16GB RAM supports up to 4,000 users
- 32GB RAM supports up to 8,000 users
- 64GB RAM supports up to 16,000 users
- 128GB RAM supports up to 32,000 users
- More users? Run it on [multiple application servers](https://about.gitlab.com/high-availability/)

Notice: The 25 workers of Sidekiq will show up as separate processes in your process overview (such as top or htop) but they share the same RAM allocation since Sidekiq is a multithreaded application. Please see the section below about Unicorn workers for information about many you need of those.

## Unicorn Workers

It's possible to increase the amount of unicorn workers and this will usually help for to reduce the response time of the applications and increase the ability to handle parallel requests.

For most instances we recommend using: CPU cores + 1 = unicorn workers.
So for a machine with 2 cores, 3 unicorn workers is ideal.

For all machines that have 1GB and up we recommend a minimum of three unicorn workers.
If you have a 512MB machine with a magnetic (non-SSD) swap drive we recommend to configure only one Unicorn worker to prevent excessive swapping.
With one Unicorn worker only git over ssh access will work because the git over HTTP access requires two running workers (one worker to receive the user request and one worker for the authorization check).
If you have a 512MB machine with a SSD drive you can use two Unicorn workers, this will allow HTTP access although it will be slow due to swapping.

To change the Unicorn workers when you have the Omnibus package please see [the Unicorn settings in the Omnibus GitLab documentation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/settings/unicorn.md#unicorn-settings).

## Database

If you want to run the database separately expect a size of about 1 MB per user.

## Redis and Sidekiq

Redis stores all user sessions and the background task queue.
The storage requirements for Redis are minimal, about 25kB per user.
Sidekiq processes the background jobs with a multithreaded process.
This process starts with the entire Rails stack (200MB+) but it can grow over time due to memory leaks.
On a very active server (10,000 active users) the Sidekiq process can use 1GB+ of memory.

## Supported web browsers

- Chrome (Latest stable version)
- Firefox (Latest released version and [latest ESR version](https://www.mozilla.org/en-US/firefox/organizations/))
- Safari 7+ (known problem: required fields in html5 do not work)
- Opera (Latest released version)
- Internet Explorer (IE) 10+ but please make sure that you have the `Compatibility View` mode disabled.
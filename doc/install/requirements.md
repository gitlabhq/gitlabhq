# Requirements

## Operating Systems

### Supported Unix distributions

- Ubuntu
- Debian
- CentOS
- RedHat Enterprise Linux
- Scientific Linux
- Oracle Linux

For the installations options please see [the installation page on the GitLab website](https://about.gitlab.com/installation/).

### Unsupported Unix distributions

- OS X
- Arch Linux
- Fedora
- Gentoo
- FreeBSD

On the above unsupported distributions is still possible to install GitLab yourself.
Please see the [manual installation guide](https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/installation.md) and the [unofficial installation guides](https://github.com/gitlabhq/gitlab-public-wiki/wiki/Unofficial-Installation-Guides) on the public wiki for more information.

### Non Unix operating systems such as Windows

GitLab is developed for Unix operating systems.
GitLab does **not** run on Windows and we have no plans of supporting it in the near future.
Please consider using a virtual machine to run GitLab.

## Ruby versions

GitLab requires Ruby (MRI) 2.0 or 2.1
You will have to use the standard MRI implementation of Ruby.
We love [JRuby](http://jruby.org/) and [Rubinius](http://rubini.us/)) but GitLab needs several Gems that have native extensions.

## Hardware requirements

### CPU

- 1 core works supports up to 100 users but the application will not be responsive
- **2 cores** is the **recommended** number of cores and supports up to 500 users
- 4 cores supports up to 2,000 users
- 8 cores supports up to 5,000 users
- 16 cores supports up to 10,000 users
- 32 cores supports up to 20,000 users
- 64 cores supports up to 40,000 users

### Memory

- 512MB is the absolute minimum but we do not recommend this amount of memory.
You will either need to configure a minimum swap of 256MB and this will only allow you to run one slow unicorn worker.
One unicorn worker will cause only git ssh access to work because the git http access requires two running workers.
It requires one worker to receive the user request and one worker for the authorization check.
Or if you use SSD you can configure 2GB of swap to use two Unicorn workers and have slow operation with http access.
- 1GB supports up to 100 users (with individual repositories under 250MB, otherwise git memory usage necessitates configuring swap space)
- **2GB** is the **recommended** memory size and supports up to 500 users
- 4GB supports up to 2,000 users
- 8GB supports up to 5,000 users
- 16GB supports up to 10,000 users
- 32GB supports up to 20,000 users
- 64GB supports up to 40,000 users

### Storage

The necessary hard drive space largely depends on the size of the repos you want to store in GitLab. But as a *rule of thumb* you should have at least twice as much free space as your all repos combined take up. You need twice the storage because [GitLab satellites](structure.md) contain an extra copy of each repo.

If you want to be flexible about growing your hard drive space in the future consider mounting it using LVM so you can add more hard drives when you need them.

Apart from a local hard drive you can also mount a volume that supports the network file system (NFS) protocol. This volume might be located on a file server, a network attached storage (NAS) device, a storage area network (SAN) or on an Amazon Web Services (AWS) Elastic Block Store (EBS) volume.

If you have enough RAM memory and a recent CPU the speed of GitLab is mainly limited by hard drive seek times. Having a fast drive (7200 RPM and up) or a solid state drive (SSD) will improve the responsiveness of GitLab.

## Database

If you want to run the database separately, the **recommended** database size is **1 MB per user**.

## Redis and Sidekiq

Redis stores all user sessions and the background task queue.
The storage requirements for Redis are minimal, about 25kB per user.
Sidekiq processes the background jobs with a multithreaded process.
This process starts with the entire Rails stack (200MB+) but it can grow over time due to memory leaks.
On a very active server (10.000 active users) the Sidekiq process can use 1GB+ of memory.

## Supported webbrowsers

- Chrome (Latest stable version)
- Firefox (Latest released version) 
- Safari 7+ (known problem: required fields in html5 do not work)
- Opera (Latest released version)
- IE 10+

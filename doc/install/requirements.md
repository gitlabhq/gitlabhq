# Operating Systems

GitLab is developed for the Linux operating system. For the installations options and instructions please see [the installation section of the readme](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/README.md#installation).

## GitLab officially supports

- Ubuntu Linux
- Debian/GNU Linux

## GitLab.com offers paid support for

- Red Hat Enterprise Linux (RHEL)
- CentOS
- Oracle Linux

## Not officially supported are

- Arch Linux
- Fedora
- Gentoo

But on the above distributions it is pretty easy to install GitLab yourself.

## Unsupported Unix Systems

There is nothing that prevents GitLab from running on other Unix operating systems.
This means you may get it to work on systems running FreeBSD or OS X.
If you want to do this, please be aware it could be a lot of work.
Please consider using a virtual machine to run GitLab.

## Other operating systems such as Windows

GitLab does **not** run on Windows and we have no plans of supporting it in the near future.
Please consider using a virtual machine to run GitLab.


# Ruby versions

GitLab requires Ruby (MRI) 1.9.3 or 2.0+.
You will have to use the standard MRI implementation of Ruby.
We love [JRuby](http://jruby.org/) and [Rubinius](http://rubini.us/)) but GitLab needs several Gems that have native extensions.


# Hardware requirements

## CPU

- 1 core works for under 100 users but the responsiveness might suffer
- **2 cores** is the **recommended** number of cores and supports up to 100 users
- 4 cores supports up to 1,000 users
- 8 cores supports up to 10,000 users

## Memory

- 512MB is too little memory, GitLab will be very slow and you will need 250MB of swap
- 768MB is the minimal memory size but we advise against this
- 1GB supports up to 100 users (with individual repositories under 250MB, otherwise git memory usage necessitates using swap space)
- **2GB** is the **recommended** memory size and supports up to 1,000 users
- 4GB supports up to 10,000 users

## Storage

The necessary hard drive space largely depends on the size of the repos you want
to store in GitLab. But as a *rule of thumb* you should have at least twice as much
free space as your all repos combined take up. You need twice the storage because [GitLab satellites](structure.md) contain an extra copy of each repo.

If you want to be flexible about growing your hard drive space in the future consider mounting it using LVM so you can add more hard drives when you need them.

Apart from a local hard drive you can also mount a volume that supports the network file system (NFS) protocol. This volume might be located on a file server, a network attached storage (NAS) device, a storage area network (SAN) or on an Amazon Web Services (AWS) Elastic Block Store (EBS) volume.

If you have enough RAM memory and a recent CPU the speed of GitLab is mainly limited by hard drive seek times. Having a fast drive (7200 RPM and up) or a solid state drive (SSD) will improve the responsiveness of GitLab.


# Supported webbrowsers

- Chrome (Latest stable version)
- Firefox (Latest released version) 
- Safari 7+ (Know problem: required fields in html5 do not work)
- Opera (Latest released version)
- IE 10+

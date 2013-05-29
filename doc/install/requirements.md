# Operating Systems

## Linux

GitLab is developed for the Linux operating system.

GitLab officially supports (recent versions of) these Linux distributions:

- Ubuntu Linux
- Debian/GNU Linux

It should also work on (though they are not officially supported):

- Arch
- CentOS
- Fedora
- Gentoo
- RedHat

## Other Unix Systems

There is nothing that prevents GitLab from running on other Unix operating
systems. This means you may get it to work on systems running FreeBSD or OS X.
**If you want to try, please proceed with caution!**

## Windows

GitLab does **not** run on Windows and we have no plans of supporting it in the
near future. Please consider using a virtual machine to run GitLab.


# Rubies

GitLab requires Ruby (MRI) 1.9.3 and several Gems with native components.
While it is generally possible to use other Rubies (like
[JRuby](http://jruby.org/) or [Rubinius](http://rubini.us/)) it might require
some work on your part.


# Hardware requirements

## CPU

We recommend a processor with **4 cores**. At a minimum you need a processor with 2 cores to responsively run an unmodified installation.

## Memory

- 512MB is too little memory, GitLab will be very slow and you will need 250MB of swap
- 768MB is the minimal memory size and supports up to 100 users
- **1GB** is the **recommended** memory size and supports up to 1,000 users
- 1.5GB supports up to 10,000 users

## Storage

The necessary hard drive space largely depends on the size of the repos you want
to store in GitLab. But as a *rule of thumb* you should have at least twice as much
free space as your all repos combined take up. You need twice the storage because [GitLab satellites](structure.md) contain an extra copy of each repo. Apart from a local hard drive you can also mount a volume that supports the network file system (NFS) protocol. This volume might be located on a file server, a network attached storage (NAS) device, a storage area network (SAN) or on an Amazon Web Services (AWS) Elastic Block Store (EBS) volume.

If you have enough RAM memory and a recent CPU the speed of GitLab is mainly limited by hard drive seek times. Having a fast drive (7200 RPM and up) or a solid state drive (SSD) will improve the responsiveness of GitLab.


# Installation troubles and reporting success or failure

If you have troubles installing GitLab following the [official installation guide](installation.md)
or want to share your experience installing GitLab on a not officially supported
platform, please follow the the [contribution guide](/CONTRIBUTING.md).

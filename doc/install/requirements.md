# Memory

We recommend you to run GitLab on a server with at least 1GB of RAM memory. You can use it with 512MB of memory but you need to setup unicorn to use only 1 worker and you need at least 200MB of swap. On a server with 1.5GB of memory you are able to support 1000+ users.


# Hard disk capacity

The necessary hard disk space largely depends on the size of the repos you want
to store in GitLab. But as a *rule of thumb* you should have at least twice as much
free space as your all repos combined take up. Apart from a local hard drive you can also mount a volume that supports the network file system (NFS) protocol. This volume might be located on a file server, a network attached storage (NAS) device, a storage area network (SAN) or on an Amazon Web Services (AWS) Elastic Block Store (EBS) volume.


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



# Installation troubles and reporting success or failure

If you have troubles installing GitLab following the official installation guide
or want to share your experience installing GitLab on a not officially supported
platform, please follow the the contribution guide (see CONTRIBUTING.md).

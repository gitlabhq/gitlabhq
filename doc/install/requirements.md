# Hardware

We recommend you to run GitLab on a server with at least 1GB RAM.

The necessary hard disk space largely depends on the size of the repos you want
to use GitLab with. But as a *rule of thumb* you should have at least as much
free space as your all repos combined take up.



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
near future.



# Rubies

GitLab requires Ruby (MRI) 1.9.3 and several Gems with native components.
While it is generally possible to use other Rubies (like
[JRuby](http://jruby.org/) or [Rubinius](http://rubini.us/)) it might require
some work on your part.



# Installation troubles and reporting success or failure

If you have troubles installing GitLab following the official installation guide
or want to share your experience installing GitLab on a not officially supported
platform, please follow the the contribution guide (see CONTRIBUTING.md).

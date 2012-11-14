## Platform requirements:

**The project is designed for the Linux operating system.**

It may work on FreeBSD and Mac OS, but we don't test our application for these systems and can't guarantee stability and full functionality.

We officially support (recent versions of) these Linux distributions:

- Ubuntu Linux
- Debian/GNU Linux

It should work on:

- Fedora
- CentOs
- RedHat

You might have some luck using these, but no guarantees:

- FreeBSD will likely work, see https://github.com/gitlabhq/gitlabhq/issues/796
- MacOS X will likely work, see https://groups.google.com/forum/#!topic/gitlabhq/5IXHbPkjKLA

GitLab does **not** run on Windows and we have no plans of making GitLab compatible.


## Hardware: 

We recommend to use server with at least 1GB RAM for gitlab instance.
Processor architectures matter.  PowerPC doesn't run V8, so it's out.  ARM, even with Debian Unstable's libv8, doesn't seem to work either.  MIPS is less supported than ARM in V8.  Right now you should probably stick to normal architectures like x86 and x64.
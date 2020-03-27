---
type: reference, howto
---

# Air-gapped (or offline) environment deployments

It is possible to run most of the GitLab security scanners when not
connected to the internet.

This document describes how to operate Secure scanners in an air-gapped or offline envionment. These instructions also apply to
self-managed installations that are secured, have security policies (e.g., firewall policies), or otherwise restricted from
accessing the full internet. These instructions are designed for physically disconnected networks,
but can also be followed in these other use cases.

## Air-gapped (or offline) environments

In this situation, the GitLab instance can be one or more servers and services that can communicate
on a local network, but with no or very restricted access to the internet. Assume anything within
the GitLab instance and supporting infrastructure (for example, a private Maven repository) can be
accessed through a local network connection. Assume any files from the internet must come in through
physical media (USB drive, hard drive, writeable DVD, etc.).

## Overview

GitLab scanners generally will connect to the internet to download the
latest sets of signatures, rules, and patches. A few extra steps are necessary
to configure the tools to function properly by using resources available on your local network.

### Container registries and package repositories

At a high-level, the security analyzers are delivered as Docker images and
may leverage various package repositories. When you run a job on
an internet-connected GitLab installation, GitLab checks the GitLab.com-hosted
container registry to check that you have the latest versions of these Docker images
and possibly connect to package repositories to install necessary dependencies.

In an air-gapped environment, these checks must be disabled so that GitLab.com is not
queried. Because the GitLab.com registry and repositories are not available,
you must update each of the scanners to either reference a different,
internally-hosted registry or provide access to the individual scanner images.

You must also ensure that your app has access to common package repositories
that are not hosted on GitLab.com, such as npm, yarn, or rubygems. Packages
from these repos can be obtained by temporarily connecting to a network or by
mirroring the packages inside your own offline network.

### Interacting with the vulnerabilities

Once a vulnerability is found, you can interact with it. Read more on how to [interact with the vulnerabilities](../index.md#interacting-with-the-vulnerabilities).

Please note that in some cases the reported vulnerabilities provide metadata that can contain external links exposed in the UI. These links might not be accessible within an air-gapped (or offline) environment.

### Scanner signature and rule updates

When connected to the internet, some scanners will reference public databases
for the latest sets of signatures and rules to check against. Without connectivity,
this is not possible. Depending on the scanner, you must therefore disable
these automatic update checks and either use the databases that they came
with and manually update those databases or provide access to your own copies
hosted within your network.

## Specific scanner instructions

Each individual scanner may be slightly different than the steps described
above. You can find more info at each of the pages below:

- [Container scanning offline directions](../container_scanning/index.md#running-container-scanning-in-an-offline-air-gapped-installation)
- [SAST offline directions](../sast/index.md#gitlab-sast-in-an-offline-air-gapped-installation)
- [DAST offline directions](../dast/index.md#running-dast-in-an-offline-air-gapped-installation)

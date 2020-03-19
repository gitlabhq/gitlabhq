---
type: reference, howto
---

# Offline deployments

This document describes how to operate Secure scanners offline.

## Overview

It is possible to run most of the GitLab security scanners when not
connected to the internet, in what is sometimes known as an offline,
limited connectivity, Local Area Network (LAN), Intranet, or "air-gap"
environment.

In this situation, the GitLab instance can be one, or more, servers and services running in a network that can talk to one another, but have zero, or perhaps very restricted access to the internet. Assume anything within the GitLab instance and supporting infrastrusture (private maven repository for example) can be accessed via local network connection. Assume any files from the internet must come in via physical media (USB drive, hard drive).

GitLab scanners generally will connect to the internet to download the
latest sets of signatures, rules, and patches. A few extra steps are necessary
to configure the tools to not do this and to still function properly.

### Container registries and package repositories

At a high-level, each of the security analyzers are delivered as Docker
containers and reference various package repositories. When you run a job on
an internet-connected GitLab installation, GitLab checks the GitLab.com-hosted
container registry and package repositories to ensure that you have
the latest versions.

In an air-gapped environment, this must be disabled so that GitLab.com is not
queried. Because the GitLab.com registry and repositories are not available,
you must update each of the scanners to either reference a different,
internally-hosted registry or provide access to the individual scanner images.

You must also ensure that your app has access to common package repos
that are not hosted on GitLab.com, such as npm, yarn, or rubygems. Packages
from these repos can be obtained by temporarily connecting to a network or by
mirroring the packages inside your own offline network.

### Scanner signature and rule updates

When connected to the internet, some scanners will reference public databases
for the latest sets of signatures and rules to check against. Without connectivity,
this is not possible. Depending on the scanner, you must therefore disable
these automatic update checks and either use the databases that they came
with or manually update those databases.

## Specific scanner instructions

Each individual scanner may be slightly different than the steps described
above. You can find more info at each of the pages below:

- [Container scanning offline directions](../container_scanning/index.md#running-container-scanning-in-an-offline-air-gapped-installation)
- [SAST offline directions](../sast/index.md#gitlab-sast-in-an-offline-air-gapped-installation)
- [DAST offline directions](../dast/index.md#running-dast-in-an-offline-air-gapped-installation)

---
type: reference, howto
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Offline environments

It's possible to run most of the GitLab security scanners when not connected to the internet.

This document describes how to operate Secure Categories (that is, scanner types) in an offline
environment. These instructions also apply to self-managed installations that are secured, have
security policies (for example, firewall policies), or are otherwise restricted from accessing the
full internet. GitLab refers to these environments as _offline environments_. Other common names
include:

- Air-gapped environments
- Limited connectivity environments
- Local area network (LAN) environments
- Intranet environments

These environments have physical barriers or security policies (for example, firewalls) that prevent
or limit internet access. These instructions are designed for physically disconnected networks, but
can also be followed in these other use cases.

## Defining offline environments

In an offline environment, the GitLab instance can be one or more servers and services that can
communicate on a local network, but with no or very restricted access to the internet. Assume
anything within the GitLab instance and supporting infrastructure (for example, a private Maven
repository) can be accessed through a local network connection. Assume any files from the internet
must come in through physical media (USB drive, hard drive, writeable DVD, etc.).

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

In an offline environment, these checks must be disabled so that GitLab.com isn't
queried. Because the GitLab.com registry and repositories are not available,
you must update each of the scanners to either reference a different,
internally-hosted registry or provide access to the individual scanner images.

You must also ensure that your app has access to common package repositories
that are not hosted on GitLab.com, such as npm, yarn, or Ruby gems. Packages
from these repos can be obtained by temporarily connecting to a network or by
mirroring the packages inside your own offline network.

### Interacting with the vulnerabilities

Once a vulnerability is found, you can interact with it. Read more on how to
[interact with the vulnerabilities](../index.md#interacting-with-the-vulnerabilities).

Please note that in some cases the reported vulnerabilities provide metadata that can contain
external links exposed in the UI. These links might not be accessible within an offline environment.

### Suggested Solutions for vulnerabilities

The [suggested solutions](../index.md#solutions-for-vulnerabilities-auto-remediation) feature
(auto-remediation) is available for Dependency Scanning and Container Scanning, but may not work
depending on your instance's configuration. We can only suggest solutions, which are generally more
current versions that have been patched, when we are able to access up-to-date registry services
hosting the latest versions of that dependency or image.

### Scanner signature and rule updates

When connected to the internet, some scanners will reference public databases
for the latest sets of signatures and rules to check against. Without connectivity,
this is not possible. Depending on the scanner, you must therefore disable
these automatic update checks and either use the databases that they came
with and manually update those databases or provide access to your own copies
hosted within your network.

## Specific scanner instructions

Each individual scanner may be slightly different than the steps described
above. You can find more information at each of the pages below:

- [Container scanning offline directions](../container_scanning/index.md#running-container-scanning-in-an-offline-environment)
- [SAST offline directions](../sast/index.md#running-sast-in-an-offline-environment)
- [DAST offline directions](../dast/index.md#running-dast-in-an-offline-environment)
- [License Compliance offline directions](../../compliance/license_compliance/index.md#running-license-compliance-in-an-offline-environment)
- [Dependency Scanning offline directions](../dependency_scanning/index.md#running-dependency-scanning-in-an-offline-environment)

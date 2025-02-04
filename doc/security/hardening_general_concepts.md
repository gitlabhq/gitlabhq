---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Hardening - General Concepts
---

General hardening guidelines are outlined in the [main hardening documentation](hardening.md).

The following documentation summarises some of the underlying philosophies for GitLab instance hardening.
While we reference GitLab, in many cases they can actually apply to all computer systems.

## Layered security

If there are two ways to implement security, both ways should be implemented instead of
just one. A quick example is account security:

- Use a long, complex, and unique password for the account.
- Implement a second factor to the authentication process for added security.
- Use a hardware token as a second factor.
- Lock out an account (for at least a fixed amount of time) for failed authentication attempts.
- An account that is unused for a specific time frame should be disabled, enforce this
  with either automation or regular audits.

Instead of using only one or two items on the list, use as many as possible. This
philosophy can apply to other areas besides account security - it should be applied to
every area possible.

## Eliminate security through obscurity

Security through obscurity means that one does not discuss certain
elements of a system, service, or process because of a fear that a potential attacker
might use those details to formulate an attack. Instead, the system should be secured to
the point that details about its configuration could be public and the system would still
be as secure as it could be. In essence, if an attacker learned about the details of the
configuration of a computer system it would not give them an advantage. One of the
downsides of security through obscurity is that it can lead to a potential false sense of
security by the administrator of the system who thinks the system is more secure than it
actually is.

An example of this is running a service on a non-standard TCP port. For example the
default SSH daemon port on servers is TCP port 22, but it is possible to configure the
SSH daemon to run on another port such as TCP port 2222. The administrator who configured
this might think it increases the security of the system, however it is quite common for
an attacker to port scan a system to discover all open ports, allowing for quick discovery
of the SSH service, and eliminating any perceived security advantage.

As GitLab is an open-core system and all of the configuration options are well documented
and public information, the idea of security through obscurity goes against a
GitLab core value - transparency. These hardening recommendations are intended to be
public, to help eliminate any security through obscurity.

## Attack Surface Reduction

GitLab is a large system with many components. As a general rule for security, it helps
if unused systems are disabled. This eliminates the
available "attack surface" a potential attacker can use to strike. This can also have
the added advantage of increasing available system resources as well.

As an example, there is a process on a system that fires up and checks queues for input every
five minutes, querying multiple sub-processes while performing its checks. If you are not
using that process, there is no reason to have it configured and it should be disabled.
If an attacker has figured out an attack vector that uses this process, the attacker might exploit it despite your organization not using it. As a general
rule, you should disable any service not being used.

## External systems

In larger but still hardened deployments, multiple nodes are often used to
handle the load your GitLab deployment
requires. In those cases, use a combination of external, operating system, and
configuration options for firewall rules. Any option that uses restrictions should only
be opened up enough to allow the subsystem to function. Whenever possible use TLS
encryption for network traffic.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

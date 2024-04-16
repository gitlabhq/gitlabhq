---
stage: Verify
group: Hosted Runners
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab-hosted runners

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

You can run your CI/CD jobs on GitLab.com and GitLab Dedicated using GitLab-hosted runners to seamlessly build, test and deploy
your application on different environments.

## Hosted runners for GitLab.com

These runners fully integrated with GitLab.com and are enabled by default for all projects, with no configuration required.
Your jobs can run on:

- [Hosted runners on Linux](hosted_runners/linux.md)
- [GPU-enabled hosted runners](hosted_runners/gpu_enabled.md)
- [Hosted runners on Windows](hosted_runners/windows.md) ([Beta](../../policy/experiment-beta-support.md#beta))
- [Hosted runners on macOS](hosted_runners/macos.md) ([Beta](../../policy/experiment-beta-support.md#beta))

For more information about the cost factor applied to the machine type based on size, see [cost factor](../../ci/pipelines/cicd_minutes.md#gitlab-hosted-runner-costs).
The number of minutes you can use on these runners depends on the [maximum number of units of compute](../pipelines/cicd_minutes.md)
in your [subscription plan](https://about.gitlab.com/pricing/).

[Untagged](../../ci/runners/configure_runners.md#control-jobs-that-a-runner-can-run) jobs automatically run in containers
on the `small` Linux runners.

The objective is to make 90% of CI/CD jobs start executing in 120 seconds or less. The error rate should be less than 0.5%.

## Hosted runners for GitLab Dedicated

These runners are created on-demand for GitLab Dedicated customers and are fully integrated with your GitLab Dedicated instance.
Your jobs can run on:

- [Hosted runners on Linux](hosted_runners/linux.md) ([Beta](../../policy/experiment-beta-support.md#beta))

## How hosted runners for GitLab.com work

When you use hosted runners:

- Each of your jobs runs in a newly provisioned VM, which is dedicated to the specific job.
- The VM is active only for the duration of the job and immediately deleted. This means that any changes that your job makes to the virtual machine will not be available to a subsequent job.
- The virtual machine where your job runs has `sudo` access with no password.
- The storage is shared by the operating system, the image with pre-installed software, and a copy of your cloned repository.
  This means that the available free disk space for your jobs to use is reduced.

NOTE:
Jobs handled by hosted runners on GitLab.com **time out after 3 hours**, regardless of the timeout configured in a project.

## Release cycle for GitLab-hosted runners

We aim to update to the latest version of [GitLab Runner](https://docs.gitlab.com/runner/#gitlab-runner-versions) within a week of its release.

You can find all GitLab Runner breaking changes under [Deprecations and removals](../../update/deprecations.md).

## Security for GitLab-hosted runners

Hosted runners on Linux and Windows for GitLab.com run on Google Compute Platform.
The [Google Infrastructure Security Design Overview whitepaper](https://cloud.google.com/docs/security/infrastructure/design/resources/google_infrastructure_whitepaper_fa.pdf)
provides an overview of how Google designs security into its technical infrastructure.
The GitLab [Trust Center](https://about.gitlab.com/security/) and
[GitLab Security Compliance Controls](https://handbook.gitlab.com/handbook/security/security-assurance/security-compliance/sec-controls/)
pages provide an overview of the security and compliance controls that govern the GitLab-hosted runners.

The following section provides an overview of the additional built-in layers that harden the security of the GitLab Runner build environment.

### Security of CI job execution

A dedicated temporary runner VM hosts and runs each CI job. On hosted runners for GitLab.com, two CI jobs never run on the same VM.

In this example, there are three jobs in the project's pipeline. Therefore, there are three temporary VMs used to run that pipeline, or one VM per job.

![Job isolation](img/build_isolation.png)

The build job ran on `runner-ns46nmmj-project-43717858`, test job on `f131a6a2runner-new2m-od-project-43717858` and deploy job on `runner-tmand5m-project-43717858`.

GitLab sends the command to remove the temporary runner VM to the Google Compute API immediately after the CI job completes. The [Google Compute Engine hypervisor](https://cloud.google.com/blog/products/gcp/7-ways-we-harden-our-kvm-hypervisor-at-google-cloud-security-in-plaintext)
takes over the task of securely deleting the virtual machine and associated data.

### Network security of CI job VMs

- Firewall rules only allow outbound communication from the temporary VM to the public internet.
- Inbound communication from the public internet to the temporary VM is not allowed.
- Firewall rules do not permit communication between VMs.
- The only internal communication allowed to the temporary VMs is from the runner manager.

## Supported image lifecycle

Hosted runners on macOS and Windows can only run jobs on supported images. You cannot bring your own image. Supported images have the following lifecycle:

- Beta
- Generally Available
- Deprecated

### Beta

To gather feedback on an image prior to making the image Generally Available (GA) and to address
any issues, new images are released as Beta. Any jobs running on Beta images are not
covered by the service-level agreement. If you use Beta images, you can provide feedback
by creating an issue.

### Generally Available

A Generally Available (GA) image is released after the image completes a Beta phase
and is considered suitable for general use. To become GA, the
image must fulfill the following requirements:

- Successful completion of a Beta phase by resolving all reported significant bugs
- Compatibility of installed software with the underlying OS

Jobs running on GA images are covered by the defined service-level agreement. Over time, these images are deprecated.

### Deprecated

A maximum of two Generally Available (GA) images are supported at a time. After a new GA image is released,
the oldest GA image becomes deprecated. A deprecated image is no longer
updated and is deleted after 3 months in accordance with the [deprecation guidelines](../../development/deprecation_guidelines/index.md).

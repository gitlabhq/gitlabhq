---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# VM instances and images for SaaS runners on macOS **(PREMIUM SAAS)**

When you use SaaS runners on macOS:

- Each of your jobs runs in a newly provisioned VM, which is dedicated to the specific job.
- The VM is active only for the duration of the job and immediately deleted. This means that any changes that your job makes to the virtual machine will not be available to a subsequent job.
- The virtual machine where your job runs has `sudo` access with no password.

NOTE:
Each time you run a job that requires tooling or dependencies not available in the base image, those items must be added to the newly provisioned build VM. That process will likely increase the total job duration.

## VM types

GitLab SaaS provides macOS build machines on Apple servers with Intel x86-64 processors.
The expectation is that virtual machines running on the Apple M1 chip will be available in the second half of 2022.

At this time there is only one available machine type offered, `shared-macos-amd64`.

| Instance type | vCPUS | Memory (GB) |
| --------- | --- | ------- |
|  `shared-macos-amd64` | 4 | 10 |

## VM images

### Image update policy

GitLab expects to release new images based on this cadence:

macOS updates:

- **For new OS versions:** When Apple releases a new macOS version to developers (like macOS `12`), GitLab will plan to release an image based on the OS within the next 30 business days. The image is considered `beta` and the contents of the image (including tool versions) are subject to change until the first patch release (`12.1`). The long-term name will not include `beta` (for example, `macos-12-xcode-13`), so customers are moved automatically out of beta over time. GitLab will try to minimize breaking changes between the first two minor versions but makes no guarantees. Tooling often gets critical bug fixes after the first public release of an OS version.

- **After the first patch release (`12.1`):**
  - The image moves to `maintenance` mode. The tools GitLab builds into the image with Homebrew and asdf are frozen. GitLab continues making Xcode updates, security updates, and any non-breaking changes deemed necessary.
  - The image for the previous OS version (`11`) moves to `frozen` mode. GitLab then does only unavoidable changes: security updates, runner version upgrades, and setting the production password.

Both macOS and Xcode follow a yearly release cadence. As time goes on, GitLab increments their versions synchronously (meaning we build macOS 11 with Xcode 12, macOS 12 with Xcode 13, and so on).

### Available images

You can execute your build on one of the following images.
You specify this image in your `.gitlab-ci.yml` file.

Each image is running a specific version of macOS and Xcode.

| VM image                  | Status | Included software  |
|---------------------------|--------|--------------------|
| `macos-10.13-xcode-7`       | `frozen` | <https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/main/toolchain/high-sierra.yml>  |
| `macos-10.13-xcode-8`       | `frozen` | <https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/main/toolchain/high-sierra.yml>  |
| `macos-10.13-xcode-9`       | `frozen` | <https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/main/toolchain/high-sierra.yml>  |
| `macos-10.14-xcode-10`      | `frozen` | <https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/main/toolchain/mojave.yml>       |
| `macos-10.15-xcode-11`      | `frozen` | <https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/main/toolchain/catalina.yml>     |
| `macos-11-xcode-12`         | `frozen` | <https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/main/toolchain/big-sur.yml>      |
| `macos-12-xcode-13`         | `maintenance` | <https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/main/toolchain/monterey.yml> |
| `macos-12-xcode-14`         | `maintenance` | <https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/macstadium/orka/-/blob/main/toolchain/monterey.yml> |
| (none, awaiting macOS 13)        | `beta` |       |

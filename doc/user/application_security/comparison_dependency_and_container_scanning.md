---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dependency Scanning compared to Container Scanning
---

GitLab offers both [Dependency Scanning](dependency_scanning/_index.md) and
[Container Scanning](container_scanning/_index.md) to ensure coverage for all of these
dependency types. To cover as much of your risk area as possible, we encourage you to use all of our
security scanning tools:

- Dependency Scanning analyzes your project and tells you which software dependencies,
  including upstream dependencies, have been included in your project, and what known
  risks the dependencies contain.
- Container Scanning analyzes your containers and tells you about known risks in the operating
  system's (OS) packages.

The following table summarizes which types of dependencies each scanning tool can detect:

| Feature                                                                                      | Dependency Scanning | Container Scanning              |
|----------------------------------------------------------------------------------------------|---------------------|---------------------------------|
| Identify the manifest, lock file, or static file that introduced the dependency              | **{check-circle}**  | **{dotted-circle}**             |
| Development dependencies                                                                     | **{check-circle}**  | **{dotted-circle}**             |
| Dependencies in a lock file committed to your repository                                     | **{check-circle}**  | **{check-circle}** <sup>1</sup> |
| Binaries built by Go                                                                         | **{dotted-circle}** | **{check-circle}** <sup>2</sup> |
| Dynamically-linked language-specific dependencies installed by the Operating System          | **{dotted-circle}** | **{check-circle}**              |
| Operating system dependencies                                                                | **{dotted-circle}** | **{check-circle}**              |
| Language-specific dependencies installed on the operating system (not built by your project) | **{dotted-circle}** | **{check-circle}**              |

1. Lock file must be present in the image to be detected.
1. [Report language-specific findings](container_scanning/_index.md#report-language-specific-findings) must be enabled, and binaries must be present in the image to be detected.

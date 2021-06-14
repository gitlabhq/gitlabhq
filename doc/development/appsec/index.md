---
stage: Secure, Protect
group: all
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, dev, reference
---

# Application Security development documentation

Development guides that are specific to the stages that work on Application Security features are listed here.

Please go to [Application Security](../../user/application_security/index.md) if you are looking for documentation on how to use those features.

## Namespaces

Application Security code in the Rails monolith is organized into the following namespaces, which generally follows
the feature categories in the [Secure](https://about.gitlab.com/stages-devops-lifecycle/secure/) and [Protect](https://about.gitlab.com/stages-devops-lifecycle/protect/) stages.

- `AppSec`: shared code.
  - `AppSec::ContainerScanning`: Container Scanning code.
  - `AppSec::Dast`: DAST code.
  - `AppSec::DependencyScanning`: Dependency Scanning code.
  - `AppSec::Fuzzing::API`: API Fuzzing code.
  - `AppSec::Fuzzing::Coverage`: Coverage Fuzzing code.
  - `AppSec::Fuzzing`: Shared fuzzing code.
  - `AppSec::LicenseCompliance`: License Compliance code.
  - `AppSec::Sast`: SAST code.
  - `AppSec::SecretDetection`: Secret Detection code.
  - `AppSec::VulnMgmt`: Vulnerability Management code.

Most AppSec code does not conform to these namespace guidelines. When developing, make an effort
to move existing code into the appropriate namespace whenever possible.

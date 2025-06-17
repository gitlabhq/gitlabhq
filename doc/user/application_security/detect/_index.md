---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Detect
description: Vulnerability detection and result evaluation.
---

Detect vulnerabilities in your project's repository and your application's behavior throughout the
software development lifecycle. During development, automated scanning provides immediate contextual
feedback, enabling developers to address potential vulnerabilities early. After development, you can
schedule or run security scanning manually, to identify new risks. A vulnerability report collates
all relevant details, enabling efficient vulnerability management.

To get the best from GitLab vulnerability detection it's important to understand:

- What aspects of your application or repository are scanned.
- What determines which scanners run.
- When vulnerability detection occurs.
- How to evaluate the results of vulnerability detection.

## Detection coverage

Scan your project's repository and test your application's behavior for vulnerabilities:

- Repository scanning can detect vulnerabilities in your project's repository. Coverage includes
  your application's source code, also the libraries and container images it's dependent on.
- Behavioral testing of your application and its API can detect vulnerabilities that occur only at
  runtime.

### Repository scanning

Your project's repository may contain source code, dependency declarations, and infrastructure
definitions. Repository scanning can detect vulnerabilities in each of these.

Repository scanning tools include:

- Static Application Security Testing (SAST): Analyze source code for vulnerabilities.
- Infrastructure as Code (IaC) scanning: Detect vulnerabilities in your application's infrastructure
  definitions.
- Secret detection: Detect and block secrets from being committed to the repository.
- Dependency scanning: Detect vulnerabilities in your application's dependencies and container
  images.

### Behavioral testing

Behavioral testing requires a deployable application to test for known vulnerabilities and
unexpected behavior.

Behavioral testing tools include:

- Dynamic Application Security Testing (DAST): Test your application for known attack vectors.
- API security testing: Test your application's API for known attacks and vulnerabilities to input.
- Coverage-guided fuzz testing: Test your application for unexpected behavior.

## Scanner selection

Security scanners are enabled for a project by either:

- Adding the scanner's CI/CD template to the `.gitlab-ci.yml` file, either directly or by using
  AutoDevOps.
- Enforcing the scanner by using a scan execution policy, pipeline execution policy, or
  compliance framework. This enforcement can be applied directly to the project or inherited from
  the project's parent group.

## Vulnerability detection

Vulnerability detection runs in a CI/CD pipeline when:

- Code changes are committed and pushed to the repository.
- A pipeline is run manually.
- Started manually, for example, a DAST on-demand scan.
- Scheduled by a scan execution policy.

Vulnerability detection runs by default in branch pipelines, and in merge request pipelines if it's
enabled in the CI/CD template.

- On branch pipelines:

  - Detect vulnerabilities on feature branches before you merge them into the default branch.
  - Investigate and respond to new vulnerabilities in your long-lived branches.
  - Run periodic, scheduled scans of your projects to identify new vulnerabilities, even if development has stopped.

- On merge request pipelines:

  - Enforce additional approval requirements to manage the risk of new vulnerabilities.
  - Keep your project open to contributions while securing it against adversarial changes.

View the results of security scanning in either the branch pipeline or the merge request.
Vulnerabilities detected in the default branch are listed in the vulnerability report.

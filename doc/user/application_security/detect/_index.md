---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Detect
---

Detect vulnerabilities in your project's repository and your application's behavior. Enable GitLab
security tools for your project's entire lifecycle, starting before the first commit.

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

## Lifecycle coverage

You should enable vulnerability detection from before the first commit through to when your
application can be deployed and run. Early detection has many benefits, including easier and quicker
remediation.

All GitLab application security scanning tools can be run in a CI/CD pipeline, triggered by code
changes. Security scans can also be run on a schedule, outside the context of code changes, and some
can be run manually. It's important to also perform detection outside the CI/CD pipeline because
risks can arise outside the context of code changes. For example, a newly-discovered vulnerability
in a dependency might be a risk to any application using it.

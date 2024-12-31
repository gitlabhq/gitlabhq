---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Detect

Detect vulnerabilities throughout your application's development lifecycle. GitLab scans your
application's code and tests its behavior for vulnerabilities.

## Detection coverage

Scan your repository's content and application's behavior for vulnerabilities:

- Repository scanning can detect vulnerabilities in your project's repository. Coverage includes
  your application's source code, also the libraries and container images it's dependent on.
- Behavioral testing of your application and its API can detect vulnerabilities that occur only at
  runtime.

For more details, see [Security scanning](security_scanning.md).

## Lifecycle coverage

You should enable vulnerability detection from before the first commit through to when your
application can be deployed and run. Early detection has many benefits, including easier and quicker
remediation.

All GitLab application security scanning tools can be run in a CI/CD pipeline, triggered by code
changes. Security scans can also be run on a schedule, outside the context of code changes, and some
can be run manually. It's important to also perform detection outside the CI/CD pipeline because
risks can arise outside the context of code changes. For example, a newly-discovered vulnerability
in a dependency might be a risk to any application using it.

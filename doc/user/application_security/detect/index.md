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
- Testing the behavior of your application and its API can detect vulnerabilities that occur only at
  runtime.

### Repository scanning

Your application's repository may contain its source code, dependency declarations, and
Infrastructure as Code definitions. Repository scanning can detect vulnerabilities in each of these.

Repository scanning tools include:

- Static Application Security Testing: Analyze source code for vulnerabilities.
- Infrastructure as Code (IaC) scanning: Detect vulnerabilities in your application's deployment
  environment.
- Secret detection: Detect and block secrets being committed to the repository.
- Dependencies: Detect vulnerabilities in your application's dependencies and container images.

### Behavioral testing

Behavioral testing requires a deployable application to test for known vulnerabilities and
unexpected behavior.

Behavioral testing tools include:

- Dynamic Application Security Testing: Test your application for known attack vectors.
- API security: Test your application's API for known attacks and vulnerabilities to input.
- Coverage-guided fuzz testing: Test your application for unexpected behavior.

## Lifecycle coverage

You should enable vulnerability detection from before the first commit through to when your
application can be deployed and run. Early detection has many benefits, including easier and quicker
remediation.

All GitLab application security scanning tools can be run in a CI/CD pipeline, triggered by code
changes. Security scans can also be run on a schedule, outside the context of code changes, and some
can be run manually. It's important to perform detection outside the CI/CD pipeline because risks
arise outside the context of code changes. For example, a newly-discovered vulnerability in a
dependency may be a risk to any application using it.

---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Security scanning

Scan your repository's content and application's behavior for vulnerabilities. GitLab security
scanners scan your application's code and tests its behavior for vulnerabilities.

## Repository scanning

Your application's repository may contain its source code, dependency declarations, and
Infrastructure as Code definitions. Repository scanning can detect vulnerabilities in each of these.

Repository scanning tools include:

- Static Application Security Testing: Analyze source code for vulnerabilities.
- Infrastructure as Code (IaC) scanning: Detect vulnerabilities in your application's deployment
  environment.
- Secret detection: Detect and block secrets being committed to the repository.
- Dependency scanning: Detect vulnerabilities in your application's dependencies and container
  images.

## Behavioral testing

Behavioral testing requires a deployable application to test for known vulnerabilities and
unexpected behavior.

Behavioral testing tools include:

- Dynamic Application Security Testing: Test your application for known attack vectors.
- API security testing: Test your application's API for known attacks and vulnerabilities to input.
- Coverage-guided fuzz testing: Test your application for unexpected behavior.

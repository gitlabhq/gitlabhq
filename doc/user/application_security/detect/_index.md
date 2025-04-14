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

## Early detection

Enable GitLab application security scanning tools from before the first commit. Early detection
provides benefits such as easier, quicker, and cheaper remediation, compared to detection later in
the software development lifecycle. GitLab provides developers immediate feedback of security
scanning, enabling them to address vulnerabilities early.

Security scans:

- Run automatically in the CI/CD pipeline when developers commit changes. Vulnerabilities detected
  in a feature branch are listed, enabling you to investigate and address them before they're merged
  into the default branch. For more details, see
  [Security scan results](security_scan_results.md).
- Can be scheduled or run manually to detect vulnerabilities. When a project is idle and no changes
  are being made, security scans configured to run in a CI/CD pipeline are not run. Risks such as
  newly-discovered vulnerabilities can go undetected in this situation. Running security scans
  outside a CI/CD pipeline helps address this risk. For more details, see
  [Scan execution policies](../policies/scan_execution_policies.md).

## Prevention

Security scanning in the pipeline can help minimize the risk of vulnerabilities in the default
branch:

- Extra approval can be enforced on merge requests according to the results of pipeline
  security scanning. For example, you can require that a member of the security team **also**
  approve a merge request if one or more critical vulnerabilities are detected in the code
  changes. For more details, see
  [Merge request approval policies](../policies/merge_request_approval_policies.md).
- Secret push protection can prevent commits being pushed to GitLab if they contain secret
  information - for example, a GitLab personal access token.

## Vulnerability management workflow

Vulnerabilities detected in the default branch are listed in the vulnerability report. To address
these vulnerabilities, follow the vulnerability management workflow:

- Triage: Evaluate vulnerabilities to identify those that need immediate attention.
- Analyze: Examine details of a vulnerability to determine if it can and should be remediated.
- Remediate: Resolve the root cause of the vulnerability, reduce the associated risks, or both.

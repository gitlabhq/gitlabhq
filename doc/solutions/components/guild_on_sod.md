---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: GitLab Tutorial Guild on Separation of Duties
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

This document provides an overview of GitLab Separation of Duties (SoD) solution through Role-Based Access Control (RBAC). The solution ensures compliance with security principles by preventing any single individual from having complete control over critical processes in the software development lifecycle.

## Getting Started

### Access the Solution Component

1. Obtain the invitation code from your account team.
1. Access the solution component from [the solution component webstore](https://cloud.gitlab-accelerator-marketplace.com) by using your invitation code.

## What is Separation of Duties 

Separation of Duties is a fundamental security principle that ensures no single individual has complete control over critical processes. In software development, SoD prevents unauthorized or accidental code releases into production environments by distributing responsibilities among different roles and teams.

The GitLab approach to implementing SoD through Role-Based Access Control (RBAC) provides:

- Clear separation between development and deployment roles
- Protected environments to control deployment access
- Protected branches to prevent unauthorized code modifications
- Merge request approval policies to enforce code review
- Built-in audit capabilities for compliance verification

## Key Components of GitLab SoD Solution

### Role-Based Access Control (RBAC)

TRBAC forms the framework for implementing and enforcing SoD. It governs permissions and responsibilities across the platform, ensuring compliance with the principles of least privilege. Through RBAC, organizations can:

- Implement holistic user management with granular role-based controls
- Assign roles with the least privileged access principles
- Maintain visibility into roles and permissions through audit/reporting

### Feature Branch Workflow

The feature branch workflow supports SoD by defining clear boundaries between development activities and production deployment:

- Development teams can modify code and trigger test pipelines in feature branches
- Security teams manage approval policies for quality gates
- Merge requests require independent review from non-authors

### Protected Branches & Environments

The default branch play a key role in enforcing SoD:

- Protected environments restrict deployments to designated teams
- Deployer teams have permission to execute deployments but are restricted from modifying source code
- Protected branches prevent unauthorized merges and pushes

### Audit & Compliance Capabilities

GitLab provides robust audit capabilities to support compliance requirements:

- Automatically generated release evidence
- Event logging for default branch activities

### Prerequisites 

To fully implement the GitLab SoD solution, organizations need:

- GitLab Ultimate License
- Properly configured CI/CD pipelines
- User groups with a clear separation between development and deployment roles

### Additional Resources

For more information on GitLab SoD implementation, refer to:

- [GitLab Role & Permissions Documentation](../../user/permissions.md)
- [Protected Branches Documentation](../../user/project/repository/branches/protected.md)
- [Protected Environments Documentation](../../ci/environments/protected_environments.md)
- [Merge Request Approvals Documentation](../../user/project/merge_requests/approvals/_index.md)

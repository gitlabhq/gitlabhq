---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: PostgreSQL upgrade timeline
---

GitLab implements annual PostgreSQL database version upgrades to maximize operational efficiency and capitalize on enhanced functionality. This critical infrastructure update impacts multiple teams and requires coordination to ensure minimal disruption to our production environment.

This document establishes a comprehensive framework outlining the responsibilities of each team involved in the PostgreSQL upgrade process at GitLab. By clearly defining ownership of specific tasks and establishing a timeline for completion, we aim to standardize our approach, mitigate risks, and ensure successful implementation across all database environments.

The timeline detailed in this document serves as a roadmap for our PostgreSQL upgrade journey, ensuring that all necessary steps are properly sequenced and executed. By following this structured approach, we can deliver the best possible experience to our customers, minimizing downtime and maintaining the high level of service they expect from GitLab.

The following sections detail the specific responsibilities assigned to each team, along with the recommended sequence of activities. This framework will serve as the standard operating procedure for all future PostgreSQL version upgrades.

## Timeline and Team Responsibilities

### January: Team Awareness and Preparation

**Owner: All Cross-functional Teams**

Teams: [Database Operations Team](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/data-access/database-operations/), [Database Frameworks Team](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/data-access/database-framework/),
Build Team, [Durability Team](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/data-access/durability/), [Geo Team](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/tenant-scale/geo/),
[Dedicated Team](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/gitlab-dedicated/)

This foundational phase initiates the mobilization of resources, with all teams conducting strategic planning for the forthcoming PostgreSQL version implementation.

Team Tasks: All teams to prepare their work and to allocate team resources for the upcoming PostgreSQL update.

### February-April: GitLab.com Platform Compatibility Assurance

#### Strategic Upgrade Cycle Planning

Analyze and propose the new PostgreSQL version for [GitLab](https://gitlab.com/).

**Owner: Database Operations Team**

Team Tasks:

1. Formulate a high-level summary of the implementation strategy;
1. Document the purpose and expected benefits for GitLab in the upgrade epic, following the [New Project template](https://gitlab.com/gitlab-com/gl-infra/data-access/team/-/blob/main/.gitlab/issue_templates/New_Project.md);
1. Invite stakeholders and cross-functional teams to collaborate and comment directly in the Epic;

#### PostgreSQL test compatibility and performance

Ensure the compatibility of [GitLab.com](https://gitlab.com) to the new proposed PostgreSQL version.

**Owner: Database Frameworks Team**

Team Tasks:

1. Integrate the new PostgreSQL version into nightly specs;
1. Ensure the compatibility with the new PostgreSQL version;
1. Document and communicate PostgreSQL inconsistencies, technical findings, and nightly specs results through an issue linked to the upgrade epic;
1. Document and communicate to cross-functional teams that comprehensive testing confirms GitLab is fully functional with the new PostgreSQL version in the upgrade epic;

#### Cloud managed PostgreSQL test compatibility

Ensure the compatibility of [GitLab Dedicated](https://about.gitlab.com/dedicated/) cloud-managed PostgreSQL to the stable version used by GitLab.com.

**Owner: Dedicated Team**

Team Tasks:

1. Review available RDS and CloudSQL upgrade documentation for the stable supported PostgreSQL version;
1. Test the upgrade with the current stable PostgreSQL version for AWS and GPC;
1. Document the rollout schedule and customer communication plan. Link the rollout schedule in the upgrade epic;

#### Geo Upgrade Preparation

**Owner: Geo Team**

Team Tasks: Verify the upgrade procedure for the PostgreSQL new version on Geo installations;

### May-July: Bundled Postgres Compatibility Assurance

Validates the bundled PostgreSQL upgrade based on [GitLab.com](https://gitlab.com) production-stable version. This usually happens on a major release only, around May every year.

#### Validate bundled PostgreSQL upgrades for supported deployment methods

**Owner: Build Team**

Team Tasks:

1. Conduct deployment-specific testing to ensure PostgreSQL compatibility with Docker, Kubernetes, and Omnibus
1. Test auto-upgrade paths thoroughly;

#### Provide optional support for bundled PostgreSQL upgrade

**Owner: Build Team**

Team Tasks:

1. Document the upgrade procedures for different deployment methods in the installation guide;
1. Existing installations will gain access to a validated upgrade pathway via the `pg-upgrade` utility tool, allowing for planned and controlled PostgreSQL upgrades;

### August-October: Pre-prod Preparation and GitLab.com Upgrade

Upgrade [GitLab.com](https://gitlab.com) environments.

**Owner: Database Operations Team**

Team Tasks:

1. Configure the [Database upgrade DDL lock](database_upgrade_ddl_lock.md) to prevent DDL operations from conflicting with the upgrade process;
1. Upgrade two STG databases and two PRD databases, typically CI + SEC or Registry. The specific databases may vary year to year;
1. Upgrade the remaining two STG databases and two PRD databases. The specific databases may vary from year to year;
1. Communicate to cross-functional teams that GitLab has successfully transitioned to a new PostgreSQL version;

### November-January: Stable Release Integration

Proceed with updating the tooling based on the stable production version of [GitLab.com](https://gitlab.com).

This upgrade migrates customers to the new PostgreSQL version, thereby discontinuing support for the current version they are using.

#### Auto upgrade self-managed single node Omnibus instances

**Owner: Build Team**

Team Tasks: Auto-upgrade the PostgreSQL version for non-high availability environments;

#### Make the new version of bundled PostgreSQL as default

**Owner: Build Team**

Team Tasks:

1. The stable bundled PostgreSQL version will become the default database version for all new installations;
1. Monitor customer adoption and address any issues that arise;
1. Document any related issues in the upgrade epic;

#### Cloud managed PostgreSQL update

Proceed with [GitLab Dedicated](https://about.gitlab.com/dedicated/) cloud-managed upgrade.

**Owner: Dedicated Team**

Team Tasks:

1. Upgrade UATs: USPubSec and Commercial Dedicated environments upgraded;
1. Upgrade production tenants: Production USPubSec and Commercial Dedicated environments upgraded;
1. Code cleanup and Post Rollout: Update the default PostgreSQL version for Instrumentor;

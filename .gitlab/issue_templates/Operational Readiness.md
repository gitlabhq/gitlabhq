<!-- title format: Operational Readiness Review - {`new component name`}

When we add a new component to our platform, we should keep in mind the non-functional requirements and operational needs we are adding to our platform. While
we want to move quickly, we also want to ensure:

- We know what is being added.
- If we can operate it.
- The it meets our general legal, compliance, and operational standards.

-->

## Links
<!-- Provide Links to the Epic, issue, handbook page, and/or blueprint. -->

## Type of new component

<!-- List the type of new component from one of following values:

- New third party SaaS service
- New data store (that is not a SaaS service)
- New service
- New software dependency
- New programming language
- New development and testing framework
 -->

## Review process

To help us to make concise and sustainable decision when converting the prototype to a product, it is highly recommended that the PM and EM start with a
self assessment with this checklist, and then engage the appropriate groups and/or departments to review if anything in doubt. This is **NOT** a gating
process, rather a friendly checklist to ensure the success of the new component.

The review should be quick and with the least number of steps. The review will likely have 2 DRIs as reviewers for each component to ensure we can move
quickly and handle any out of office (OOO).

## Checklist

Complete common and the appropriate checklists per the type of new component mentioned above (Skip any item if not applicable).

### Common

- [ ] Definition and Goals
  - [ ] What the component does and what values it provides from the external and internal customer's perspective?
  - [ ] Is any existing component capable for the same use case? If so, why is the new component required?
  - [ ] What is the usage estimation in both .com and self-managed?
  - [ ] Who are the development and operation DRI groups?

- [ ] Legal and Security
  - [ ] Are you conducting a legal and compliance review with legal department?
  - [ ] Are you conducting an in-depth security review of the component with security department?
  - [ ] What type of license do they use?
  - [ ] What is the data classification this component will process?
- [ ] Support
   - [ ] Have you involved the Customer Support Team by drafting a [Support Readiness Issue](https://gitlab.com/gitlab-com/support/support-team-meta/-/issues/new?issuable_template=Support%20Readiness)? And complete it before releasing to customers.

- [ ] Business
  - [ ] Margin impact - (sheet to be created)
  - [ ] What is the estimated cost of the component and associated support including infrastructure operations if any?

- [ ] Architecture and Design
  - [ ] What are the dependencies between existing GitLab services and this component?
  - [ ] How does adding this component affect the typical GitLab installation procedure?
  - [ ] What changes are expected to GitLab Upgrade (Zero Downtime and Downtime) and Downgrade process with the component?
  - [ ] How does the component work with GitLab Geo setup? What is the process for Failover and Recovery?
  - [ ] How does the new component fit into existing GitLab Backup and Restore process?

- [ ] Operational Readiness
  - [ ] Complete the [production readiness review](https://about.gitlab.com/handbook/engineering/infrastructure/production/readiness/).
  - [ ] What is the infrastructure requirement for each Reference Architecture type?
  - [ ] How does the component affect estimated costs for each Reference Architecture type? Estimations for specs, storage, network with information about growth rate of stored data.
  - [ ] What is the support and documentation for monitoring, observability, and logging mechanisms?
  - [ ] What is the migration process for the new feature?
  - [ ] What is the process to roll back to the old configuration?

- [ ] Scalability and Performance
  - [ ] Does the component support auto-scaling? If not, what would be the guidance to handle sudden load increases?
  - [ ] What is the expected load for the feature?
  - [ ] Does it have horizontal and vertical scaling capabilities?
  - [ ] Are there recommendations and guidance for when the component should be scaled up and down?
  - [ ] Can the component be collocated with other existing nodes and how does it affect the performance?
  - [ ] What are the key performance indicators (KPIs) for this component, and how will they be monitored?

- [ ] Integration and Compatibility
  - [ ] Is this SaaS only, or will it also be supported for Self-Managed and Dedicated?
  - [ ] Is the feature supported in all GitLab distributions - Linux package (Omnibus), GitLab Charts and GitLab Operator?
  - [ ] For Dedicated integrations, what is the disaster recovery plan for this component? (backup strategy, replication, RTO/RPO, failover procedures)

- [ ] Maintenance and Support
  - [ ] As the owner, are you confident to manage and maintain the new component end to end (E2E)? Consider the following:
    <details><summary>Typical considerations</summary>
    - [ ] Talent pool, e.g. existing engineers, maintainers, and future hiring opportunities. <br />
    - [ ] Testing, e.g. end-to-end, dependencies, performance. <br />
    - [ ] Operational considerations, e.g. observability, hosting knowledge, etc. <br />
    </details>

### New GitLab service

- [ ] Legal and Security
  - [ ] Is there any specific security standard and compliance required before deploying to production? If so, what needs to be done?
- [ ] Architecture
  - [ ] Complete `New data store, third party dependency` checklist as well if a new dependency is used
  - [ ] Complete `New programming language, development, and testing framework` checklist as well if a new programming language, development, and/or testing framework is used
  - [ ] Complete `New database` checklist as well if a new database is added

### New data store, third party dependency

- [ ] Legal and Security
  - [ ] What is the [classification](https://about.gitlab.com/handbook/security/data-classification-standard.html#data-classification-levels) of data stored in the data store?
  - [ ] Have they got any security standards to meet our and/or our customers' requirements? (i.e. FIPS and/or Fed-RAMP) If not, what needs to be done?
- [ ] Development, Testing, Deployment, and Operation
  - [ ] What integration types do they provide, e.g. SaaS and/or self-hosting?
    - [ ] For SaaS - what is the cloud provider compatibility for the component? Specific considerations for major cloud providers (AWS, GCP, Azure)
    - [ ] For self-managed - What are results of Distribution group review for the dependency check, package size, OS support and other packaging analysis?
  - [ ] Is rate limit possible?
  - [ ] What is the cadence of version upgrades?
  - [ ] What is their defect fix and security patch turnaround time?

### New programming language, development, and testing framework

- [ ] Is there a mature ecosystem that provides tooling (profiling, debugging, etc.) and 3rd party libraries?

### New database

  - [ ] Can the database be collocated beside `main`? Including when Geo replication is enabled?
  - [ ] What impact a separate database will have for a customer in terms of costs and maintenance?
  - [ ] What are the expected performance requirements for the database?
  - [ ] How is the database and its dependencies (users, extensions) created?
  - [ ] What is upgrade support for Omnibus?
  - [ ] How are migrations handled?


/assign <pm/em>
/label <tbd>
/cc <tbd>
/confidential

---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Kubernetes Agent user stories **(PREMIUM SELF)**

The [personas in action](https://about.gitlab.com/handbook/marketing/strategic-marketing/roles-personas/#user-personas)
for the Kubernetes Agent are:

- [Sasha, the Software Developer](https://about.gitlab.com/handbook/marketing/strategic-marketing/roles-personas/#sasha-software-developer).
- [Allison, the Application Operator](https://about.gitlab.com/handbook/marketing/strategic-marketing/roles-personas/#allison-application-ops).
- [Priyanka, the Platform Engineer](https://about.gitlab.com/handbook/marketing/strategic-marketing/roles-personas/#priyanka-platform-engineer).

[Devon, the DevOps engineer](https://about.gitlab.com/handbook/marketing/strategic-marketing/roles-personas/#devon-devops-engineer)
is intentionally excluded here, as DevOps is more of a role than a persona.

There are various workflows to support, so some user stories might seem to contradict each other. They don't.

## Software Developer user stories

<!-- vale gitlab.FirstPerson = NO -->

- As a Software Developer, I want to push my code, and move to the next development task,
  to work on business applications.
- As a Software Developer, I want to set necessary dependencies and resource requirements
  together with my application code, so my code runs fine after deployment.

<!-- vale gitlab.FirstPerson = YES -->

## Application Operator user stories

<!-- vale gitlab.FirstPerson = NO -->

- As an Application Operator, I want to standardize the deployments used by my teams,
  so I can support all teams with minimal effort.
- As an Application Operator, I want to have a single place to define all the deployments,
  so I can assure security fixes are applied everywhere.
- As an Application Operator, I want to offer a set of predefined templates to
  Software Developers, so they can get started quickly and can deploy to production
  without my intervention, and I am not a bottleneck.
- As an Application Operator, I want to know exactly what changes are being deployed,
  so I can fulfill my SLAs.
- As an Application Operator, I want deep insights into what versions of my applications
  are running and want to be able to debug them, so I can fix operational issues.
- As an Application Operator, I want application code to be automatically deployed
  to staging environments when new versions are available.
- As an Application Operator, I want to follow my preferred deployment strategy,
  so I can move code into production in a reliable way.
- As an Application Operator, I want review all code before it's deployed into production,
  so I can fulfill my SLAs.
- As an Application Operator, I want to be notified before deployment when new code needs my attention,
  so I can review it swiftly.

<!-- vale gitlab.FirstPerson = YES -->

## Platform Engineer user stories

<!-- vale gitlab.FirstPerson = NO -->

- As a Platform Engineer, I want to restrict customizations to preselected values
  for Operators, so I can fulfill my SLAs.
- As a Platform Engineer, I want to allow some level of customization to Operators,
  so I don't become a bottleneck.
- As a Platform Engineer, I want to define all deployments in a single place, so
  I can assure security fixes are applied everywhere.
- As a Platform Engineer, I want to define the infrastructure by code, so my
  infrastructure management is testable, reproducible, traceable, and scalable.
- As a Platform Engineer, I want to define various policies that applications must
  follow, so that I can fulfill my SLAs.
- As a Platform Engineer, I want approved tooling for log management and persistent storage,
  so I can scale, secure, and manage them as needed.
- As a Platform Engineer, I want to be alerted when my infrastructure differs from
  its definition, so I can make sure that everything is configured as expected.

<!-- vale gitlab.FirstPerson = YES -->

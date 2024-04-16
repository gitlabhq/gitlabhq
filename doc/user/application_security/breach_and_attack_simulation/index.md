---
stage: none
group: unassigned
info: This is a GitLab Incubation Engineering program. No technical writer assigned to this group.
---

<!--- start_remove The following content will be removed on remove_date: '2024-08-15' -->

# Breach and Attack Simulation (deprecated)

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Experiment

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/430966) in GitLab 16.9 and will be removed in 17.0. This change is a breaking change.

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/402784) in GitLab 15.11 as an Incubating feature.
> - [Included](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119981) in the `Security/BAS.latest.gitlab-ci.yml` in GitLab 16.0.

DISCLAIMER:
Breach and Attack Simulation is a set of incubating features being developed by the Incubation Engineering Department and is subject to significant changes over time.

Breach and Attack Simulation (BAS) uses additional security testing techniques to assess the risk of detected vulnerabilities and prioritize the remediation of exploitable vulnerabilities.

This feature is an [Experiment](../../../policy/experiment-beta-support.md). For feedback, bug
reports, and feature requests, see the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/404809).

WARNING:
Only run BAS scans against test servers. Testing attacker behavior can lead to modification or loss of data.

## Extend Dynamic Application Security Testing (DAST)

You can simulate attacks with [DAST](../dast/index.md) to detect vulnerabilities.
By default, DAST active checks match an expected response, or determine by response
time whether a vulnerability was exploited.

To enable BAS extended DAST scanning for your application, use the `dast_with_bas` job defined
in the GitLab BAS CI/CD template file. Updates to the template are provided with GitLab
upgrades, allowing you to benefit from any improvements and additions.

1. Include the appropriate CI/CD template:

   - [`BAS.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/BAS.latest.gitlab-ci.yml):
     Latest version of the BAS template. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119981)
     in GitLab 16.0).

   WARNING:
   The latest version of the template may include breaking changes. Use the
   stable template unless you need a feature provided only in the latest template.

   For more information about template versioning, see the [CI/CD documentation](../../../development/cicd/templates.md#latest-version).

1. Choose one of the following options for running BAS extended DAST scans:

   - [Enable a separate BAS extended DAST job](#enable-a-separate-bas-extended-dast-job)

     - You're not using the latest DAST template yet.
     - Continue using a stable version of the DAST security analyzer image for DAST scans.
     - Create a duplicate `dast_with_bas` job which extends your existing DAST job configuration.

   - [Extend an existing DAST job](#extend-an-existing-dast-job)
     - You're already using the latest DAST template rather than the stable template.
     - Extend your existing DAST job to include the latest DAST security analyzer image tag from the Breach and Attack Simulation SEG.

1. Setup a callback server to [enable callback attacks](#enable-callback-attacks).

### Enable a separate BAS extended DAST job

To maintain a separate DAST job while testing the BAS extended DAST image:

1. Add a `dast` stage to your GitLab CI/CD stages configuration.

   ```yaml
     stages:
       - build
       - test
       - deploy
       - dast
   ```

1. Set the `DAST_WEBSITE` [CI/CD variable](../../../ci/yaml/index.md#variables).

   ```yaml
     dast_with_bas:
       variables:
         DAST_WEBSITE: http://yourapp
   ```

### Extend an existing DAST job

To enable Breach and Attack Simulation features inside of an existing DAST job:

1. Follow the steps in [Create a DAST CI/CD job](../dast/browser/configuration/enabling_the_analyzer.md#create-a-dast-cicd-job).

1. Extend DAST to using the [extends](../../../ci/yaml/yaml_optimization.md#use-extends-to-reuse-configuration-sections) keyword to your DAST job's configuration:

   ```yaml
   dast:
     extends: .dast_with_bas
   ```

1. Disable the `dast_with_bas` job included in the BAS template by setting `DAST_BAS_DISABLED`:

   ```yaml
   variables:
     DAST_BAS_DISABLED: "true"
   ```

### Enable callback attacks

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
As with all projects, the items mentioned on this page are subject to change or delay.
The development, release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.

Perform Out-of-Band Application Security Testing (OAST) for certain [active checks](../dast/browser/checks/index.md#active-checks).

1. Extend the `.dast_with_bas_using_services` job configuration using the [extends](../../../ci/yaml/yaml_optimization.md#use-extends-to-reuse-configuration-sections) keyword:

   ```yaml
   dast:
     extends: .dast_with_bas_using_services

   dast_with_bas:
     extends:
       # NOTE: extends overwrites rather than merges so dast must be included in this list.
       - dast
       - .dast_with_bas_using_services
   ```

1. Use a [!reference tag](../../../ci/yaml/yaml_optimization.md#reference-tags) to pull in the default `callback` service container in your `services`.

   ```yaml
     services:
       # NOTE: services overwrites rather than merges so it must be referenced to merge.
       - !reference [.dast_with_bas_using_services, services]
       # NOTE: Link your application container to the dast job and
       # access it with the hostname yourapp. See more about Docker services at
       # https://docs.gitlab.com/ee/user/application_security/dast/#docker-services
       - name: $CI_REGISTRY_IMAGE
         alias: yourapp
   ```

You can also manually enable callback attacks by making sure to:

1. Set the `DAST_FF_ENABLE_BAS` [CI/CD variable](../dast/browser/configuration/variables.md) to `true`.
1. Enable both the application being tested and callback service container using [services](../../../ci/services/index.md).
1. Enable container-to-container networking [making the callback service accessible](../../../ci/services/index.md#connecting-services) in the job.
1. Set `DAST_BROWSER_CALLBACK` to include `Address:$YOUR_CALLBACK_URL` key/value pair where the callback service is accessible to the Runner/DAST container.

<!--- end_remove -->

---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Learn how to configure dependency scanning using SBOM, detect vulnerabilities in your project dependencies, and understand which vulnerabilities are reachable in your code.
title: 'Tutorial: Set up dependency scanning by using SBOM'
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com

{{< /details >}}

Dependency scanning can automatically detect security vulnerabilities in your software dependencies
before they're committed to your main branch. While you develop and test your applications,
you can identify and address vulnerable dependencies early in your workflow. The dependency
analyzer generates a Software Bill of Materials (SBOM) of your application's dependencies, then
compares them against advisories to identify vulnerabilities. Static reachability analysis enhances
the vulnerability risk assessment data by identifying which of the vulnerable dependencies your
application imports.

This tutorial shows you how to do the following:

- Create an example JavaScript application.
- Set up dependency scanning by using the new SBOM analyzer, including static reachability analysis.
- Triage vulnerabilities in the application's dependencies.
- Remediate a vulnerability by updating a dependency.

> [!note]
> This tutorial uses outdated dependencies with known vulnerabilities to demonstrate detection.

## Before you begin

Before you begin this tutorial, make sure you have the following:

- GitLab.com account and access to create a new project
- Git
- Node.js (version 14 or later)

## Create example application files

The first task in this tutorial is to set up the example project, including the example vulnerable
application, and configure CI/CD.

1. On GitLab.com, create a blank project using the default values.
1. Clone the project to your local machine:

   ```plaintext
   git clone https://gitlab.com/<your-username>/<project-name>.git
   cd <project-name>
   ```

1. On your local machine, create the following files in your project:

   - `.gitlab-ci.yml`
   - `package.json`
   - `app.js`

   Filename: `.gitlab-ci.yml`

   ```yaml
   stages:

   - build
   - test

   include:
   - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
       inputs:
         enable_static_reachability: true
   ```

   Filename: `package.json`

   ```json
   {
      "name": "tutorial-ds-sbom-scanning-with-sra",
      "version": "1.0.0",
      "main": "index.js",
      "dependencies": {
         "axios": "0.21.1",
         "fastify": "2.14.1"
      }
   }
   ```

   Filename: `app.js`

   ```javascript
   const axios = require('axios');

   async function runDemo() {
     console.log("Starting Reachability Demo...");
     try {
       // This specific call creates the reachability link
       const response = await axios.get('<https://gitlab.com>');
       console.log("Request successful, status:", response.status);
     } catch (err) {
       console.log("Demo request finished.");
     }
   }

   runDemo();
   ```

1. Create the lock file.

   ```plaintext
   npm install
   ```

1. Commit and push these files to your project:

   ```plaintext
   git add .gitlab-ci.yml app.js package.json package-lock.json
   git commit -m "Set up files for tutorial"
   git push
   ```

1. On GitLab.com, go to **Build** > **Pipelines** and confirm that the latest pipeline completed
   successfully.

   In the pipeline, dependency scanning runs and does the following:

   - Generates an SBOM from your dependencies. You can [download the SBOM](#optional-download-sbom).
   - Scans the dependencies listed in the SBOM against known vulnerability advisories.
   - Enriches the results with static reachability analysis to identify which dependencies are
     imported in your code.

## Triage and analyze vulnerabilities

Dependency scanning should have detected vulnerabilities in the application's dependencies. The next
task is to triage and analyze those vulnerabilities.

> [!note]
> To streamline this tutorial, all changes are committed to the `main` branch. In a real
> environment, you would run dependency scanning in development branches to detect vulnerabilities
> before the branch is merged.

In this tutorial, we'll triage and analyze only one vulnerability. We selected this vulnerability
because it's reachable and has a clear remediation path.

1. On GitLab.com, go to **Secure** > **Vulnerability report**.

   You should see multiple vulnerabilities listed in the report. As at the time of writing, 12
   vulnerabilities were detected.

   > For the purposes of this tutorial, we'll focus on only one vulnerability. In a real
   > environment, you would analyze all the
   > [risk assessment data available](../user/application_security/vulnerabilities/risk_assessment_data.md)
   > and apply your organization's risk management framework.
1. Select the search filter and from the dropdown list select **Reachability**, then select
   **Yes**.

   The vulnerability report now lists only vulnerabilities that are reachable. The vulnerability
   counts by severity are updated to match the new filter.

   > In this example you declared the following direct dependencies in `package.json`:
   >
   > - `axios` - version 0.21.1
   > - `fastify` - version 2.14.1
   >
   > Dependency scanning detected vulnerabilities in both `fastify` and `axios`, and their
   > transitive dependencies. However, only `axios` is imported by the example application, so
   > vulnerabilities in `fastify` are not reachable. When you apply the reachability filter,
   > vulnerabilities in `fastify` are excluded from the vulnerability report.

1. Select the description of CVE-2026-25223 - "Fastify's Content-Type header tab character allows
   body validation bypass".

   1. View this vulnerability's details.

      The vulnerability is of high severity and has a **Reachable** value of **Yes**, meaning that
      the dependency is imported by the application. That makes it riskier than other high severity
      vulnerabilities that aren't reachable.

   1. Scroll down to the **Solution** section.

      For this vulnerability, the solution is to upgrade this dependency's version.

To streamline this tutorial, we'll apply the stated solution. In a real environment, you would
follow your company's vulnerability analysis processes to verify this solution before applying it.

## Remediate the vulnerability

Now that we have a solution, we'll go ahead and upgrade the `fastify` dependency.

1. On your local machine, update version `package.json` file to the `fastify` version listed in the
   vulnerability's details page - 5.7.2.

   ```json
   {
      "name": "tutorial-ds-sbom-scanning-with-sra",
      "version": "1.0.0",
      "main": "index.js",
      "dependencies": {
         "axios": "0.21.1",
         "fastify": "5.7.2"
      }
   }
   ```

1. Update the lock file.

   ```plaintext
   npm install
   ```

   This updates the `package-lock.json` file with the new dependency version.
1. Create a new branch and commit these changes:

   ```plaintext
   git checkout -b update-dependencies
   git add package.json package-lock.json
   git commit -m "Update version of fastify"
   git push -u origin update-dependencies
   ```

1. On GitLab.com, go to **Code** > **Merge requests** and select **Create merge request**.
1. On the **New merge request** page, scroll to the bottom and select **Create merge request**.

   After the merge request pipeline completes, wait for the security results widget to appear.
   Processing the security report typically takes a minute or two.
1. In the security results widget, select **Show details** ({{< icon name="chevron-lg-down" >}}).

   The security results widget states that the changes in the merge request fix 7 vulnerabilities,
   including the vulnerability you triaged and analyzed.
1. Select **Merge**.

   Wait for the merge request to be merged.
1. Go to **Secure** > **Vulnerability report**.

   Vulnerability CVE-2026-25223 is no longer listed because the vulnerability report defaults to
   listing only vulnerabilities that are **Still detected**. To see the vulnerability details, you can change the
   status filter.

In this tutorial you've learned how to do the following:

- Set up dependency scanning with SBOM and static reachability analysis
- Detect and triage vulnerabilities in your dependencies
- Remediate vulnerabilities by updating dependencies
- Verify that vulnerabilities are fixed

## Optional: Download SBOM

To download the SBOM generated by the dependency scanning analyzer:

1. Go to **Build** > **Pipelines**.
1. Select the most recent pipeline.
1. Select the **dependency-scanning** job.
1. In the **Job artifacts** section, select **Download**.

The job's artifacts download as file `artifacts.zip`. Unzip it to access the SBOM file
`gl-sbom-npm-npm.cdx.json`.

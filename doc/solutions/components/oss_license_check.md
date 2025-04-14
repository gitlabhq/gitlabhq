---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: OSS License Check
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Getting Started

### Download the Solution Component

1. Obtain the invitation code from your account team.
1. Download the solution component from [the solution component webstore](https://cloud.gitlab-accelerator-marketplace.com) by using your invitation code.

## OSS Library License Check - GitLab Policy

This guide helps you implement a License Compliance Policy for your projects based on the Blue Oak Council license ratings. The policy will automatically require approval for any dependencies using licenses not included in the Blue Oak Council's Gold, Silver, and Bronze tiers.

You can also [keep your license list up to date](#keeping-your-license-list-up-to-date) with the provided Python script `update_licenses.py` that fetches the latest approved licenses.

## Overview

The OSS Library License Check provides:

- Automated license scanning for all dependencies in your projects
- Pre-configured policy to allow licenses rated [Gold](https://blueoakcouncil.org/list#gold), [Silver](https://blueoakcouncil.org/list#silver), and [Bronze](https://blueoakcouncil.org/list#bronze) by the Blue Oak Council
- Approval workflow for any licenses not in these tiers

## Prerequisites

- GitLab Ultimate tier
- Administrator access to your GitLab instance or group
- [Dependency scanning](../../user/application_security/dependency_scanning/_index.md) enabled for your projects (this can optionally be enabled and enforced for all projects of a specified scope by following the [Dependency Scanning Setup](#setting-up-dependency-scanning-from-scratch) instructions below)

## Implementation Guide

This guide covers two main scenarios:

1. [Setting up from scratch](#setting-up-from-scratch-using-the-ui) (no existing security policy project)
   - [Setting up Dependency Scanning](#setting-up-dependency-scanning-from-scratch)
   - [Setting up License Compliance](#setting-up-license-compliance-from-scratch)
1. [Adding to an existing policy](#adding-to-an-existing-policy) (existing security policy project)

### Setting up from scratch (using the UI)

If you don't have a security policy project yet, you'll need to create one and then set up both dependency scanning and license compliance policies.

#### Setting up Dependency Scanning from scratch

1. First, identify which group you want to apply this policy to. This will be the highest group level where the policy can be applied (you can include or exclude projects within this group).
1. Navigate to that group's **Secure > Policies** page.
1. Click on **New policy**.
1. Select **Scan execution policy**.
1. Enter a name for your policy (e.g., "Dependency Scanning Policy").
1. Enter a description (e.g., "Enforces dependency scanning to get a list of OSS licenses used").
1. Set the **Policy scope** by selecting either "All projects in this group" (and optionally set exceptions) or "Specific projects" (and select the projects from the dropdown).
1. Under the **Actions** section, select "Dependency scanning" instead of "Secret Detection" (default).
1. Under the **Conditions** section, you can optionally change "Triggers:" to "Schedules:" if you want to run the scan on a schedule instead of at every commit.
1. Click **Create policy**.

#### Setting up License Compliance from scratch

After setting up dependency scanning, follow these steps to set up the license compliance policy:

1. Navigate back to the same group's **Secure > Policies** page.
1. Click on **New policy**.
1. Select **Merge request approval policy**.
1. Enter a name for your policy (e.g., "OSS Compliance Policy").
1. Enter a description (e.g., "Block any licenses that are not included in the Blue Oak Council's Gold, Silver, or Bronze tiers").
1. Set the **Policy scope** by selecting either "All projects in this group" (and optionally set exceptions) or "Specific projects" (and select the projects from the dropdown).
1. Under the **Rules** section, click the "Select scan type" dropdown and select **License Scan**.
1. Set the target branches (default is all protected branches).
1. Change the "Status is:" dropdown to **Newly detected** or **Pre-existing** (depending on whether you want to enforce the policy only on new dependencies or also on existing ones).
1. **IMPORTANT**: Change the "License is:" dropdown from the default "Matching" to **Except** (this ensures the policy works correctly to block non-approved licenses).
1. Scroll down to the **Actions** section and set the number of required approvals.
1. On the "Choose approver type" dropdown, select the users, groups, or roles that should provide approval (you can add multiple approver types in the same rule by clicking "Add new approver").
1. Configure the "Override project approval settings" section and change the default settings as needed.
1. Scroll back to the top of the page and click `.yaml mode`.
1. In the YAML editor, locate the `license_types` section and replace it with the complete list of approved licenses from the [Complete Policy Configuration](#complete-policy-configuration) section. The section will look something like this:

```yaml
rules:
  - type: license_finding
    match_on_inclusion_license: false
    license_types:
    # Replace this section with the full list of licenses from the Complete Policy Configuration section
    - MIT License
    - Apache License 2.0
    # etc...
```

1. Click **Create policy**.

### Adding to an existing policy

If you already have a security policy project but don't have dependency and/or license compliance policies:

1. Navigate to your group's Security policy project.
1. Navigate to the `policy.yml` file in `.gitlab/security-policies/`.
1. Click on **Edit** > **Edit single file**.
1. Add the `scan_execution_policy` and `approval_policy` sections from the configuration below.
1. Make sure to:
   - Maintain the existing YAML structure
   - Place these sections at the same level as other top-level sections
   - Set `user_approvers_ids` and/or `group_approvers_ids` and/or `role_approvers` (only one is needed)
     - Replace `YOUR_USER_ID_HERE` or `YOUR_GROUP_ID_HERE` with appropriate user/group IDs (ensure you paste the user/group IDs e.g. 1234567 and NOT the usernames)
   - Replace `YOUR_PROJECT_ID_HERE` if you'd like to exclude any projects from the policy (ensure you paste the project IDs e.g. 1234 and NOT the project names/paths)
   - Set `approvals_required: 1` to the number of approvals you want to require
   - Modify the `approval_settings` section as needed (anything set to `true` will override project approval settings)
1. Click **Commit changes**, and commit to a new branch. Select **Create a merge request for this change** so that the policy change can be merged.

## Complete Policy Configuration

For reference, here is the complete policy configuration:

```yaml
scan_execution_policy:
- name: License scan policy
  description: Enforces dependency scanning to get a list of OSS licenses used, in
    order to remain compliant with OSS usage guidance.
  enabled: true
  policy_scope:
    projects:
      excluding:
      - id: YOUR_PROJECT_ID_HERE
      - id: YOUR_PROJECT_ID_HERE
  rules:
  - type: pipeline
    branch_type: all
  actions:
  - scan: dependency_scanning
  skip_ci:
    allowed: true
    allowlist:
      users: []
approval_policy:
- name: OSS Compliance Policy
  description: |-
    Block any licenses that are not included in the Blue Oak Council's Gold, Silver, or Bronze tiers.
    https://blueoakcouncil.org/list
  enabled: true
  policy_scope:
    projects:
      excluding:
      - id: YOUR_PROJECT_ID_HERE
      - id: YOUR_PROJECT_ID_HERE
  rules:
  - type: license_finding
    match_on_inclusion_license: false
    license_types:
    - BSD-2-Clause Plus Patent License
    - Amazon Digital Services License
    - Apache License 2.0
    - Adobe Postscript AFM License
    - BSD 1-Clause License
    - BSD 2-Clause "Simplified" License
    - BSD 2-Clause FreeBSD License
    - BSD 2-Clause NetBSD License
    - BSD 2-Clause with Views Sentence
    - Boost Software License 1.0
    - DSDP License
    - Educational Community License v1.0
    - Educational Community License v2.0
    - hdparm License
    - ImageMagick License
    - Intel ACPI Software License Agreement
    - ISC License
    - Linux Kernel Variant of OpenIB.org license
    - MIT License
    - MIT License Modern Variant
    - MIT testregex Variant
    - MIT Tom Wu Variant
    - Microsoft Public License
    - Mulan Permissive Software License, Version 1
    - Mup License
    - PostgreSQL License
    - Solderpad Hardware License v0.5
    - Spencer License 99
    - Universal Permissive License v1.0
    - Xerox License
    - Xfig License
    - BSD Zero Clause License
    - Academic Free License v1.1
    - Academic Free License v1.2
    - Academic Free License v2.0
    - Academic Free License v2.1
    - Academic Free License v3.0
    - AMD's plpa_map.c License
    - Apple MIT License
    - Academy of Motion Picture Arts and Sciences BSD
    - ANTLR Software Rights Notice
    - ANTLR Software Rights Notice with license fallback
    - Apache License 1.0
    - Apache License 1.1
    - Artistic License 2.0
    - Bahyph License
    - Barr License
    - bcrypt Solar Designer License
    - BSD 3-Clause "New" or "Revised" License
    - BSD with attribution
    - BSD 3-Clause Clear License
    - Hewlett-Packard BSD variant license
    - Lawrence Berkeley National Labs BSD variant license
    - BSD 3-Clause Modification
    - BSD 3-Clause No Nuclear License 2014
    - BSD 3-Clause No Nuclear Warranty
    - BSD 3-Clause Open MPI Variant
    - BSD 3-Clause Sun Microsystems
    - BSD 4-Clause "Original" or "Old" License
    - BSD 4-Clause Shortened
    - BSD-4-Clause (University of California-Specific)
    - BSD Source Code Attribution
    - bzip2 and libbzip2 License v1.0.5
    - bzip2 and libbzip2 License v1.0.6
    - Creative Commons Zero v1.0 Universal
    - CFITSIO License
    - Clips License
    - CNRI Jython License
    - CNRI Python License
    - CNRI Python Open Source GPL Compatible License Agreement
    - Cube License
    - curl License
    - eGenix.com Public License 1.1.0
    - Entessa Public License v1.0
    - Freetype Project License
    - fwlw License
    - Historical Permission Notice and Disclaimer - Fenneberg-Livingston variant
    - Historical Permission Notice and Disclaimer - sell regexpr variant
    - HTML Tidy License
    - IBM PowerPC Initialization and Boot Software
    - ICU License
    - Info-ZIP License
    - Intel Open Source License
    - JasPer License
    - libpng License
    - PNG Reference Library version 2
    - libtiff License
    - LaTeX Project Public License v1.3c
    - LZMA SDK License (versions 9.22 and beyond)
    - MIT No Attribution
    - Enlightenment License (e16)
    - CMU License
    - enna License
    - feh License
    - MIT Open Group Variant
    - MIT +no-false-attribs license
    - Matrix Template Library License
    - Mulan Permissive Software License, Version 2
    - Multics License
    - Naumen Public License
    - University of Illinois/NCSA Open Source License
    - Net-SNMP License
    - NetCDF license
    - NICTA Public Software License, Version 1.0
    - NIST Software License
    - NTP License
    - Open Government Licence - Canada
    - Open LDAP Public License v2.0 (or possibly 2.0A and 2.0B)
    - Open LDAP Public License v2.0.1
    - Open LDAP Public License v2.1
    - Open LDAP Public License v2.2
    - Open LDAP Public License v2.2.1
    - Open LDAP Public License 2.2.2
    - Open LDAP Public License v2.3
    - Open LDAP Public License v2.4
    - Open LDAP Public License v2.5
    - Open LDAP Public License v2.6
    - Open LDAP Public License v2.7
    - Open LDAP Public License v2.8
    - Open Market License
    - OpenSSL License
    - PHP License v3.0
    - PHP License v3.01
    - Plexus Classworlds License
    - Python Software Foundation License 2.0
    - Python License 2.0
    - Ruby License
    - Saxpath License
    - SGI Free Software License B v2.0
    - Standard ML of New Jersey License
    - SunPro License
    - Scheme Widget Library (SWL) Software License Agreement
    - Symlinks License
    - TCL/TK License
    - TCP Wrappers License
    - UCAR License
    - Unicode License Agreement - Data Files and Software (2015)
    - Unicode License Agreement - Data Files and Software (2016)
    - UnixCrypt License
    - The Unlicense
    - Vovida Software License v1.0
    - W3C Software Notice and License (2002-12-31)
    - X11 License
    - XFree86 License 1.1
    - xlock License
    - X.Net License
    - XPP License
    - zlib License
    - zlib/libpng License with Acknowledgment
    - Zope Public License 2.0
    - Zope Public License 2.1
    license_states:
    - newly_detected
    branch_type: default
  actions:
  - type: require_approval
    approvals_required: 1
    user_approvers_ids:
    # Replace with the user IDs of your compliance approver(s)
    - YOUR_USER_ID_HERE
    - YOUR_USER_ID_HERE
    group_approvers_ids:
    # Replace with the group IDs of your compliance approver(s)
    - YOUR_GROUP_ID_HERE
    - YOUR_GROUP_ID_HERE
    role_approvers:
    # Replace with the roles of your compliance approver(s)
    - owner
    - maintainer
  - type: send_bot_message
    enabled: true
  approval_settings:
    block_branch_modification: true
    block_group_branch_modification: true
    prevent_pushing_and_force_pushing: true
    prevent_approval_by_author: true
    prevent_approval_by_commit_author: true
    remove_approvals_with_new_commit: true
    require_password_to_approve: false
  fallback_behavior:
    fail: closed
```

## How It Works

1. The `scan_execution_policy` section configures GitLab to run dependency scanning on all branches, which generates a CycloneDX format SBOM file that is used by the license approval policy.
1. The `approval_policy` section creates a rule that:
   - Contains a list of pre-approved licenses ([Gold](https://blueoakcouncil.org/list#gold), [Silver](https://blueoakcouncil.org/list#silver), and [Bronze](https://blueoakcouncil.org/list#bronze) tiers from Blue Oak Council)
   - Requires approval for any license not in this list
   - Sends a bot message when a non-approved license is detected
   - Blocks merging until approval is granted

## Customization Options

- **Approvers**: You can specify approvers in three ways:
  - `user_approvers_ids`: Replace with the user IDs of individuals who should approve licenses (e.g., `1234567`)
  - `group_approvers_ids`: Replace with the group IDs that contain approvers (e.g., `9876543`)
  - `role_approvers`: Specify roles that can approve, options are `developer`, `maintainer`, or `owner`
- **Project Exclusions**: Add project IDs to the `policy_scope.projects.excluding` section to exempt them from the policy
- **Required approvals**: Change `approvals_required: 1` to require more approvals
- **Bot messages**: Set `enabled: false` under `send_bot_message` to disable bot notifications
- **Override project approval settings**: Modify the `approval_settings` section as needed (anything set to `true` will override project settings)

## Keeping Your License List Up to Date

To ensure your list of approved licenses stays current with the Blue Oak Council ratings, you can use the following Python script to fetch the latest license data:

```python
import requests

def fetch_license_data():
    url = "https://blueoakcouncil.org/list.json"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise an exception for bad status codes
        return response.json()
    except requests.RequestException as e:
        print(f"Error fetching data: {e}")
        return None

# Fetch and print the data to verify it worked
data = fetch_license_data()
if data:
    # Look through each rating section
    target_tiers = ['Gold', 'Silver', 'Bronze']
    
    for rating in data['ratings']:
        if rating['name'] in target_tiers:
            # Print each license name in this tier
            for license in rating['licenses']:
                print(f"- {license['name']}")
```

To use this script:

1. Save it as `update_licenses.py`.
1. Install the requests library if you haven't already: `pip install requests`.
1. Run the script: `python update_licenses.py`.
1. Copy the output (list of licenses) and replace the existing `license_types` list in your `policy.yml` file.

This ensures your policy always reflects the most current Blue Oak Council license ratings.

## Troubleshooting

### Policy not applying

Ensure the security policy project you modified is correctly linked to your group. See [Link to a security policy project](../../user/application_security/policies/_index.md#link-to-a-security-policy-project) for more.

### Dependency scan not running

Check that dependency scanning is enabled in your CI/CD configuration, and there is a dependency file present. See [Troubleshooting Dependency Scanning](../../user/application_security/dependency_scanning/troubleshooting_dependency_scanning.md) for more.

## Additional Resources

- [Blue Oak Council License List](https://blueoakcouncil.org/list)
- [GitLab License Compliance Documentation](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md)
- [GitLab Merge Request Approval Policies](../../user/compliance/license_approval_policies.md)
- [GitLab Dependency Scanning](../../user/application_security/dependency_scanning/_index.md)

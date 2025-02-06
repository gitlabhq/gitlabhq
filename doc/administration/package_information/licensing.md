---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Package Licensing
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

## License

While GitLab itself is MIT, the Linux package sources are licensed under the Apache-2.0.

## License file location

Starting with version 8.11, the Linux package contains license
information of all software that is bundled in the package.

After installing the package, licenses for each individual bundled library
can be found in `/opt/gitlab/LICENSES` directory.

There is also one `LICENSE` file which contains all licenses compiled together.
This compiled license can be found in `/opt/gitlab/LICENSE` file.

Starting with version 9.2, the Linux package ships with a
`dependency_licenses.json` file containing version and license information of
all bundled software, including software libraries, Ruby gems that the rails
application uses, and JavaScript libraries that is required for the frontend
components. Because it's in JSON format, GitLab can parse this file and use it for automated checks or validations. The file may be found at
`/opt/gitlab/dependency_licenses.json`.

Starting with version 11.3, we have also made the license information available
online, at: <https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html>

## Checking licenses

The Linux package is made up of many pieces of software, comprising code
that is covered by many different licenses. Those licenses are provided and
compiled as stated above.

Starting with version 8.13, GitLab has placed an additional step into
Linux package installation. The `license_check` step calls
`lib/gitlab/tasks/license_check.rake`, which checks the compiled `LICENSE` file
against the current list of approved and questionable licenses as denoted in the
arrays at the top of the script. This script outputs one of `Good`,
`Unknown` or `Check` for each piece of software that is a part of the
Linux package.

- `Good`: denotes a license that is approved for all usage types, in GitLab and
  the Linux package.
- `Unknown`: denotes a license that is not recognized in the list of 'good' or 'bad',
  which should be immediately reviewed for implications of use.
- `Check`: denotes a license that has the potential be incompatible with GitLab itself,
  and thus should be checked for how it is used as a part of the Linux package
  to ensure compliance.

This list is sourced from the [GitLab development documentation on licensing](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/doc/development/licensing.md).
However, due to the nature of the Linux package, the licenses may not apply
in the same way. Such as with `git` and `rsync`. See the [GNU License FAQ](https://www.gnu.org/licenses/gpl-faq.en.html#MereAggregation)

## License acknowledgements

### libjpeg-turbo - BSD 3-clause license

This software is based in part on the work of the Independent JPEG Group.

## Trademark Usage

Within the GitLab documentation, reference to third-party technologies and/or trademarks of third-party entities may be made. The inclusion of reference to third-party technology and/or entities is solely for the purposes of examples of how GitLab software may interact with, or be used in conjunction with, such third-party technology.
All trademarks, materials, documentation, and other intellectual property remain the property of any/all such third party.

### Trademark Requirements

Use of GitLab Trademarks must be in compliance with the standards set forth in [our guidelines](https://handbook.gitlab.com/handbook/marketing/brand-and-product-marketing/brand/brand-activation/trademark-guidelines/) (as updated from time to time).
CHEF® and all Chef marks are owned by Progress Software Corporation and must be used in accordance with the [Progress Software Trademark Usage Policy](https://www.progress.com/legal/trademarks).

When using a GitLab or 3rd party trademark in documentation, include the (R) symbol in the first instance, for example, "Chef(R) is used for configuring...." You may omit the symbol in subsequent instances.

If a trademark owner requires a particular notice or trademark requirement, such notice or requirement should be stated above.

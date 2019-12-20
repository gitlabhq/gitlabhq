# GitLab Licensing and Compatibility

[GitLab Community Edition](https://gitlab.com/gitlab-org/gitlab-foss/) (CE) is licensed [under the terms of the MIT License][CE]. [GitLab Enterprise Edition](https://gitlab.com/gitlab-org/gitlab/) (EE) is licensed under "[The GitLab Enterprise Edition (EE) license][EE]" wherein there are more restrictions.

## Automated Testing

In order to comply with the terms the libraries we use are licensed under, we have to make sure to check new gems for compatible licenses whenever they're added. To automate this process, we use the [license_finder][license_finder] gem by Pivotal. It runs every time a new commit is pushed and verifies that all gems and node modules in the bundle use a license that doesn't conflict with the licensing of either GitLab Community Edition or GitLab Enterprise Edition.

There are some limitations with the automated testing, however. CSS, JavaScript, or Ruby libraries which are not included by way of Bundler, NPM, or Yarn (for instance those manually copied into our source tree in the `vendor` directory), must be verified manually and independently. Take care whenever one such library is used, as automated tests won't catch problematic licenses from them.

Some gems may not include their license information in their `gemspec` file, and some node modules may not include their license information in their `package.json` file. These won't be detected by License Finder, and will have to be verified manually.

### License Finder commands

There are a few basic commands License Finder provides that you'll need in order to manage license detection.

To verify that the checks are passing, and/or to see what dependencies are causing the checks to fail:

```
bundle exec license_finder
```

To whitelist a new license:

```
license_finder whitelist add MIT
```

To blacklist a new license:

```
license_finder blacklist add GPLv2
```

To tell License Finder about a dependency's license if it isn't auto-detected:

```
license_finder licenses add my_unknown_dependency MIT
```

For all of the above, please include `--why "Reason"` and `--who "My Name"` so the `decisions.yml` file can keep track of when, why, and who approved of a dependency.

More detailed information on how the gem and its commands work is available in the [License Finder README][license_finder].

## Acceptable Licenses

Libraries with the following licenses are acceptable for use:

- [The MIT License](https://choosealicense.com/licenses/mit/) (the MIT Expat License specifically): The MIT License requires that the license itself is included with all copies of the source. It is a permissive (non-copyleft) license as defined by the Open Source Initiative.
- [LGPL](https://choosealicense.com/licenses/lgpl-3.0/) (version 2, version 3): GPL constraints regarding modification and redistribution under the same license are not required of projects using an LGPL library, only upon modification of the LGPL-licensed library itself.
- [Apache 2.0 License](https://choosealicense.com/licenses/apache-2.0/): A permissive license that also provides an express grant of patent rights from contributors to users.
- [Ruby 1.8 License][ruby-1.8]: Dual-licensed under either itself or the GPLv2, defer to the Ruby License itself. Acceptable because of point 3b: "You may distribute the software in object code or binary form, provided that you do at least ONE of the following: b) accompany the distribution with the machine-readable source of the software."
- [Ruby 1.9 License][ruby-1.9]: Dual-licensed under either itself or the BSD 2-Clause License, defer to BSD 2-Clause.
- [BSD 2-Clause License][BSD-2-Clause]: A permissive (non-copyleft) license as defined by the Open Source Initiative.
- [BSD 3-Clause License][BSD-3-Clause] (also known as New BSD or Modified BSD): A permissive (non-copyleft) license as defined by the Open Source Initiative
- [ISC License][ISC] (also known as the OpenBSD License): A permissive (non-copyleft) license as defined by the Open Source Initiative.
- [Creative Commons Zero (CC0)][CC0]: A public domain dedication, recommended as a way to disclaim copyright on your work to the maximum extent possible.
- [Unlicense][UNLICENSE]: Another public domain dedication.
- [OWFa 1.0][OWFa1]: An open-source license and patent grant designed for specifications.

## Unacceptable Licenses

Libraries with the following licenses require legal approval for use:

- [GNU GPL](https://choosealicense.com/licenses/gpl-3.0/) (version 1, [version 2][GPLv2], [version 3][GPLv3], or any future versions): GPL-licensed libraries cannot be linked to from non-GPL projects.
- [GNU AGPLv3](https://choosealicense.com/licenses/agpl-3.0/): AGPL-licensed libraries cannot be linked to from non-GPL projects.
- [Open Software License (OSL)][OSL]: is a copyleft license. In addition, the FSF [recommend against its use][OSL-GNU].
- [WTFPL][WTFPL]: is a public domain dedication [rejected by the OSI (3.2)][WTFPL-OSI]. Also has a strong language which is not in accordance with our diversity policy.

## GPL Cooperation Commitment

Before filing or continuing to prosecute any legal proceeding or claim (other than a Defensive Action) arising from termination of a Covered License, GitLab commits to extend to the person or entity (“you”) accused of violating the Covered License the following provisions regarding cure and reinstatement, taken from GPL version 3. As used here, the term ‘this License’ refers to the specific Covered License being enforced.

However, if you cease all violation of this License, then your license from a particular copyright holder is reinstated (a) provisionally, unless and until the copyright holder explicitly and finally terminates your license, and (b) permanently, if the copyright holder fails to notify you of the violation by some reasonable means prior to 60 days after the cessation.

Moreover, your license from a particular copyright holder is reinstated permanently if the copyright holder notifies you of the violation by some reasonable means, this is the first time you have received notice of violation of this License (for any work) from that copyright holder, and you cure the violation prior to 30 days after your receipt of the notice.

GitLab intends this Commitment to be irrevocable, and binding and enforceable against GitLab and assignees of or successors to GitLab’s copyrights.

GitLab may modify this Commitment by publishing a new edition on this page or a successor location.

Definitions

‘Covered License’ means the GNU General Public License, version 2 (GPLv2), the GNU Lesser General Public License, version 2.1 (LGPLv2.1), or the GNU Library General Public License, version 2 (LGPLv2), all as published by the Free Software Foundation.

‘Defensive Action’ means a legal proceeding or claim that GitLab brings against you in response to a prior proceeding or claim initiated by you or your affiliate.

GitLab means GitLab Inc. and its affiliates and subsidiaries.

## Requesting Approval for Licenses or any other Intellectual Property

Libraries that are not already approved and listed on the [Acceptable Licenses][Acceptable-Licenses] list or that may be listed on the [Unacceptable Licenses][Unacceptable-Licenses] list may be submitted to the legal team for review and use on a case-by-case basis. Please email `legal@gitlab.com` with the details of how the software will be used, whether or not it will be modified, and how it will be distributed (if at all). After a decision has been made, the original requestor is responsible for updating this document, if applicable. Not all approvals will be approved for universal use and may continue to remain on the Unacceptable License list.

All inquiries relating to patents should be directed to the Legal team.

## Notes

Decisions regarding the GNU GPL licenses are based on information provided by [The GNU Project][GNU-GPL-FAQ], as well as [the Open Source Initiative][OSI-GPL], which both state that linking GPL libraries makes the program itself GPL.

If a gem uses a license which is not listed above, open an issue and ask. If a license is not included in the "acceptable" list, operate under the assumption that it is not acceptable.

Keep in mind that each license has its own restrictions (typically defined in their body text). Please make sure to comply with those restrictions at all times whenever an external library is used.

Dependencies which are only used in development or test environment are exempt from license requirements, as they're not distributed for use in production.

**NOTE:** This document is **not** legal advice, nor is it comprehensive. It should not be taken as such.

[CE]: https://gitlab.com/gitlab-org/gitlab-foss/blob/master/LICENSE
[EE]: https://gitlab.com/gitlab-org/gitlab/blob/master/LICENSE
[license_finder]: https://github.com/pivotal/LicenseFinder
[ruby-1.8]: https://github.com/ruby/ruby/blob/ruby_1_8_6/COPYING
[ruby-1.9]: https://www.ruby-lang.org/en/about/license.txt
[BSD-2-Clause]: https://opensource.org/licenses/BSD-2-Clause
[BSD-3-Clause]: https://opensource.org/licenses/BSD-3-Clause
[ISC]: https://opensource.org/licenses/ISC
[CC0]: https://creativecommons.org/publicdomain/zero/1.0/
[GPLv2]: http://www.gnu.org/licenses/gpl-2.0.txt
[GPLv3]: http://www.gnu.org/licenses/gpl-3.0.txt
[GNU-GPL-FAQ]: http://www.gnu.org/licenses/gpl-faq.html#IfLibraryIsGPL
[OSI-GPL]: https://opensource.org/faq#linking-proprietary-code
[OSL]: https://opensource.org/licenses/OSL-3.0
[OSL-GNU]: https://www.gnu.org/licenses/license-list.en.html#OSL
[Org-Repo]: https://gitlab.com/gitlab-com/organization
[UNLICENSE]: https://unlicense.org
[OWFa1]: http://www.openwebfoundation.org/legal/the-owf-1-0-agreements/owfa-1-0
[x-list]: https://www.apache.org/legal/resolved.html#category-x
[Acceptable-Licenses]: #acceptable-licenses
[Unacceptable-Licenses]: #unacceptable-licenses
[WTFPL]: https://wtfpl.net
[WTFPL-OSI]: https://opensource.org/minutes20090304

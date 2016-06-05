# GitLab Licensing and Compatibility

GitLab CE is licensed under the terms of the MIT License. GitLab EE is licensed under "The GitLab Enterprise Edition (EE) license" wherein there are more restrictions. See their respective LICENSE files ([CE][CE], [EE][EE]) for more information.

## Automated Testing

In order to comply with the terms the libraries we use are licensed under, we have to make sure to check new gems for compatible licenses whenever they're added. To automate this process, we use the [license_finder][license_finder] gem by Pivotal. It runs every time a new commit is pushed and verifies that all gems in the bundle use a license that doesn't conflict with the licensing of either GitLab Community Edition or GitLab Enterprise Edition.

There are some limitations with the automated testing, however. CSS and JavaScript libraries, as well as any Ruby libraries not included by way of Bundler, must be verified manually and independently. Take care whenever one such library is used, as automated tests won't catch problematic licenses from them.

Some gems may not include their license information in their `gemspec` file. These won't be detected by License Finder, and will have to be verified manually.

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

- [The MIT License][MIT] (the MIT Expat License specifically): The MIT License requires that the license itself is included with all copies of the source. It is a permissive (non-copyleft) license as defined by the Open Source Initiative.
- [LGPL][LGPL] (version 2, version 3): GPL constraints regarding modification and redistribution under the same license are not required of projects using an LGPL library, only upon modification of the LGPL-licensed library itself.
- [Apache 2.0 License][apache-2]: A permissive license that also provides an express grant of patent rights from contributors to users.
- [Ruby 1.8 License][ruby-1.8]: Dual-licensed under either itself or the GPLv2, defer to the Ruby License itself. Acceptable because of point 3b: "You may distribute the software in object code or binary form, provided that you do at least ONE of the following: b) accompany the distribution with the machine-readable source of the software."
- [Ruby 1.9 License][ruby-1.9]: Dual-licensed under either itself or the BSD 2-Clause License, defer to BSD 2-Clause.
- [BSD 2-Clause License][BSD-2-Clause]: A permissive (non-copyleft) license as defined by the Open Source Initiative.
- [BSD 3-Clause License][BSD-3-Clause] (also known as New BSD or Modified BSD): A permissive (non-copyleft) license as defined by the Open Source Initiative
- [ISC License][ISC] (also known as the OpenBSD License): A permissive (non-copyleft) license as defined by the Open Source Initiative.

## Unacceptable Licenses

Libraries with the following licenses are unacceptable for use:

- [GNU GPL][GPL] (version 1, [version 2][GPLv2], [version 3][GPLv3], or any future versions): GPL-licensed libraries cannot be linked to from non-GPL projects.
- [GNU AGPLv3][AGPLv3]: AGPL-licensed libraries cannot be linked to from non-GPL projects.

## Notes

Decisions regarding the GNU GPL licenses are based on information provided by [The GNU Project][GNU-GPL-FAQ], as well as [the Open Source Initiative][OSI-GPL], which both state that linking GPL libraries makes the program itself GPL.

If a gem uses a license which is not listed above, open an issue and ask. If a license is not included in the "acceptable" list, operate under the assumption that it is not acceptable.

Keep in mind that each license has its own restrictions (typically defined in their body text). Please make sure to comply with those restrictions at all times whenever an external library is used.

Gems which are included only in the "development" or "test" groups by Bundler are exempt from license requirements, as they're not distributed for use in production.

**NOTE:** This document is **not** legal advice, nor is it comprehensive. It should not be taken as such.

[CE]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/LICENSE
[EE]: https://gitlab.com/gitlab-org/gitlab-ee/blob/master/LICENSE
[license_finder]: https://github.com/pivotal/LicenseFinder
[MIT]: http://choosealicense.com/licenses/mit/
[LGPL]: http://choosealicense.com/licenses/lgpl-3.0/
[apache-2]: http://choosealicense.com/licenses/apache-2.0/
[ruby-1.8]: https://github.com/ruby/ruby/blob/ruby_1_8_6/COPYING
[ruby-1.9]: https://www.ruby-lang.org/en/about/license.txt
[BSD-2-Clause]: https://opensource.org/licenses/BSD-2-Clause
[BSD-3-Clause]: https://opensource.org/licenses/BSD-3-Clause
[ISC]: https://opensource.org/licenses/ISC
[GPL]: http://choosealicense.com/licenses/gpl-3.0/
[GPLv2]: http://www.gnu.org/licenses/gpl-2.0.txt
[GPLv3]: http://www.gnu.org/licenses/gpl-3.0.txt
[AGPLv3]: http://choosealicense.com/licenses/agpl-3.0/
[GNU-GPL-FAQ]: http://www.gnu.org/licenses/gpl-faq.html#IfLibraryIsGPL
[OSI-GPL]: https://opensource.org/faq#linking-proprietary-code

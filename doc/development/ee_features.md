# Guidelines for implementing Enterprise Edition feature

- **Write the code and the tests.** As with any code, EE features should have
  good test coverage to prevent regressions.
- **Write documentation.** Add documentation to the `doc/` directory. Describe
  the feature and include screenshots, if applicable.
- **Submit a MR to the `www-gitlab-com` projectd.** Add the new feature to the
  [EE feature comparison page](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/source/gitlab-ee/index.html)

## Separation of EE code

Merging changes from GitLab CE to EE can result in numerous conflicts.
To reduce conflicts, EE code should be separated in to the `EE` module
as much as possible.

For code in the `lib/` directory, place EE-specific logic in the top-level `EE`
module namespace. Namespace the class beneath the `EE` module just as you would
normally. For example, if CE has LDAP classes in `lib/gitlab/ldap/` then you
would place EE-specific LDAP classes in `lib/ee/gitlab/ldap`.

TODO: Talk about `app/` stuff.

### Classes vs. Module Mixins

If the feature being developed is not present in any form in CE, separation is
easier - build the class entirely in the `EE` namespace. For features that build
on existing CE features, write a module in the `EE` namespace and include it
in the CE class. This makes conflicts less likely during CE to EE merges
because only one line is added to the CE class - the `include` statement.

TODO: Discuss `prepend` and options for overriding CE methods.


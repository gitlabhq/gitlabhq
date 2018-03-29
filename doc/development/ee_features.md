# Guidelines for implementing Enterprise Edition features

- **Write the code and the tests.**: As with any code, EE features should have
  good test coverage to prevent regressions.
- **Write documentation.**: Add documentation to the `doc/` directory. Describe
  the feature and include screenshots, if applicable.
- **Submit a MR to the `www-gitlab-com` project.**: Add the new feature to the
  [EE features list][ee-features-list].

## Act as CE when unlicensed

Since the implementation of [GitLab CE features to work with unlicensed EE instance][ee-as-ce]
GitLab Enterprise Edition should work like GitLab Community Edition
when no license is active. So EE features always should be guarded by
`project.feature_available?` or `group.feature_available?` (or
`License.feature_available?` if it is a system-wide feature).

CE specs should remain untouched as much as possible and extra specs
should be added for EE. Licensed features can be stubbed using the
spec helper `stub_licensed_features` in `EE::LicenseHelpers`.

[ee-as-ce]: https://gitlab.com/gitlab-org/gitlab-ee/issues/2500

## Separation of EE code

We want a [single code base][] eventually, but before we reach the goal,
we still need to merge changes from GitLab CE to EE. To help us get there,
we should make sure that we no longer edit CE files in place in order to
implement EE features.

Instead, all EE code should be put inside the `ee/` top-level directory. The
rest of the code should be as close to the CE files as possible.

[single code base]: https://gitlab.com/gitlab-org/gitlab-ee/issues/2952#note_41016454

### EE-specific comments

When complete separation can't be achieved with the `ee/` directory, you can wrap
code in EE specific comments to designate the difference from CE/EE and add
some context for someone resolving a conflict.

```rb
# EE-specific start
stub_licensed_features(variable_environment_scope: true)
# EE specific end
```

```haml
-# EE-specific start
= render 'ci/variables/environment_scope', form_field: form_field, variable: variable
-# EE-specific end
```

EE-specific comments should not be backported to CE.

### Detection of EE-only files

For each commit (except on `master`), the `ee-files-location-check` CI job tries
to detect if there are any new files that are EE-only. If any file is detected,
the job fails with an explanation of why and what to do to make it pass.

Basically, the fix is simple: `git mv <file> ee/<file>`.

#### How to name your branches?

For any EE branch, the job will try to detect its CE counterpart by removing any
`ee-` prefix or `-ee` suffix from the EE branch name, and matching the last
branch that contains it.

For instance, from the EE branch `new-shiny-feature-ee` (or
`ee-new-shiny-feature`), the job would find the corresponding CE branches:

- `new-shiny-feature`
- `ce-new-shiny-feature`
- `new-shiny-feature-ce`
- `my-super-new-shiny-feature-in-ce`

#### Whitelist some EE-only files that cannot be moved to `ee/`

The `ee-files-location-check` CI job provides a whitelist of files or folders
that cannot or should not be moved to `ee/`. Feel free to open an issue to
discuss adding a new file/folder to this whitelist.

For instance, it was decided that moving EE-only files from `qa/` to `ee/qa/`
would make it difficult to build the `gitLab-{ce,ee}-qa` Docker images and it
was [not worth the complexity].

[not worth the complexity]: https://gitlab.com/gitlab-org/gitlab-ee/issues/4997#note_59764702

### EE-only features

If the feature being developed is not present in any form in CE, we don't
need to put the codes under `EE` namespace. For example, an EE model could
go into: `ee/app/models/awesome.rb` using `Awesome` as the class name. This
is applied not only to models. Here's a list of other examples:

- `ee/app/controllers/foos_controller.rb`
- `ee/app/finders/foos_finder.rb`
- `ee/app/helpers/foos_helper.rb`
- `ee/app/mailers/foos_mailer.rb`
- `ee/app/models/foo.rb`
- `ee/app/policies/foo_policy.rb`
- `ee/app/serializers/foo_entity.rb`
- `ee/app/serializers/foo_serializer.rb`
- `ee/app/services/foo/create_service.rb`
- `ee/app/validators/foo_attr_validator.rb`
- `ee/app/workers/foo_worker.rb`

This works because for every path that are present in CE's eager-load/auto-load
paths, we add the same `ee/`-prepended path in [`config/application.rb`].

[`config/application.rb`]: https://gitlab.com/gitlab-org/gitlab-ee/blob/d278b76d6600a0e27d8019a0be27971ba23ab640/config/application.rb#L41-51

### EE features based on CE features

For features that build on existing CE features, write a module in the
`EE` namespace and `prepend` it in the CE class. This makes conflicts
less likely to happen during CE to EE merges because only one line is
added to the CE class - the `prepend` line.

Since the module would require an `EE` namespace, the file should also be
put in an `ee/` sub-directory. For example, we want to extend the user model
in EE, so we have a module called `::EE::User` put inside
`ee/app/models/ee/user.rb`.

This is also not just applied to models. Here's a list of other examples:

- `ee/app/controllers/ee/foos_controller.rb`
- `ee/app/finders/ee/foos_finder.rb`
- `ee/app/helpers/ee/foos_helper.rb`
- `ee/app/mailers/ee/foos_mailer.rb`
- `ee/app/models/ee/foo.rb`
- `ee/app/policies/ee/foo_policy.rb`
- `ee/app/serializers/ee/foo_entity.rb`
- `ee/app/serializers/ee/foo_serializer.rb`
- `ee/app/services/ee/foo/create_service.rb`
- `ee/app/validators/ee/foo_attr_validator.rb`
- `ee/app/workers/ee/foo_worker.rb`

#### Overriding CE methods

To override a method present in the CE codebase, use `prepend`. It
lets you override a method in a class with a method from a module, while
still having access the class's implementation with `super`.

There are a few gotchas with it:

- you should always [`extend ::Gitlab::Utils::Override`] and use `override` to
  guard the "overrider" method to ensure that if the method gets renamed in
  CE, the EE override won't be silently forgotten.
- when the "overrider" would add a line in the middle of the CE
  implementation, you should refactor the CE method and split it in
  smaller methods. Or create a "hook" method that is empty in CE,
  and with the EE-specific implementation in EE.
- when the original implementation contains a guard clause (e.g.
  `return unless condition`), we cannot easily extend the behaviour by
  overriding the method, because we can't know when the overridden method
  (i.e. calling `super` in the overriding method) would want to stop early.
  In this case, we shouldn't just override it, but update the original method
  to make it call the other method we want to extend, like a [template method
  pattern](https://en.wikipedia.org/wiki/Template_method_pattern).
  For example, given this base:
  ``` ruby
    class Base
      def execute
        return unless enabled?

        # ...
        # ...
      end
    end
  ```
  Instead of just overriding `Base#execute`, we should update it and extract
  the behaviour into another method:
  ``` ruby
    class Base
      def execute
        return unless enabled?

        do_something
      end

      private

      def do_something
        # ...
        # ...
      end
    end
  ```
  Then we're free to override that `do_something` without worrying about the
  guards:
  ``` ruby
    module EE::Base
      extend ::Gitlab::Utils::Override

      override :do_something
      def do_something
        # Follow the above pattern to call super and extend it
      end
    end
  ```
  This would require updating CE first, or make sure this is back ported to CE.

When prepending, place them in the `ee/` specific sub-directory, and
wrap class or module in `module EE` to avoid naming conflicts.

For example to override the CE implementation of
`ApplicationController#after_sign_out_path_for`:

```ruby
def after_sign_out_path_for(resource)
  current_application_settings.after_sign_out_path.presence || new_user_session_path
end
```

Instead of modifying the method in place, you should add `prepend` to
the existing file:

```ruby
class ApplicationController < ActionController::Base
  prepend EE::ApplicationController
  # ...

  def after_sign_out_path_for(resource)
    current_application_settings.after_sign_out_path.presence || new_user_session_path
  end

  # ...
end
```

And create a new file in the `ee/` sub-directory with the altered
implementation:

```ruby
module EE
  module ApplicationController
    extend ::Gitlab::Utils::Override

    override :after_sign_out_path_for
    def after_sign_out_path_for(resource)
      if Gitlab::Geo.secondary?
        Gitlab::Geo.primary_node.oauth_logout_url(@geo_logout_state)
      else
        super
      end
    end
  end
end
```

[`extend ::Gitlab::Utils::Override`]: utilities.md#override

#### Use self-descriptive wrapper methods

When it's not possible/logical to modify the implementation of a
method. Wrap it in a self-descriptive method and use that method.

For example, in CE only an `admin` is allowed to access all private
projects/groups, but in EE also an `auditor` has full private
access. It would be incorrect to override the implementation of
`User#admin?`, so instead add a method `full_private_access?` to
`app/models/users.rb`. The implementation in CE will be:

```ruby
def full_private_access?
  admin?
end
```

In EE, the implementation `ee/app/models/ee/users.rb` would be:

```ruby
override :full_private_access?
def full_private_access?
  super || auditor?
end
```

In `lib/gitlab/visibility_level.rb` this method is used to return the
allowed visibilty levels:

```ruby
def levels_for_user(user = nil)
  if user.full_private_access?
    [PRIVATE, INTERNAL, PUBLIC]
  elsif # ...
end
```

See [CE MR][ce-mr-full-private] and [EE MR][ee-mr-full-private] for
full implementation details.

[ce-mr-full-private]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/12373
[ee-mr-full-private]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/2199

### Code in `app/controllers/`

In controllers, the most common type of conflict is with `before_action` that
has a list of actions in CE but EE adds some actions to that list.

The same problem often occurs for `params.require` / `params.permit` calls.

**Mitigations**

Separate CE and EE actions/keywords. For instance for `params.require` in
`ProjectsController`:

```ruby
def project_params
  params.require(:project).permit(project_params_attributes)
end

# Always returns an array of symbols, created however best fits the use case.
# It _should_ be sorted alphabetically.
def project_params_attributes
  %i[
    description
    name
    path
  ]
end

```

In the `EE::ProjectsController` module:

```ruby
def project_params_attributes
  super + project_params_attributes_ee
end

def project_params_attributes_ee
  %i[
    approvals_before_merge
    approver_group_ids
    approver_ids
    ...
  ]
end
```

### Code in `app/models/`

EE-specific models should `extend EE::Model`.

For example, if EE has a specific `Tanuki` model, you would
place it in `ee/app/models/ee/tanuki.rb`.

### Code in `app/views/`

It's a very frequent problem that EE is adding some specific view code in a CE
view. For instance the approval code in the project's settings page.

**Mitigations**

Blocks of code that are EE-specific should be moved to partials. This
avoids conflicts with big chunks of HAML code that that are not fun to
resolve when you add the indentation to the equation.

EE-specific views should be placed in `ee/app/views/ee/`, using extra
sub-directories if appropriate.

### Code in `lib/`

Place EE-specific logic in the top-level `EE` module namespace. Namespace the
class beneath the `EE` module just as you would normally.

For example, if CE has LDAP classes in `lib/gitlab/ldap/` then you would place
EE-specific LDAP classes in `ee/lib/ee/gitlab/ldap`.

### Code in `spec/`

When you're testing EE-only features, avoid adding examples to the
existing CE specs. Also do no change existing CE examples, since they
should remain working as-is when EE is running without a license.

Instead place EE specs in the `ee/spec` folder.

## JavaScript code in `assets/javascripts/`

To separate EE-specific JS-files we should also move the files into an `ee` folder.

For example there can be an
`app/assets/javascripts/protected_branches/protected_branches_bundle.js` and an
EE counterpart
`ee/app/assets/javascripts/protected_branches/protected_branches_bundle.js`.

See the frontend guide [performance section](./fe_guide/performance.md) for
information on managing page-specific javascript within EE.

## SCSS code in `assets/stylesheets`

To separate EE-specific styles in SCSS files, if a component you're adding styles for
is limited to only EE, it is better to have a separate SCSS file in appropriate directory
within `app/assets/stylesheets`.

In some cases, this is not entirely possible or creating dedicated SCSS file is an overkill,
e.g. a text style of some component is different for EE. In such cases,
styles are usually kept in stylesheet that is common for both CE and EE, and it is wise
to isolate such ruleset from rest of CE rules (along with adding comment describing the same)
to avoid conflicts during CE to EE merge.

#### Bad
```scss
.section-body {
  .section-title {
    background: $gl-header-color;
  }

  &.ee-section-body {
    .section-title {
      background: $gl-header-color-cyan;
    }
  }
}
```

#### Good
```scss
.section-body {
  .section-title {
    background: $gl-header-color;
  }
}

// EE-specific start
.section-body.ee-section-body {
  .section-title {
    background: $gl-header-color-cyan;
  }
}
// EE-specific end
```

## gitlab-svgs

Conflicts in `app/assets/images/icons.json` or `app/assets/images/icons.svg` can
be resolved simply by regenerating those assets with
[`yarn run svg`](https://gitlab.com/gitlab-org/gitlab-svgs).

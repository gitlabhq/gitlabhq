---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Guidelines for implementing Enterprise Edition features
---

- **Place code in `ee/`**: Put all Enterprise Edition (EE) inside the `ee/` top-level directory. The
  rest of the code must be as close to the Community Edition (CE) files as possible.
- **Write tests**: As with any code, EE features must have good test coverage to prevent
  regressions. All `ee/` code must have corresponding tests in `ee/`.
- **Write documentation.**: Add documentation to the `doc/` directory. Describe
  the feature and include screenshots, if applicable. Indicate [what editions](documentation/styleguide/availability_details.md)
  the feature applies to.
<!-- markdownlint-disable MD044 -->
- **Submit a MR to the [`www-gitlab-com`](https://gitlab.com/gitlab-com/www-gitlab-com) project.**: Add the new feature to the
  [EE features list](https://about.gitlab.com/features/).
<!-- markdownlint-enable MD044 -->

## SaaS-only feature

Use the following guidelines when you develop a feature that is only applicable for SaaS (for example, a CustomersDot integration).

In general, features should be provided for [both SaaS and self-managed deployments](https://handbook.gitlab.com/handbook/product/product-principles/#parity-between-saas-and-self-managed-deployments).
However, there are cases when a feature should only be available on SaaS and this guide will help show how that is
accomplished.

It is recommended you use `Gitlab::Saas.feature_available?`. This enables
context rich definitions around the reason the feature is SaaS-only.

### Implementing a SaaS-only feature with `Gitlab::Saas.feature_available?`

#### Adding to the FEATURES constant

1. See the [namespacing concepts guide](software_design.md#use-namespaces-to-define-bounded-contexts)
   for help in naming a new SaaS-only feature.
1. Add the new feature to `FEATURE` in `ee/lib/ee/gitlab/saas.rb`.

   ```ruby
   FEATURES = %i[purchases_additional_minutes some_domain_new_feature_name].freeze
   ```

1. Use the new feature in code with `Gitlab::Saas.feature_available?(:some_domain_new_feature_name)`.

#### SaaS-only feature definition and validation

This process is meant to ensure consistent SaaS feature usage in the codebase. All SaaS features **must**:

- Be known. Only use SaaS features that are explicitly defined.
- Have an owner.

All SaaS features are self-documented in YAML files stored in:

- [`ee/config/saas_features`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/config/saas_features)

Each SaaS feature is defined in a separate YAML file consisting of a number of fields:

| Field               | Required | Description                                                                                                  |
|---------------------|----------|--------------------------------------------------------------------------------------------------------------|
| `name`              | yes      | Name of the SaaS feature.                                                                                    |
| `introduced_by_url` | no       | The URL to the merge request that introduced the SaaS feature.                                               |
| `milestone`         | no       | Milestone in which the SaaS feature was created.                                                             |
| `group`             | no       | The [group](https://handbook.gitlab.com/handbook/product/categories/#devops-stages) that owns the feature flag. |

#### Create a new SaaS feature file definition

The GitLab codebase provides [`bin/saas-feature.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/bin/saas-feature.rb),
a dedicated tool to create new SaaS feature definitions.
The tool asks various questions about the new SaaS feature, then creates
a YAML definition in `ee/config/saas_features`.

Only SaaS features that have a YAML definition file can be used when running the development or testing environments.

```shell
❯ bin/saas-feature my_saas_feature
You picked the group 'group::acquisition'

>> URL of the MR introducing the SaaS feature (enter to skip and let Danger provide a suggestion directly in the MR):
?> https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38602
create ee/config/saas_features/my_saas_feature.yml
---
name: my_saas_feature
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38602
milestone: '16.8'
group: group::acquisition
```

### Opting out of a SaaS-only feature on another SaaS instance (JiHu)

Prepend the `ee/lib/ee/gitlab/saas.rb` module and override the `Gitlab::Saas.feature_available?` method.

```ruby
JH_DISABLED_FEATURES = %i[some_domain_new_feature_name].freeze

override :feature_available?
def feature_available?(feature)
  super && JH_DISABLED_FEATURES.exclude?(feature)
end
```

### Do not use SaaS-only features for functionality in CE

`Gitlab::Saas.feature_available?` must not appear in CE.
See [extending CE with EE guide](#extend-ce-features-with-ee-backend-code).

### SaaS-only features in tests

Introducing a SaaS-only feature into the codebase creates an additional code path that should be tested.
It is strongly advised to include automated tests for all code affected by a SaaS-only feature, both when **enabled** and **disabled**
to ensure the feature works properly.

To enable a SaaS-only feature in a test, use the `stub_saas_features`
helper. For example, to globally disable the `purchases_additional_minutes` feature
flag in a test:

```ruby
stub_saas_features(purchases_additional_minutes: false)

::Gitlab::Saas.feature_available?(:purchases_additional_minutes) # => false
```

A common pattern of testing both paths looks like:

```ruby
it 'purchases/additional_minutes is not available' do
  # tests assuming purchases_additional_minutes is not enabled by default
  ::Gitlab::Saas.feature_available?(:purchases_additional_minutes) # => false
end

context 'when purchases_additional_minutes is available' do
  before do
    stub_saas_features(purchases_additional_minutes: true)
  end

  it 'returns true' do
    ::Gitlab::Saas.feature_available?(:purchases_additional_minutes) # => true
  end
end
```

### Simulate a SaaS instance

If you're developing locally and need your instance to simulate the SaaS (GitLab.com)
version of the product:

1. Export this environment variable:

   ```shell
   export GITLAB_SIMULATE_SAAS=1
   ```

   There are many ways to pass an environment variable to your local GitLab instance.
   For example, you can create an `env.runit` file in the root of your GDK with the above snippet.

1. Enable **Allow use of licensed EE features** to make licensed EE features available to projects
   only if the project namespace's plan includes the feature.

   1. On the left sidebar, at the bottom, select **Admin**.
   1. On the left sidebar, select **Settings > General**.
   1. Expand **Account and limit**.
   1. Select the **Allow use of licensed EE features** checkbox.
   1. Select **Save changes**.

1. Ensure the group you want to test the EE feature for is actually using an EE plan:
   1. On the left sidebar, at the bottom, select **Admin**.
   1. On the left sidebar, select **Overview > Groups**.
   1. Identify the group you want to modify, and select **Edit**.
   1. Scroll to **Permissions and group features**. For **Plan**, select `Ultimate`.
   1. Select **Save changes**.

Here's a [📺 video](https://youtu.be/DHkaqXw_Tmc) demonstrating how to do the steps above.

<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/DHkaqXw_Tmc" frameborder="0" allowfullscreen> </iframe>
</figure>

## Implement a new EE feature

If you're developing a GitLab Premium or GitLab Ultimate licensed feature, use these steps to
add your new feature or extend it.

GitLab license features are added to [`ee/app/models/gitlab_subscriptions/features.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/gitlab_subscriptions/features.rb). To determine how
to modify this file, first discuss how your feature fits into our licensing with your Product Manager.

Use the following questions to guide you:

1. Is this a new feature, or are you extending an existing licensed feature?
   - If your feature already exists, you don't have to modify `features.rb`, but you
     must locate the existing feature identifier to [guard it](#guard-your-ee-feature).
   - If this is a new feature, decide on an identifier, such as `my_feature_name`, to add to the
     `features.rb` file.
1. Is this a **GitLab Premium** or **GitLab Ultimate** feature?
   - Based on the plan you choose to use the feature in, add the feature identifier to `PREMIUM_FEATURES`
     or `ULTIMATE_FEATURES`.
1. Will this feature be available globally (system-wide for the GitLab instance)?
   - Features such as [Geo](../administration/geo/_index.md) and
     [Database Load Balancing](../administration/postgresql/database_load_balancing.md) are used by the entire instance
     and cannot be restricted to individual user namespaces. These features are defined in the instance license.
     Add these features to `GLOBAL_FEATURES`.

### Guard your EE feature

A licensed feature can only be available to licensed users. You must add a check or guard
to determine if users have access to the feature.

To guard your licensed feature:

1. Locate your feature identifier in `ee/app/models/gitlab_subscriptions/features.rb`.
1. Use the following methods, where `my_feature_name` is your feature
   identifier:

   - In a project context:

     ```ruby
     my_project.licensed_feature_available?(:my_feature_name) # true if available for my_project
     ```

   - In a group or user namespace context:

     ```ruby
     my_group.licensed_feature_available?(:my_feature_name) # true if available for my_group
     ```

   - For a global (system-wide) feature:

     ```ruby
     License.feature_available?(:my_feature_name)  # true if available in this instance
     ```

1. Optional. If your global feature is also available to namespaces with a paid plan, combine two
   feature identifiers to allow both administrators and group users. For example:

   ```ruby
   License.feature_available?(:my_feature_name) || group.licensed_feature_available?(:my_feature_name_for_namespace) # Both admins and group members can see this EE feature
   ```

### Simulate a CE instance when unlicensed

After the implementation of
[GitLab CE features to work with unlicensed EE instance](https://gitlab.com/gitlab-org/gitlab/-/issues/2500)
GitLab Enterprise Edition works like GitLab Community Edition
when no license is active.

CE specs should remain untouched as much as possible and extra specs
should be added for EE. Licensed features can be stubbed using the
spec helper `stub_licensed_features` in `EE::LicenseHelpers`.

You can force GitLab to act as CE by either deleting the `ee/` directory or by
setting the [`FOSS_ONLY` environment variable](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/helpers/is_ee_env.js)
to something that evaluates as `true`. The same works for running tests
(for example `FOSS_ONLY=1 yarn jest`).

### Simulate a CE instance with a licensed GDK

To simulate a CE instance without deleting the license in a GDK:

1. Create an `env.runit` file in the root of your GDK with the line:

   ```shell
   export FOSS_ONLY=1
   ```

1. Then restart the GDK:

   ```shell
   gdk restart rails && gdk restart webpack
   ```

Remove the line in `env.runit` if you want to revert back to an EE
installation, and repeat step 2.

#### Run feature specs as CE

When running [feature specs](testing_guide/best_practices.md#system--feature-tests)
as CE, you should ensure that the edition of backend and frontend match.
To do so:

1. Set the `FOSS_ONLY=1` environment variable:

   ```shell
   export FOSS_ONLY=1
   ```

1. Start GDK:

   ```shell
   gdk start
   ```

1. Run feature specs:

   ```shell
   bin/rspec spec/features/<path_to_your_spec>
   ```

### Run CI pipelines in a FOSS context

By default, merge request pipelines for development run in an EE-context only. If you are
developing features that differ between FOSS and EE, you may wish to run pipelines in a
FOSS context as well.

To run pipelines in both contexts, add the `~"pipeline:run-as-if-foss"` label to the merge request.

See the [As-if-FOSS jobs and cross project downstream pipeline](pipelines/_index.md#as-if-foss-jobs-and-cross-project-downstream-pipeline) pipelines documentation for more information.

## Separation of EE code in the backend

### EE-only features

If the feature being developed is not present in any form in CE, we don't
need to put the code under the `EE` namespace. For example, an EE model could
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
- `ee/app/views/foo.html.haml`
- `ee/app/views/foo/_bar.html.haml`
- `ee/config/initializers/foo_bar.rb`

This works because for every path in the CE `eager-load/auto-load`
path, we add the same `ee/`-prepended path in [`config/application.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/925d3d4ebc7a2c72964ce97623ae41b8af12538d/config/application.rb#L42-52).
This also applies to views.

#### Testing EE-only backend features

To test an EE class that doesn't exist in CE, create the spec file as you usually
would in the `ee/spec` directory, but without the second `ee/` subdirectory.
For example, a class `ee/app/models/vulnerability.rb` would have its tests in `ee/spec/models/vulnerability_spec.rb`.

By default, licensed features are disabled for specs in `specs/`.
Specs in the `ee/spec` directory have Starter license initialized by default.

To effectively test your feature
you must explicitly enable the feature using the `stub_licensed_features` helper, for example:

```ruby
  stub_licensed_features(my_awesome_feature_name: true)
```

### Extend CE features with EE backend code

For features that build on existing CE features, write a module in the `EE`
namespace and inject it in the CE class, on the last line of the file that the
class resides in. This makes conflicts less likely to happen during CE to EE
merges because only one line is added to the CE class - the line that injects
the module. For example, to prepend a module into the `User` class you would use
the following approach:

```ruby
class User < ActiveRecord::Base
  # ... lots of code here ...
end

User.prepend_mod
```

Do not use methods such as `prepend`, `extend`, and `include`. Instead, use
`prepend_mod`, `extend_mod`, or `include_mod`. These methods will try to
find the relevant EE module by the name of the receiver module, for example;

```ruby
module Vulnerabilities
  class Finding
    #...
  end
end

Vulnerabilities::Finding.prepend_mod
```

will prepend the module named `::EE::Vulnerabilities::Finding`.

If the extending module does not follow this naming convention, you can also provide the module name
by using `prepend_mod_with`, `extend_mod_with`, or `include_mod_with`. These methods take a
_String_ containing the full module name as the argument, not the module itself, like so;

```ruby
class User
  #...
end

User.prepend_mod_with('UserExtension')
```

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

#### Testing EE features based on CE features

To test an `EE` namespaced module that extends a CE class with EE features,
create the spec file as you usually would in the `ee/spec` directory, including the second `ee/` subdirectory.
For example, an extension `ee/app/models/ee/user.rb` would have its tests in `ee/spec/models/ee/user_spec.rb`.

In the `RSpec.describe` call, use the CE class name where the EE module would be used.
For example, in `ee/spec/models/ee/user_spec.rb`, the test would start with:

```ruby
RSpec.describe User do
  describe 'ee feature added through extension'
end
```

#### Overriding CE methods

To override a method present in the CE codebase, use `prepend`. It
lets you override a method in a class with a method from a module, while
still having access the class's implementation with `super`.

There are a few gotchas with it:

- you should always [`extend ::Gitlab::Utils::Override`](utilities.md#override) and use `override` to
  guard the `overrider` method to ensure that if the method gets renamed in
  CE, the EE override isn't silently forgotten.
- when the `overrider` would add a line in the middle of the CE
  implementation, you should refactor the CE method and split it in
  smaller methods. Or create a "hook" method that is empty in CE,
  and with the EE-specific implementation in EE.
- when the original implementation contains a guard clause (for example,
  `return unless condition`), we cannot easily extend the behavior by
  overriding the method, because we can't know when the overridden method
  (that is, calling `super` in the overriding method) would want to stop early.
  In this case, we shouldn't just override it, but update the original method
  to make it call the other method we want to extend, like a
  [template method pattern](https://en.wikipedia.org/wiki/Template_method_pattern).
  For example, given this base:

  ```ruby
    class Base
      def execute
        return unless enabled?

        # ...
        # ...
      end
    end
  ```

  Instead of just overriding `Base#execute`, we should update it and extract
  the behavior into another method:

  ```ruby
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

  ```ruby
    module EE::Base
      extend ::Gitlab::Utils::Override

      override :do_something
      def do_something
        # Follow the above pattern to call super and extend it
      end
    end
  ```

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
  # ...

  def after_sign_out_path_for(resource)
    current_application_settings.after_sign_out_path.presence || new_user_session_path
  end

  # ...
end

ApplicationController.prepend_mod_with('ApplicationController')
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

##### Overriding CE class methods

The same applies to class methods, except we want to use
`ActiveSupport::Concern` and put `extend ::Gitlab::Utils::Override`
within the block of `class_methods`. Here's an example:

```ruby
module EE
  module Groups
    module GroupMembersController
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :admin_not_required_endpoints
        def admin_not_required_endpoints
          super.concat(%i[update override])
        end
      end
    end
  end
end
```

#### Use self-descriptive wrapper methods

When it's not possible/logical to modify the implementation of a method, then
wrap it in a self-descriptive method and use that method.

For example, in GitLab-FOSS, the only user created by the system is `Users::Internal.ghost`
but in EE there are several types of bot-users that aren't really users. It would
be incorrect to override the implementation of `User#ghost?`, so instead we add
a method `#internal?` to `app/models/user.rb`. The implementation:

```ruby
def internal?
  ghost?
end
```

In EE, the implementation `ee/app/models/ee/users.rb` would be:

```ruby
override :internal?
def internal?
  super || bot?
end
```

### Code in `config/initializers`

Rails initialization code is located in

- `config/initializers` for CE-only features
- `ee/config/initializers` for EE features

Use `Gitlab.ee { ... }`/`Gitlab.ee?` in `config/initializers` only when
splitting is not possible. For example:

```ruby
SomeGem.configure do |config|
  config.base = 'https://example.com'

  config.encryption = true if Gitlab.ee?
end
```

### Code in `config/routes`

When we add `draw :admin` in `config/routes.rb`, the application tries to
load the file located in `config/routes/admin.rb`, and also try to load the
file located in `ee/config/routes/admin.rb`.

In EE, it should at least load one file, at most two files. If it cannot find
any files, an error is raised. In CE, since we don't know if an
EE route exists, it doesn't raise any errors even if it cannot find anything.

This means if we want to extend a particular CE route file, just add the same
file located in `ee/config/routes`. If we want to add an EE only route, we
could still put `draw :ee_only` in both CE and EE, and add
`ee/config/routes/ee_only.rb` in EE, similar to `render_if_exists`.

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

EE-specific models should be defined in `ee/app/models/`.

To override a CE model create the file in
`ee/app/models/ee/` and add new code to a `prepended` block.

ActiveRecord `enums` should be entirely
[defined in FOSS](database/creating_enums.md#all-of-the-keyvalue-pairs-should-be-defined-in-foss).

### Code in `app/views/`

It's a very frequent problem that EE is adding some specific view code in a CE
view. For instance the approval code in the project's settings page.

**Mitigations**

Blocks of code that are EE-specific should be moved to partials. This
avoids conflicts with big chunks of HAML code that are not fun to
resolve when you add the indentation to the equation.

EE-specific views should be placed in `ee/app/views/`, using extra
sub-directories if appropriate.

#### Using `render_if_exists`

Instead of using regular `render`, we should use `render_if_exists`, which
doesn't render anything if it cannot find the specific partial. We use this
so that we could put `render_if_exists` in CE, keeping code the same between
CE and EE.

The advantages of this:

- Very clear hints about where we're extending EE views while reading CE code.

The disadvantage of this:

- If we have typos in the partial name, it would be silently ignored.

##### Caveats

The `render_if_exists` view path argument must be relative to `app/views/` and `ee/app/views`.
Resolving an EE template path that is relative to the CE view path doesn't work.

```haml
- # app/views/projects/index.html.haml

= render_if_exists 'button' # Will not render `ee/app/views/projects/_button` and will quietly fail
= render_if_exists 'projects/button' # Will render `ee/app/views/projects/_button`
```

#### Using `render_ce`

For `render` and `render_if_exists`, they search for the EE partial first,
and then CE partial. They would only render a particular partial, not all
partials with the same name. We could take the advantage of this, so that
the same partial path (for example, `projects/settings/archive`) could
be referring to the CE partial in CE (that is,
`app/views/projects/settings/_archive.html.haml`), while EE
partial in EE (that is,
`ee/app/views/projects/settings/_archive.html.haml`). This way,
we could show different things between CE and EE.

However sometimes we would also want to reuse the CE partial in EE partial
because we might just want to add something to the existing CE partial. We
could workaround this by adding another partial with a different name, but it
would be tedious to do so.

In this case, we could as well just use `render_ce` which would ignore any EE
partials. One example would be
`ee/app/views/projects/settings/_archive.html.haml`:

```haml
- return if @project.marked_for_deletion?
= render_ce 'projects/settings/archive'
```

In the above example, we can't use
`render 'projects/settings/archive'` because it would find the
same EE partial, causing infinite recursion. Instead, we could use `render_ce`
so it ignores any partials in `ee/` and then it would render the CE partial
(that is, `app/views/projects/settings/_archive.html.haml`)
for the same path (that is, `projects/settings/archive`). This way
we could easily wrap around the CE partial.

### Code in `lib/gitlab/background_migration/`

When you create EE-only background migrations, you have to plan for users that
downgrade GitLab EE to CE. In other words, every EE-only migration has to be present in
CE code but with no implementation, instead you need to extend it on EE side.

GitLab CE:

```ruby
# lib/gitlab/background_migration/prune_orphaned_geo_events.rb

module Gitlab
  module BackgroundMigration
    class PruneOrphanedGeoEvents
      def perform(table_name)
      end
    end
  end
end

Gitlab::BackgroundMigration::PruneOrphanedGeoEvents.prepend_mod_with('Gitlab::BackgroundMigration::PruneOrphanedGeoEvents')
```

GitLab EE:

```ruby
# ee/lib/ee/gitlab/background_migration/prune_orphaned_geo_events.rb

module EE
  module Gitlab
    module BackgroundMigration
      module PruneOrphanedGeoEvents
        extend ::Gitlab::Utils::Override

        override :perform
        def perform(table_name = EVENT_TABLES.first)
          return if ::Gitlab::Database.read_only?

          deleted_rows = prune_orphaned_rows(table_name)
          table_name   = next_table(table_name) if deleted_rows.zero?

          ::BackgroundMigrationWorker.perform_in(RESCHEDULE_DELAY, self.class.name.demodulize, table_name) if table_name
        end
      end
    end
  end
end
```

### Code in `app/graphql/`

EE-specific mutations, resolvers, and types should be added to
`ee/app/graphql/{mutations,resolvers,types}`.

To override a CE mutation, resolver, or type, create the file in
`ee/app/graphql/ee/{mutations,resolvers,types}` and add new code to a
`prepended` block.

For example, if CE has a mutation called `Mutations::Tanukis::Create` and you
wanted to add a new argument, place the EE override in
`ee/app/graphql/ee/mutations/tanukis/create.rb`:

```ruby
module EE
  module Mutations
    module Tanukis
      module Create
        extend ActiveSupport::Concern

        prepended do
          argument :name,
                   GraphQL::Types::String,
                   required: false,
                   description: 'Tanuki name'
        end
      end
    end
  end
end
```

### Code in `lib/`

Place EE-specific logic in the top-level `EE` module namespace. Namespace the
class beneath the `EE` module as you usually would.

For example, if CE has LDAP classes in `lib/gitlab/ldap/` then you would place
EE-specific LDAP classes in `ee/lib/ee/gitlab/ldap`.

### Code in `lib/api/`

It can be very tricky to extend EE features by a single line of `prepend_mod_with`,
and for each different [Grape](https://github.com/ruby-grape/grape) feature, we
might need different strategies to extend it. To apply different strategies
easily, we would use `extend ActiveSupport::Concern` in the EE module.

Put the EE module files following
[Extend CE features with EE backend code](#extend-ce-features-with-ee-backend-code).

#### EE API routes

For EE API routes, we put them in a `prepended` block:

```ruby
module EE
  module API
    module MergeRequests
      extend ActiveSupport::Concern

      prepended do
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
        end
        resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          # ...
        end
      end
    end
  end
end
```

We need to use the full qualifier for some constants due to namespace differences.

#### EE parameters

We can define `params` and use `use` in another `params` definition to
include parameters defined in EE. However, we need to define the "interface" first
in CE in order for EE to override it. We don't have to do this in other places
due to `prepend_mod_with`, but Grape is complex internally and we couldn't easily
do that, so we follow regular object-oriented practices that we define the
interface first here.

For example, suppose we have a few more optional parameters for EE. We can move the
parameters out of the `Grape::API::Instance` class to a helper module, so we can inject it
before it would be used in the class.

```ruby
module API
  class Projects < Grape::API::Instance
    helpers Helpers::ProjectsHelpers
  end
end
```

Given this CE API `params`:

```ruby
module API
  module Helpers
    module ProjectsHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      params :optional_project_params_ce do
        # CE specific params go here...
      end

      params :optional_project_params_ee do
      end

      params :optional_project_params do
        use :optional_project_params_ce
        use :optional_project_params_ee
      end
    end
  end
end

API::Helpers::ProjectsHelpers.prepend_mod_with('API::Helpers::ProjectsHelpers')
```

We could override it in EE module:

```ruby
module EE
  module API
    module Helpers
      module ProjectsHelpers
        extend ActiveSupport::Concern

        prepended do
          params :optional_project_params_ee do
            # EE specific params go here...
          end
        end
      end
    end
  end
end
```

#### EE helpers

To make it easy for an EE module to override the CE helpers, we need to define
those helpers we want to extend first. Try to do that immediately after the
class definition to make it easy and clear:

```ruby
module API
  module Ci
    class JobArtifacts < Grape::API::Instance
      # EE::API::Ci::JobArtifacts would override the following helpers
      helpers do
        def authorize_download_artifacts!
          authorize_read_builds!
        end
      end
    end
  end
end

API::Ci::JobArtifacts.prepend_mod_with('API::Ci::JobArtifacts')
```

And then we can follow regular object-oriented practices to override it:

```ruby
module EE
  module API
    module Ci
      module JobArtifacts
        extend ActiveSupport::Concern

        prepended do
          helpers do
            def authorize_download_artifacts!
              super
              check_cross_project_pipelines_feature!
            end
          end
        end
      end
    end
  end
end
```

#### EE-specific behavior

Sometimes we need EE-specific behavior in some of the APIs. Usually we could
use EE methods to override CE methods, however API routes are not methods and
therefore cannot be overridden. We need to extract them into a standalone
method, or introduce some "hooks" where we could inject behavior in the CE
route. Something like this:

```ruby
module API
  class MergeRequests < Grape::API::Instance
    helpers do
      # EE::API::MergeRequests would override the following helpers
      def update_merge_request_ee(merge_request)
      end
    end

    put ':id/merge_requests/:merge_request_iid/merge' do
      merge_request = find_project_merge_request(params[:merge_request_iid])

      # ...

      update_merge_request_ee(merge_request)

      # ...
    end
  end
end

API::MergeRequests.prepend_mod_with('API::MergeRequests')
```

`update_merge_request_ee` doesn't do anything in CE, but
then we could override it in EE:

```ruby
module EE
  module API
    module MergeRequests
      extend ActiveSupport::Concern

      prepended do
        helpers do
          def update_merge_request_ee(merge_request)
            # ...
          end
        end
      end
    end
  end
end
```

#### EE `route_setting`

It's very hard to extend this in an EE module, and this is storing
some meta-data for a particular route. Given that, we could leave the
EE `route_setting` in CE as it doesn't hurt and we don't use
those meta-data in CE.

We could revisit this policy when we're using `route_setting` more and whether
or not we really need to extend it from EE. For now we're not using it much.

#### Utilizing class methods for setting up EE-specific data

Sometimes we need to use different arguments for a particular API route, and we
can't easily extend it with an EE module because Grape has different context in
different blocks. In order to overcome this, we need to move the data to a class
method that resides in a separate module or class. This allows us to extend that
module or class before its data is used, without having to place a
`prepend_mod_with` in the middle of CE code.

For example, in one place we need to pass an extra argument to
`at_least_one_of` so that the API could consider an EE-only argument as the
least argument. We would approach this as follows:

```ruby
# api/merge_requests/parameters.rb
module API
  class MergeRequests < Grape::API::Instance
    module Parameters
      def self.update_params_at_least_one_of
        %i[
          assignee_id
          description
        ]
      end
    end
  end
end

API::MergeRequests::Parameters.prepend_mod_with('API::MergeRequests::Parameters')

# api/merge_requests.rb
module API
  class MergeRequests < Grape::API::Instance
    params do
      at_least_one_of(*Parameters.update_params_at_least_one_of)
    end
  end
end
```

And then we could easily extend that argument in the EE class method:

```ruby
module EE
  module API
    module MergeRequests
      module Parameters
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :update_params_at_least_one_of
          def update_params_at_least_one_of
            super.push(*%i[
              squash
            ])
          end
        end
      end
    end
  end
end
```

It could be annoying if we need this for a lot of routes, but it might be the
simplest solution right now.

This approach can also be used when models define validations that depend on
class methods. For example:

```ruby
# app/models/identity.rb
class Identity < ActiveRecord::Base
  def self.uniqueness_scope
    [:provider]
  end

  prepend_mod_with('Identity')

  validates :extern_uid,
    allow_blank: true,
    uniqueness: { scope: uniqueness_scope, case_sensitive: false }
end

# ee/app/models/ee/identity.rb
module EE
  module Identity
    extend ActiveSupport::Concern

    class_methods do
      extend ::Gitlab::Utils::Override

      def uniqueness_scope
        [*super, :saml_provider_id]
      end
    end
  end
end
```

Instead of taking this approach, we would refactor our code into the following:

```ruby
# ee/app/models/ee/identity/uniqueness_scopes.rb
module EE
  module Identity
    module UniquenessScopes
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        def uniqueness_scope
          [*super, :saml_provider_id]
        end
      end
    end
  end
end

# app/models/identity/uniqueness_scopes.rb
class Identity < ActiveRecord::Base
  module UniquenessScopes
    def self.uniqueness_scope
      [:provider]
    end
  end
end

Identity::UniquenessScopes.prepend_mod_with('Identity::UniquenessScopes')

# app/models/identity.rb
class Identity < ActiveRecord::Base
  validates :extern_uid,
    allow_blank: true,
    uniqueness: { scope: Identity::UniquenessScopes.scopes, case_sensitive: false }
end
```

### Code in `spec/`

When you're testing EE-only features, avoid adding examples to the
existing CE specs. Also do not change existing CE examples, since they
should remain working as-is when EE is running without a license.

Instead place EE specs in the `ee/spec` folder.

### Code in `spec/factories`

Use `FactoryBot.modify` to extend factories already defined in CE.

You cannot define new factories (even nested ones) inside the `FactoryBot.modify` block. You can do so in a
separate `FactoryBot.define` block as shown in the example below:

```ruby
# ee/spec/factories/notes.rb
FactoryBot.modify do
  factory :note do
    trait :on_epic do
      noteable { create(:epic) }
      project nil
    end
  end
end

FactoryBot.define do
  factory :note_on_epic, parent: :note, traits: [:on_epic]
end
```

## Separation of EE code in the frontend

To separate EE-specific JS-files, move the files into an `ee` folder.

For example there can be an
`app/assets/javascripts/protected_branches/protected_branches_bundle.js` and an
EE counterpart
`ee/app/assets/javascripts/protected_branches/protected_branches_bundle.js`.
The corresponding import statement would then look like this:

```javascript
// app/assets/javascripts/protected_branches/protected_branches_bundle.js
import bundle from '~/protected_branches/protected_branches_bundle.js';

// ee/app/assets/javascripts/protected_branches/protected_branches_bundle.js
// (only works in EE)
import bundle from 'ee/protected_branches/protected_branches_bundle.js';

// in CE: app/assets/javascripts/protected_branches/protected_branches_bundle.js
// in EE: ee/app/assets/javascripts/protected_branches/protected_branches_bundle.js
import bundle from 'ee_else_ce/protected_branches/protected_branches_bundle.js';
```

### Add new EE-only features in the frontend

If the feature being developed is not present in CE, add your entry point in
`ee/`. For example:

```shell
# Add HTML element to mount
ee/app/views/admin/geo/designs/index.html.haml

# Init the application
ee/app/assets/javascripts/pages/ee_only_feature/index.js

# Mount the feature
ee/app/assets/javascripts/ee_only_feature/index.js
```

Feature guarding `licensed_feature_available?` and `License.feature_available?` typical
occurs in the controller, as described in the [backend guide](#ee-only-features).

#### Testing EE-only frontend features

Add your EE tests to `ee/spec/frontend/` following the same directory structure you use for CE.

Check the note under [Testing EE-only backend features](#testing-ee-only-backend-features) regarding
enabling licensed features.

### Extend CE features with EE frontend code

Use the [`push_licensed_feature`](#guard-your-ee-feature) to guard frontend features that extend
existing views:

```ruby
# ee/app/controllers/ee/admin/my_controller.rb
before_action do
  push_licensed_feature(:my_feature_name) # for global features
end
```

```ruby
# ee/app/controllers/ee/group/my_controller.rb
before_action do
  push_licensed_feature(:my_feature_name, @group) # for group pages
end
```

```ruby
# ee/app/controllers/ee/project/my_controller.rb
before_action do
  push_licensed_feature(:my_feature_name, @group) # for group pages
  push_licensed_feature(:my_feature_name, @project) # for project pages
end
```

Verify your feature appears in `gon.licensed_features` in the browser console.

#### Extend Vue applications with EE Vue components

EE licensed features that enhance existing functionality in the UI add new
elements or interactions to your Vue application as components.

You can import EE components inside CE components to add EE features.

Use an `ee_component` alias to import an EE component. In EE the `ee_component` import alias points
to the `ee/app/assets/javascripts` directory. While in CE this alias will be resolved to an empty
component that renders nothing.

Here is an example of an EE component imported to a CE component:

```vue
<script>
// app/assets/javascripts/feature/components/form.vue

// In EE this will be resolved as `ee/app/assets/javascripts/feature/components/my_ee_component.vue`
// In CE as `app/assets/javascripts/vue_shared/components/empty_component.js`
import MyEeComponent from 'ee_component/feature/components/my_ee_component.vue';

export default {
  components: {
    MyEeComponent,
  },
};
</script>

<template>
  <div>
    <!-- ... -->
    <my-ee-component/>
    <!-- ... -->
  </div>
</template>
```

NOTE:
An EE component can be imported
[asynchronously](https://v2.vuejs.org/v2/guide/components-dynamic-async.html#Async-Components) if
its rendering within CE codebase relies on some check (e.g. a feature flag check).

Check `glFeatures` to ensure that the Vue components are guarded. The components render only when
the license is present.

```vue
<script>
// ee/app/assets/javascripts/feature/components/special_component.vue

import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  mixins: [glFeatureFlagMixin()],
  computed: {
    shouldRenderComponent() {
      // Comes from gon.licensed_features as a camel-case version of `my_feature_name`
      return this.glFeatures.myFeatureName;
    }
  },
};
</script>

<template>
  <div v-if="shouldRenderComponent">
    <!-- EE licensed feature UI -->
  </div>
</template>
```

NOTE:
Do not use mixins unless ABSOLUTELY NECESSARY. Try to find an alternative pattern.

##### Recommended alternative approach (named/scoped slots)

- We can use slots and/or scoped slots to achieve the same thing as we did with mixins. If you only need an EE component there is no need to create the CE component.

1. First, we have a CE component that can render a slot in case we need EE template and functionality to be decorated on top of the CE base.

```vue
// ./ce/my_component.vue

<script>
export default {
  props: {
    tooltipDefaultText: {
      type: String,
    },
  },
  computed: {
    tooltipText() {
      return this.tooltipDefaultText || "5 issues please";
    }
  },
}
</script>

<template>
  <span v-gl-tooltip :title="tooltipText" class="ce-text">Community Edition Only Text</span>
  <slot name="ee-specific-component">
</template>
```

1. Next, we render the EE component, and inside of the EE component we render the CE component and add additional content in the slot.

```vue
// ./ee/my_component.vue

<script>
export default {
  computed: {
    tooltipText() {
      if (this.weight) {
        return "5 issues with weight 10";
      }
    }
  },
  methods: {
    submit() {
      // do something.
    }
  },
}
</script>

<template>
  <my-component :tooltipDefaultText="tooltipText">
    <template #ee-specific-component>
      <span class="some-ee-specific">EE Specific Value</span>
      <button @click="submit">Click Me</button>
    </template>
  </my-component>
</template>
```

1. Finally, wherever the component is needed we can require it like so

`import MyComponent from 'ee_else_ce/path/my_component'.vue`

- this way the correct component is included for either the CE or EE implementation

**For EE components that need different results for the same computed values, we can pass in props to the CE wrapper as seen in the example.**

- **EE extra HTML**
  - For the templates that have extra HTML in EE we should move it into a new component and use the `ee_else_ce` import alias

#### Extend other JS code

To extend JS files, complete the following steps:

1. Use the `ee_else_ce` helper, where that EE only code must be inside the `ee/` folder.
   1. Create an EE file with only the EE, and extend the CE counterpart.
   1. For code inside functions that can't be extended, move the code to a new file and use `ee_else_ce` helper:

```javascript
  import eeCode from 'ee_else_ce/ee_code';

  function test() {
    const test = 'a';

    eeCode();

    return test;
  }
```

In some cases, you'll need to extend other logic in your application. To extend your JS
modules, create an EE version of the file and extend it with your custom logic:

```javascript
// app/assets/javascripts/feature/utils.js

export const myFunction = () => {
  // ...
};

// ... other CE functions ...
```

```javascript
// ee/app/assets/javascripts/feature/utils.js
import {
  myFunction as ceMyFunction,
} from '~/feature/utils';

/* eslint-disable import/export */

// Export same utils as CE
export * from '~/feature/utils';

// Only override `myFunction`
export const myFunction = () => {
  const result = ceMyFunction();
  // add EE feature logic
  return result;
};

/* eslint-enable import/export */
```

#### Testing modules using EE/CE aliases

When writing Frontend tests, if the module under test imports other modules with `ee_else_ce/...` and these modules are also needed by the relevant test, then the relevant test **must** import these modules with `ee_else_ce/...`. This avoids unexpected EE or FOSS failures, and helps ensure the EE behaves like CE when it is unlicensed.

For example:

```vue
<script>
// ~/foo/component_under_test.vue

import FriendComponent from 'ee_else_ce/components/friend.vue;'

export default {
  name: 'ComponentUnderTest',
  components: { FriendComponent }.
}
</script>

<template>
  <friend-component />
</template>
```

```javascript
// spec/frontend/foo/component_under_test_spec.js

// ...
// because we referenced the component using ee_else_ce we have to do the same in the spec.
import Friend from 'ee_else_ce/components/friend.vue;'

describe('ComponentUnderTest', () => {
  const findFriend = () => wrapper.find(Friend);

  it('renders friend', () => {
    // This would fail in CE if we did `ee/component...`
    // and would fail in EE if we did `~/component...`
    expect(findFriend().exists()).toBe(true);
  });
});

```

### Running EE vs CE tests

Whenever you create tests for both CE and EE environments, you need to take some steps to ensure that both tests pass locally and on the pipeline when run.

- By default, tests run in the EE environment, executing both EE and CE tests.
- If you want to test only the CE file in the FOSS environment, you need to run the following command:

```shell
FOSS_ONLY=1 yarn jest path/to/spec/file.spec.js
```

As for CE tests we only add CE features, it may fail in the EE environment if EE-specific mock data is missing. To ensure CE tests work in both environments:

- Use the `ee_else_ce_jest` alias when importing mock data. For example:

```javascript
import { sidebarDataCountResponse } from 'ee_else_ce_jest/super_sidebar/mock_data';
```

- Make sure that you have a CE and an EE `mock_data` file with an object (in the example above, `sidebarDataCountResponse`) with the corresponding data. One with only CE features data for the CE file and another with both CE and EE features data.

- In the CE file `expect` blocks, if you need to compare an object, use `toMatchObject` instead of `toEqual`, so it doesn't expect that EE data to exist in the CE data. For example:

```javascript
expect(findPinnedSection().props('asyncCount')).toMatchObject(asyncCountData);
```

#### SCSS code in `assets/stylesheets`

If a component you're adding styles for is limited to EE, it is better to have a
separate SCSS file in an appropriate directory within `app/assets/stylesheets`.

In some cases, this is not entirely possible or creating dedicated SCSS file is an overkill,
for example, a text style of some component is different for EE. In such cases,
styles are usually kept in a stylesheet that is common for both CE and EE, and it is wise
to isolate such ruleset from rest of CE rules (along with adding comment describing the same)
to avoid conflicts during CE to EE merge.

```scss
// Bad
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

```scss
// Good
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

### GitLab-svgs

Conflicts in `app/assets/images/icons.json` or `app/assets/images/icons.svg` can
be resolved by regenerating those assets with
[`yarn run svg`](https://gitlab.com/gitlab-org/gitlab-svgs).

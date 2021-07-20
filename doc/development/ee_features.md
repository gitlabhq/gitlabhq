---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Guidelines for implementing Enterprise Edition features

- **Write the code and the tests.**: As with any code, EE features should have
  good test coverage to prevent regressions.
- **Write documentation.**: Add documentation to the `doc/` directory. Describe
  the feature and include screenshots, if applicable. Indicate [what editions](documentation/styleguide/index.md#product-tier-badges)
  the feature applies to.
- **Submit a MR to the `www-gitlab-com` project.**: Add the new feature to the
  [EE features list](https://about.gitlab.com/features/).

## Act as CE when unlicensed

Since the implementation of
[GitLab CE features to work with unlicensed EE instance](https://gitlab.com/gitlab-org/gitlab/-/issues/2500)
GitLab Enterprise Edition should work like GitLab Community Edition
when no license is active. So EE features always should be guarded by
`project.feature_available?` or `group.licensed_feature_available?` (or
`License.feature_available?` if it is a system-wide feature).

Frontend features should be guarded by pushing a flag from the backend by [using `push_licensed_feature`](licensed_feature_availability.md#restricting-frontend-features), and checked using `this.glFeatures.someFeature` in the frontend.

CE specs should remain untouched as much as possible and extra specs
should be added for EE. Licensed features can be stubbed using the
spec helper `stub_licensed_features` in `EE::LicenseHelpers`.

You can force GitLab to act as CE by either deleting the `ee/` directory or by
setting the [`FOSS_ONLY` environment variable](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/helpers/is_ee_env.js)
to something that evaluates as `true`. The same works for running tests
(for example `FOSS_ONLY=1 yarn jest`).

## CI pipelines in a FOSS context

By default, merge request pipelines for development run in an EE-context only. If you are
developing features that differ between FOSS and EE, you may wish to run pipelines in a
FOSS context as well.

To run pipelines in both contexts, include `RUN AS-IF-FOSS` in the merge request title.

See the [As-if-FOSS jobs](pipelines.md#as-if-foss-jobs) pipelines documentation for more information.

## Separation of EE code

All EE code should be put inside the `ee/` top-level directory. The
rest of the code should be as close to the CE files as possible.

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

This works because for every path that is present in CE's eager-load/auto-load
paths, we add the same `ee/`-prepended path in [`config/application.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/925d3d4ebc7a2c72964ce97623ae41b8af12538d/config/application.rb#L42-52).
This also applies to views.

#### Testing EE-only features

To test an EE class that doesn't exist in CE, create the spec file as you normally
would in the `ee/spec` directory, but without the second `ee/` subdirectory.
For example, a class `ee/app/models/vulnerability.rb` would have its tests in `ee/spec/models/vulnerability_spec.rb`.

### EE features based on CE features

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
create the spec file as you normally would in the `ee/spec` directory, including the second `ee/` subdirectory.
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
- when the original implementation contains a guard clause (e.g.
  `return unless condition`), we cannot easily extend the behavior by
  overriding the method, because we can't know when the overridden method
  (i.e. calling `super` in the overriding method) would want to stop early.
  In this case, we shouldn't just override it, but update the original method
  to make it call the other method we want to extend, like a [template method
  pattern](https://en.wikipedia.org/wiki/Template_method_pattern).
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

For example, in GitLab-FOSS, the only user created by the system is `User.ghost`
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

### Code in `config/routes`

When we add `draw :admin` in `config/routes.rb`, the application tries to
load the file located in `config/routes/admin.rb`, and also try to load the
file located in `ee/config/routes/admin.rb`.

In EE, it should at least load one file, at most two files. If it cannot find
any files, an error is raised. In CE, since we don't know if an
an EE route exists, it doesn't raise any errors even if it cannot find anything.

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

EE-specific models should `extend EE::Model`.

For example, if EE has a specific `Tanuki` model, you would
place it in `ee/app/models/ee/tanuki.rb`.

### Code in `app/views/`

It's a very frequent problem that EE is adding some specific view code in a CE
view. For instance the approval code in the project's settings page.

**Mitigations**

Blocks of code that are EE-specific should be moved to partials. This
avoids conflicts with big chunks of HAML code that are not fun to
resolve when you add the indentation to the equation.

EE-specific views should be placed in `ee/app/views/`, using extra
sub-directories if appropriate.

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
                   GraphQL::STRING_TYPE,
                   required: false,
                   description: 'Tanuki name'
        end
      end
    end
  end
end
```

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
the same partial path (e.g. `shared/issuable/form/default_templates`) could
be referring to the CE partial in CE (i.e.
`app/views/shared/issuable/form/_default_templates.html.haml`), while EE
partial in EE (i.e.
`ee/app/views/shared/issuable/form/_default_templates.html.haml`). This way,
we could show different things between CE and EE.

However sometimes we would also want to reuse the CE partial in EE partial
because we might just want to add something to the existing CE partial. We
could workaround this by adding another partial with a different name, but it
would be tedious to do so.

In this case, we could as well just use `render_ce` which would ignore any EE
partials. One example would be
`ee/app/views/shared/issuable/form/_default_templates.html.haml`:

```haml
- if @project.feature_available?(:issuable_default_templates)
  = render_ce 'shared/issuable/form/default_templates'
- elsif show_promotions?
  = render 'shared/promotions/promote_issue_templates'
```

In the above example, we can't use
`render 'shared/issuable/form/default_templates'` because it would find the
same EE partial, causing infinite recursion. Instead, we could use `render_ce`
so it ignores any partials in `ee/` and then it would render the CE partial
(i.e. `app/views/shared/issuable/form/_default_templates.html.haml`)
for the same path (i.e. `shared/issuable/form/default_templates`). This way
we could easily wrap around the CE partial.

### Code in `lib/`

Place EE-specific logic in the top-level `EE` module namespace. Namespace the
class beneath the `EE` module just as you would normally.

For example, if CE has LDAP classes in `lib/gitlab/ldap/` then you would place
EE-specific LDAP classes in `ee/lib/ee/gitlab/ldap`.

### Code in `lib/api/`

It can be very tricky to extend EE features by a single line of `prepend_mod_with`,
and for each different [Grape](https://github.com/ruby-grape/grape) feature, we
might need different strategies to extend it. To apply different strategies
easily, we would use `extend ActiveSupport::Concern` in the EE module.

Put the EE module files following
[EE features based on CE features](#ee-features-based-on-ce-features).

#### EE API routes

For EE API routes, we put them in a `prepended` block:

```ruby
module EE
  module API
    module MergeRequests
      extend ActiveSupport::Concern

      prepended do
        params do
          requires :id, type: String, desc: 'The ID of a project'
        end
        resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          # ...
        end
      end
    end
  end
end
```

Note that due to namespace differences, we need to use the full qualifier for some
constants.

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

Sometimes we need EE-specific behavior in some of the APIs. Normally we could
use EE methods to override CE methods, however API routes are not methods and
therefore can't be simply overridden. We need to extract them into a standalone
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

Note that `update_merge_request_ee` doesn't do anything in CE, but
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

It's very hard to extend this in an EE module, and this is simply storing
some meta-data for a particular route. Given that, we could simply leave the
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

Note that you cannot define new factories (even nested ones) inside the `FactoryBot.modify` block. You can do so in a
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

## JavaScript code in `assets/javascripts/`

To separate EE-specific JS-files we should also move the files into an `ee` folder.

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

See the frontend guide [performance section](fe_guide/performance.md) for
information on managing page-specific JavaScript within EE.

## Vue code in `assets/javascript`

### script tag

#### Child Component only used in EE

To separate Vue template differences we should [import the components asynchronously](https://vuejs.org/v2/guide/components-dynamic-async.html#Async-Components).

Doing this allows for us to load the correct component in EE while in CE
we can load a empty component that renders nothing. This code **should**
exist in the CE repository as well as the EE repository.

```html
<script>
export default {
  components: {
    EEComponent: () => import('ee_component/components/test.vue'),
  },
};
</script>

<template>
  <div>
    <ee-component />
  </div>
</template>
```

#### For JS code that is EE only, like props, computed properties, methods, etc

- Please do not use mixins unless ABSOLUTELY NECESSARY. Please try to find an alternative pattern.

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

- **EE Child components**
  - Since we are using the asynchronous loading to check which component to load, we'd still use the component's name, check [this example](#child-component-only-used-in-ee).

- **EE extra HTML**
  - For the templates that have extra HTML in EE we should move it into a new component and use the `ee_else_ce` dynamic import

### Non Vue Files

For regular JS files, the approach is similar.

1. We keep using the [`ee_else_ce`](../development/ee_features.md#javascript-code-in-assetsjavascripts) helper, this means that EE only code should be inside the `ee/` folder.
   1. An EE file should be created with the EE only code, and it should extend the CE counterpart.
   1. For code inside functions that can't be extended, the code should be moved into a new file and we should use `ee_else_ce` helper:

#### Example

```javascript
  import eeCode from 'ee_else_ce/ee_code';

  function test() {
    const test = 'a';

    eeCode();

    return test;
  }
```

## SCSS code in `assets/stylesheets`

If a component you're adding styles for is limited to EE, it is better to have a
separate SCSS file in an appropriate directory within `app/assets/stylesheets`.

In some cases, this is not entirely possible or creating dedicated SCSS file is an overkill,
e.g. a text style of some component is different for EE. In such cases,
styles are usually kept in a stylesheet that is common for both CE and EE, and it is wise
to isolate such ruleset from rest of CE rules (along with adding comment describing the same)
to avoid conflicts during CE to EE merge.

### Bad

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

### Good

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

## GitLab-svgs

Conflicts in `app/assets/images/icons.json` or `app/assets/images/icons.svg` can
be resolved simply by regenerating those assets with
[`yarn run svg`](https://gitlab.com/gitlab-org/gitlab-svgs).

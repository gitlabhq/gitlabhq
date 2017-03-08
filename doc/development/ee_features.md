# Guidelines for implementing Enterprise Edition feature

- **Write the code and the tests.**: As with any code, EE features should have
  good test coverage to prevent regressions.
- **Write documentation.**: Add documentation to the `doc/` directory. Describe
  the feature and include screenshots, if applicable.
- **Submit a MR to the `www-gitlab-com` project.**: Add the new feature to the
  [EE features list][ee-features-list].

## Separation of EE code

Merging changes from GitLab CE to EE can result in numerous conflicts.
To reduce conflicts, EE code should be separated in to the `EE` module
as much as possible.

### Code in `app/`

Place EE-specific controllers, finders, helpers, mailers, models, policies,
serializers/entities, services, validators and workers in the top-level
`EE` module namespace, and in a specific `/ee/` sub-folder:

- `app/controllers/ee/foos_controller.rb`
- `app/finders/ee/foos_finder.rb`
- `app/helpers/ee/foos_helper.rb`
- `app/mailers/ee/foos_mailer.rb`
- `app/models/ee/foo.rb`
- `app/policies/ee/foo_policy.rb`
- `app/serializers/ee/foo_entity.rb`
- `app/serializers/ee/foo_serializer.rb`
- `app/services/ee/foo/create_service.rb`
- `app/validators/ee/foo_attr_validator.rb`
- `app/workers/ee/foo_worker.rb`

If you modify an existing part of a CE controller, model, service, worker etc.
one simple solution is to use the `prepend` strategy ([presented below](#overriding-ce-methods)).

For example to override the CE implementation of
`ApplicationController#after_sign_out_path_for`:

```ruby
def after_sign_out_path_for(resource)
  current_application_settings.after_sign_out_path.presence || new_user_session_path
end
```

Instead of modifying the method in place, you should do the following:

```ruby
class ApplicationController < ActionController::Base
  prepend EE::ApplicationController
  [...]

  def after_sign_out_path_for(resource)
    current_application_settings.after_sign_out_path.presence || new_user_session_path
  end

  [...]
end

module EE
  class ApplicationController    
    def after_sign_out_path_for(resource)
      raise NotImplementedError unless defined?(super)

      if Gitlab::Geo.secondary?
        Gitlab::Geo.primary_node.oauth_logout_url(@geo_logout_state)
      else
        super
      end
    end
  end
end
```

#### Code in `app/controllers/`

In controllers, the most common type of conflict is with `before_action` that
has a list of actions in CE but EE adds some actions to that list.

The same problem often occurs for `params.require` / `params.permit` calls.

**Mitigations**

Separate CE and EE actions/keywords. For instance for `params.require` in
`ProjectsController`:

```ruby
def project_params
  params.require(:project).permit(project_params_ce)
  # On EE, this is always:
  # params.require(:project).permit(project_params_ce << project_params_ee)
end

# Always returns an array of symbols, created however best fits the use case.
# It _should_ be sorted alphabetically.
def project_params_ce
  %i[
    description
    name
    path
  ]
end

# (On EE)
def project_params_ee
  %i[
    approvals_before_merge
    approver_group_ids
    approver_ids
    ...
  ]
end
```

#### Code in `app/models/`

EE-specific models should `extend EE::Model`.

For example, if EE has a specific `Tanuki` model, you would
place it in `app/models/ee/tanuki.rb`.

#### Code in `app/views/`

It's a very frequent problem that EE is adding some specific view code in a CE
view. For instance the approval code in the project's settings page.

**Mitigations**

Blocks of code that are EE-specific should be moved to partials as much as
possible to avoid conflicts with big chunks of HAML code that that are not
fun to resolve when you add the indentation to the equation.

### Code in `lib/`

Place EE-specific logic in the top-level `EE` module namespace. Namespace the
class beneath the `EE` module just as you would normally.

For example, if CE has LDAP classes in `lib/gitlab/ldap/` then you would place
EE-specific LDAP classes in `lib/ee/gitlab/ldap`.

### Classes vs. Module Mixins

If the feature being developed is not present in any form in CE, separation is
easier - build the class entirely in the `EE` namespace. For features that build
on existing CE features, write a module in the `EE` namespace and include it
in the CE class. This makes conflicts less likely during CE to EE merges
because only one line is added to the CE class - the `include` statement.

#### Overriding CE methods

There are two ways for overriding a method that's defined in CE:

- changing the method's body in place
- override the method's body by using `prepend` which lets you override a
  method in a class with a method from a module, and still access the class's
  implementation with `super`.

The `prepend` method should always be preferred but there are a few gotchas with it:

- you should always add a `raise NotImplementedError unless defined?(super)`
  guard clause in the "overrider" method to ensure that if the method gets
  renamed in CE, the EE override won't be silently forgotten.
- when the "overrider" would add a line in the middle of the CE implementation,
  it usually means that you'd better refactor the method to split it in
  smaller methods that can be more easily and automatically overriden.
- when the original implementation contains a guard clause (e.g.
  `return unless condition`), it doesn't return from the overriden method (it's
  actually the same behavior as with method overridding via inheritance). In
  this case, it's usually better to create a "hook" method that is empty in CE,
  and with the EE-specific implementation in EE
- sometimes for one-liner methods that don't change often it can be more
  pragmatic to just change the method in place since conflicts resolution
  should be trivial in this case. Use your best judgement!

[ee-features-list]: https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/features.yml

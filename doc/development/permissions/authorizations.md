---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Authorization
---

## Where should permissions be checked?

When deciding where to check permissions, apply defense-in-depth by implementing multiple checks at
different layers. Starting with low-level layers, such as finders and services,
followed by high-level layers, such as GraphQL, public REST API, and controllers.

For more information, see [guidelines for reusing abstractions](../reusing_abstractions.md).

Protecting the same resources at many points means that if one layer of defense is compromised
or missing, customer data is still protected by the additional layers.

For more information on permissions, see the permissions section in the [secure coding guidelines](../secure_coding_guidelines.md#permissions).

### Considerations

Services or finders are appropriate locations because:

- Multiple endpoints share services or finders so downstream logic is more likely to be re-used.
- Sometimes authorization logic must be incorporated in DB queries to filter records.
- You should avoid permission checks at the display layer except to provide better UX,
  and not as a security check. For example, showing and hiding non-data elements like buttons.

The downsides to defense-in-depth are:

- `DeclarativePolicy` rules are relatively performant, but conditions may perform database calls.
- Higher maintenance costs.

### Exceptions

Developers can choose to do authorization in only a single area after weighing
the risks and drawbacks for their specific case.

Prefer domain logic (services or finders) as the source of truth when making exceptions.

Logic, like backend worker logic, might not need authorization based on the current user.
If the service or finder's constructor does not expect `current_user`, then it typically does not
check permissions.

### Frontend

When using an ability check in UI elements, make sure to _also_ use an ability
check for the underlying backend code, if there is any. This ensures there is
absolutely no way to use the feature until the user has proper access.

If the UI element is HAML, you can use embedded Ruby to check if
`Ability.allowed?(user, action, subject)`.

If the UI element is JavaScript or Vue, use the `push_frontend_ability` method,
which is available to all controllers that inherit from `ApplicationController`.
You can use this method to expose the ability, for example:

```ruby
before_action do
  push_frontend_ability(ability: :read_project, resource: @project, user: current_user)
end
```

You can then check the state of the ability in JavaScript as follows:

```javascript
if ( gon.abilities.readProject ) {
  // ...
}
```

The name of the ability in JavaScript is always camelCase,
so checking for `gon.abilities.read_project` would not work.

To check for an ability in a Vue template, see the
[developer documentation for access abilities in Vue](../fe_guide/vue.md#accessing-abilities).

### Tips

If a class accepts `current_user`, then it may be responsible for authorization.

### Example: Adding a new API endpoint

By default, we authorize at the endpoint. Checking an existing ability may make sense; if not, then we probably need to add one.

As an aside, most endpoints can be cleanly categorized as a CRUD (create, read, update, destroy) action on a resource. The services and abilities follow suit, which is why many are named like `Projects::CreateService` or `:read_project`.

Say, for example, we extract the whole endpoint into a service. The `can?` check will now be in the service. Say the service reuses an existing finder, which we are modifying for our purposes. Should we make the finder check an ability?

- If the finder does not accept `current_user`, and therefore does not check permissions, then probably no.
- If the finder accepts `current_user`, and does not check permissions, then you should double-check other usages of the finder, and you might consider adding authorization.
- If the finder accepts `current_user`, and already checks permissions, then either we need to add our case, or the existing checks are appropriate.

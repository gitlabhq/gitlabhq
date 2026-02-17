---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: The `DeclarativePolicy` framework
---

The DeclarativePolicy framework is designed to assist in performance of policy checks, and to
enable ease of extension for EE. The DSL code in `app/policies` is what `Ability.allowed?` uses
to check whether a particular action is allowed on a subject.

The policy used is based on the subject's class name - so `Ability.allowed?(user, :some_ability, project)`
creates a `ProjectPolicy` and check permissions on that.

The Ruby gem source is available in the [declarative-policy](https://gitlab.com/gitlab-org/ruby/gems/declarative-policy)
GitLab project.

For information about naming and conventions, see [permission conventions](permissions/conventions.md).

## Managing Permission Rules

Permissions are broken into two parts: `conditions` and `rules`. Conditions are boolean expressions
that can access the database and the environment, while rules are statically configured combinations
of expressions and other rules that enable or prevent certain abilities. For an ability to be
allowed, it must be enabled by at least one rule, and not prevented by any.

### Conditions

Conditions are defined by the `condition` method, and are given a name and a block. The block is
executed in the context of the policy object - so it can access `@user` and `@subject`, as well as
call any methods defined on the policy. `@user` may be nil (in the anonymous case), but `@subject`
is guaranteed to be a real instance of the subject class.

```ruby
class FooPolicy < BasePolicy
  condition(:is_public) do
    # @subject guaranteed to be an instance of Foo
    @subject.public?
  end

  # instance methods can be called from the condition as well
  condition(:thing) { check_thing }

  def check_thing
    # ...
  end
end
```

When you define a condition, a predicate method is defined on the policy to check whether that
condition passes - so in the above example, an instance of `FooPolicy` also responds to
`#is_public?` and `#thing?`.

Conditions are cached according to their scope. Scope and ordering is covered later.

### Rules

A `rule` is a logical combination of conditions and other rules, that are configured to enable or
prevent certain abilities. The rule configuration is static - a rule's logic cannot touch the
database or know about `@user` or `@subject`. This allows us to cache only at the condition level.
Rules are specified through the `rule` method, which takes a block of DSL configuration, and returns
an object that responds to `#enable` or `#prevent`:

```ruby
class FooPolicy < BasePolicy
  # ...

  rule { is_public }.enable :read
  rule { ~thing }.prevent :read

  # equivalently,
  rule { is_public }.policy do
    enable :read
  end

  rule { ~thing }.policy do
    prevent :read
  end
end
```

Within the rule DSL, you can use:

- A regular word mentions a condition by name - a rule that is in effect when that condition is truthy.
- `~` indicates negation, also available as `negate`.
- `&` and `|` are logical combinations, also available as `all?(...)` and `any?(...)`.
- `can?(:other_ability)` delegates to the rules that apply to `:other_ability`. This is distinct
  from the instance method `can?`, which can check dynamically - this only configures a delegation
  to another ability.

`~`, `&` and `|` operators are overridden methods in
[`DeclarativePolicy::Rule::Base`](https://gitlab.com/gitlab-org/ruby/gems/declarative-policy/-/blob/main/lib/declarative_policy/rule.rb).

Do not use boolean operators such as `&&` and `||` within the rule DSL,
as conditions within rule blocks are objects, not booleans. The same
applies for ternary operators (`condition ? ... : ...`), and `if`
blocks. These operators cannot be overridden, and are hence banned via a
[custom cop](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49771).

## Scores, Order, Performance

To see how the rules are evaluated into a judgment, open a Rails console and run:
`policy.debug(:some_ability)`. This prints the rules in the order they are evaluated.

For example, to debug `IssuePolicy`. You might run the following command:

```ruby
user = User.find_by(username: 'sidneyjones')
issue = Issue.first
policy = IssuePolicy.new(user, issue)
policy.debug(:read_issue)
```

An example debug output would look like:

```ruby
- [0] prevent when all?(confidential, ~can_read_confidential) ((@sidneyjones : Issue/1))
- [0] prevent when archived ((@sidneyjones : Project/4))
- [0] prevent when issues_disabled ((@sidneyjones : Project/4))
- [0] prevent when all?(anonymous, ~public_project) ((@sidneyjones : Project/4))
+ [32] enable when can?(:reporter_access) ((@sidneyjones : Project/4))
```

Each line represents a rule that was evaluated. There are a few things to note:

1. The `-` symbol indicates the rule block was evaluated to be
   `false`. A `+` symbol indicates the rule block was evaluated to be
   `true`.
1. The number inside the brackets indicates the score.
1. The last part of the line (for example, `@sidneyjones : Issue/1`) shows the username
   and subject for that rule.

Here you can see that the first four rules were evaluated `false` for
which user and subject. For example, you can see in the last line that
the rule was activated because the user `sidneyjones` had the Reporter role on
`Project/4`.

When a policy is asked whether a particular ability is allowed
(`policy.allowed?(:some_ability)`), it does not necessarily have to
compute all the conditions on the policy. First, only the rules relevant
to that particular ability are selected. Then, the execution model takes
advantage of short-circuiting, and attempts to sort rules based on a
heuristic of how expensive they are to calculate. The sorting is
dynamic and cache-aware, so that previously calculated conditions are
considered first, before computing other conditions.

The score is chosen by a developer via the `score:` parameter
in a `condition` to denote how expensive evaluating this rule would be
relative to other rules.

## Scope

Sometimes, a condition only uses data from `@user` or only from `@subject`. In this case, we want
to change the scope of the caching, so that we don't recalculate conditions unnecessarily.
For example, given:

```ruby
class FooPolicy < BasePolicy
  condition(:expensive_condition) { @subject.expensive_query? }

  rule { expensive_condition }.enable :some_ability
end
```

Naively, if we call `Ability.allowed?(user1, :some_ability, foo)` and `Ability.allowed?(user2, :some_ability, foo)`,
we would have to calculate the condition twice - since they are for different users. But if we use the
`scope: :subject` option:

```ruby
  condition(:expensive_condition, scope: :subject) { @subject.expensive_query? }
```

then the result of the condition is cached globally only based on the subject - so it is not
calculated repeatedly for different users. Similarly, `scope: :user` caches only based on the user.

You can use the `:global` scope when the condition is universally true:

```ruby
  condition(:earth_exists, scope: :global) { Planet::Earth.exists? }
```

For more information about scopes, see the gem's
[caching documentation](https://gitlab.com/gitlab-org/ruby/gems/declarative-policy/-/blob/main/doc/caching.md#cache-sharing-scopes).

> [!warning]
> If you use a `:scope` option when the condition actually uses data from both user and subject
> (including a simple anonymous check!) your result is cached at too global of a scope and
> results in cache bugs.

Sometimes we are checking permissions for a lot of users for one subject, or a lot of subjects for
one user. In this case, we want to set a *preferred scope* - that is, tell the system that we
prefer rules that can be cached on the repeated parameter.
For example, in `Ability.users_that_can_read_project`:

```ruby
def users_that_can_read_project(users, project)
  DeclarativePolicy.subject_scope do
    users.select { |u| allowed?(u, :read_project, project) }
  end
end
```

This, for example, prefers checking `project.public?` to checking `user.admin?`.

## Delegation

Delegation is the inclusion of rules from another policy, on a different subject. For example:

```ruby
class FooPolicy < BasePolicy
  delegate { @subject.project }
end
```

includes all rules from `ProjectPolicy`. The delegated conditions are evaluated with the correct
delegated subject, and are sorted along with the regular rules in the policy. Only the relevant
rules for a particular ability are actually considered.

### Overrides

Policies can opt out of delegated abilities when the delegation does not make sense.

Delegated policies may define some abilities in a way that is incorrect for the
delegating policy. For example, consider a parent-child relationship where some
abilities can be inferred and some cannot:

```ruby
class ParentPolicy < BasePolicy
  condition(:speaks_spanish) { @subject.spoken_languages.include?(:es) }
  condition(:has_license) { @subject.driving_license.present? }
  condition(:is_employed) { @subject.is_employed? }

  rule { speaks_spanish }.enable :read_spanish
  rule { has_license }.enable :drive_car
  rule { is_employed }.enable :earn_money
  rule { ~is_employed }.prevent :earn_money
end
```

If the child policy delegates to the parent policy, some values would be
incorrect. You might correctly infer that the child can speak the parent's
language, but you can't infer that the child can drive or earn money just
because the parent can.

You can handle some of these cases. For example, you can forbid driving in the
child policy:

```ruby
class ChildPolicy < BasePolicy
  delegate { @subject.parent }

  rule { default }.prevent :drive_car
end
```

Earning money is more complex. Because of the `prevent` call in the parent
policy, if the parent is not employed, neither the parent nor the child can
earn money. Even explicitly enabling `:earn_money` in the child policy would not
work.

Removing the `prevent` call in the `ParentPolicy` doesn't help because the rules
that enable `:earn_money` differ between the parent and child policy.

With delegation, child resources can only enable permissions that the parent policy
has not explicitly prevented. In this case, only children with parents who earn money
can earn money themselves. However, a parent who doesn't earn money might still
want to give a child an allowance.

The solution is to override the `:earn_money` ability in the child policy:

```ruby
class ChildPolicy < BasePolicy
  delegate { @subject.parent }

  overrides :earn_money

  condition(:has_allowance) { @subject.has_allowance? }

  rule { has_allowance }.enable :earn_money
end
```

With this definition, the `ChildPolicy` never looks in the `ParentPolicy` to
satisfy `:earn_money`, but still uses it for any other abilities. The child
policy can then define `:earn_money` in a way that makes sense for `Child`
and not `Parent`.

### Alternatives to using `overrides`

Overriding policy delegation is complex, for the same reason delegation is
complex - it involves reasoning about logical inference, and being clear about
semantics. Misuse of `override` has the potential to duplicate code, and
potentially introduce security bugs, allowing things that should be prevented.
For this reason, it should be used only when other approaches are not feasible.

Other approaches can include for example using different ability names. Earning
an income and earning an allowance are semantically distinct, and they
could be named differently (perhaps `earn_salary` and `earn_allowance` in this case).
It can depend on how polymorphic the call site is. If you know that we always check
the policy with a `Parent` or a `Child`, then we can choose the appropriate ability
name. If the call site is polymorphic, then we cannot do that.

## Specifying Policy Class

You can also override the Policy used for a given subject:

```ruby
class Foo

  def self.declarative_policy_class
    'SomeOtherPolicy'
  end
end
```

This uses and checks permissions on the `SomeOtherPolicy` class rather than the usual
calculated `FooPolicy` class.

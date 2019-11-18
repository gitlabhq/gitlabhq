# `DeclarativePolicy` framework

The DeclarativePolicy framework is designed to assist in performance of policy checks, and to enable ease of extension for EE. The DSL code in `app/policies` is what `Ability.allowed?` uses to check whether a particular action is allowed on a subject.

The policy used is based on the subject's class name - so `Ability.allowed?(user, :some_ability, project)` will create a `ProjectPolicy` and check permissions on that.

## Managing Permission Rules

Permissions are broken into two parts: `conditions` and `rules`. Conditions are boolean expressions that can access the database and the environment, while rules are statically configured combinations of expressions and other rules that enable or prevent certain abilities. For an ability to be allowed, it must be enabled by at least one rule, and not prevented by any.

### Conditions

Conditions are defined by the `condition` method, and are given a name and a block. The block will be executed in the context of the policy object - so it can access `@user` and `@subject`, as well as call any methods defined on the policy. Note that `@user` may be nil (in the anonymous case), but `@subject` is guaranteed to be a real instance of the subject class.

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

When you define a condition, a predicate method is defined on the policy to check whether that condition passes - so in the above example, an instance of `FooPolicy` will also respond to `#is_public?` and `#thing?`.

Conditions are cached according to their scope. Scope and ordering will be covered later.

### Rules

A `rule` is a logical combination of conditions and other rules, that are configured to enable or prevent certain abilities. It is important to note that the rule configuration is static - a rule's logic cannot touch the database or know about `@user` or `@subject`. This allows us to cache only at the condition level. Rules are specified through the `rule` method, which takes a block of DSL configuration, and returns an object that responds to `#enable` or `#prevent`:

```ruby
class FooPolicy < BasePolicy
  # ...

  rule { is_public }.enable :read
  rule { thing }.prevent :read

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
- `~` indicates negation.
- `&` and `|` are logical combinations, also available as `all?(...)` and `any?(...)`.
- `can?(:other_ability)` delegates to the rules that apply to `:other_ability`. Note that this is distinct from the instance method `can?`, which can check dynamically - this only configures a delegation to another ability.

## Scores, Order, Performance

To see how the rules get evaluated into a judgment, it is useful in a console to use `policy.debug(:some_ability)`. This will print the rules in the order they are evaluated.

For example, let's say you wanted to debug `IssuePolicy`. You might run
the debugger in this way:

```ruby
user = User.find_by(username: 'john')
issue = Issue.first
policy = IssuePolicy.new(user, issue)
policy.debug(:read_issue)
```

An example debug output would look as follows:

```ruby
- [0] prevent when all?(confidential, ~can_read_confidential) ((@john : Issue/1))
- [0] prevent when archived ((@john : Project/4))
- [0] prevent when issues_disabled ((@john : Project/4))
- [0] prevent when all?(anonymous, ~public_project) ((@john : Project/4))
+ [32] enable when can?(:reporter_access) ((@john : Project/4))
```

Each line represents a rule that was evaluated. There are a few things to note:

1. The `-` or `+` symbol indicates whether the rule block was evaluated to be
   `false` or `true`, respectively.
1. The number inside the brackets indicates the score.
1. The last part of the line (e.g. `@john : Issue/1`) shows the username
   and subject for that rule.

Here you can see that the first four rules were evaluated `false` for
which user and subject. For example, you can see in the last line that
the rule was activated because the user `root` had at reporter access to
the `Project/4`.

When a policy is asked whether a particular ability is allowed
(`policy.allowed?(:some_ability)`), it does not necessarily have to
compute all the conditions on the policy. First, only the rules relevant
to that particular ability are selected. Then, the execution model takes
advantage of short-circuiting, and attempts to sort rules based on a
heuristic of how expensive they will be to calculate. The sorting is
dynamic and cache-aware, so that previously calculated conditions will
be considered first, before computing other conditions.

Note that the score is chosen by a developer via the `score:` parameter
in a `condition` to denote how expensive evaluating this rule would be
relative to other rules.

## Scope

Sometimes, a condition will only use data from `@user` or only from `@subject`. In this case, we want to change the scope of the caching, so that we don't recalculate conditions unnecessarily. For example, given:

```ruby
class FooPolicy < BasePolicy
  condition(:expensive_condition) { @subject.expensive_query? }

  rule { expensive_condition }.enable :some_ability
end
```

Naively, if we call `Ability.can?(user1, :some_ability, foo)` and `Ability.can?(user2, :some_ability, foo)`, we would have to calculate the condition twice - since they are for different users. But if we use the `scope: :subject` option:

```ruby
  condition(:expensive_condition, scope: :subject) { @subject.expensive_query? }
```

then the result of the condition will be cached globally only based on the subject - so it will not be calculated repeatedly for different users. Similarly, `scope: :user` will cache only based on the user.

**DANGER**: If you use a `:scope` option when the condition actually uses data from
both user and subject (including a simple anonymous check!) your result will be cached at too global of a scope and will result in cache bugs.

Sometimes we are checking permissions for a lot of users for one subject, or a lot of subjects for one user. In this case, we want to set a *preferred scope* - i.e. tell the system that we prefer rules that can be cached on the repeated parameter. For example, in `Ability.users_that_can_read_project`:

```ruby
def users_that_can_read_project(users, project)
  DeclarativePolicy.subject_scope do
    users.select { |u| allowed?(u, :read_project, project) }
  end
end
```

This will, for example, prefer checking `project.public?` to checking `user.admin?`.

## Delegation

Delegation is the inclusion of rules from another policy, on a different subject. For example:

```ruby
class FooPolicy < BasePolicy
  delegate { @subject.project }
end
```

will include all rules from `ProjectPolicy`. The delegated conditions will be evaluated with the correct delegated subject, and will be sorted along with the regular rules in the policy. Note that only the relevant rules for a particular ability will actually be considered.

## Specifying Policy Class

You can also override the Policy used for a given subject:

```ruby
class Foo

  def self.declarative_policy_class
    'SomeOtherPolicy'
  end
end
```

This will use & check permissions on the `SomeOtherPolicy` class rather than the usual calculated `FooPolicy` class.

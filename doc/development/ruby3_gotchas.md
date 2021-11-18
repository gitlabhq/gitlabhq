---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Ruby 3 gotchas

This section documents several problems we found while working on [Ruby 3 support](https://gitlab.com/groups/gitlab-org/-/epics/5149)
and which led to subtle bugs or test failures that were difficult to understand. We encourage every GitLab contributor
who writes Ruby code on a regular basis to familiarize themselves with these issues.

To find the complete list of changes to the Ruby 3 language and standard library, see
[Ruby Changes](https://rubyreferences.github.io/rubychanges/3.0.html).

## `Hash#each` consistently yields a 2-element array to lambdas

Consider the following code snippet:

```ruby
def foo(a, b)
  p [a, b]
end

def bar(a, b = 2)
  p [a, b]
end

foo_lambda = method(:foo).to_proc
bar_lambda = method(:bar).to_proc

{ a: 1 }.each(&foo_lambda)
{ a: 1 }.each(&bar_lambda)
```

In Ruby 2.7, the output of this program suggests that yielding hash entries to lambdas behaves
differently depending on how many required arguments there are:

```ruby
# Ruby 2.7
{ a: 1 }.each(&foo_lambda) # prints [:a, 1]
{ a: 1 }.each(&bar_lambda) # prints [[:a, 1], 2]
```

Ruby 3 makes this behavior consistent and always attempts to yield hash entries as a single `[key, value]` array:

```ruby
# Ruby 3.0
{ a: 1 }.each(&foo_lambda) # `foo': wrong number of arguments (given 1, expected 2) (ArgumentError)
{ a: 1 }.each(&bar_lambda) # prints [[:a, 1], 2]
```

To write code that works under both 2.7 and 3.0, consider the following options:

- Always pass the lambda body as a block: `{ a: 1 }.each { |a, b| p [a, b] }`.
- Deconstruct the lambda arguments: `{ a: 1 }.each(&->((a, b)) { p [a, b] })`.

We recommend always passing the block explicitly, and prefer two required arguments as block parameters.

To learn more, see [Ruby issue 12706](https://bugs.ruby-lang.org/issues/12706).

## `Symbol#to_proc` returns signature metadata consistent with lambdas

A common idiom in Ruby is to obtain `Proc` objects using the `&:<symbol>` shorthand and
pass them to higher-order functions:

```ruby
[1, 2, 3].each(&:to_s)
```

Ruby desugars `&:<symbol>` to `Symbol#to_proc`. We can call it with
the method _receiver_ as its first argument (here: `Integer`), and all method _arguments_
(here: none) as its remaining arguments.

This behaves the same in both Ruby 2.7 and Ruby 3. Where Ruby 3 diverges is when capturing
this `Proc` object and inspecting its call signature.
This is often done when writing DSLs or using other forms of meta-programming:

```ruby
p = :foo.to_proc # This usually happens via a conversion through `&:foo`

# Ruby 2.7: prints [[:rest]] (-1)
# Ruby 3.0: prints [[:req], [:rest]] (-2)
puts "#{p.parameters} (#{p.arity})"
```

Ruby 2.7 reports zero required and one optional parameter for this `Proc` object, while Ruby 3 reports one required
and one optional parameter. Ruby 2.7 is incorrect: the first argument must
always be passed, as it is the receiver of the method the `Proc` object represents, and methods cannot be
called without a receiver.

Ruby 3 corrects this: the code that tests `Proc` object arity or parameter lists might now break and
has to be updated.

To learn more, see [Ruby issue 16260](https://bugs.ruby-lang.org/issues/16260).

## `OpenStruct` does not evaluate fields lazily

The `OpenStruct` implementation has undergone a partial rewrite in Ruby 3, resulting in
behavioral changes. In Ruby 2.7, `OpenStruct` defines methods lazily, when the method is first accessed.
In Ruby 3.0, it defines these methods eagerly in the initializer, which can break classes that inherit from `OpenStruct`
and override these methods.

Don't inherit from `OpenStruct` for these reasons; ideally, don't use it at all.
`OpenStruct` is [considered problematic](https://ruby-doc.org/stdlib-3.0.2/libdoc/ostruct/rdoc/OpenStruct.html#class-OpenStruct-label-Caveats).
When writing new code, prefer a `Struct` instead, which is simpler in implementation, although less flexible.

## `Regexp` and `Range` instances are frozen

It is not necessary anymore to explicitly freeze `Regexp` or `Range` instances because Ruby 3 freezes
them automatically upon creation.

This has a subtle side-effect: Tests that stub method calls on these types now fail with an error because
RSpec cannot stub frozen objects:

```ruby
# Ruby 2.7: works
# Ruby 3.0: error: "can't modify frozen object"
allow(subject.function_returning_range).to receive(:max).and_return(42)
```

Rewrite affected tests by not stubbing method calls on frozen objects. The example above can be rewritten as:

```ruby
# Works with any Ruby version
allow(subject).to receive(:function_returning_range).and_return(1..42)
```

## Table tests fail with Ruby 3.0.2

Ruby 3.0.2 has a known bug that causes [table tests](testing_guide/best_practices.md#table-based--parameterized-tests)
to fail when table values consist of integer values.
The reasons are documented in [issue 337614](https://gitlab.com/gitlab-org/gitlab/-/issues/337614).
This problem has been fixed in Ruby and the fix is expected to be included in Ruby 3.0.3.

The problem only affects users who run an unpatched Ruby 3.0.2. This is likely the case when you
installed Ruby manually or via tools like `asdf`. Users of the `gitlab-development-kit (GDK)`
are also affected by this problem.

Build images are not affected because they include the patch set addressing this bug.

---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Ruby 3 gotchas
---

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

For more information, see [Ruby issue 12706](https://bugs.ruby-lang.org/issues/12706).

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

For more information, see [Ruby issue 16260](https://bugs.ruby-lang.org/issues/16260).

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

## Deprecations are not caught in DeprecationToolkit if the method is stubbed

We rely on `deprecation_toolkit` to fail fast when using functionality that is deprecated in Ruby 2 and removed in Ruby 3.
A common issue caught during the transition from Ruby 2 to Ruby 3 relates to
the [separation of positional and keyword arguments in Ruby 3.0](https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/).

Unfortunately, if the author has stubbed such methods in tests, deprecations would not be caught.
We run automated detection for this warning in tests via `deprecation_toolkit`,
but it relies on the fact that `Kernel#warn` emits a warning, so stubbing out this call will effectively remove the call to warn, which means `deprecation_toolkit` will never see the deprecation warnings.
Stubbing out the implementation removes that warning, and we never pick it up, so the build is green.

Refer to [issue 364099](https://gitlab.com/gitlab-org/gitlab/-/issues/364099) for more context.

## Testing in `irb` and `rails console`

Another pitfall is that testing in `irb`/`rails c` silences the deprecation warning,
since `irb` in Ruby 2.7.x has a [bug](https://bugs.ruby-lang.org/issues/17377) that prevents deprecation warnings from showing.

When writing code and performing code reviews, pay extra attention to method calls of the form `f({k: v})`.
This is valid in Ruby 2 when `f` takes either a `Hash` or keyword arguments, but Ruby 3 only considers this valid if `f` takes a `Hash`.
For Ruby 3 compliance, this should be changed to one of the following invocations if `f` takes keyword arguments:

- `f(**{k: v})`
- `f(k: v)`

## RSpec `with` argument matcher fails for shorthand Hash syntax

Because keyword arguments ("kwargs") are a first-class concept in Ruby 3, keyword arguments are not
converted into internal `Hash` instances anymore. This leads to RSpec method argument matchers failing
when the receiver takes a positional options hash instead of kwargs:

```ruby
def m(options={}); end
```

```ruby
expect(subject).to receive(:m).with(a: 42)
```

In Ruby 3 this expectations fails with the following error:

```plaintext
  Failure/Error:

     #<subject> received :m with unexpected arguments
       expected: ({:a=>42})
            got: ({:a=>42})
```

This happens because RSpec uses a kwargs argument matcher here, but the method takes a hash.
It works in Ruby 2, because `a: 42` is converted to a hash first and RSpec will use a hash argument matcher.

A workaround is to not use the shorthand syntax and pass an actual `Hash` instead whenever we know a method
to take an options hash:

```ruby
# Note the braces around the key-value pair.
expect(subject).to receive(:m).with({ a: 42 })
```

For more information, see [the official issue report for RSpec](https://github.com/rspec/rspec-mocks/issues/1460).

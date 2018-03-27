## Modules with instance variables could be considered harmful

### Background

Rails somehow encourages people using modules and instance variables
everywhere. For example, using instance variables in the controllers,
helpers, and views. They're also encouraging the use of
`ActiveSupport::Concern`, which further strengthens the idea of
saving everything in a giant, single object, and people could access
everything in that one giant object.

### The problems

Of course this is convenient to develop, because we just have everything
within reach. However this has a number of downsides when that chosen object
is growing, it would later become out of control for the same reason.

There are just too many things in the same context, and we don't know if
those things are tightly coupled or not, depending on each others or not.
It's very hard to tell when the complexity grows to a point, and it makes
tracking the code also extremely hard. For example, a class could be using
3 different instance variables, and all of them could be initialized and
manipulated from 3 different modules. It's hard to track when those variables
start giving us troubles. We don't know which module would suddenly change
one of the variables. Everything could touch anything.

### Similar concerns

People are saying multiple inheritance is bad. Mixing multiple modules with
multiple instance variables scattering everywhere suffer from the same issue.
The same applies to `ActiveSupport::Concern`. See:
[Consider replacing concerns with dedicated classes & composition](
https://gitlab.com/gitlab-org/gitlab-ce/issues/23786)

There's also a similar idea:
[Use decorators and interface segregation to solve overgrowing models problem](
https://gitlab.com/gitlab-org/gitlab-ce/issues/13484)

Note that `included` doesn't solve the whole issue. They define the
dependencies, but they still allow each modules to talk implicitly via the
instance variables in the final giant object, and that's where the problem is.

### Solutions

We should split the giant object into multiple objects, and they communicate
with each other with the API, i.e. public methods. In short, composition over
inheritance. This way, each smaller objects would have their own respective
limited states, i.e. instance variables. If one instance variable goes wrong,
we would be very clear that it's from that single small object, because
no one else could be touching it.

With clearly defined API, this would make things less coupled and much easier
to debug and track, and much more extensible for other objects to use, because
they communicate in a clear way, rather than implicit dependencies.

### Acceptable use

However, it's not always bad to use instance variables in a module,
as long as it's contained in the same module; that is, no other modules or
objects are touching them, then it would be an acceptable use.

We especially allow the case where a single instance variable is used with
`||=` to setup the value. This would look like:

``` ruby
module M
  def f
    @f ||= true
  end
end
```

Unfortunately it's not easy to code more complex rules into the cop, so
we rely on people's best judgement. If we could find another good pattern
we could easily add to the cop, we should do it.

### How to rewrite and avoid disabling this cop

Even if we could just disable the cop, we should avoid doing so. Some code
could be easily rewritten in simple form. Consider this acceptable method:

``` ruby
module Gitlab
  module Emoji
    def emoji_unicode_version(name)
      @emoji_unicode_versions_by_name ||=
        JSON.parse(File.read(Rails.root.join('fixtures', 'emojis', 'emoji-unicode-version-map.json')))
      @emoji_unicode_versions_by_name[name]
    end
  end
end
```

This method is totally fine because it's already self-contained. No other
methods should be using `@emoji_unicode_versions_by_name` and we're good.
However it's still offending the cop because it's not just `||=`, and the
cop is not smart enough to judge that this is fine.

On the other hand, we could split this method into two:

``` ruby
module Gitlab
  module Emoji
    def emoji_unicode_version(name)
      emoji_unicode_versions_by_name[name]
    end

    private

    def emoji_unicode_versions_by_name
      @emoji_unicode_versions_by_name ||=
        JSON.parse(File.read(Rails.root.join('fixtures', 'emojis', 'emoji-unicode-version-map.json')))
    end
  end
end
```

Now the cop won't complain. Here's a bad example which we could rewrite:

``` ruby
module SpamCheckService
  def filter_spam_check_params
    @request            = params.delete(:request)
    @api                = params.delete(:api)
    @recaptcha_verified = params.delete(:recaptcha_verified)
    @spam_log_id        = params.delete(:spam_log_id)
  end

  def spam_check(spammable, user)
    spam_service = SpamService.new(spammable, @request)

    spam_service.when_recaptcha_verified(@recaptcha_verified, @api) do
      user.spam_logs.find_by(id: @spam_log_id)&.update!(recaptcha_verified: true)
    end
  end
end
```

There are several implicit dependencies here. First, `params` should be
defined before use. Second, `filter_spam_check_params` should be called
before `spam_check`. These are all implicit and the includer could be using
those instance variables without awareness.

This should be rewritten like:

``` ruby
class SpamCheckService
  def initialize(request:, api:, recaptcha_verified:, spam_log_id:)
    @request            = request
    @api                = api
    @recaptcha_verified = recaptcha_verified
    @spam_log_id        = spam_log_id
  end

  def spam_check(spammable, user)
    spam_service = SpamService.new(spammable, @request)

    spam_service.when_recaptcha_verified(@recaptcha_verified, @api) do
      user.spam_logs.find_by(id: @spam_log_id)&.update!(recaptcha_verified: true)
    end
  end
end
```

And use it like:

``` ruby
class UpdateSnippetService < BaseService
  def execute
    # ...
    spam = SpamCheckService.new(params.slice!(:request, :api, :recaptcha_verified, :spam_log_id))

    spam.check(snippet, current_user)
    # ...
  end
end
```

This way, all those instance variables are isolated in `SpamCheckService`
rather than whatever includes the module, and those modules which were also
included, making it much easier to track down any issues,
and reducing the chance of having name conflicts.

### How to disable this cop

Put the disabling comment right after your code in the same line:

``` ruby
module M
  def violating_method
    @f + @g # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end
end
```

If there are multiple lines, you could also enable and disable for a section:

``` ruby
module M
  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def violating_method
    @f = 0
    @g = 1
    @h = 2
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end
```

Note that you need to enable it at some point, otherwise everything below
won't be checked.

### Things we might need to ignore right now

Because of the way Rails helpers and mailers work, we might not be able to
avoid the use of instance variables there. For those cases, we could ignore
them at the moment. At least we're not going to share those modules with
other random objects, so they're still somewhat isolated.

### Instance variables in views

They're bad because we can't easily tell who's using the instance variables
(from controller's point of view) and where we set them up (from partials'
point of view), making it extremely hard to track data dependency.

We're trying to use something like this instead:

``` haml
= render 'projects/commits/commit', commit: commit, ref: ref, project: project
```

And in the partial:

``` haml
- ref = local_assigns.fetch(:ref)
- commit = local_assigns.fetch(:commit)
- project = local_assigns.fetch(:project)
```

This way it's clearer where those values were coming from, and we gain the
benefit to have typo check over using instance variables. In the future,
we should also forbid the use of instance variables in partials.

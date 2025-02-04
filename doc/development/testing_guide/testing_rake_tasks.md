---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Testing Rake tasks
---

To make testing Rake tasks a little easier:

- Use RSpec's metadata tag `type: :task` or
- Place your spec in `spec/tasks` or `ee/spec/tasks`

By doing so, `RakeHelpers` is included which exposes a `run_rake_task(<task>)`
method to make executing tasks possible.

See `spec/support/helpers/rake_helpers.rb` for all available methods.

`$stdout` can be redirected by adding `:silence_stdout`.

Example:

```ruby
require 'spec_helper'

describe 'gitlab:shell rake tasks', :silence_stdout do
  before do
    Rake.application.rake_require 'tasks/gitlab/shell'

    stub_warn_user_is_not_gitlab
  end

 describe 'install task' do
    it 'invokes create_hooks task' do
      expect(Rake::Task['gitlab:shell:create_hooks']).to receive(:invoke)

      run_rake_task('gitlab:shell:install')
    end
  end
end
```

---

[Return to Testing documentation](_index.md)

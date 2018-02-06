# Testing Rake tasks

To make testing Rake tasks a little easier, there is a helper that can be included
in lieu of the standard Spec helper. Instead of `require 'spec_helper'`, use
`require 'rake_helper'`. The helper includes `spec_helper` for you, and configures
a few other things to make testing Rake tasks easier.

At a minimum, requiring the Rake helper will redirect `stdout`, include the
runtime task helpers, and include the `RakeHelpers` Spec support module.

The `RakeHelpers` module exposes a `run_rake_task(<task>)` method to make
executing tasks simple. See `spec/support/rake_helpers.rb` for all available
methods.

Example:

```ruby
require 'rake_helper'

describe 'gitlab:shell rake tasks' do
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

[Return to Testing documentation](index.md)

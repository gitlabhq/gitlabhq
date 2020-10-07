# Finders

These types of classes are responsible for retrieving collection items based on different conditions.
They prevent lookup methods in models like this:


```ruby
class Project < ApplicationRecord
  def issues_for_user_filtered_by(user, filter)
    # A lot of logic not related to project model itself
  end
end

issues = project.issues_for_user_filtered_by(user, params)
```

The GitLab approach is to use a Finder:

```ruby
issues = IssuesFinder.new(project, user, filter).execute
```

It will help keep models thinner.

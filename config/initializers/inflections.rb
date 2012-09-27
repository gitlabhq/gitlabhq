# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format
# (all these examples are active by default):
# ActiveSupport::Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Mark "commits" as uncountable.
#
# Without this change, the routes
#
#   resources :commit,  only: [:show], constraints: {id: /[[:alnum:]]{6,40}/}
#   resources :commits, only: [:show], constraints: {id: /.+/}
#
# would generate identical route helper methods (`project_commit_path`), resulting
# in one of them not getting a helper method at all.
#
# After this change, the helper methods are:
#
#   project_commit_path(@project, @project.commit)
#   # => "/gitlabhq/commit/bcf03b5de6c33f3869ef70d68cf06e679d1d7f9a
#
#   project_commits_path(@project, 'stable/README.md')
#   # => "/gitlabhq/commits/stable/README.md"
ActiveSupport::Inflector.inflections do |inflect|
  inflect.uncountable %w(commits)
end

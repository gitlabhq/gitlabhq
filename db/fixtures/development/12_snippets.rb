require './spec/support/sidekiq_middleware'

SNIPPET_REPO_URL = "https://gitlab.com/gitlab-org/gitlab-snippet-test.git"

Gitlab::Seeder.quiet do
  20.times do |i|
    user = User.not_mass_generated.sample

    user.snippets.create({
      type: 'PersonalSnippet',
      title: FFaker::Lorem.sentence(3),
      file_name:  'file.rb',
      visibility_level: Gitlab::VisibilityLevel.values.sample,
      content: 'foo'
    }).tap do |snippet|
      unless snippet.repository_exists?
        snippet.repository.import_repository(SNIPPET_REPO_URL)
      end

      snippet.track_snippet_repository(snippet.repository.storage)
      snippet.statistics.refresh!
    end

    print('.')
  end
end


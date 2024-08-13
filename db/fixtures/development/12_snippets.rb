require './spec/support/sidekiq_middleware'

SNIPPET_REPO_URL = "https://gitlab.com/gitlab-org/gitlab-snippet-test.git"
BUNDLE_PATH = File.join(Rails.root, 'db/fixtures/development/gitlab-snippet-test.bundle')

class Gitlab::Seeder::SnippetRepository
  def initialize(snippet)
    @snippet = snippet
  end

  def import
    if File.exist?(BUNDLE_PATH)
      @snippet.repository.create_from_bundle(BUNDLE_PATH)
    else
      @snippet.repository.import_repository(SNIPPET_REPO_URL)
      @snippet.repository.bundle_to_disk(BUNDLE_PATH)
    end
  end

  def self.cleanup
    File.delete(BUNDLE_PATH) if File.exist?(BUNDLE_PATH)
  rescue => e
    warn "\nError cleaning up snippet bundle: #{e}"
  end
end

Gitlab::Seeder.quiet do
  20.times do |i|
    user = User.not_mass_generated.sample

    user.snippets.create({
      type: 'PersonalSnippet',
      title: FFaker::Lorem.sentence(3),
      file_name:  'file.rb',
      visibility_level: Gitlab::VisibilityLevel.values.sample,
      organization: Organizations::Organization.default_organization,
      content: 'foo'
    }).tap do |snippet|
      snippet.repository.expire_exists_cache

      unless snippet.repository_exists?
        Gitlab::Seeder::SnippetRepository.new(snippet).import
      end

      snippet.track_snippet_repository(snippet.repository.storage)
      snippet.statistics.refresh!
    end

    print('.')
  end

  Gitlab::Seeder::SnippetRepository.cleanup
end

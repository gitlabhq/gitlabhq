# frozen_string_literal: true

namespace :gitlab do
  namespace :organizations do
    namespace :release do
      desc 'GitLab | Organizations | Regenerate the platform release status doc'
      task docs: :environment do
        Organizations::Release::Registry.reset!
        path = Organizations::Release::TableRenderer.new.write!

        puts "Wrote #{path}"
      end

      desc 'GitLab | Organizations | Check the platform release status doc is up to date'
      task check_docs: :environment do
        Organizations::Release::Registry.reset!
        path = Rails.root.join(Organizations::Release::TableRenderer::DOC_PATH)
        rendered = Organizations::Release::TableRenderer.new.render

        if File.exist?(path) && File.read(path) == rendered
          puts 'Organizations release status doc is up to date.'
        else
          warn <<~MSG
            Organizations release status doc is outdated!
            Run `bin/rake gitlab:organizations:release:docs` and commit the result.
          MSG
          abort
        end
      end
    end
  end
end

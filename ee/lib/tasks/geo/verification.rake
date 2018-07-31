# frozen_string_literal: true

namespace :geo do
  namespace :verification do
    namespace :repository do
      desc "GitLab | Verification | Repository | Reset | Resync repositories where verification has failed"
      task reset: :gitlab_environment do
        flag_for_resync(:repository)
      end
    end

    namespace :wiki do
      desc "GitLab | Verification | Wiki | Reset | Resync wiki repositories where verification has failed"
      task reset: :gitlab_environment do
        flag_for_resync(:wiki)
      end
    end

    def flag_for_resync(type)
      abort GEO_LICENSE_ERROR_TEXT unless Gitlab::Geo.license_allows?

      unless Gitlab::Geo.secondary?
        puts "This command is only available on a secondary node".color(:red)
        exit
      end

      puts "Marking #{type.to_s.pluralize} where verification has failed to be resynced..."
      num_updated = Geo::RepositoryVerificationReset.new(type).execute
      puts "Number of #{type.to_s.pluralize} marked to be resynced: #{num_updated}"
    end
  end
end

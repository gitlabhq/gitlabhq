# frozen_string_literal: true

module SystemCheck
  module App
    class MigrationsAreUpCheck < SystemCheck::BaseCheck
      set_name 'All migrations up?'

      def check?
        migration_status, _ = Gitlab::Popen.popen(%w[bundle exec rake db:migrate:status])

        migration_status !~ /down\s+\d{14}/
      end

      def show_error
        try_fixing_it(
          sudo_gitlab('bundle exec rake db:migrate RAILS_ENV=production')
        )
        fix_and_rerun
      end
    end
  end
end

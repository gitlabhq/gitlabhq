# frozen_string_literal: true

require 'tty-prompt'

module Tasks
  module Gitlab
    module Tokens
      class ManageExpiryTask
        TOTAL_WIDTH = 70

        def analyze
          show_pat_expires_at_migration_status
          show_most_common_pat_expiration_dates
        end

        def edit
          loop do
            analyze

            break unless prompt_action
          end
        end

        private

        def show_pat_expires_at_migration_status
          sql = <<~SQL
            SELECT * FROM batched_background_migrations
            WHERE job_class_name = 'CleanupPersonalAccessTokensWithNilExpiresAt'
            AND table_name = 'personal_access_tokens'
            AND column_name = 'id'
          SQL

          print_header("Personal/Project/Group Access Token Expiration Migration")

          base_model = ::Gitlab::Database.database_base_models[::Gitlab::Database::MAIN_DATABASE_NAME]
          record = base_model.connection.select_one(sql)

          if record
            puts "Started at: #{record['started_at']}"
            puts "Finished  : #{record['finished_at']}"
          else
            puts "Status: Not run"
          end
        end

        def show_most_common_pat_expiration_dates
          print_header "Top 10 Personal/Project/Group Access Token Expiration Dates"

          puts "| Expiration Date | Count |"
          puts "|-----------------|-------|"

          with_most_common_pat_expiration_dates do |row|
            expiry_date = row[:expires_at] || "(none)"
            puts "| #{expiry_date.to_s.ljust(15)} | #{row[:count].to_s.ljust(5)} |"
          end

          print_footer
        end

        def with_most_common_pat_expiration_dates
          # rubocop:disable CodeReuse/ActiveRecord -- Rake task specifically for fixing an issue
          ApplicationRecord.with_fast_read_statement_timeout(0) do # rubocop: disable Performance/ActiveRecordSubtransactionMethods -- no subtransaction here
            PersonalAccessToken
              .select(:expires_at, Arel.sql('count(*)'))
              .group(:expires_at)
              .order(Arel.sql('count(*) DESC'))
              .order(expires_at: :desc)
              .limit(10)
              .each do |row|
              yield row
            end
          end
          # rubocop:enable CodeReuse/ActiveRecord
        end

        def prompt_action
          prompt = TTY::Prompt.new

          puts ""
          user_choice = prompt.select("What do you want to do?") do |menu|
            menu.enum "."

            menu.choice "Extend expiration date", 1
            menu.choice "Remove expiration date", 2
            menu.choice "Quit", 3
          end

          case user_choice
          when 1
            extend_expiration_date
            true
          when 2
            remove_expiration_date
            true
          when 3
            false
          end
        end

        def extend_expiration_date
          old_date = prompt_expiration_date_selection

          return unless old_date

          prompt = TTY::Prompt.new

          num_days = ::Gitlab::CurrentSettings.max_personal_access_token_lifetime || 365
          new_date = old_date + num_days.days
          new_date = prompt.ask("What would you like the new expiration date to be?", default: new_date)

          new_date = Date.parse(new_date) unless new_date.is_a?(Date)

          puts ""
          puts "Old expiration date: #{old_date}"
          puts "New expiration date: #{new_date}"
          confirmed = prompt.yes?(
            "WARNING: This will now update #{token_count(old_date)} token(s). Are you sure?",
            default: false
          )

          if confirmed
            puts "Updating tokens..."
            update_tokens_with_expiration(old_date, new_date)
          else
            puts "Aborting!"
          end
        rescue Date::Error
          puts "Invalid date, aborting..."
        end

        def remove_expiration_date
          old_date = prompt_expiration_date_selection

          return unless old_date

          prompt = TTY::Prompt.new

          puts ""
          puts "WARNING: This will remove the expiration for tokens that expire on #{old_date}."
          confirmed = prompt.yes?("This will affect #{token_count(old_date)} tokens. Are you sure?", default: false)

          if confirmed
            update_tokens_with_expiration(old_date, nil)
          else
            puts "Aborting!"
          end
        end

        def update_tokens_with_expiration(old_date, new_date)
          total = 0
          # rubocop:disable CodeReuse/ActiveRecord -- Rake task specifically for fixing an issue
          PersonalAccessToken.where(expires_at: old_date).each_batch do |batch|
            puts "Updating personal access tokens from ID #{batch.minimum(:id)} to #{batch.maximum(:id)}..."
            total += batch.update_all(expires_at: new_date)
          end
          # rubocop:enable CodeReuse/ActiveRecord -- Rake task specifically for fixing an issue

          puts "Updated #{total} tokens!"
        end

        def prompt_expiration_date_selection
          prompt = TTY::Prompt.new

          choices = []
          with_most_common_pat_expiration_dates do |row|
            choices << row[:expires_at] if row[:expires_at]
          end

          abort_choice = "--> Abort"
          choices << abort_choice

          selection = prompt.select("Select an expiration date", choices)
          selection == abort_choice ? nil : selection
        end

        def token_count(expiration_date)
          # rubocop:disable CodeReuse/ActiveRecord -- Rake task specifically for fixing an issue
          ApplicationRecord.with_fast_read_statement_timeout(0) do # rubocop: disable Performance/ActiveRecordSubtransactionMethods -- no subtransaction here
            PersonalAccessToken.where(expires_at: expiration_date).count
          end
          # rubocop:enable CodeReuse/ActiveRecord
        end

        def print_header(title, total_width = TOTAL_WIDTH)
          title_length = title.length
          side_length = (total_width - title_length) / 2

          left_side = "=" * side_length
          right_side = "=" * (side_length + (total_width % 2))

          header = "#{left_side} #{title} #{right_side}"
          puts header
        end

        def print_footer
          # Account for the spaces between the "=" in the header
          puts "=" * (TOTAL_WIDTH + 2)
        end
      end
    end
  end
end

# frozen_string_literal: true

class GenerateMissingRoutesForBots < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    self.table_name = 'users'

    USER_TYPES = {
      human: nil,
      support_bot: 1,
      alert_bot: 2,
      visual_review_bot: 3,
      service_user: 4,
      ghost: 5,
      project_bot: 6,
      migration_bot: 7
    }.with_indifferent_access.freeze

    BOT_USER_TYPES = %w[alert_bot project_bot support_bot visual_review_bot migration_bot].freeze

    scope :bots, -> { where(user_type: USER_TYPES.values_at(*BOT_USER_TYPES)) }
  end

  class Route < ActiveRecord::Base
    self.table_name = 'routes'

    validates :path,
      uniqueness: { case_sensitive: false }
  end

  class Namespace < ActiveRecord::Base
    self.table_name = 'namespaces'

    belongs_to :owner, class_name: 'GenerateMissingRoutesForBots::User'

    scope :for_user, -> { where(type: nil) }
    scope :for_bots, -> { for_user.joins(:owner).merge(GenerateMissingRoutesForBots::User.bots) }

    scope :without_routes, -> do
      where(
        'NOT EXISTS (
          SELECT 1
          FROM routes
          WHERE source_type = ?
          AND source_id = namespaces.id
        )',
          self.source_type_for_route
      )
    end

    def self.source_type_for_route
      'Namespace'
    end

    def attributes_for_insert
      {
        source_type: self.class.source_type_for_route,
        source_id: id,
        name: name,
        path: path
      }
    end
  end

  def up
    # Reset the column information of all the models that update the database
    # to ensure the Active Record's knowledge of the table structure is current
    Route.reset_column_information

    logger = Gitlab::BackgroundMigration::Logger.build
    attributes_to_be_logged = %w(id path name)

    GenerateMissingRoutesForBots::Namespace.for_bots.without_routes.each do |namespace|
      route = GenerateMissingRoutesForBots::Route.create(namespace.attributes_for_insert)
      namespace_details = namespace.as_json.slice(*attributes_to_be_logged)

      if route.persisted?
        logger.info namespace_details.merge(message: 'a new route was created for the namespace')
      else
        errors = route.errors.full_messages.join(',')
        logger.info namespace_details.merge(message: 'route creation failed for the namespace', errors: errors)
      end
    end
  end

  def down
    # no op
  end
end

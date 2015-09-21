require 'yaml'

module Ci
  module Migrate
    class Tags
      def restore
        puts 'Inserting tags...'
        connection.select_all('SELECT ci_tags.name FROM ci_tags').each do |tag|
          begin
            connection.execute("INSERT INTO tags (name) VALUES(#{ActiveRecord::Base::sanitize(tag['name'])})")
          rescue ActiveRecord::RecordNotUnique
          end
        end

        ActiveRecord::Base.transaction do
          puts 'Deleting old taggings...'
          connection.execute "DELETE FROM taggings WHERE context = 'tags' AND taggable_type LIKE 'Ci::%'"

          puts 'Inserting taggings...'
          connection.execute(
            'INSERT INTO taggings (taggable_type, taggable_id, tag_id, context) ' +
              "SELECT CONCAT('Ci::', ci_taggings.taggable_type), ci_taggings.taggable_id, tags.id, 'tags' FROM ci_taggings " +
              'JOIN ci_tags ON ci_tags.id = ci_taggings.tag_id ' +
              'JOIN tags ON tags.name = ci_tags.name '
          )

          puts 'Resetting counters... '
          connection.execute(
            'UPDATE tags SET ' +
              'taggings_count = (SELECT COUNT(*) FROM taggings WHERE tags.id = taggings.tag_id)'
          )
        end
      end

      protected

      def connection
        ActiveRecord::Base.connection
      end
    end
  end
end

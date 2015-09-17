require 'yaml'

module Ci
  module Migrate
    class Tags
      def restore
        puts 'Migrating tags for Runners... '
        list_objects('Runner').each do |id|
          putc '.'
          runner = Ci::Runner.find_by_id(id)
          if runner
            tags = list_tags('Runner', id)
            runner.update_attributes(tag_list: tags)
          end
        end
        puts ''

        puts 'Migrating tags for Builds... '
        list_objects('Build').each do |id|
          putc '.'
          build = Ci::Build.find_by_id(id)
          if build
            tags = list_tags('Build', id)
            build.update_attributes(tag_list: tags)
          end
        end
        puts ''
      end

      protected

      def list_objects(type)
        ids = ActiveRecord::Base.connection.select_all(
          "select distinct taggable_id from ci_taggings where taggable_type = #{ActiveRecord::Base::sanitize(type)}"
        )
        ids.map { |id| id['taggable_id'] }
      end

      def list_tags(type, id)
        tags = ActiveRecord::Base.connection.select_all(
          'select ci_tags.name from ci_tags ' +
            'join ci_taggings on ci_tags.id = ci_taggings.tag_id ' +
            "where taggable_type = #{ActiveRecord::Base::sanitize(type)} and taggable_id = #{ActiveRecord::Base::sanitize(id)} and context = 'tags'"
        )
        tags.map { |tag| tag['name'] }
      end
    end
  end
end

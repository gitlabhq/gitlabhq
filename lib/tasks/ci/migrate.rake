namespace :ci do
  namespace :migrate do
    def list_objects(type)
      ids = ActiveRecord::Base.connection.select_all(
        'select distinct taggable_id from ci_taggings where taggable_type = $1',
        nil, [[nil, type]]
      )
      ids.map { |id| id['taggable_id'] }
    end

    def list_tags(type, id)
      tags = ActiveRecord::Base.connection.select_all(
        'select ci_tags.name from ci_tags ' +
        'join ci_taggings on ci_tags.id = ci_taggings.tag_id ' +
        'where taggable_type = $1 and taggable_id = $2 and context = $3',
        nil, [[nil, type], [nil, id], [nil, 'tags']]
      )
      tags.map { |tag| tag['name'] }
    end

    desc 'GitLab | Migrate CI tags'
    task tags: :environment do
      list_objects('Runner').each do |id|
        runner = Ci::Runner.find_by_id(id)
        if runner
          tags = list_tags('Runner', id)
          runner.update_attributes(tag_list: tags)
        end
      end

      list_objects('Build').each do |id|
        build = Ci::Build.find_by_id(id)
        if build
          tags = list_tags('Build', id)
          build.update_attributes(tag_list: tags)
        end
      end
    end
  end
end

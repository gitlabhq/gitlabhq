# frozen_string_literal: true

module BulkImports
  class TransformReferencesWorker
    include ApplicationWorker

    idempotent!
    data_consistency :delayed
    sidekiq_options retry: 3, dead: false
    feature_category :importers

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(object_ids, klass, tracker_id)
      @tracker = BulkImports::Tracker.find_by_id(tracker_id)

      return unless tracker

      project = tracker.entity.project

      klass.constantize.where(id: object_ids, project: project).find_each do |object|
        transform_and_save(object)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    attr_reader :tracker

    private

    def transform_and_save(object)
      body = object_body(object).dup

      return if body.blank?

      object.refresh_markdown_cache!

      unless Import::BulkImports::EphemeralData.new(tracker.entity.bulk_import_id).importer_user_mapping_enabled?
        body.gsub!(username_regex(mapped_usernames), mapped_usernames)
      end

      if object_has_reference?(body)
        matching_urls(object).each do |old_url, new_url|
          body.gsub!(old_url, new_url) if body.include?(old_url)
        end
      end

      object.importing = true
      object.assign_attributes(body_field(object) => body)
      object.save!(touch: false) if object_body_changed?(object)

      object
    rescue StandardError => e
      log_and_fail(e)
    end

    def object_body(object)
      call_object_method(object)
    end

    def object_body_changed?(object)
      call_object_method(object, suffix: '_changed?')
    end

    def call_object_method(object, suffix: nil)
      method = body_field(object)
      method = "#{method}#{suffix}" if suffix.present?

      object.public_send(method) # rubocop:disable GitlabSecurity/PublicSend -- the method being called is dependent on several factors
    end

    def body_field(object)
      object.is_a?(Note) ? 'note' : 'description'
    end

    def mapped_usernames
      @mapped_usernames ||= ::BulkImports::UsersMapper.new(context: context)
                              .map_usernames.transform_keys { |key| "@#{key}" }
                              .transform_values { |value| "@#{value}" }
    end

    def username_regex(mapped_usernames)
      @username_regex ||= Regexp.new(mapped_usernames.keys.sort_by(&:length)
                            .reverse.map { |x| Regexp.escape(x) }.join('|'))
    end

    def matching_urls(object)
      URI.extract(object_body(object), %w[http https]).each_with_object([]) do |url, array|
        parsed_url = URI.parse(url)

        next unless source_host == parsed_url.host
        next unless parsed_url.path&.start_with?("/#{source_full_path}")

        array << [url, new_url(object, parsed_url)]
      end
    end

    def new_url(object, parsed_old_url)
      parsed_old_url.host = ::Gitlab.config.gitlab.host
      parsed_old_url.port = ::Gitlab.config.gitlab.port
      parsed_old_url.scheme = ::Gitlab.config.gitlab.https ? 'https' : 'http'
      parsed_old_url.to_s.gsub!(source_full_path, full_path(object))
    end

    def source_host
      @source_host ||= URI.parse(context.configuration.url).host
    end

    def source_full_path
      @source_full_path ||= context.entity.source_full_path
    end

    def full_path(object)
      object.project.full_path
    end

    def object_has_reference?(body)
      body.include?(source_full_path)
    end

    def log_and_fail(exception)
      Gitlab::ErrorTracking.track_exception(exception, log_params)
      BulkImports::Failure.create(failure_attributes(exception))
    end

    def log_params
      {
        message: 'Failed to update references',
        bulk_import_id: context.bulk_import_id,
        bulk_import_entity_id: tracker.bulk_import_entity_id,
        source_full_path: context.entity.source_full_path,
        source_version: context.bulk_import.source_version,
        importer: 'gitlab_migration'
      }
    end

    def failure_attributes(exception)
      {
        bulk_import_entity_id: context.entity.id,
        pipeline_class: 'ReferencesPipeline',
        exception_class: exception.class.to_s,
        exception_message: exception.message.truncate(255),
        correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id
      }
    end

    def context
      @context ||= BulkImports::Pipeline::Context.new(tracker)
    end
  end
end

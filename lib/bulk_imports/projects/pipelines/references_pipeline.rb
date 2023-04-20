# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class ReferencesPipeline
        include Pipeline

        BATCH_SIZE = 100

        def extract(_context)
          data = Enumerator.new do |enum|
            add_matching_objects(portable.issues, enum)
            add_matching_objects(portable.merge_requests, enum)
            add_notes(portable.issues, enum)
            add_notes(portable.merge_requests, enum)
          end

          BulkImports::Pipeline::ExtractedData.new(data: data)
        end

        def transform(_context, object)
          body = object_body(object).dup

          matching_urls(object).each do |old_url, new_url|
            body.gsub!(old_url, new_url)
          end

          object.assign_attributes(body_field(object) => body)

          object
        end

        def load(_context, object)
          object.save! if object_body_changed?(object)
        end

        private

        def add_matching_objects(collection, enum)
          collection.each_batch(of: BATCH_SIZE, column: :iid) do |batch|
            batch.each do |object|
              enum << object if object_has_reference?(object)
            end
          end
        end

        def add_notes(collection, enum)
          collection.each_batch(of: BATCH_SIZE, column: :iid) do |batch|
            batch.each do |object|
              object.notes.each_batch(of: BATCH_SIZE) do |notes_batch|
                notes_batch.each do |note|
                  note.refresh_markdown_cache!
                  enum << note if object_has_reference?(note)
                end
              end
            end
          end
        end

        def object_has_reference?(object)
          object_body(object)&.include?(source_full_path)
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

          object.public_send(method) # rubocop:disable GitlabSecurity/PublicSend
        end

        def body_field(object)
          object.is_a?(Note) ? 'note' : 'description'
        end

        def matching_urls(object)
          URI.extract(object_body(object), %w[http https]).each_with_object([]) do |url, array|
            parsed_url = URI.parse(url)

            next unless source_host == parsed_url.host
            next unless parsed_url.path&.start_with?("/#{source_full_path}")

            array << [url, new_url(parsed_url)]
          end
        end

        def new_url(parsed_old_url)
          parsed_old_url.host = ::Gitlab.config.gitlab.host
          parsed_old_url.port = ::Gitlab.config.gitlab.port
          parsed_old_url.scheme = ::Gitlab.config.gitlab.https ? 'https' : 'http'
          parsed_old_url.to_s.gsub!(source_full_path, portable.full_path)
        end

        def source_host
          @source_host ||= URI.parse(context.configuration.url).host
        end

        def source_full_path
          context.entity.source_full_path
        end
      end
    end
  end
end

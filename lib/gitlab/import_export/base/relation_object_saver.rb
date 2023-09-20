# frozen_string_literal: true

# RelationObjectSaver allows for an alternative approach to persisting
# objects during Project/Group Import which persists object's
# nested collection subrelations separately, in batches.
#
# Instead of the regular `relation_object.save!` that opens one db
# transaction for the object itself and all of its subrelations we
# separate collection subrelations from the object and save them
# in batches in smaller more frequent db transactions.
module Gitlab
  module ImportExport
    module Base
      class RelationObjectSaver
        include Gitlab::Utils::StrongMemoize

        BATCH_SIZE = 100

        attr_reader :invalid_subrelations

        # @param relation_object [Object] Object of a project/group, e.g. an issue
        # @param relation_key [String] Name of the object association to group/project, e.g. :issues
        # @param relation_definition [Hash] Object subrelations as defined in import_export.yml
        # @param importable [Project|Group] Project or group where relation object is getting saved to
        #
        # @example
        #   Gitlab::ImportExport::Base::RelationObjectSaver.new(
        #     relation_key: 'merge_requests',
        #     relation_object: #<MergeRequest id: root/mrs!1, notes: [#<Note id: nil, note: 'test', ...>, #<Note id: nil, noteL 'another note'>]>,
        #     relation_definition: {"metrics"=>{}, "award_emoji"=>{}, "notes"=>{"author"=>{}, ... }}
        #     importable: @importable
        #   ).execute
        def initialize(relation_object:, relation_key:, relation_definition:, importable:)
          @relation_object = relation_object
          @relation_key = relation_key
          @relation_definition = relation_definition
          @importable = importable
          @invalid_subrelations = []
        end

        def execute
          move_subrelations

          relation_object.save!

          save_subrelations
        end

        private

        attr_reader :relation_object, :relation_key, :relation_definition, :importable, :collection_subrelations

        # rubocop:disable GitlabSecurity/PublicSend
        def save_subrelations
          collection_subrelations.each_pair do |relation_name, records|
            records.each_slice(BATCH_SIZE) do |batch|
              valid_records, invalid_records = batch.partition { |record| record.valid? }

              relation_object.public_send(relation_name) << valid_records

              # Attempt to save some of the invalid subrelations, as they might be valid after all.
              # For example, a merge request `Approval` validates presence of merge_request_id.
              # It is not present at a time of calling `#valid?` above, since it's indeed missing.
              # However, when saving such subrelation against already persisted merge request
              # such validation won't fail (e.g. `merge_request.approvals << Approval.new(user_id: 1)`),
              # as we're operating on a merge request that has `id` present.
              invalid_records.each do |invalid_record|
                relation_object.public_send(relation_name) << invalid_record

                invalid_subrelations << invalid_record unless invalid_record.persisted?
              end

              relation_object.save
            end
          end
        end

        def move_subrelations
          strong_memoize(:collection_subrelations) do
            relation_definition.each_key.each_with_object({}) do |definition, collection_subrelations|
              subrelation = relation_object.public_send(definition)
              association = relation_object.class.reflect_on_association(definition)

              next unless association&.collection?

              collection_subrelations[definition] = subrelation.records

              subrelation.clear
            end
          end
        end
        # rubocop:enable GitlabSecurity/PublicSend
      end
    end
  end
end

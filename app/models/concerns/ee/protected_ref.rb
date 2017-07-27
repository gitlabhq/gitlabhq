module EE
  module ProtectedRef
    extend ActiveSupport::Concern

    class_methods do
      def protected_ref_access_levels(*types)
        types.each do |type|
          # We need to set `inverse_of` to make sure the `belongs_to`-object is set
          # when creating children using `accepts_nested_attributes_for`.
          #
          # If we don't `protected_branch` or `protected_tag` would be empty and
          # `project` cannot be delegated to it, which in turn would cause validations
          # to fail.
          has_many :"#{type}_access_levels", inverse_of: self.model_name.singular # rubocop:disable Cop/ActiveRecordDependent

          accepts_nested_attributes_for :"#{type}_access_levels", allow_destroy: true

          # Overwrite the validation for access levels
          #
          # EE Needs to allow more access levels in the relation:
          # - 1 for each user/group
          # - 1 with the `access_level` (Master, Developer)
          validates :"#{type}_access_levels", length: { is: 1 }, if: -> { false }

          # Returns access levels that grant the specified access type to the given user / group.
          access_level_class = const_get("#{type}_access_level".classify)
          protected_type = self.model_name.singular
          scope(
            :"#{type}_access_by_user",
            -> (user) do
              access_level_class.joins(protected_type.to_sym)
                .where("#{protected_type}_id" => self.ids)
                .merge(access_level_class.by_user(user))
            end
          )
          scope(
            :"#{type}_access_by_group",
            -> (group) do
              access_level_class.joins(protected_type.to_sym)
                .where("#{protected_type}_id" => self.ids)
                .merge(access_level_class.by_group(group))
            end
          )
        end
      end
    end
  end
end

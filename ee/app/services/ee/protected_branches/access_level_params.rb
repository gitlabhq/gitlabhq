module EE
  module ProtectedBranches
    module AccessLevelParams
      extend ::Gitlab::Utils::Override

      override :access_levels
      def access_levels
        ce_style_access_level + ee_style_access_levels
      end

      def group_ids
        ids_for('group_id')
      end

      def user_ids
        ids_for('user_id')
      end

      private

      override :use_default_access_level?
      def use_default_access_level?(params)
        params[:"allowed_to_#{type}"].blank?
      end

      def ee_style_access_levels
        params[:"allowed_to_#{type}"] || []
      end

      def ids_for(key)
        ee_style_access_levels.select { |level| level[key] }.flat_map(&:values)
      end
    end
  end
end

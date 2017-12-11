module EE
  module ProtectedBranches
    module AccessLevelParams
      def access_levels
        raise NotImplementedError unless defined?(super)

        ce_style_access_level + ee_style_access_levels
      end

      def group_ids
        ids_for('group_id')
      end

      def user_ids
        ids_for('user_id')
      end

      private

      def use_default_access_level?(params)
        raise NotImplementedError unless defined?(super)

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

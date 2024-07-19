# frozen_string_literal: true

module Members
  module RoleParser
    def get_access_level(role_string)
      extract_number(role_string, :static)
    end

    def get_member_role_id(role_string)
      extract_number(role_string, :custom)
    end

    private

    def extract_number(role_string, type)
      role_string.try(:match, /^#{type}-(\d+)$/).to_a.second&.to_i
    end
  end
end

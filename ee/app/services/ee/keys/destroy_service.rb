module EE
  module Keys
    module DestroyService
      extend ::Gitlab::Utils::Override

      override :destroy_possible?
      def destroy_possible?(key)
        super && !key.is_a?(LDAPKey)
      end
    end
  end
end

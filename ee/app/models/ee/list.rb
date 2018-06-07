module EE
  module List
    extend ::Gitlab::Utils::Override

    # ActiveSupport::Concern does not prepend the ClassMethods,
    # so we cannot call `super` if we use it.
    def self.prepended(base)
      class << base
        prepend ClassMethods
      end

      base.belongs_to :user

      base.validates :user, presence: true, if: :assignee?
      base.validates :user_id, uniqueness: { scope: :board_id }, if: :assignee?
      base.validates :list_type,
        exclusion: { in: %w[assignee], message: _('Assignee boards not available with your current license') },
        unless: -> { board&.parent&.feature_available?(:board_assignee_lists) }
    end

    def assignee=(user)
      self.user = user
    end

    override :destroyable?
    def destroyable?
      assignee? || super
    end

    override :movable?
    def movable?
      assignee? || super
    end

    override :title
    def title
      assignee? ? user.to_reference : super
    end

    override :as_json
    def as_json(options = {})
      super.tap do |json|
        if options.key?(:user)
          json[:user] = UserSerializer.new.represent(user).as_json
        end
      end
    end

    module ClassMethods
      def destroyable_types
        super + [:assignee]
      end

      def movable_types
        super + [:assignee]
      end
    end
  end
end

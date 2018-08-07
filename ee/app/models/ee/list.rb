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
      base.belongs_to :milestone

      base.validates :user, presence: true, if: :assignee?
      base.validates :milestone, presence: true, if: :milestone?
      base.validates :user_id, uniqueness: { scope: :board_id }, if: :assignee?
      base.validates :milestone_id, uniqueness: { scope: :board_id }, if: :milestone?
      base.validates :list_type,
        exclusion: { in: %w[assignee], message: _('Assignee lists not available with your current license') },
        unless: -> { board&.parent&.feature_available?(:board_assignee_lists) }
      base.validates :list_type,
        exclusion: { in: %w[milestone], message: _('Milestone lists not available with your current license') },
        unless: -> { board&.parent&.feature_available?(:board_milestone_lists) }
    end

    def assignee=(user)
      self.user = user
    end

    override :title
    def title
      case list_type
      when 'assignee'
        user.to_reference
      when 'milestone'
        milestone.title
      else
        super
      end
    end

    override :as_json
    def as_json(options = {})
      super.tap do |json|
        if options.key?(:user)
          json[:user] = UserSerializer.new.represent(user).as_json
        end

        if options.key?(:milestone)
          json[:milestone] = MilestoneSerializer.new.represent(milestone).as_json
        end
      end
    end

    module ClassMethods
      def destroyable_types
        super + [:assignee, :milestone]
      end

      def movable_types
        super + [:assignee, :milestone]
      end
    end
  end
end

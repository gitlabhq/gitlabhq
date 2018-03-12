module AtomicInternalId
  extend ActiveSupport::Concern

  included do
    class << self
      def has_internal_id(on, scope:, usage: nil, init: nil)
        before_validation(on: :create) do
          if self.public_send(on).blank? # rubocop:disable GitlabSecurity/PublicSend
            usage = (usage || self.class.name.tableize).to_sym
            new_iid = InternalId.generate_next(self, scope, usage, init)
            self.public_send("#{on}=", new_iid) # rubocop:disable GitlabSecurity/PublicSend
          end
        end

        validates on, presence: true, numericality: true
      end
    end
  end

  def to_param
    iid.to_s
  end
end

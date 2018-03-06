module AtomicInternalId
  extend ActiveSupport::Concern

  # Include this module in a class that acts as a scope
  # for internal id generation.
  #
  # In the example used here, that is Project:
  # ```
  # class Project
  #   include AtomicInternalId::Scope
  #   scopes_internal_id :issues_iid
  # end
  # ```
  module Scope
    extend ActiveSupport::Concern

    included do
      class << self
        def scopes_internal_id(on)
          belongs_to on, class_name: InternalId, foreign_key: on
          before_destroy do
            self.public_send(on).destroy! # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end
    end
  end

  included do
    class << self
      # Include atomic internal id generation scheme for a model
      #
      # This allows to atomically generate internal ids that are
      # unique within the given scope.
      #
      # In the example used here, let's generate internal ids for
      # Issue per Project:
      # ```
      # class Issue < ActiveRecord::Base
      #   has_internal_id :iid, scope: :project, through: :issues_iid, init: ->(o) { o.project.issues.maximum(:iid) }
      # end
      # ```
      #
      # This generates unique internal ids per project for newly created issues.
      # The generated internal id is saved in the `iid` attribute of `Issue`.
      #
      # Model-wise, a `Project` comes with `#issues_iid` which is a foreign key
      # to `InternalId`. That attribute may be null first but is populated as
      # soon as a `InternalId` record is created.
      #
      # The `init` lambda passed in is used to calculate the last internal id
      # value that was used based on the existing records. In the example above,
      # we calculate the maximum `iid` of all issues within the given project.
      # Note this is only called during initialization if `InternalId` is not
      # yet present.
      def has_internal_id(on, scope:, through:, init: nil)
        before_validation(on: :create) do
          new_iid = InternalId.generate!(self, scope: scope, through: through, init: init) if iid.blank?
          self.public_send("#{on}=".to_sym, new_iid) # rubocop:disable GitlabSecurity/PublicSend
        end

        validates on, presence: true, numericality: true
      end

    end
  end

  def to_param
    iid.to_s
  end
end

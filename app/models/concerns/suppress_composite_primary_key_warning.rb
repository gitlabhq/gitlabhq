# frozen_string_literal: true

# When extended, silences this warning below:
# WARNING: Active Record does not support composite primary key.
#
# project_authorizations has composite primary key. Composite primary key is ignored.
#
# See https://gitlab.com/gitlab-org/gitlab/-/issues/292909
module SuppressCompositePrimaryKeyWarning
  extend ActiveSupport::Concern

  private

  def suppress_composite_primary_key(pk)
    silence_warnings do
      super
    end
  end
end

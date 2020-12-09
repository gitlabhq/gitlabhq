# frozen_string_literal: true

# TODO: remove this entirely when framework authorization is released
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/290216
module ManualAuthorization
  def resolve(**args)
    super
  rescue ::Gitlab::Graphql::Errors::ResourceNotAvailable
    nil
  end
end

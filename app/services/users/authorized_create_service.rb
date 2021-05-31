# frozen_string_literal: true

module Users
  class AuthorizedCreateService < CreateService
    extend ::Gitlab::Utils::Override

    private

    override :build_class
    def build_class
      Users::AuthorizedBuildService
    end
  end
end

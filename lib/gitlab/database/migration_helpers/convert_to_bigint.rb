# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module ConvertToBigint
        # This helper is extracted for the purpose of
        # https://gitlab.com/gitlab-org/gitlab/-/issues/392815
        # so that we can test all combinations just once,
        # and simplify migration tests.
        #
        # Once we are done with the PK conversions we can remove this.
        def com_or_dev_or_test_but_not_jh?
          !Gitlab.jh? && (Gitlab.com? || Gitlab.dev_or_test_env?)
        end
      end
    end
  end
end

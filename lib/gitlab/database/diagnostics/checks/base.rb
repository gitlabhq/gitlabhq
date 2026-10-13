# frozen_string_literal: true

module Gitlab
  module Database
    module Diagnostics
      module Checks
        class Base
          def initialize(connection)
            @connection = connection
          end

          def execute
            raise Gitlab::AbstractMethodError
          end

          private

          attr_reader :connection

          # The verdict every check reports alongside its own payload, so the views
          # and the admin page read the same keys for all of them.
          def verdict(findings)
            {
              findings: Findings.sort(findings),
              severity: Findings.worst(findings.pluck(:severity)),
              counts: Findings.counts(findings)
            }
          end

          def quoted_names(names)
            names.map { |name| connection.quote(name) }.join(', ')
          end
        end
      end
    end
  end
end

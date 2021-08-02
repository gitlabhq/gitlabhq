# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Kubeconfig
      module Entry
        class User
          attr_reader :name

          def initialize(name:, token:)
            @name = name
            @token = token
          end

          def to_h
            {
              name: name,
              user: { token: token }
            }
          end

          private

          attr_reader :token
        end
      end
    end
  end
end

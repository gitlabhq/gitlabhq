# frozen_string_literal: true

module QA
  module Resource
    module Ci
      class GroupRunner < UserRunners
        attribute :group do
          Resource::Group.fabricate_via_api! do |resource|
            resource.name = "group-with-ci-cd-#{SecureRandom.hex(8)}"
            resource.description = 'Group with CI/CD Pipelines'
          end
        end

        attribute :runner_type do
          'group_type'
        end

        private

        def runner(**kwargs)
          fail_msg = "Wait for runner '#{name}' to register in group '#{group.name}'"
          Support::Retrier.retry_until(max_duration: 60, sleep_interval: 1, message: fail_msg) do
            group.runners(**kwargs).find { |runner| runner[:description] == name }
          end
        end
      end
    end
  end
end

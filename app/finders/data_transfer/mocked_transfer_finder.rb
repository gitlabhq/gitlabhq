# frozen_string_literal: true

# Mocked data for data transfer
# Follow this epic for recent progress: https://gitlab.com/groups/gitlab-org/-/epics/9330
module DataTransfer
  class MockedTransferFinder
    def execute
      start_date = Date.new(2023, 0o1, 0o1)
      date_for_index = ->(i) { (start_date + i.months).strftime('%Y-%m-%d') }

      0.upto(11).map do |i|
        {
          date: date_for_index.call(i),
          repository_egress: rand(70000..550000),
          artifacts_egress: rand(70000..550000),
          packages_egress: rand(70000..550000),
          registry_egress: rand(70000..550000)
        }.tap do |hash|
          hash[:total_egress] = hash
            .slice(:repository_egress, :artifacts_egress, :packages_egress, :registry_egress)
            .values
            .sum
        end
      end
    end
  end
end

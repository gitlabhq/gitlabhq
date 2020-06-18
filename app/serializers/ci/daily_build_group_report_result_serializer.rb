# frozen_string_literal: true

module Ci
  class DailyBuildGroupReportResultSerializer < BaseSerializer
    entity ::Ci::DailyBuildGroupReportResultEntity

    def represent(resource, opts = {})
      group(resource).map do |group_name, data|
        {
          group_name: group_name,
          data: super(data, opts)
        }
      end
    end

    private

    def group(resource)
      collect(resource).group_by(&:group_name)
    end

    def collect(resource)
      return resource if resource.respond_to?(:group_by)

      [resource]
    end
  end
end

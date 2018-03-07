module Badges
  class CreateService < Badges::BaseService
    # returns the created badge
    def execute(source)
      badge = Badges::BuildService.new(params).execute(source)

      badge.tap { |b| b.save }
    end
  end
end

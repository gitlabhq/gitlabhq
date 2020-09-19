# frozen_string_literal: true

class Ci::Lint::JobEntity < Grape::Entity
  expose :name
  expose :stage
  expose :before_script
  expose :script
  expose :after_script
  expose :tag_list
  expose :environment
  expose :when
  expose :allow_failure
  expose :only
  expose :except
end

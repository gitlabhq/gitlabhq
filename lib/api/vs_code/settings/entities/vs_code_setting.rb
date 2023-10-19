# frozen_string_literal: true

module API
  module VsCode
    module Settings
      module Entities
        class VsCodeSetting < Grape::Entity
          expose :content, expose_nil: false
          expose :machines, expose_nil: false
          expose :version
          expose :machine_id, as: :machineId, expose_nil: false
        end
      end
    end
  end
end

# frozen_string_literal: true

module Ci
  class RunnerMachine < Ci::ApplicationRecord
    include Ci::HasRunnerExecutor

    belongs_to :runner

    validates :runner, presence: true
    validates :machine_xid, presence: true, length: { maximum: 64 }
    validates :version, length: { maximum: 2048 }
    validates :revision, length: { maximum: 255 }
    validates :platform, length: { maximum: 255 }
    validates :architecture, length: { maximum: 255 }
    validates :ip_address, length: { maximum: 1024 }
  end
end

# frozen_string_literal: true

class Ci::BuildPendingState < Ci::ApplicationRecord
  belongs_to :build, class_name: 'Ci::Build', foreign_key: :build_id

  enum state: Ci::Stage.statuses
  enum failure_reason: CommitStatus.failure_reasons

  validates :build, presence: true

  def crc32
    trace_checksum.try do |checksum|
      checksum.to_s.split('crc32:').last.to_i(16)
    end
  end
end

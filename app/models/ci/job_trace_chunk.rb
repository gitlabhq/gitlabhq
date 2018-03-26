module Ci
  class JobTraceChunk < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :job, class_name: "Ci::Build", foreign_key: :job_id
  end
end

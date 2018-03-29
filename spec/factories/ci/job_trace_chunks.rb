include ActionDispatch::TestProcess

FactoryBot.define do
  factory :job_trace_chunk, class: Ci::JobTraceChunk do
    job factory: :ci_build
  end
end

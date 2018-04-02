FactoryBot.define do
  factory :ci_job_trace_chunk, class: Ci::JobTraceChunk do
    job factory: :ci_build
  end
end

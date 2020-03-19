# frozen_string_literal: true

FactoryBot.define do
  factory :ci_ref, class: 'Ci::Ref' do
    ref { 'master' }
    status { :success }
    tag { false }
    project

    before(:create) do |ref, evaluator|
      next if ref.pipelines.exists?

      ref.update!(last_updated_by_pipeline: create(:ci_pipeline, project: evaluator.project, ref: evaluator.ref, tag: evaluator.tag, status: evaluator.status))
    end
  end
end

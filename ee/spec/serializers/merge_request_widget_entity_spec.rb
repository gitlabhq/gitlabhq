require 'spec_helper'

describe MergeRequestWidgetEntity do
  let(:user) { create(:user) }
  let(:project) { create :project, :repository }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:request) { double('request', current_user: user) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  before do
    project.add_developer(user)
  end

  subject do
    described_class.new(merge_request, request: request)
  end

  it 'has blob path data' do
    allow(merge_request).to receive(:base_pipeline).and_return(pipeline)
    allow(merge_request).to receive(:head_pipeline).and_return(pipeline)

    expect(subject.as_json).to include(:blob_path)
    expect(subject.as_json[:blob_path]).to include(:base_path)
    expect(subject.as_json[:blob_path]).to include(:head_path)
  end

  it 'has performance data' do
    build = create(:ci_build, name: 'job')

    allow(merge_request).to receive(:expose_performance_data?).and_return(true)
    allow(merge_request).to receive(:base_performance_artifact).and_return(build)
    allow(merge_request).to receive(:head_performance_artifact).and_return(build)

    expect(subject.as_json).to include(:performance)
  end

  it 'has sast data' do
    build = create(:ci_build, name: 'sast', pipeline: pipeline)

    allow(merge_request).to receive(:expose_sast_data?).and_return(true)
    allow(merge_request).to receive(:base_has_sast_data?).and_return(true)
    allow(merge_request).to receive(:base_sast_artifact).and_return(build)
    allow(merge_request).to receive(:head_sast_artifact).and_return(build)

    expect(subject.as_json).to include(:sast)
    expect(subject.as_json[:sast]).to include(:head_path)
    expect(subject.as_json[:sast]).to include(:base_path)
  end

  it 'has dependency_scanning data' do
    build = create(:ci_build, name: 'dependency_scanning', pipeline: pipeline)

    allow(merge_request).to receive(:expose_dependency_scanning_data?).and_return(true)
    allow(merge_request).to receive(:base_has_dependency_scanning_data?).and_return(true)
    allow(merge_request).to receive(:base_dependency_scanning_artifact).and_return(build)
    allow(merge_request).to receive(:head_dependency_scanning_artifact).and_return(build)

    expect(subject.as_json).to include(:dependency_scanning)
    expect(subject.as_json[:dependency_scanning]).to include(:head_path)
    expect(subject.as_json[:dependency_scanning]).to include(:base_path)
  end

  it 'has sast_container data' do
    build = create(:ci_build, name: 'sast:image', pipeline: pipeline)

    allow(merge_request).to receive(:expose_sast_container_data?).and_return(true)
    allow(merge_request).to receive(:base_has_sast_container_data?).and_return(true)
    allow(merge_request).to receive(:base_sast_container_artifact).and_return(build)
    allow(merge_request).to receive(:head_sast_container_artifact).and_return(build)

    expect(subject.as_json).to include(:sast_container)
    expect(subject.as_json[:sast_container]).to include(:head_path)
    expect(subject.as_json[:sast_container]).to include(:base_path)
  end

  it 'has dast data' do
    build = create(:ci_build, name: 'dast', pipeline: pipeline)

    allow(merge_request).to receive(:expose_dast_data?).and_return(true)
    allow(merge_request).to receive(:base_has_dast_data?).and_return(true)
    allow(merge_request).to receive(:base_dast_artifact).and_return(build)
    allow(merge_request).to receive(:head_dast_artifact).and_return(build)

    expect(subject.as_json).to include(:dast)
    expect(subject.as_json[:dast]).to include(:head_path)
    expect(subject.as_json[:dast]).to include(:base_path)
  end
end

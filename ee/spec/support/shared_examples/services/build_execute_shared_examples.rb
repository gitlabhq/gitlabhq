# frozen_string_literal: true
RSpec.shared_examples 'restricts access to protected environments' do |developer_access_when_protected, developer_access_when_unprotected|
  context 'when build is related to a protected environment' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:environment) { create(:environment, project: project, name: 'production') }
    let(:build) { create(:ci_build, :created, pipeline: pipeline, environment: environment.name) }
    let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }
    let(:service) { described_class.new(project, user) }

    before do
      allow(project).to receive(:feature_available?).and_call_original
      allow(project).to receive(:feature_available?)
        .with(:protected_environments).and_return(true)

      project.add_developer(user)
      protected_environment
    end

    context 'when user does not have access to the environment' do
      it 'should raise Gitlab::Access::DeniedError' do
        expect { service.execute(build) }
          .to raise_error Gitlab::Access::AccessDeniedError
      end
    end

    context 'when user has access to the environment' do
      before do
        protected_environment.deploy_access_levels.create(user: user)
      end

      it 'enqueues the build' do
        build_enqueued = service.execute(build)

        expect(build_enqueued).to be_pending
      end
    end
  end
end

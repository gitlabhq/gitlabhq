# frozen_string_literal: true
RSpec.shared_examples 'protected environments access' do |developer_access = true|
  using RSpec::Parameterized::TableSyntax

  before do
    stub_feature_flags(protected_environments: enabled)
  end

  context 'when Protected Environments feature is not on' do
    let(:enabled) { false }

    where(:access_level, :result) do
      :guest      | false
      :reporter   | false
      :developer  | developer_access
      :maintainer | true
      :admin      | true
    end

    with_them do
      before do
        environment

        update_user_access(access_level, user, project)
      end

      it { is_expected.to eq(result) }
    end
  end

  context 'when Protected Environments feature is not available in the project' do
    let(:enabled) { true }

    where(:access_level, :result) do
      :guest      | false
      :reporter   | false
      :developer  | developer_access
      :maintainer | true
      :admin      | true
    end

    with_them do
      before do
        environment

        update_user_access(access_level, user, project)
      end

      it { is_expected.to eq(result) }
    end
  end

  context 'when Protected Environments feature is available in the project' do
    let(:enabled) { true }

    before do
      allow(License).to receive(:feature_available?).and_call_original
      allow(License).to receive(:feature_available?).with(:protected_environments).and_return(true)
    end

    context 'when environment is protected' do
      let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

      context 'when user does not have access to the environment' do
        where(:access_level, :result) do
          :guest      | false
          :reporter   | false
          :developer  | false
          :maintainer | false
          :admin      | true
        end

        with_them do
          before do
            protected_environment

            update_user_access(access_level, user, project)
          end

          it { is_expected.to eq(result) }
        end
      end

      context 'when user has access to the environment' do
        where(:access_level, :result) do
          :guest      | false
          :reporter   | false
          :developer  | developer_access
          :maintainer | true
          :admin      | true
        end

        with_them do
          before do
            protected_environment.deploy_access_levels.create(user: user)

            update_user_access(access_level, user, project)
          end

          it { is_expected.to eq(result) }
        end
      end
    end

    context 'when environment is not protected' do
      where(:access_level, :result) do
        :guest      | false
        :reporter   | false
        :developer  | developer_access
        :maintainer | true
        :admin      | true
      end

      with_them do
        before do
          update_user_access(access_level, user, project)
        end

        it { is_expected.to eq(result) }
      end
    end
  end

  def update_user_access(access_level, user, project)
    if access_level == :admin
      user.update_attribute(:admin, true)
    elsif access_level.present?
      project.add_user(user, access_level)
    end
  end
end

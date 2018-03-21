require 'spec_helper'

describe Projects::CreateService, '#execute' do
  let(:user) { create :user }
  let(:opts) do
    {
      name: "GitLab",
      namespace: user.namespace
    }
  end

  context 'with a CI/CD only project' do
    before do
      opts.merge!(
        ci_cd_only: true,
        import_url: 'http://foo.com'
      )
    end

    context 'when CI/CD projects feature is available' do
      before do
        stub_licensed_features(ci_cd_projects: true)
      end

      it 'calls the service to setup CI/CD on the project' do
        expect(CiCd::SetupProject).to receive_message_chain(:new, :execute)

        create_project(user, opts)
      end
    end

    context 'when CI/CD projects feature is not available' do
      before do
        stub_licensed_features(ci_cd_projects: false)
      end

      it "doesn't call the service to setup CI/CD on the project" do
        expect(CiCd::SetupProject).not_to receive(:new)

        create_project(user, opts)
      end
    end
  end

  context 'repository_size_limit assignment as Bytes' do
    let(:admin_user) { create(:user, admin: true) }

    context 'when param present' do
      let(:opts) { { repository_size_limit: '100' } }

      it 'assign repository_size_limit as Bytes' do
        project = create_project(admin_user, opts)

        expect(project.repository_size_limit).to eql(100 * 1024 * 1024)
      end
    end

    context 'when param not present' do
      let(:opts) { { repository_size_limit: '' } }

      it 'assign nil value' do
        project = create_project(admin_user, opts)

        expect(project.repository_size_limit).to be_nil
      end
    end
  end

  context 'without repository mirror' do
    before do
      stub_licensed_features(repository_mirrors: true)
      opts.merge!(import_url: 'http://foo.com')
    end

    it 'sets the mirror to false' do
      project = create_project(user, opts)

      expect(project).to be_persisted
      expect(project.mirror).to be false
    end
  end

  context 'with repository mirror' do
    before do
      opts.merge!(import_url: 'http://foo.com',
                  mirror: true,
                  mirror_user_id: user.id)
    end

    context 'when licensed' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      it 'sets the correct attributes' do
        project = create_project(user, opts)

        expect(project).to be_persisted
        expect(project.mirror).to be true
        expect(project.mirror_user_id).to eq(user.id)
      end

      context 'with mirror trigger builds' do
        before do
          opts.merge!(mirror_trigger_builds: true)
        end

        it 'sets the mirror trigger builds' do
          project = create_project(user, opts)

          expect(project).to be_persisted
          expect(project.mirror_trigger_builds).to be true
        end
      end

      context 'with checks on the namespace' do
        before do
          stub_const('License::ANY_PLAN_FEATURES', [])
          enable_namespace_license_check!
        end

        context 'when not licensed on a namespace' do
          it 'does not allow enabeling mirrors' do
            project = create_project(user, opts)

            expect(project).to be_persisted
            expect(project.mirror).to be_falsey
          end
        end

        context 'when licensed on a namespace' do
          it 'allows enabling mirrors' do
            plan = create(:gold_plan)
            user.namespace.update!(plan: plan)

            project = create_project(user, opts)

            expect(project).to be_persisted
            expect(project.mirror).to be_truthy
          end
        end
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'does not set mirror attributes' do
        project = create_project(user, opts)

        expect(project).to be_persisted
        expect(project.mirror).to be false
        expect(project.mirror_user_id).to be_nil
      end

      context 'with mirror trigger builds' do
        before do
          opts.merge!(mirror_trigger_builds: true)
        end

        it 'sets the mirror trigger builds' do
          project = create_project(user, opts)

          expect(project).to be_persisted
          expect(project.mirror_trigger_builds).to be false
        end
      end
    end
  end

  context 'git hook sample' do
    let!(:sample) { create(:push_rule_sample) }

    subject(:push_rule) { create_project(user, opts).push_rule }

    it 'creates git hook from sample' do
      is_expected.to have_attributes(
        force_push_regex: sample.force_push_regex,
        deny_delete_tag: sample.deny_delete_tag,
        delete_branch_regex: sample.delete_branch_regex,
        commit_message_regex: sample.commit_message_regex
      )
    end

    context 'push rules unlicensed' do
      before do
        stub_licensed_features(push_rules: false)
      end

      it 'ignores the push rule sample' do
        is_expected.to be_nil
      end
    end
  end

  context 'when running on a primary node' do
    set(:primary) { create(:geo_node, :primary) }
    set(:secondary) { create(:geo_node) }

    it 'logs an event to the Geo event log' do
      expect { create_project(user, opts) }.to change(Geo::RepositoryCreatedEvent, :count).by(1)
    end

    it 'does not log event to the Geo log if project creation fails' do
      failing_opts = {
        name: nil,
        namespace: user.namespace
      }

      expect { create_project(user, failing_opts) }.not_to change(Geo::RepositoryCreatedEvent, :count)
    end
  end

  context 'when importing Project by repo URL' do
    context 'and check namespace plan is enabled' do
      before do
        allow_any_instance_of(EE::Project).to receive(:add_import_job)
        enable_namespace_license_check!
      end

      it 'creates the project' do
        opts = {
          name: 'GitLab',
          import_url: 'https://www.gitlab.com/gitlab-org/gitlab-ce',
          visibility_level: Gitlab::VisibilityLevel::PRIVATE,
          namespace_id: user.namespace.id,
          mirror: true,
          mirror_user_id: user.id,
          mirror_trigger_builds: true
        }

        project = create_project(user, opts)

        expect(project).to be_persisted
      end
    end
  end

  context 'audit events' do
    include_examples 'audit event logging' do
      let(:operation) { create_project(user, opts) }
      let(:fail_condition!) do
        allow(Gitlab::VisibilityLevel).to receive(:allowed_for?).and_return(false)
      end
      let(:attributes) do
        {
           author_id: user.id,
           entity_id: @resource.id,
           entity_type: 'Project',
           details: {
             add: 'project',
             author_name: user.name,
             target_id: @resource.full_path,
             target_type: 'Project',
             target_details: @resource.full_path
           }
         }
      end
    end
  end

  def create_project(user, opts)
    described_class.new(user, opts).execute
  end
end

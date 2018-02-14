require 'spec_helper'

describe Projects::UpdateService, '#execute' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, creator: user, namespace: user.namespace) }

  context 'repository mirror' do
    let!(:opts) do
      {
        import_url: 'http://foo.com',
        mirror: true,
        mirror_user_id: user.id,
        mirror_trigger_builds: true
      }
    end

    context 'when licensed' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      it 'updates the correct attributes' do
        update_project(project, user, opts)

        updated_project = project.reload
        expect(updated_project).to be_valid
        expect(updated_project.mirror).to be true
        expect(updated_project.mirror_user_id).to eq(user.id)
        expect(updated_project.mirror_trigger_builds).to be true
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'does not update mirror attributes' do
        update_project(project, user, opts)

        updated_project = project.reload
        expect(updated_project).to be_valid
        expect(updated_project.mirror).to be false
        expect(updated_project.mirror_user_id).to be_nil
        expect(updated_project.mirror_trigger_builds).to be false
      end
    end
  end

  context 'audit events' do
    let(:audit_event_params) do
      {
        author_id: user.id,
        entity_id: project.id,
        entity_type: 'Project',
        details: {
          author_name: user.name,
          target_id: project.id,
          target_type: 'Project',
          target_details: project.full_path
        }
      }
    end

    context '#name' do
      include_examples 'audit event logging' do
        let!(:old_name) { project.full_name }
        let(:operation) { update_project(project, user, name: 'foobar') }
        let(:fail_condition!) do
          allow_any_instance_of(Project).to receive(:update_attributes).and_return(false)
        end

        let(:attributes) do
          audit_event_params.tap do |param|
            param[:details].merge!(
              change: 'name',
              from: old_name,
              to: project.full_name
            )
          end
        end
      end
    end

    context '#path' do
      include_examples 'audit event logging' do
        let(:operation) { update_project(project, user, path: 'foobar1') }
        let(:fail_condition!) do
          allow_any_instance_of(Project).to receive(:update_attributes).and_return(false)
        end

        let(:attributes) do
          audit_event_params.tap do |param|
            param[:details].merge!(
              change: 'path',
              from: project.old_path_with_namespace,
              to: project.full_path
            )
          end
        end
      end
    end

    context '#visibility' do
      include_examples 'audit event logging' do
        let(:operation) do
          update_project(project, user, visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        end
        let(:fail_condition!) do
          allow_any_instance_of(Project).to receive(:update_attributes).and_return(false)
        end

        let(:attributes) do
          audit_event_params.tap do |param|
            param[:details].merge!(
              change: 'visibility',
              from: 'Private',
              to: 'Internal'
            )
          end
        end
      end
    end
  end

  def update_project(project, user, opts)
    Projects::UpdateService.new(project, user, opts).execute
  end
end

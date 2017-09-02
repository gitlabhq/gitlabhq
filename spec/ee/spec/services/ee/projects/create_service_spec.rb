require 'spec_helper'

describe Projects::CreateService, '#execute' do
  let(:user) { create :user }
  let(:opts) do
    {
      name: "GitLab",
      namespace: user.namespace
    }
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

  def create_project(user, opts)
    Projects::CreateService.new(user, opts).execute
  end
end

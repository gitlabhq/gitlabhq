require 'spec_helper'

describe RepositoryImportWorker do
  let(:project) { create(:project, :import_scheduled) }

  it 'updates the error on custom project template Import/Export' do
    stub_licensed_features(custom_project_templates: true)
    error = %q{remote: Not Found fatal: repository 'https://user:pass@test.com/root/repoC.git/' not found }

    project.update(import_jid: '123', import_type: 'gitlab_custom_project_template')
    expect_any_instance_of(Projects::ImportService).to receive(:execute).and_return({ status: :error, message: error })

    expect do
      subject.perform(project.id)
    end.to raise_error(RuntimeError, error)

    expect(project.reload.import_error).not_to be_nil
  end

  context 'when project is a mirror' do
    let(:project) { create(:project, :mirror, :import_scheduled) }

    it 'adds mirror in front of the mirror scheduler queue' do
      expect_any_instance_of(Projects::ImportService).to receive(:execute)
        .and_return({ status: :ok })

      expect_any_instance_of(EE::Project).to receive(:force_import_job!)

      subject.perform(project.id)
    end
  end
end

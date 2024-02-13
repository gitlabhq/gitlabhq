# frozen_string_literal: true

RSpec.describe QA::Runtime::Datastore do
  subject(:instance) { described_class.new(gdk_folder: '~/src/gdk2') }

  let(:query_string) { 'select name from projects;' }
  let(:query_result) { 'a,b,c' }

  shared_examples 'queries gdk' do
    def test_action; end

    it 'returns true' do
      expect(instance).to receive(:query_gdk).with(query_string).and_return(query_result)
      test_action
    end
  end

  context 'when a run generates an error' do
    it 'if query handler not defined' do
      instance = described_class.new
      expect { instance.namespaces }.to raise_error('query handler not defined for this instance')
    end

    it 'if pointed at invalid gdk folder' do
      gdk_folder = '~/nonexistent_folder123456'
      instance = described_class.new(gdk_folder: gdk_folder)

      expect { instance.projects }.to raise_error(RuntimeError, /#{gdk_folder}/)
    end
  end

  context 'when retrieving projects' do
    it_behaves_like 'queries gdk' do
      def test_action
        instance.projects
      end
    end
  end

  context 'when retrieving namespaces' do
    let(:query_string) { 'select name from namespaces;' }

    it_behaves_like 'queries gdk' do
      def test_action
        instance.namespaces
      end
    end
  end

  context 'when checking a project exists' do
    let(:project_name) { 'test project' }
    let(:query_string) { "select name from projects where name LIKE '#{project_name}';" }

    context 'with a valid project' do
      it_behaves_like 'queries gdk' do
        let(:query_result) { project_name }

        def test_action
          expect(instance).to have_project(project_name)
        end
      end
    end

    context 'without a valid project' do
      let(:query_string) { "select name from projects where name LIKE '#{project_name}';" }

      it_behaves_like 'queries gdk' do
        def test_action
          expect(instance).not_to have_project(project_name)
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Go::ModuleFinder do
  let_it_be(:project) { create :project }
  let_it_be(:other_project) { create :project }

  let(:finder) { described_class.new project, module_name }

  shared_examples 'an invalid path' do
    describe '#module_name' do
      it 'returns the expected name' do
        expect(finder.module_name).to eq(expected_name)
      end
    end

    describe '#execute' do
      it 'returns nil' do
        expect(finder.execute).to be_nil
      end
    end
  end

  describe '#execute' do
    context 'with module name equal to project name' do
      let(:module_name) { base_url(project) }

      it 'returns a module with empty path' do
        mod = finder.execute
        expect(mod).not_to be_nil
        expect(mod.path).to eq('')
      end
    end

    context 'with module name starting with project name and slash' do
      let(:module_name) { base_url(project) + '/mod' }

      it 'returns a module with non-empty path' do
        mod = finder.execute
        expect(mod).not_to be_nil
        expect(mod.path).to eq('mod')
      end
    end

    context 'with a module name not equal to and not starting with project name' do
      let(:module_name) { base_url(other_project) }

      it 'returns nil' do
        expect(finder.execute).to be_nil
      end
    end
  end

  context 'with relative path component' do
    it_behaves_like 'an invalid path' do
      let(:module_name) { base_url(project) + '/../xyz' }
      let(:expected_name) { base_url(project.namespace) + '/xyz' }
    end
  end

  context 'with many relative path components' do
    it_behaves_like 'an invalid path' do
      let(:module_name) { base_url(project) + ('/..' * 10) + '/xyz' }
      let(:expected_name) { ('../' * 7) + 'xyz' }
    end
  end

  def base_url(project)
    "#{Settings.build_gitlab_go_url}/#{project.full_path}"
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DesignManagement::DesignsFinder do
  include DesignManagementTestHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:design1) { create(:design, :with_file, issue: issue, versions_count: 1, relative_position: 3) }
  let_it_be(:design2) { create(:design, :with_file, issue: issue, versions_count: 1, relative_position: 2) }
  let_it_be(:design3) { create(:design, :with_file, issue: issue, versions_count: 1, relative_position: 1) }

  let(:params) { {} }

  subject(:designs) { described_class.new(issue, user, params).execute }

  describe '#execute' do
    context 'when user can not read designs of an issue' do
      it 'returns no results' do
        is_expected.to be_empty
      end
    end

    context 'when user can read designs of an issue' do
      before do
        project.add_developer(user)
      end

      context 'when design management feature is disabled' do
        it 'returns no results' do
          is_expected.to be_empty
        end
      end

      context 'when design management feature is enabled' do
        before do
          enable_design_management
        end

        it 'returns the designs sorted by their relative position' do
          is_expected.to eq([design3, design2, design1])
        end

        context 'when argument is the ids of designs' do
          let(:params) { { ids: [design1.id] } }

          it { is_expected.to eq([design1]) }
        end

        context 'when argument is the filenames of designs' do
          let(:params) { { filenames: [design2.filename] } }

          it { is_expected.to eq([design2]) }
        end

        context 'when passed empty array' do
          context 'for filenames' do
            let(:params) { { filenames: [] } }

            it { is_expected.to be_empty }
          end

          context "for ids" do
            let(:params) { { ids: [] } }

            it { is_expected.to be_empty }
          end
        end

        describe 'returning designs that existed at a particular given version' do
          let(:all_versions) { issue.design_collection.versions.ordered }
          let(:first_version) { all_versions.last }
          let(:second_version) { all_versions.second }

          context 'when argument is the first version' do
            let(:params) { { visible_at_version: first_version } }

            it { is_expected.to eq([design1]) }
          end

          context 'when arguments are version and id' do
            context 'when id is absent at version' do
              let(:params) { { visible_at_version: first_version, ids: [design2.id] } }

              it { is_expected.to eq([]) }
            end

            context 'when id is present at version' do
              let(:params) { { visible_at_version: second_version, ids: [design2.id] } }

              it { is_expected.to eq([design2]) }
            end
          end

          context 'when argument is the second version' do
            let(:params) { { visible_at_version: second_version } }

            it { is_expected.to contain_exactly(design1, design2) }
          end
        end
      end
    end
  end
end

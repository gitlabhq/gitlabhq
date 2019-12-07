# frozen_string_literal: true

require 'spec_helper'

describe GroupProjectsFinder do
  include_context 'GroupProjectsFinder context'

  subject { finder.execute }

  describe 'with a group member current user' do
    before do
      group.add_maintainer(current_user)
    end

    context "only shared" do
      let(:options) { { only_shared: true } }

      it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1]) }
    end

    context "only owned" do
      let(:options) { { only_owned: true } }

      context 'with subgroups projects' do
        before do
          options[:include_subgroups] = true
        end

        it { is_expected.to match_array([private_project, public_project, subgroup_project, subgroup_private_project]) }
      end

      context 'without subgroups projects' do
        it { is_expected.to match_array([private_project, public_project]) }
      end
    end

    context "all" do
      context 'with subgroups projects' do
        before do
          options[:include_subgroups] = true
        end

        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1, private_project, public_project, subgroup_project, subgroup_private_project]) }
      end

      context 'without subgroups projects' do
        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1, private_project, public_project]) }
      end
    end
  end

  describe 'without group member current_user' do
    before do
      shared_project_2.add_maintainer(current_user)
      current_user.reload
    end

    context "only shared" do
      let(:options) { { only_shared: true } }

      context "without external user" do
        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1]) }
      end

      context "with external user" do
        before do
          current_user.update(external: true)
        end

        it { is_expected.to match_array([shared_project_2, shared_project_1]) }
      end
    end

    context "only owned" do
      let(:options) { { only_owned: true } }

      context "without external user" do
        before do
          private_project.add_maintainer(current_user)
          subgroup_private_project.add_maintainer(current_user)
        end

        context 'with subgroups projects' do
          before do
            options[:include_subgroups] = true
          end

          it { is_expected.to match_array([private_project, public_project, subgroup_project, subgroup_private_project]) }
        end

        context 'without subgroups projects' do
          it { is_expected.to match_array([private_project, public_project]) }
        end
      end

      context "with external user" do
        before do
          current_user.update(external: true)
        end

        context 'with subgroups projects' do
          before do
            options[:include_subgroups] = true
          end

          it { is_expected.to match_array([public_project, subgroup_project]) }
        end

        context 'without subgroups projects' do
          it { is_expected.to eq([public_project]) }
        end
      end
    end

    context "all" do
      context 'with subgroups projects' do
        before do
          options[:include_subgroups] = true
        end

        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1, public_project, subgroup_project]) }
      end

      context 'without subgroups projects' do
        it { is_expected.to match_array([shared_project_3, shared_project_2, shared_project_1, public_project]) }
      end
    end
  end

  describe 'with an admin current user' do
    let(:current_user) { create(:admin) }

    context "only shared" do
      let(:options) { { only_shared: true } }
      it            { is_expected.to eq([shared_project_3, shared_project_2, shared_project_1]) }
    end

    context "only owned" do
      let(:options) { { only_owned: true } }
      it            { is_expected.to eq([private_project, public_project]) }
    end

    context "all" do
      it { is_expected.to eq([shared_project_3, shared_project_2, shared_project_1, private_project, public_project]) }
    end
  end

  describe "no user" do
    context "only shared" do
      let(:options) { { only_shared: true } }

      it { is_expected.to match_array([shared_project_3, shared_project_1]) }
    end

    context "only owned" do
      let(:options) { { only_owned: true } }

      context 'with subgroups projects' do
        before do
          options[:include_subgroups] = true
        end

        it { is_expected.to match_array([public_project, subgroup_project]) }
      end

      context 'without subgroups projects' do
        it { is_expected.to eq([public_project]) }
      end
    end
  end

  describe 'limiting' do
    context 'without limiting' do
      it 'returns all projects' do
        expect(subject.count).to eq(3)
      end
    end

    context 'with limiting' do
      let(:options) { { limit: 1 } }

      it 'returns only the number of projects specified by the limit' do
        expect(subject.count).to eq(1)
      end
    end
  end
end

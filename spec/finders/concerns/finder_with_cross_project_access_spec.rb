# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FinderWithCrossProjectAccess do
  let(:finder_class) do
    Class.new do
      prepend FinderWithCrossProjectAccess
      include FinderMethods

      requires_cross_project_access if: -> { requires_access? }

      attr_reader :current_user

      def initialize(user)
        @current_user = user
      end

      def execute
        Issue.all
      end
    end
  end

  let(:user) { create(:user) }
  let!(:result) { create(:issue) }

  subject(:finder) { finder_class.new(user) }

  before do
    result.project.add_maintainer(user)
  end

  def expect_access_check_on_result
    expect(finder).not_to receive(:requires_access?)
    expect(Ability).to receive(:allowed?).with(user, :read_issue, result).and_call_original
  end

  context 'when the user cannot read cross project' do
    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(user, :read_cross_project)
                          .and_return(false)
    end

    describe '#execute' do
      it 'returns a issue if the check is disabled' do
        expect(finder).to receive(:requires_access?).and_return(false)

        expect(finder.execute).to include(result)
      end

      it 'returns an empty relation when the check is enabled' do
        expect(finder).to receive(:requires_access?).and_return(true)

        expect(finder.execute).to be_empty
      end

      it 'only queries once when check is enabled' do
        expect(finder).to receive(:requires_access?).and_return(true)

        expect { finder.execute }.not_to exceed_query_limit(1)
      end

      it 'only queries once when check is disabled' do
        expect(finder).to receive(:requires_access?).and_return(false)

        expect { finder.execute }.not_to exceed_query_limit(1)
      end
    end

    describe '#find' do
      it 'checks the accessibility of the subject directly' do
        expect_access_check_on_result

        finder.find(result.id)
      end

      it 'returns the issue' do
        expect(finder.find(result.id)).to eq(result)
      end
    end

    describe '#find_by' do
      it 'checks the accessibility of the subject directly' do
        expect_access_check_on_result

        finder.find_by(id: result.id)
      end
    end

    describe '#find_by!' do
      it 'checks the accessibility of the subject directly' do
        expect_access_check_on_result

        finder.find(result.id)
      end

      it 're-enables the check after the find failed' do
        begin
          finder.find(non_existing_record_id)
        rescue ActiveRecord::RecordNotFound
          nil
        end

        expect(finder.instance_variable_get(:@should_skip_cross_project_check))
          .to eq(false)
      end
    end
  end

  context 'when the user can read cross project' do
    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?).with(user, :read_cross_project)
                          .and_return(true)
    end

    it 'returns the result' do
      expect(finder).not_to receive(:requires_access?)

      expect(finder.execute).to include(result)
    end
  end

  context 'when specifying a model' do
    let(:finder_class) do
      Class.new do
        prepend FinderWithCrossProjectAccess

        requires_cross_project_access model: Project
      end
    end

    describe '.finder_model' do
      it 'is set correctly' do
        expect(finder_class.finder_model).to eq(Project)
      end
    end
  end
end

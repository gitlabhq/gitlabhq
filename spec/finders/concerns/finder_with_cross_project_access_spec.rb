require 'spec_helper'

describe FinderWithCrossProjectAccess do
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
  subject(:finder) { finder_class.new(user) }
  let!(:result) { create(:issue) }

  before do
    result.project.add_master(user)
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

        finder.find_by!(id: result.id)
      end

      it 're-enables the check after the find failed' do
        finder.find_by!(id: 9999) rescue ActiveRecord::RecordNotFound

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
end

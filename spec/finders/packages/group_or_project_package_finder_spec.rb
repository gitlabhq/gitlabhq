# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::GroupOrProjectPackageFinder do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:finder) { described_class.new(user, project) }

  describe 'execute' do
    subject(:run_finder) { finder.execute }

    it { expect { run_finder }.to raise_error(NotImplementedError) }
  end

  describe 'execute!' do
    subject(:run_finder) { finder.execute! }

    it { expect { run_finder }.to raise_error(NotImplementedError) }
  end
end

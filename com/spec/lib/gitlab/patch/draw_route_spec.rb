# frozen_string_literal: true

require 'fast_spec_helper'
require 'com_spec_helper'

describe Gitlab::Patch::DrawRoute do
  subject do
    Class.new do
      include Gitlab::Patch::DrawRoute

      def route_path(route_name)
        File.expand_path("../../../../../#{route_name}", __dir__)
      end
    end.new
  end

  before do
    allow(subject).to receive(:instance_eval)
  end

  it 'raises an error when nothing is drawn' do
    expect { subject.draw(:non_existing) }
        .to raise_error(described_class::RoutesNotFound)
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Grape::Entity patch' do
  let(:entity_class) { Class.new(Grape::Entity) }

  describe 'NameError in block exposure with argument' do
    subject(:represent) { entity_class.represent({}, serializable: true) }

    before do
      entity_class.expose :raise_no_method_error do |_|
        foo
      end
    end

    it 'propagates the error to the caller' do
      expect { represent }.to raise_error(NameError)
    end
  end
end

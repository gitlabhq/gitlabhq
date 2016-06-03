require 'spec_helper'

describe 'factories' do
  FactoryGirl.factories.each do |factory|
    describe "#{factory.name} factory" do
      let(:entity) { build(factory.name) }

      it 'does not raise error when created 'do
        expect { entity }.to_not raise_error
      end

      it 'should be valid', if: factory.build_class < ActiveRecord::Base do
        expect(entity).to be_valid
      end
    end
  end
end

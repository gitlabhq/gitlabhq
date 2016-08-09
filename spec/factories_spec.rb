require 'spec_helper'

describe 'factories' do
  FactoryGirl.factories.each do |factory|
    describe "#{factory.name} factory" do
      let(:entity) { build(factory.name) }

      it 'does not raise error when created' do
        expect { entity }.not_to raise_error
      end

      it 'is valid', if: factory.build_class < ActiveRecord::Base do
        expect(entity).to be_valid
      end
    end
  end
end

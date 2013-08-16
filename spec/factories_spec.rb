require 'spec_helper'

INVALID_FACTORIES = [
  :key_with_a_space_in_the_middle,
  :invalid_key,
]

FactoryGirl.factories.map(&:name).each do |factory_name|
  next if INVALID_FACTORIES.include?(factory_name)
  describe "#{factory_name} factory" do
    it 'should be valid' do
      build(factory_name).should be_valid
    end
  end
end

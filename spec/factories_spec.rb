# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'factories' do
  shared_examples 'factory' do |factory|
    describe "#{factory.name} factory" do
      it 'does not raise error when built' do
        expect { build(factory.name) }.not_to raise_error
      end

      it 'does not raise error when created' do
        expect { create(factory.name) }.not_to raise_error
      end

      factory.definition.defined_traits.map(&:name).each do |trait_name|
        describe "linting #{trait_name} trait" do
          skip 'does not raise error when created' do
            expect { create(factory.name, trait_name) }.not_to raise_error
          end
        end
      end
    end
  end

  # FactoryDefault speed up specs by creating associations only once
  # and reuse them in other factories.
  #
  # However, for some factories we cannot use FactoryDefault because the
  # associations must be unique and cannot be reused.
  skip_factory_defaults = %i[
    fork_network_member
  ].to_set.freeze

  without_fd, with_fd = FactoryBot.factories
    .partition { |factory| skip_factory_defaults.include?(factory.name) }

  context 'with factory defaults', factory_default: :keep do
    let_it_be(:namespace) { create_default(:namespace) }
    let_it_be(:project) { create_default(:project, :repository) }
    let_it_be(:user) { create_default(:user) }

    with_fd.each do |factory|
      it_behaves_like 'factory', factory
    end
  end

  context 'without factory defaults' do
    without_fd.each do |factory|
      it_behaves_like 'factory', factory
    end
  end
end

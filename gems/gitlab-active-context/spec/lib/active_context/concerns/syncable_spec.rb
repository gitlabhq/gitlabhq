# frozen_string_literal: true

RSpec.describe ActiveContext::Concerns::Syncable do
  let(:mock_model_class) do
    Class.new do
      include ActiveContext::Concerns::Syncable
    end
  end

  [:create, :update, :destroy].each do |operation|
    describe ".sync_with_active_context on #{operation}" do
      let(:using_block) { -> { foo } }

      it "calls after_#{operation}_commit where the first condition is syncable?" do
        expect(mock_model_class).to receive(:"after_#{operation}_commit") do |options, &block|
          expect(block).to eq(using_block)
          expect(options[:if].source_location.first).to include('concerns/syncable.rb')
        end

        mock_model_class.sync_with_active_context(on: operation, using: using_block)
      end
    end
  end
end

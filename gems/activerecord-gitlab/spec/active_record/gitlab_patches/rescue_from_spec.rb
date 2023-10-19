# frozen_string_literal: true

RSpec.describe ActiveRecord::GitlabPatches::RescueFrom do
  let(:model_with_rescue_from) do
    Class.new(Project) do
      rescue_from ActiveRecord::StatementInvalid, with: :handle_exception
      rescue_from ActiveRecord::UnknownAttributeError, with: :handle_attr_exception

      class << self
        def handle_exception(exception); end
      end

      def handle_attr_exception(exc); end
    end
  end

  let(:model_without_rescue_from) do
    Class.new(Project)
  end

  context 'for errors from ActiveRelation.load' do
    it 'triggers rescue_from' do
      expect(model_with_rescue_from).to receive(:handle_exception)

      expect { model_with_rescue_from.where('BADQUERY').load }.not_to raise_error
    end

    it 'does not trigger rescue_from' do
      expect { model_without_rescue_from.where('BADQUERY').load }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  context 'for errors from ActiveRecord::Base.assign_attributes' do
    it 'triggers rescue_from' do
      model_instance = model_with_rescue_from.new

      expect(model_instance).to receive(:handle_attr_exception)

      expect { model_instance.assign_attributes(nonexistent_column: "some value") }.not_to raise_error
    end

    it 'does not trigger rescue_from' do
      expect { model_without_rescue_from.new.assign_attributes(nonexistent_column: "some value") }
        .to raise_error(ActiveRecord::UnknownAttributeError)
    end
  end
end

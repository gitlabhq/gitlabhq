# frozen_string_literal: true

RSpec.describe ActiveRecord::GitlabPatches::RescueFrom do
  let(:model_with_rescue_from) do
    Class.new(Project) do
      rescue_from ActiveRecord::StatementInvalid, with: :handle_exception

      class << self
        def handle_exception(exception); end
      end
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
end

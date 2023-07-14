# frozen_string_literal: true

RSpec.describe ActiveRecord::GitlabPatches::RescueFrom, :without_sqlite3 do
  let(:model_with_rescue_from) do
    Class.new(ActiveRecord::Base) do
      rescue_from ActiveRecord::ConnectionNotEstablished, with: :handle_exception

      class << self
        def handle_exception(exception); end
      end
    end
  end

  let(:model_without_rescue_from) do
    Class.new(ActiveRecord::Base)
  end

  it 'triggers rescue_from' do
    stub_const('ModelWithRescueFrom', model_with_rescue_from)

    expect(model_with_rescue_from).to receive(:handle_exception)

    expect { model_with_rescue_from.all.load }.not_to raise_error
  end

  it 'does not trigger rescue_from' do
    stub_const('ModelWithoutRescueFrom', model_without_rescue_from)

    expect { model_without_rescue_from.all.load }.to raise_error(ActiveRecord::ConnectionNotEstablished)
  end
end

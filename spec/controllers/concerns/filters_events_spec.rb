# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FiltersEvents, feature_category: :groups_and_projects do
  let(:controller_class) do
    # rubocop:disable Rails/ApplicationController -- the concern only needs params and cookies
    Class.new(ActionController::Base) do
      include FiltersEvents
    end
    # rubocop:enable Rails/ApplicationController
  end

  let(:request_params) { {} }
  let(:cookie_jar) { {} }

  subject(:controller) { controller_class.new }

  before do
    allow(controller).to receive_messages(
      params: ActionController::Parameters.new(request_params),
      cookies: cookie_jar
    )
  end

  describe '#event_filter' do
    context 'when the event_filter param is given' do
      let(:request_params) { { event_filter: EventFilter::ISSUE } }
      let(:cookie_jar) { { event_filter: EventFilter::PUSH } }

      it 'prefers the param over the cookie and persists it' do
        expect(controller.event_filter.filter).to eq(EventFilter::ISSUE)
        expect(cookie_jar[:event_filter]).to eq(EventFilter::ISSUE)
      end
    end

    context 'when the event_filter param is blank' do
      let(:request_params) { { event_filter: '' } }
      let(:cookie_jar) { { event_filter: EventFilter::MERGED } }

      it 'falls back to the cookie' do
        expect(controller.event_filter.filter).to eq(EventFilter::MERGED)
      end
    end

    context 'when neither the param nor the cookie is set' do
      it 'falls back to the default filter' do
        expect(controller.event_filter.filter).to eq(EventFilter::ALL)
      end
    end

    context 'when an unpermitted param is given' do
      let(:request_params) { { filter: EventFilter::ISSUE } }
      let(:cookie_jar) { { event_filter: EventFilter::PUSH } }

      it 'ignores it and falls back to the cookie' do
        expect(controller.event_filter.filter).to eq(EventFilter::PUSH)
      end
    end
  end
end

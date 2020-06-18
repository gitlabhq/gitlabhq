# frozen_string_literal: true

require 'spec_helper'

class PageLimiterSpecController < ApplicationController
  include PageLimiter

  before_action do
    limit_pages 200
  end

  def index
    head :ok
  end
end

RSpec.describe PageLimiter do
  let(:controller_class) do
    PageLimiterSpecController
  end

  let(:instance) do
    controller_class.new
  end

  before do
    allow(instance).to receive(:params) do
      {
        controller: "explore/projects",
        action: "index"
      }
    end

    allow(instance).to receive(:request) do
      double(:request, user_agent: "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)")
    end
  end

  describe "#limit_pages" do
    using RSpec::Parameterized::TableSyntax

    where(:max_page, :actual_page, :result) do
      2   | 1 | nil
      2   | 2 | nil
      2   | 3 | PageLimiter::PageOutOfBoundsError
      nil | 1 | PageLimiter::PageLimitNotANumberError
      0   | 1 | PageLimiter::PageLimitNotSensibleError
      -1  | 1 | PageLimiter::PageLimitNotSensibleError
    end

    with_them do
      subject { instance.limit_pages(max_page) }

      before do
        allow(instance).to receive(:params) { { page: actual_page.to_s } }
      end

      it "returns the expected result" do
        if result == PageLimiter::PageOutOfBoundsError
          expect(instance).to receive(:record_page_limit_interception)
          expect { subject }.to raise_error(result)
        elsif result&.superclass == PageLimiter::PageLimiterError
          expect { subject }.to raise_error(result)
        else
          expect(subject).to eq(result)
        end
      end
    end
  end

  describe "#default_page_out_of_bounds_response" do
    subject { instance.send(:default_page_out_of_bounds_response) }

    it "returns a bad_request header" do
      expect(instance).to receive(:head).with(:bad_request)

      subject
    end
  end

  describe "#record_page_limit_interception" do
    subject { instance.send(:record_page_limit_interception) }

    let(:counter) { double("counter", increment: true) }

    before do
      allow(Gitlab::Metrics).to receive(:counter) { counter }
    end

    it "creates a metric counter" do
      expect(Gitlab::Metrics).to receive(:counter).with(
        :gitlab_page_out_of_bounds,
        controller: "explore/projects",
        action: "index",
        bot: true
      )

      subject
    end

    it "increments the counter" do
      expect(counter).to receive(:increment)

      subject
    end
  end
end

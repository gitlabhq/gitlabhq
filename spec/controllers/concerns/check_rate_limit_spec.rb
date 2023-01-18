# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CheckRateLimit do
  let(:key) { :some_key }
  let(:scope) { [:some, :scope] }
  let(:request) { instance_double('Rack::Request') }
  let(:user) { build_stubbed(:user) }

  let(:controller_class) do
    Class.new do
      include CheckRateLimit

      attr_reader :request, :current_user

      def initialize(request, current_user)
        @request = request
        @current_user = current_user
      end

      def redirect_back_or_default(**args); end

      def render(**args); end
    end
  end

  subject { controller_class.new(request, user) }

  before do
    allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?)
    allow(::Gitlab::ApplicationRateLimiter).to receive(:log_request)
  end

  describe '#check_rate_limit!' do
    it 'calls ApplicationRateLimiter#throttled_request? with the right arguments' do
      expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).with(request, user, key, scope: scope).and_return(false)
      expect(subject).not_to receive(:render)

      subject.check_rate_limit!(key, scope: scope)
    end

    it 'renders error and logs request if throttled' do
      expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(key, scope: scope).and_return(true)
      expect(::Gitlab::ApplicationRateLimiter).to receive(:log_request).with(request, "#{key}_request_limit".to_sym, user)
      expect(subject).to receive(:render).with({ plain: _('This endpoint has been requested too many times. Try again later.'), status: :too_many_requests })

      subject.check_rate_limit!(key, scope: scope)
    end

    it 'redirects back if throttled and redirect_back option is set to true' do
      expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(key, scope: scope).and_return(true)
      expect(::Gitlab::ApplicationRateLimiter).to receive(:log_request).with(request, "#{key}_request_limit".to_sym, user)
      expect(subject).not_to receive(:render)
      expect(subject).to receive(:redirect_back_or_default).with(options: { alert: _('This endpoint has been requested too many times. Try again later.') })

      subject.check_rate_limit!(key, scope: scope, redirect_back: true)
    end

    context 'when the bypass header is set' do
      before do
        allow(Gitlab::Throttle).to receive(:bypass_header).and_return('SOME_HEADER')
      end

      it 'skips rate limit if set to "1"' do
        allow(request).to receive(:get_header).with(Gitlab::Throttle.bypass_header).and_return('1')

        expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)
        expect(subject).not_to receive(:render)

        subject.check_rate_limit!(key, scope: scope)
      end

      it 'does not skip rate limit if set to something else than "1"' do
        allow(request).to receive(:get_header).with(Gitlab::Throttle.bypass_header).and_return('0')

        expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?)

        subject.check_rate_limit!(key, scope: scope)
      end
    end
  end
end

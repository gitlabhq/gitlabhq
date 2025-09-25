# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::SearchRateLimitable, feature_category: :global_search do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:resolver_class) do
    Class.new do
      include Search::SearchRateLimitable

      attr_reader :context

      def initialize(context)
        @context = context
      end

      def resolve(**args)
        verify_search_rate_limit!(**args)
        []
      end

      def current_user
        context[:current_user]
      end

      private

      def search_params(**args)
        args
      end

      def scope
        'issues'
      end
    end
  end

  let(:context) { { current_user: current_user, request: request } }
  let(:resolver) { resolver_class.new(context) }
  let(:request) { instance_double(ActionDispatch::Request, ip: '127.0.0.1') }

  describe '#verify_search_rate_limit!' do
    context 'when current_user is present' do
      context 'when rate limit is not exceeded' do
        before do
          allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).and_return(false)
        end

        it 'does not raise an error' do
          expect { resolver.resolve(search: 'test') }.not_to raise_error
        end

        it 'calls ApplicationRateLimiter with correct parameters' do
          expect(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).with(
            request,
            current_user,
            :search_rate_limit,
            scope: [current_user, 'issues'],
            users_allowlist: Gitlab::CurrentSettings.current_application_settings.search_rate_limit_allowlist
          )

          resolver.resolve(search: 'test')
        end
      end

      context 'when rate limit is exceeded' do
        before do
          allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).and_return(true)
        end

        it 'raises a resource not available error' do
          expect { resolver.resolve(search: 'test') }.to raise_error(
            Gitlab::Graphql::Errors::ResourceNotAvailable,
            "_('This endpoint has been requested too many times. Try again later.')"
          )
        end
      end

      context 'when search params are abusive' do
        let(:abusive_resolver_class) do
          Class.new do
            include Search::SearchRateLimitable

            attr_reader :context

            def initialize(context)
              @context = context
            end

            def resolve(**args)
              verify_search_rate_limit!(**args)
              []
            end

            def current_user
              context[:current_user]
            end

            private

            def search_params(**args)
              args
            end

            def scope
              'issues'
            end
          end
        end

        let(:abusive_resolver) { abusive_resolver_class.new(context) }

        before do
          allow_next_instance_of(Gitlab::Search::Params) do |search_params|
            allow(search_params).to receive(:abusive?).and_return(true)
          end
          allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).and_return(false)
        end

        it 'excludes search scope when search params are abusive' do
          expect(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).with(
            request,
            current_user,
            :search_rate_limit,
            scope: [current_user],
            users_allowlist: Gitlab::CurrentSettings.current_application_settings.search_rate_limit_allowlist
          )

          abusive_resolver.resolve(search: 'x' * 1000)
        end
      end
    end

    context 'when current_user is nil' do
      let(:nil_user_context) { { current_user: nil, request: request } }
      let(:nil_user_resolver) { resolver_class.new(nil_user_context) }

      context 'when rate limit is not exceeded' do
        before do
          allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).and_return(false)
        end

        it 'does not raise an error' do
          expect { nil_user_resolver.resolve(search: 'test') }.not_to raise_error
        end

        it 'calls ApplicationRateLimiter with unauthenticated key and IP scope' do
          expect(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).with(
            request,
            nil,
            :search_rate_limit_unauthenticated,
            scope: ['127.0.0.1'],
            users_allowlist: nil
          )

          nil_user_resolver.resolve(search: 'test')
        end
      end

      context 'when rate limit is exceeded' do
        before do
          allow(Gitlab::ApplicationRateLimiter).to receive(:throttled_request?).and_return(true)
        end

        it 'raises a resource not available error' do
          expect { nil_user_resolver.resolve(search: 'test') }.to raise_error(
            Gitlab::Graphql::Errors::ResourceNotAvailable,
            "_('This endpoint has been requested too many times. Try again later.')"
          )
        end
      end
    end
  end

  describe 'required method implementations' do
    let(:incomplete_resolver_class) do
      Class.new do
        include Search::SearchRateLimitable

        attr_reader :context

        def initialize(context)
          @context = context
        end

        def current_user
          context[:current_user]
        end
      end
    end

    let(:incomplete_resolver) { incomplete_resolver_class.new(context) }

    it 'requires search_params method to be implemented' do
      expect do
        incomplete_resolver.verify_search_rate_limit!(search: 'test')
      end.to raise_error(NoMethodError, /search_params/)
    end

    it 'requires scope method to be implemented' do
      allow(incomplete_resolver).to receive(:search_params).and_return({})
      expect { incomplete_resolver.verify_search_rate_limit!(search: 'test') }.to raise_error(NameError, /scope/)
    end
  end
end

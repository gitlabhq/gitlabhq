# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::HookExecutionNotice, feature_category: :webhooks do
  let(:test_class) do
    Class.new do
      include WebHooks::HookExecutionNotice

      attr_accessor :flash

      def initialize
        @flash = {}
      end
    end
  end

  subject(:controller) { test_class.new }

  describe '#set_hook_execution_notice' do
    let(:result) { ServiceResponse.new(status: :success, message: message, payload: { http_status: http_status }) }

    context 'when message is within limit' do
      let(:message) { 'Short error message' }
      let(:http_status) { 500 }

      it 'displays the full message' do
        controller.send(:set_hook_execution_notice, result)

        expect(controller.flash[:alert])
          .to eq("Hook executed successfully but returned HTTP 500 #{message}")
      end
    end

    context 'when message exceeds WebHookService::RESPONSE_BODY_SIZE_LIMIT' do
      let(:message) { 'a' * 10_000 }
      let(:http_status) { 500 }

      it 'truncates message' do
        controller.send(:set_hook_execution_notice, result)

        expect(controller.flash[:alert])
          .to eq("Hook executed successfully but returned HTTP 500 #{'a' * 8189}…")
      end
    end

    context 'when hook execution is successful' do
      let(:message) { 'Success' }
      let(:http_status) { 200 }

      it 'sets notice flash' do
        controller.send(:set_hook_execution_notice, result)

        expect(controller.flash[:notice]).to eq('Hook executed successfully: HTTP 200')
      end
    end

    context 'when hook execution fails without http_status' do
      let(:message) { 'a' * 10_000 }
      let(:http_status) { nil }

      it 'truncates message' do
        controller.send(:set_hook_execution_notice, result)

        expect(controller.flash[:alert])
          .to eq("Hook execution failed: #{'a' * 8189}…")
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebHooks::HookActions, feature_category: :webhooks do
  controller(ApplicationController) do
    include WebHooks::HookActions
    include WebHooks::HookExecutionNotice

    attr_accessor :hooks, :hook

    def relation
      @relation ||= WebHook.all
    end

    def trigger_values
      %i[push_events issues_events merge_requests_events]
    end

    def pagination_params
      { page: params[:page] }
    end
  end

  let(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let(:webhook) { create(:project_hook, project: project) }
  let(:relation_mock) { instance_double(ActiveRecord::Relation) }
  let(:errors_mock) { instance_double(ActiveModel::Errors) }
  let(:valid_params) do
    {
      hook: {
        url: 'http://example.com/hook',
        push_events: true,
        issues_events: false,
        custom_headers: [{ key: 'X-Custom', value: 'test' }],
        url_variables: [{ key: 'token', value: 'secret' }]
      }
    }
  end

  before do
    sign_in(user)
    allow(controller).to receive_messages(
      current_user: user,
      relation: relation_mock,
      hook: webhook
    )

    allow(relation_mock).to receive_messages(
      select: [webhook],
      new: WebHook.new
    )

    allow(controller).to receive(:redirect_to)
    allow(controller).to receive(:render)
  end

  describe '#index' do
    before do
      allow(controller).to receive(:hook).and_call_original
    end

    it 'sets hooks and creates new hook instance' do
      controller.index

      expect(controller.hooks).to contain_exactly(webhook)
      expect(controller.hook).to be_a_new(WebHook)
    end

    it 'only includes persisted hooks' do
      new_hook = WebHook.new
      persisted_hooks = [webhook]
      allow(relation_mock).to receive(:select).and_yield(webhook).and_yield(new_hook).and_return(persisted_hooks)

      controller.index

      expect(controller.hooks).to contain_exactly(webhook)
    end
  end

  # rubocop:disable Rails/SaveBang -- methods with ! are not defined

  describe '#create' do
    let(:create_service) { instance_double(WebHooks::CreateService) }

    before do
      allow(WebHooks::CreateService).to receive(:new).with(user).and_return(create_service)
      allow(controller).to receive(:hook_params).and_return(valid_params[:hook])
    end

    context 'when creation is successful' do
      it 'creates webhook and sets success message' do
        result = ServiceResponse.success
        allow(create_service).to receive(:execute).and_return(result)

        controller.create

        expect(create_service).to have_received(:execute).with(valid_params[:hook], relation_mock)
        expect(flash[:notice]).to eq('Webhook created')
        expect(controller).to have_received(:redirect_to).with(action: :index)
      end
    end

    context 'when creation fails' do
      it 'sets hooks and redirects with error message' do
        result = ServiceResponse.error(message: 'Invalid URL')
        allow(create_service).to receive(:execute).and_return(result)

        controller.create

        expect(controller.hooks).to contain_exactly(webhook)
        expect(flash[:alert]).to eq('Invalid URL')
        expect(controller).to have_received(:redirect_to).with(action: :index)
      end
    end
  end

  describe '#update' do
    before do
      allow(controller).to receive(:hook_params).and_return(valid_params[:hook])
    end

    context 'when update is successful' do
      it 'updates webhook and sets success message' do
        allow(webhook).to receive(:update).and_return(true)

        controller.update

        expect(flash[:notice]).to eq('Webhook updated')
        expect(controller).to have_received(:redirect_to).with(action: :edit)
      end
    end

    context 'when update fails with custom headers errors' do
      before do
        allow(webhook).to receive_messages(
          update: false,
          errors: errors_mock
        )
        allow(errors_mock).to receive(:[]).with(:custom_headers).and_return(instance_double(Array, present?: true,
          join: 'Invalid header'))
        allow(webhook).to receive(:custom_headers=)
      end

      it 'renders edit with custom headers error message' do
        allow(controller).to receive(:filter_valid_headers).and_return({})
        controller.update

        expect(flash.now[:alert]).to include('Custom headers validation failed: Invalid header')
        expect(controller).to have_received(:render).with('edit')
      end

      it 'filters valid headers before re-rendering' do
        expect(controller).to receive(:filter_valid_headers).with({})

        controller.update
      end
    end

    context 'when update fails with other errors' do
      it 'renders edit with general error message' do
        allow(webhook).to receive_messages(
          update: false,
          errors: errors_mock
        )
        allow(errors_mock).to receive(:[]).with(:custom_headers).and_return(instance_double(Array, present?: false))
        allow(errors_mock).to receive_messages(
          any?: true,
          full_messages: instance_double(Array, join: 'URL is invalid')
        )

        controller.update

        expect(flash.now[:alert]).to include('Please fix the following errors: URL is invalid')
        expect(controller).to have_received(:render).with('edit')
      end
    end
  end

  describe '#destroy' do
    let(:destroy_service) { instance_double(WebHooks::DestroyService) }

    before do
      allow(WebHooks::DestroyService).to receive(:new).with(user).and_return(destroy_service)
    end

    context 'when destruction is successful and synchronous' do
      it 'destroys webhook and sets success message' do
        allow(destroy_service).to receive(:execute).and_return({ status: :success, async: false })

        controller.destroy

        expect(flash[:notice]).to eq('Webhook deleted')
        expect(controller).to have_received(:redirect_to).with(action: :index, status: :found)
      end
    end

    context 'when destruction is successful and asynchronous' do
      it 'schedules webhook for deletion and sets message' do
        allow(destroy_service).to receive(:execute).and_return({ status: :success, async: true })

        controller.destroy

        expect(flash[:notice]).to eq('Webhook scheduled for deletion')
        expect(controller).to have_received(:redirect_to).with(action: :index, status: :found)
      end
    end

    context 'when destruction fails' do
      it 'sets error message' do
        allow(destroy_service).to receive(:execute).and_return({ status: :error, message: 'Cannot delete webhook' })

        controller.destroy

        expect(flash[:alert]).to eq('Cannot delete webhook')
        expect(controller).to have_received(:redirect_to).with(action: :index, status: :found)
      end
    end
  end

  # rubocop:enable Rails/SaveBang

  describe '#edit' do
    context 'when hook exists' do
      it 'does not redirect' do
        controller.edit

        expect(controller).not_to have_received(:redirect_to)
      end
    end

    context 'when hook does not exist' do
      it 'redirects to index' do
        allow(controller).to receive(:hook).and_return(nil)

        controller.edit

        expect(controller).to have_received(:redirect_to).with(action: :index)
      end
    end

    describe '#filter_valid_headers' do
      let(:headers) { { 'X-Valid' => 'value1', ' X Invalid' => 'value2' } }

      it 'returns empty hash for blank headers' do
        result = controller.send(:filter_valid_headers, nil)
        expect(result).to eq({})
      end

      it 'returns empty hash for empty headers' do
        result = controller.send(:filter_valid_headers, {})
        expect(result).to eq({})
      end

      it 'filters out invalid headers' do
        temp_hook_valid = instance_double(WebHook)
        temp_hook_invalid = instance_double(WebHook)

        allow(webhook.class).to receive(:new).with(custom_headers: { 'X-Valid' => 'value1' }).and_return(temp_hook_valid) # rubocop:disable Layout/LineLength,Lint/RedundantCopDisableDirective -- minor
        allow(webhook.class).to receive(:new).with(custom_headers: { ' X Invalid' => 'value2' }).and_return(temp_hook_invalid) # rubocop:disable Layout/LineLength,Lint/RedundantCopDisableDirective -- minor

        allow(temp_hook_valid).to receive(:validate)
        allow(temp_hook_invalid).to receive(:validate)

        valid_errors = instance_double(ActiveModel::Errors)
        invalid_errors = instance_double(ActiveModel::Errors)

        allow(temp_hook_valid).to receive(:errors).and_return(valid_errors)
        allow(temp_hook_invalid).to receive(:errors).and_return(invalid_errors)

        allow(valid_errors).to receive(:[]).with(:custom_headers).and_return(instance_double(Array, empty?: true))
        allow(invalid_errors).to receive(:[]).with(:custom_headers).and_return(instance_double(Array, empty?: false))

        result = controller.send(:filter_valid_headers, headers)

        expect(result).to eq({ 'X-Valid' => 'value1' })
      end

      it 'returns all headers when all are valid' do
        temp_hook1 = instance_double(WebHook)
        temp_hook2 = instance_double(WebHook)

        allow(webhook.class).to receive(:new).with(custom_headers: { 'X-Valid1' => 'value1' }).and_return(temp_hook1)
        allow(webhook.class).to receive(:new).with(custom_headers: { 'X-Valid2' => 'value2' }).and_return(temp_hook2)

        allow(temp_hook1).to receive(:validate)
        allow(temp_hook2).to receive(:validate)

        errors1 = instance_double(ActiveModel::Errors)
        errors2 = instance_double(ActiveModel::Errors)

        allow(temp_hook1).to receive(:errors).and_return(errors1)
        allow(temp_hook2).to receive(:errors).and_return(errors2)

        allow(errors1).to receive(:[]).with(:custom_headers).and_return(instance_double(Array, empty?: true))
        allow(errors2).to receive(:[]).with(:custom_headers).and_return(instance_double(Array, empty?: true))

        valid_headers = { 'X-Valid1' => 'value1', 'X-Valid2' => 'value2' }
        result = controller.send(:filter_valid_headers, valid_headers)

        expect(result).to eq(valid_headers)
      end
    end
  end
end

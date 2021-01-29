# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::CanMutateSpammable do
  let(:mutation_class) do
    Class.new(Mutations::BaseMutation) do
      include Mutations::CanMutateSpammable
    end
  end

  let(:request) { double(:request) }
  let(:query) { double(:query, schema: GitlabSchema) }
  let(:context) { GraphQL::Query::Context.new(query: query, object: nil, values: { request: request }) }

  subject(:mutation) { mutation_class.new(object: nil, context: context, field: nil) }

  describe '#additional_spam_params' do
    it 'returns additional spam-related params' do
      expect(subject.additional_spam_params).to eq({ api: true, request: request })
    end
  end

  describe '#with_spam_action_fields' do
    let(:spam_log) { double(:spam_log, id: 1) }
    let(:spammable) { double(:spammable, spam?: true, render_recaptcha?: true, spam_log: spam_log) }

    before do
      allow(Gitlab::CurrentSettings).to receive(:recaptcha_site_key) { 'abc123' }
    end

    it 'merges in spam action fields from spammable' do
      result = subject.with_spam_action_fields(spammable) do
        { other_field: true }
      end
      expect(result)
        .to eq({
                 spam: true,
                 needs_captcha_response: true,
                 spam_log_id: 1,
                 captcha_site_key: 'abc123',
                 other_field: true
               })
    end
  end
end

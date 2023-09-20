# frozen_string_literal: true

RSpec.describe QA::Support::SystemLogs::Sentry do
  using RSpec::Parameterized::TableSyntax

  let(:correlation_id) { 'foo123' }

  describe '#url' do
    subject { described_class.new(env, correlation_id).url }

    let(:staging_url) do
      "https://new-sentry.gitlab.net/organizations/gitlab/issues/?environment=gstg&project=3&query=correlation_id%3A%22#{correlation_id}%22"
    end

    let(:staging_ref_url) do
      "https://new-sentry.gitlab.net/organizations/gitlab/projects/staging-ref/?project=18&query=correlation_id%3A%22#{correlation_id}%22"
    end

    let(:pre_url) do
      "https://new-sentry.gitlab.net/organizations/gitlab/issues/?environment=pre&project=3&query=correlation_id%3A%22#{correlation_id}%22"
    end

    let(:production_url) do
      "https://new-sentry.gitlab.net/organizations/gitlab/issues/?environment=gprd&project=3&query=correlation_id%3A%22#{correlation_id}%22"
    end

    where(:env, :expected_url) do
      :staging     | ref(:staging_url)
      :staging_ref | ref(:staging_ref_url)
      :production  | ref(:production_url)
      :pre         | ref(:pre_url)
      :foo         | nil
      nil          | nil
    end

    with_them do
      it 'returns the expected URL' do
        expect(subject).to eq(expected_url)
      end
    end
  end
end

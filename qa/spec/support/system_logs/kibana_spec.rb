# frozen_string_literal: true

RSpec.describe QA::Support::SystemLogs::Kibana do
  using RSpec::Parameterized::TableSyntax

  let(:correlation_id) { 'foo123' }

  shared_examples 'returns the expected URL' do
    where(:env, :expected_url) do
      :staging    | ref(:staging_url)
      :production | ref(:production_url)
      :pre        | ref(:pre_url)
      :foo        | nil
      nil         | nil
    end

    with_them do
      before do
        allow(Time).to receive(:now).and_return(Time.new(2022, 11, 14, 0, 0, 0, '+00:00'))
      end

      specify do
        expect(subject).to eq(expected_url)
      end
    end
  end

  describe '#discover_url' do
    subject { described_class.new(env, correlation_id).discover_url }

    let(:staging_url) do
      "https://nonprod-log.gitlab.net/app/discover#/?_a=%28index:%27ed942d00-5186-11ea-ad8a-f3610a492295%27" \
      "%2Cquery%3A%28language%3Akuery%2Cquery%3A%27json.correlation_id%20%3A%20#{correlation_id}%27%29" \
      "%29&_g=%28time%3A%28from%3A%272022-11-13T00:00:00.000Z%27%2Cto%3A%272022-11-14T00:00:00.000Z%27%29%29"
    end

    let(:production_url) do
      "https://log.gprd.gitlab.net/app/discover#/?_a=%28index:%277092c4e2-4eb5-46f2-8305-a7da2edad090%27" \
      "%2Cquery%3A%28language%3Akuery%2Cquery%3A%27json.correlation_id%20%3A%20#{correlation_id}%27%29" \
      "%29&_g=%28time%3A%28from%3A%272022-11-13T00:00:00.000Z%27%2Cto%3A%272022-11-14T00:00:00.000Z%27%29%29"
    end

    let(:pre_url) do
      "https://nonprod-log.gitlab.net/app/discover#/?_a=%28index:%27pubsub-rails-inf-pre%27" \
      "%2Cquery%3A%28language%3Akuery%2Cquery%3A%27json.correlation_id%20%3A%20#{correlation_id}%27%29" \
      "%29&_g=%28time%3A%28from%3A%272022-11-13T00:00:00.000Z%27%2Cto%3A%272022-11-14T00:00:00.000Z%27%29%29"
    end

    it_behaves_like 'returns the expected URL'
  end

  describe '#dashboard_url' do
    subject { described_class.new(env, correlation_id).dashboard_url }

    let(:staging_url) do
      "https://nonprod-log.gitlab.net/app/dashboards#/view/b74dc030-6f56-11ed-9af2-6131f0ee4ce6?_g=%28time" \
      "%3A%28from:%272022-11-13T00:00:00.000Z%27%2Cto%3A%272022-11-14T00:00:00.000Z%27%29%29&_a=%28filters%3A%21" \
      "%28%28query%3A%28match_phrase%3A%28json.correlation_id%3A%27#{correlation_id}%27%29%29%29%29%29"
    end

    let(:production_url) do
      "https://log.gprd.gitlab.net/app/dashboards#/view/5e6d3440-7597-11ed-9f43-e3784d7fe3ca?_g=%28time" \
      "%3A%28from:%272022-11-13T00:00:00.000Z%27%2Cto%3A%272022-11-14T00:00:00.000Z%27%29%29&_a=%28filters%3A%21" \
      "%28%28query%3A%28match_phrase%3A%28json.correlation_id%3A%27#{correlation_id}%27%29%29%29%29%29"
    end

    let(:pre_url) do
      "https://nonprod-log.gitlab.net/app/dashboards#/view/15596340-7570-11ed-9af2-6131f0ee4ce6?_g=%28time" \
      "%3A%28from:%272022-11-13T00:00:00.000Z%27%2Cto%3A%272022-11-14T00:00:00.000Z%27%29%29&_a=%28filters%3A%21" \
      "%28%28query%3A%28match_phrase%3A%28json.correlation_id%3A%27#{correlation_id}%27%29%29%29%29%29"
    end

    it_behaves_like 'returns the expected URL'
  end
end

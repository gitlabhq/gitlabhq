# frozen_string_literal: true

RSpec.describe 'Interceptor' do
  let(:browser) { Capybara.current_session }
  # need a real host for the js runtime
  let(:url) { "file://#{File.join(Runtime::Path.fixtures_path, 'script_extensions', 'test.html')}" }

  before(:context) do
    skip 'Only can test for chrome' unless QA::Runtime::Env.can_intercept?

    QA::Runtime::Browser.configure!
    QA::Runtime::Browser::Session.enable_interception
  end

  after(:context) do
    QA::Runtime::Browser::Session.disable_interception
  end

  before do
    browser.visit url

    clear_cache
  end

  after do
    browser.visit 'about:blank'
  end

  context 'with Interceptor' do
    context 'with caching' do
      it 'checks the cache' do
        expect(check_cache).to be(true)
      end

      it 'returns false if the cache cannot be accessed' do
        browser.visit 'about:blank'

        expect(check_cache).to be(false)
      end

      it 'gets and sets the cache data' do
        commit_to_cache({ foo: 'bar' })

        expect(get_cache['data']).to eql({ 'foo' => 'bar' })
      end
    end

    context 'when intercepting' do
      let(:resource_url) { 'chrome://chrome-urls' }

      it 'intercepts fetch errors' do
        trigger_fetch(resource_url, 'GET')

        errors = get_cache['errors']

        expect(errors.size).to be(1)
        expect(errors[0]['status']).to be(-1)
        expect(errors[0]['method']).to eql('GET')
        expect(errors[0]['url']).to eql(resource_url)
      end

      it 'intercepts xhr' do
        trigger_xhr(resource_url, 'POST')

        errors = get_cache['errors']

        expect(errors.size).to be(1)
        expect(errors[0]['status']).to be(-1)
        expect(errors[0]['method']).to eql('POST')
        expect(errors[0]['url']).to eql(resource_url)
      end
    end
  end

  def clear_cache
    browser.execute_script <<~JS
      Interceptor.saveCache({})
    JS
  end

  def check_cache
    browser.execute_script <<~JS
      return Interceptor.checkCache()
    JS
  end

  def trigger_fetch(url, method)
    browser.execute_script <<~JS
      (() => {
        fetch('#{url}', { method: '#{method}' })
      })()
    JS
  end

  def trigger_xhr(url, method)
    browser.execute_script <<~JS
      (() => {
        let xhr = new XMLHttpRequest();
        xhr.open('#{method}', '#{url}')
        xhr.send()
      })()
    JS
  end

  def commit_to_cache(payload)
    browser.execute_script <<~JS
      Interceptor.commitToCache((cache) => {
        cache.data = JSON.parse('#{payload.to_json}');
        return cache
      })
    JS
  end

  def get_cache
    browser.execute_script <<~JS
      return Interceptor.getCache()
    JS
  end
end

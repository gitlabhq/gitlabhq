require 'spec_helper'

describe OpensearchController do
  describe '#index' do
    it 'accessible without authentication' do
      get :index
      expect(response).to have_http_status(200)
    end

    it 'renders the opensearch xml' do
      get :index
      expect(response).to render_template('shared/opensearch.xml')
    end

    describe 'if the host name is very long' do
      render_views

      before do
        @mock_host = Array.new(1050) { 'a' }.join
        allow(Gitlab.config.gitlab).to receive(:host) { @mock_host }
        get :index
      end

      it 'displays a description with a truncated host' do
        expect(response.body).to have_content("Search #{@mock_host.truncate(1010)} GitLab")
      end

      it 'displays a long name with a truncated host' do
        expect(response.body).to have_content("#{@mock_host.truncate(34)} GitLab search")
      end
    end
  end
end

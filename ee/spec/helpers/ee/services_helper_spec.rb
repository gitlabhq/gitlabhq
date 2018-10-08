# frozen_string_literal: true

require 'spec_helper'

describe EE::ServicesHelper do
  let(:controller_class) do
    Class.new(ActionController::Base) do
      include EE::ServicesHelper

      def slack_auth_project_settings_slack_url(project)
        "http://some-path/project/1"
      end
    end
  end

  set(:project) { create(:project) }

  subject { controller_class.new }

  describe '#add_to_slack_link' do
    it 'encodes a masked CSRF token' do
      expect(subject).to receive(:form_authenticity_token).and_return('a token')
      slack_link = subject.add_to_slack_link(project, '123456')

      expect(slack_link).to start_with('https://slack.com/oauth/authorize')
      expect(slack_link).to include('redirect_uri=http://some-path/project/1&state=a+token')
    end
  end
end

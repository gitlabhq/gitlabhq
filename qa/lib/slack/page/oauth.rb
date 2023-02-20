# frozen_string_literal: true

module Slack
  module Page
    class Oauth < Chemlab::Page
      button :submit_oauth, data_qa: 'oauth_submit_button'
    end
  end
end

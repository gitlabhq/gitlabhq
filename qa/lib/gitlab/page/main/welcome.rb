# frozen_string_literal: true

module Gitlab
  module Page
    module Main
      class Welcome < Chemlab::Page
        path '/users/sign_up/welcome'

        button :get_started_button
      end
    end
  end
end

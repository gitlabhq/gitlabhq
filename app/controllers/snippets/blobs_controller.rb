# frozen_string_literal: true

class Snippets::BlobsController < Snippets::ApplicationController
  include Snippets::BlobsActions

  urgency :low

  skip_before_action :authenticate_user!, only: [:raw]
end

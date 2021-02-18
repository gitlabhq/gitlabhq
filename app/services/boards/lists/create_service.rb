# frozen_string_literal: true

module Boards
  module Lists
    class CreateService < Boards::Lists::BaseCreateService
    end
  end
end

Boards::Lists::CreateService.prepend_if_ee('EE::Boards::Lists::CreateService')

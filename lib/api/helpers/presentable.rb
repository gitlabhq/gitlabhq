# frozen_string_literal: true

module API
  module Helpers
    ##
    # This module makes it possible to use `app/presenters` with
    # Grape Entities. It instantiates the model presenter and passes
    # options defined in the API endpoint to the presenter itself.
    #
    #   present object, with: Entities::Something,
    #                   current_user: current_user,
    #                   another_option: 'my options'
    #
    # Example above will make `current_user` and `another_option`
    # values available in the subclass of `Gitlab::View::Presenter`
    # thorough a separate method in the presenter.
    #
    # The model class needs to have `::Presentable` module mixed in
    # if you want to use `API::Helpers::Presentable`.
    #
    module Presentable
      extend ActiveSupport::Concern

      def initialize(object, options = {})
        options = options.opts_hash if options.is_a?(Grape::Entity::Options)
        super(object.present(**options), options)
      end
    end
  end
end

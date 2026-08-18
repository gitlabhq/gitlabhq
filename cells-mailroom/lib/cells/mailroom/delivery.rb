# frozen_string_literal: true

require_relative 'config'
require_relative 'topology_stub'
require_relative 'processor'
require_relative 'cell_router'
require_relative 'forwarder'

module Cells
  module Mailroom
    # mail_room delivery method. mail_room instantiates Options.new(mailbox) and
    # calls #deliver(raw) for each fetched message.
    class Delivery
      Options = Struct.new(:mailbox_type, :wildcard_address, :logger, :rails_root) do
        def initialize(mailbox)
          opts = mailbox.delivery_options
          super(
            opts[:mailbox_type] || 'incoming_email',
            opts[:wildcard_address],
            mailbox.logger,
            opts[:rails_root] || Dir.pwd
          )
        end
      end

      def initialize(delivery_options)
        @options = delivery_options
      end

      def deliver(raw)
        processor.process(raw)
        true
      end

      private

      def processor
        @processor ||= begin
          config = Config.new(rails_root: @options.rails_root)
          cell_router = CellRouter.new(
            stub: TopologyStub.classify_stub(config),
            logger: @options.logger
          )
          forwarder = Forwarder.new(
            mailbox_type: @options.mailbox_type,
            signing_key_path: config.signing_key_path(@options.mailbox_type),
            scheme: config.cell_scheme,
            logger: @options.logger
          )

          Processor.new(
            wildcard_address: @options.wildcard_address,
            gitlab_host: config.gitlab_host,
            route_unidentified_to_default_cell: config.route_unidentified_to_default_cell?,
            cell_router: cell_router,
            forwarder: forwarder,
            logger: @options.logger
          )
        end
      end
    end
  end
end

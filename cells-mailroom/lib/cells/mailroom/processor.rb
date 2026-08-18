# frozen_string_literal: true

require 'mail'
require 'labkit/fields'
require 'gitlab/email_handler'
require_relative 'cell_router'
require_relative 'forwarder'
require_relative 'recipient_targets'

module Cells
  module Mailroom
    # Processes a single incoming email with one uniform pipeline:
    #
    #   1. Scan the recipient headers for mail key candidates, in the precedence
    #      order owned by Gitlab::EmailHandler::MailKey.
    #   2. For each candidate, derive its routing Targets and resolve the first
    #      that maps to a cell via the Topology Service.
    #   3. Forward the raw email directly to that cell.
    #
    # The header scanning and precedence live in the gem, so this service and the
    # GitLab application can never disagree on which key an email resolves to.
    # This stops at the first candidate that resolves to a cell, the same way the
    # application stops at the first parseable key; a candidate that parses but
    # does not resolve (for example a well-formed address that is not a claimed
    # custom email) simply falls through to the next.
    class Processor
      def initialize(wildcard_address:, gitlab_host:, route_unidentified_to_default_cell:, cell_router:, forwarder:,
        logger:)
        @wildcard_address = wildcard_address
        @gitlab_host = gitlab_host
        @route_unidentified_to_default_cell = route_unidentified_to_default_cell
        @cell_router = cell_router
        @forwarder = forwarder
        @logger = logger
      end

      def process(raw)
        mail = Mail::Message.new(raw)

        target, cell_address = resolve_cell(mail)

        if cell_address
          @logger.info(
            Labkit::Fields::LOG_MESSAGE => "Email identified (#{describe(target)})",
            Labkit::Fields::TCP_ADDRESS => cell_address
          )
          @forwarder.forward(raw, cell_address)
        else
          forward_to_default_cell(raw)
        end
      rescue StandardError => e
        @logger.warn(
          Labkit::Fields::LOG_MESSAGE => 'Failed to process email',
          Labkit::Fields::ERROR_MESSAGE => e.message
        )
        false
      end

      private

      # Routes an email that could not be identified to the default (first)
      # cell, unless that fallback is disabled, in which case the email is
      # dropped.
      def forward_to_default_cell(raw)
        unless @route_unidentified_to_default_cell
          @logger.info(Labkit::Fields::LOG_MESSAGE => 'Email could not be routed to a cell')
          return false
        end

        cell_address = @cell_router.default_cell_address
        unless cell_address
          @logger.warn(Labkit::Fields::LOG_MESSAGE => 'Email could not be routed and no default cell is available')
          return false
        end

        @logger.info(
          Labkit::Fields::LOG_MESSAGE => 'Email routed to the default cell',
          Labkit::Fields::TCP_ADDRESS => cell_address
        )
        @forwarder.forward(raw, cell_address)
      end

      # Resolves the first Target that the Topology Service maps to a cell,
      # scanning candidates in the gem's precedence order and stopping at the
      # first hit. Returns [target, cell_address] or [nil, nil].
      def resolve_cell(mail)
        result = ::Gitlab::EmailHandler::MailKey.each_candidate(
          mail,
          wildcard_address: @wildcard_address,
          gitlab_host: @gitlab_host
        ) do |candidate|
          resolve_candidate(candidate)
        end

        result || [nil, nil]
      end

      # Returns [target, cell_address] for the first of the candidate's Targets
      # that resolves to a cell, or nil so the scan continues.
      def resolve_candidate(candidate)
        RecipientTargets.for_candidate(candidate).each do |target|
          cell_address = @cell_router.address_for(target)
          return [target, cell_address] if cell_address
        end

        nil
      end

      def describe(target)
        "#{target.kind}=#{target.value}"
      end
    end
  end
end

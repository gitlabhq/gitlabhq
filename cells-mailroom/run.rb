# frozen_string_literal: true

# Standalone, cells-routable mail_room runner.
#
# Usage:
#   cd cells-mailroom
#   bundle install
#   MAIL_ROOM_GITLAB_CONFIG_FILE=/path/to/gitlab.yml bundle exec ruby run.rb
#
# Reads the mailbox and Topology Service configuration from the GitLab
# application's config/gitlab.yml (located via MAIL_ROOM_GITLAB_CONFIG_FILE,
# the same variable the GitLab application's mail_room uses), then watches each
# enabled mailbox and forwards every incoming email to the owning cell's
# internal mail_room endpoint. No Rails environment is loaded.

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))

require 'mail_room'
require 'cells/mailroom/config'
require 'cells/mailroom/delivery'

rails_root = File.expand_path('..', __dir__)
config = Cells::Mailroom::Config.new(rails_root: rails_root)

# Build a mail_room mailbox per enabled GitLab mailbox, wiring in our delivery
# class. We set :delivery_klass (rather than :delivery_method) because mail_room
# resolves delivery methods to its own built-in classes; :delivery_klass lets us
# inject Cells::Mailroom::Delivery. rails_root is passed through so the delivery
# can locate config/gitlab.yml the same way.
#
# Arbitration attributes are merged in so that several service instances can
# poll the same mailbox safely: mail_room coordinates via a Redis lock on the
# same namespace the existing GitLab mailroom uses.
arbitration = config.arbitration_attributes

mailboxes = config.mailboxes.map do |attributes|
  attributes[:delivery_klass] = Cells::Mailroom::Delivery
  attributes[:delivery_options][:rails_root] = rails_root
  attributes[:logger] = { log_path: $stdout }
  attributes.merge!(arbitration)

  MailRoom::Mailbox.new(attributes)
end

MailRoom::Coordinator.new(mailboxes).run

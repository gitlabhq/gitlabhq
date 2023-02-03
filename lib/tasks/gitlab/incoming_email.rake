# frozen_string_literal: true

namespace :gitlab do
  namespace :incoming_email do
    namespace :secret do
      desc 'GitLab | Incoming Email | Secret | Write Incoming Email secrets'
      task write: [:environment] do
        content = $stdin.tty? ? $stdin.gets : $stdin.read
        Gitlab::EncryptedIncomingEmailCommand.write(content)
      end

      desc 'GitLab | Incoming Email | Secret | Edit Incoming Email secrets'
      task edit: [:environment] do
        Gitlab::EncryptedIncomingEmailCommand.edit
      end

      desc 'GitLab | Incoming Email | Secret | Show Incoming Email secrets'
      task show: [:environment] do
        Gitlab::EncryptedIncomingEmailCommand.show
      end
    end
  end
end

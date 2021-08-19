# frozen_string_literal: true

namespace :gitlab do
  namespace :smtp do
    namespace :secret do
      desc 'GitLab | SMTP | Secret | Write SMTP secrets'
      task write: [:environment] do
        content = $stdin.tty? ? $stdin.gets : $stdin.read
        Gitlab::EncryptedSmtpCommand.write(content)
      end

      desc 'GitLab | SMTP | Secret | Edit SMTP secrets'
      task edit: [:environment] do
        Gitlab::EncryptedSmtpCommand.edit
      end

      desc 'GitLab | SMTP | Secret | Show SMTP secrets'
      task show: [:environment] do
        Gitlab::EncryptedSmtpCommand.show
      end
    end
  end
end

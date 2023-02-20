# frozen_string_literal: true

namespace :gitlab do
  namespace :service_desk_email do
    namespace :secret do
      desc 'GitLab | Service Desk Email | Secret | Write Service Desk Email secrets'
      task write: [:environment] do
        content = $stdin.tty? ? $stdin.gets : $stdin.read
        Gitlab::EncryptedServiceDeskEmailCommand.write(content)
      end

      desc 'GitLab | Service Desk Email | Secret | Edit Service Desk Email secrets'
      task edit: [:environment] do
        Gitlab::EncryptedServiceDeskEmailCommand.edit
      end

      desc 'GitLab | Service Desk Email | Secret | Show Service Desk Email secrets'
      task show: [:environment] do
        Gitlab::EncryptedServiceDeskEmailCommand.show
      end
    end
  end
end

# frozen_string_literal: true

module SystemCheck
  module App
    class SystemdUnitFilesOrInitScriptExistCheck < SystemCheck::BaseCheck
      set_name 'Systemd unit files or init script exist?'
      set_skip_reason 'skipped (omnibus-gitlab has neither init script nor systemd units)'

      def skip?
        omnibus_gitlab?
      end

      def check?
        unit_paths = [
          '/usr/local/lib/systemd/system/gitlab-gitaly.service',
          '/usr/local/lib/systemd/system/gitlab-mailroom.service',
          '/usr/local/lib/systemd/system/gitlab-puma.service',
          '/usr/local/lib/systemd/system/gitlab-sidekiq.service',
          '/usr/local/lib/systemd/system/gitlab.slice',
          '/usr/local/lib/systemd/system/gitlab.target',
          '/usr/local/lib/systemd/system/gitlab-workhorse.service'
        ]
        script_path = '/etc/init.d/gitlab'

        unit_paths.all? { |s| File.exist?(s) } || File.exist?(script_path)
      end

      def show_error
        try_fixing_it(
          'Install the Service'
        )
        for_more_information(
          see_installation_guide_section('Install the Service')
        )
        fix_and_rerun
      end
    end
  end
end

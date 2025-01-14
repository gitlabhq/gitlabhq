require './spec/support/sidekiq_middleware'

Sidekiq::Testing.inline! do
  Gitlab::Seeder.quiet do
    flag = 'SEED_NESTED_GROUPS'

    if ENV[flag]
      project_urls = [
        'https://android.googlesource.com/platform/hardware/broadcom/libbt.git',
        'https://android.googlesource.com/platform/hardware/broadcom/wlan.git',
        'https://android.googlesource.com/platform/hardware/bsp/bootloader/intel/edison-u-boot.git',
        'https://android.googlesource.com/platform/hardware/bsp/broadcom.git',
        'https://android.googlesource.com/platform/hardware/bsp/freescale.git',
        'https://android.googlesource.com/platform/hardware/bsp/imagination.git',
        'https://android.googlesource.com/platform/hardware/bsp/intel.git',
        'https://android.googlesource.com/platform/hardware/bsp/kernel/common/v4.1.git',
        'https://android.googlesource.com/platform/hardware/bsp/kernel/common/v4.4.git'
      ]

      user = User.admins.first

      project_urls.each_with_index do |url, i|
        full_path = url.sub('https://android.googlesource.com/', '')
        full_path = full_path.sub(/\.git\z/, '')
        full_path, _, project_path = full_path.rpartition('/')
        group = Sidekiq::Worker.skipping_transaction_check do
          Group.find_by_full_path(full_path) || Groups::NestedCreateService.new(
            user, group_path: full_path, organization_id: Organizations::Organization.default_organization.id
          ).execute
        end

        params = {
          import_url: url,
          namespace_id: group.id,
          path: project_path,
          name: project_path,
          description: FFaker::Lorem.sentence,
          visibility_level: Gitlab::VisibilityLevel.values.sample
        }

        project = Projects::CreateService.new(user, params).execute
        project.send(:_run_after_commit_queue)

        if project.valid?
          print '.'
        else
          print 'F'
        end
      end
    else
      puts "Skipped. Use the `#{flag}` environment variable to enable."
    end
  end
end

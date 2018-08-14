namespace :gitlab do
  namespace :exclusive_lease do
    desc 'GitLab | Clear existing exclusive leases for specified scope (default: *)'
    task :clear, [:scope] => [:environment] do |_, args|
      args[:scope].nil? ? Gitlab::ExclusiveLease.reset_all! : Gitlab::ExclusiveLease.reset_all!(args[:scope])
      puts 'All exclusive lease entries were removed.'
    end
  end
end

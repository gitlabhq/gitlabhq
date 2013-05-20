desc "GITLAB | Migrate duplicate deploy keys"
task migrate_duplicate_deploy_keys: :environment do
  puts "In old version (with gitolite), duplicate deploy key was allowed."
  puts "Since 5.2 it allows by another way: share one key between multiple projects."
  puts "* * *"
  puts "The duplicate keys will be removed and the relationship will be created."
  puts "IMPORTANT: Please backup the database and file /home/git/.ssh/authorized_keys."
  ask_to_continue

  DeployKey.group('`key`').having('COUNT(*) > 1').each do |key1|
    DeployKey.where("id != ?", key1.id).where(key: key1.key).each do |key2|
      key2.projects.each do |project|
        project.deploy_keys << key1
        puts "Key #{key2.id} for project #{project.id} was replaced to #{key1.id}."
      end
      key2.destroy
    end
  end
end


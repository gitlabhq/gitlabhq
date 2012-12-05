require "net/ldap"

# if a project belongs to a ldap group
#   add users from ldap group to the project
#   remove all other users from the project
# else
#   add all users as usual
desc "Add or removes users from projects (admin users are added as masters) respecting LDAP and project groups"
task :add_or_remove_users_from_project_teams_using_ldap_groups => :environment  do |t, args|
  gl = Gitlab.config
  return unless gl.ldap_enabled?

  start = Time.now
  puts "=== Add or remove users from teams using ldap groups ==="
  puts "started @ #{start}"

  ldap = Net::LDAP.new(
      host: gl.ldap['host'],
      port: gl.ldap['port'],
      auth: {
          method: :simple,
          username: gl.ldap['bind_dn'],
          password: gl.ldap['password']
      }
  )

  users = User.where(:admin => false).select("id, email, username")
  admins = User.where(:admin => true).select("id, email, username")

  all_user_ids = users.map(&:id)
  all_admins_ids = admins.map(&:id)
  ldap_groups = {}

  Project.find_each do |project|
    user_ids = all_user_ids
    admin_ids = all_admins_ids
    rejected_ids = []

    project.group.try(:name).tap do |group_name|
      if ldap_groups[group_name]
        ldap_groups[group_name].tap do |ids|
          user_ids = ids[0]
          admin_ids = ids[1]
          rejected_ids = ids[2]
        end
      else
        get_ldap_group_dn(gl, ldap, group_name) do |group_dn|
          ldap_users = get_ldap_users_for_group_dn(gl, ldap, group_dn)

          user_ids = users.select {|user| ldap_users.include?(user)}.map(&:id)
          admin_ids = admins.select {|user| ldap_users.include?(user)}.map(&:id)
          rejected_ids = (all_user_ids - user_ids) + (all_admins_ids - admin_ids)

          ldap_groups[group_name] = [user_ids, admin_ids, rejected_ids]
        end
      end
    end

    puts "=== add_or_remove_users_from_project_teams_using_ldap_groups ==="
    puts "Importing #{user_ids.size} users into #{project.code}"
    UsersProject.bulk_import(project, user_ids, UsersProject::DEVELOPER)
    puts "Importing #{admin_ids.size} admins into #{project.code}"
    UsersProject.bulk_import(project, admin_ids, UsersProject::MASTER)
    puts "Removing #{rejected_ids.size} users from #{project.code}"
    UsersProject.bulk_delete(project, rejected_ids)
  end
  finish = Time.now
  puts "finished @ #{finish}"
  puts "took #{(finish - start).to_i} seconds"
  puts "=== /Add or remove users from teams using ldap groups ==="
end

class LdapUser < Struct.new(:username, :email)
  include Comparable

  def <=>(other)
    username <=> other.username || email <=> other.email
  end
end

def get_ldap_users_for_group_dn(gl, ldap, group_dn)
  return [] unless ldap && group_dn

  group_filter = Net::LDAP::Filter.eq("memberof", group_dn)
  record_type_filter = Net::LDAP::Filter.eq("objectClass", "user")
  filter = Net::LDAP::Filter.join(group_filter, record_type_filter)

  ldap.search(:base => gl.ldap['base'], :filter => filter, :attributes => [gl.ldap['uid'], 'mail'], :return_result => true).map { |user|
    email = user.mail.first rescue ""
    LdapUser.new(user.send(gl.ldap['uid']).first, email)
  }
end

def get_ldap_group_dn(gl, ldap, group_name)
  return nil unless ldap && group_name

  name_filter = Net::LDAP::Filter.eq("cn", group_name)
  record_type_filter = Net::LDAP::Filter.eq("objectClass", "group")
  filter = Net::LDAP::Filter.join(name_filter, record_type_filter)

  group_dns = ldap.search(:base => gl.ldap['base'], :filter => filter, :attributes => [], :return_result => true).map(&:dn)

  return unless group_dns.size == 1
  yield group_dns.first if block_given?
  group_dns.first
end

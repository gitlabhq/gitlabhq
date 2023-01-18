# frozen_string_literal: true

class Gitlab::Seeder::Emails
  attr_reader :user, :group_namespace_ids, :project_namespace_ids

  def initialize(user, group_namespace_ids, project_namespace_ids)
    @user = user
    @group_namespace_ids = group_namespace_ids.sample(3)
    @project_namespace_ids = project_namespace_ids.sample(3)
  end

  def seed!
    company_email = "#{user.username}-work@example.com"
    personal_email = "#{user.username}-home@example.com"
    oss_email = "#{user.username}-oss@example.com"
    unverified_email = "#{user.username}-unverified@example.com"

    Email.create!(
      user_id: user.id,
      email: unverified_email
    )

    [company_email, personal_email, oss_email].each_with_index do |email, index|
      email_id = Email.create!(
        user_id: user.id,
        email: email,
        confirmed_at: DateTime.current
      ).id
      Users::NamespaceCommitEmail.create!(
        user_id: user.id,
        namespace_id: group_namespace_ids[index],
        email_id: email_id
      )
      Users::NamespaceCommitEmail.create!(
        user_id: user.id,
        namespace_id: project_namespace_ids[index],
        email_id: email_id
      )
      print '.'
    end
  end
end

Gitlab::Seeder.quiet do
  puts "\nGenerating email data"

  group_namespace_ids = Group.not_mass_generated.where('parent_id IS NULL').pluck(:id)
  project_namespace_ids = Project.all.pluck(:project_namespace_id)

  User.first(3).each do |user|
    Gitlab::Seeder::Emails.new(user, group_namespace_ids, project_namespace_ids).seed!
  rescue => e
    warn "\nError seeding e-mails: #{e}"
  end
end

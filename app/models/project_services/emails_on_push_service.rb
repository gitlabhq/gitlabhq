# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#  subdomain   :string(255)
#  room        :string(255)
#

class EmailsOnPushService < Service
  attr_accessible :recipients

  validates :recipients, presence: true, if: :activated?

  def title
    'Emails on push'
  end

  def description
    'Send emails to recipients on push'
  end

  def to_param
    'emails_on_push'
  end

  def execute(push_data)
    before_sha = push_data[:before]
    after_sha = push_data[:after]
    branch = push_data[:ref]
    author_id = push_data[:user_id]

    if before_sha =~ /^000000/ || after_sha =~ /^000000/
      # skip if new branch was pushed or branch was removed
      return true
    end

    compare = Gitlab::Git::Compare.new(project.repository.raw_repository, before_sha, after_sha)

    # Do not send emails if git compare failed
    return false unless compare && compare.commits.present?

    recipients.split(" ").each do |recipient|
      Notify.delay.repository_push_email(project_id, recipient, author_id, branch, compare)
    end
  end

  def fields
    [
      { type: 'textarea', name: 'recipients', placeholder: 'Emails separated by whitespace' },
    ]
  end
end


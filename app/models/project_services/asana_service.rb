# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#
require 'asana'

class AsanaService < Service
  prop_accessor :api_key, :restrict_to_branch
  validates :api_key, presence: true, if: :activated?

  def title
    'Asana'
  end

  def description
    'Asana - Teamwork without email'
  end

  def help
    'This service adds commit messages as comments to Asana tasks.
Once enabled, commit messages are checked for Asana task URLs
(for example, `https://app.asana.com/0/123456/987654`) or task IDs
starting with # (for example, `#987654`). Every task ID found will
get the commit comment added to it.

You can also close a task with a message containing: `fix #123456`.

You can find your Api Keys here:
http://developer.asana.com/documentation/#api_keys'
  end

  def to_param
    'asana'
  end

  def fields
    [
      {
        type: 'text',
        name: 'api_key',
        placeholder: 'User API token. User must have access to task,
all comments will be attributed to this user.'
      },
      {
        type: 'text',
        name: 'restrict_to_branch',
        placeholder: 'Comma-separated list of branches which will be
automatically inspected. Leave blank to include all branches.'
      }
    ]
  end

  def supported_events
    %w(push)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    Asana.configure do |client|
      client.api_key = api_key
    end

    user = data[:user_name]
    branch = Gitlab::Git.ref_name(data[:ref])

    branch_restriction = restrict_to_branch.to_s

    # check the branch restriction is poplulated and branch is not included
    if branch_restriction.length > 0 && branch_restriction.index(branch).nil?
      return
    end

    project_name = project.name_with_namespace
    push_msg = user + ' pushed to branch ' + branch + ' of ' + project_name

    data[:commits].each do |commit|
      check_commit(' ( ' + commit[:url] + ' ): ' + commit[:message], push_msg)
    end
  end

  def check_commit(message, push_msg)
    task_list = []
    close_list = []

    message.split("\n").each do |line|
      # look for a task ID or a full Asana url
      task_list.concat(line.scan(/#(\d+)/))
      task_list.concat(line.scan(/https:\/\/app\.asana\.com\/\d+\/\d+\/(\d+)/))
      # look for a word starting with 'fix' followed by a task ID
      close_list.concat(line.scan(/(fix\w*)\W*#(\d+)/i))
    end

    # post commit to every taskid found
    task_list.each do |taskid|
      task = Asana::Task.find(taskid[0])

      if task
        task.create_story(text: push_msg + ' ' + message)
      end
    end

    # close all tasks that had 'fix(ed/es/ing) #:id' in them
    close_list.each do |taskid|
      task = Asana::Task.find(taskid.last)

      if task
        task.modify(completed: true)
      end
    end
  end
end

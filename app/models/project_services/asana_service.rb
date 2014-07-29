# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#  subdomain   :string(255)
#  room        :string(255)
#  recipients  :text
#  api_key     :string(255)
#

require 'asana'

class AsanaService < Service
  validates :api_key, presence: true, if: :activated?

  def title
    'Asana'
  end

  def description
    'Asana - Teamwork without email'
  end

  def help
    'This service adds commit messages as comments to Asana tasks. Once enabled, commit messages
are checked for Asana task URLs (for example, `https://app.asana.com/0/123456/987654`) or task IDs
starting with # (for example, `#987654`). Every task ID found will get the commit comment added to it.

You can also close a task with a message containing: `fix #123456`.

You can find your Api Keys here: http://developer.asana.com/documentation/#api_keys'
  end

  def to_param
    'asana'
  end

  def fields
    [
      { type: 'text', name: 'api_key', placeholder: 'User API token. User must have access to task, all comments will be attributed to this user.' }
    ]
  end

  def execute(push)
    Asana.configure do |client|
      client.api_key = api_key
    end

    user = push[:user_name]
    branch = push[:ref].gsub('refs/heads/', '')
    project_name = project.name_with_namespace
    push_msg = user + ' pushed to branch ' + branch + ' of ' + project_name

    push[:commits].each do |commit|
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

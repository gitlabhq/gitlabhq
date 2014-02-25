# == Schema Information
#
# Table name: events
#
#  id          :integer          not null, primary key
#  target_type :string(255)
#  target_id   :integer
#  title       :string(255)
#  data        :text
#  project_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  action      :integer
#  author_id   :integer
#

class Event < ActiveRecord::Base
  attr_accessible :project, :action, :data, :author_id, :project_id,
                  :target_id, :target_type

  default_scope { where.not(author_id: nil) }

  CREATED   = 1
  UPDATED   = 2
  CLOSED    = 3
  REOPENED  = 4
  PUSHED    = 5
  COMMENTED = 6
  MERGED    = 7
  JOINED    = 8 # User joined project
  LEFT      = 9 # User left project

  delegate :name, :email, to: :author, prefix: true, allow_nil: true
  delegate :title, to: :issue, prefix: true, allow_nil: true
  delegate :title, to: :merge_request, prefix: true, allow_nil: true

  belongs_to :author, class_name: "User"
  belongs_to :project
  belongs_to :target, polymorphic: true

  # For Hash only
  serialize :data

  # Scopes
  scope :recent, -> { order("created_at DESC") }
  scope :code_push, -> { where(action: PUSHED) }
  scope :in_projects, ->(project_ids) { where(project_id: project_ids).recent }

  class << self
    def determine_action(record)
      if [Issue, MergeRequest].include? record.class
        Event::CREATED
      elsif record.kind_of? Note
        Event::COMMENTED
      end
    end

    def create_ref_event(project, user, ref, action = 'add', prefix = 'refs/heads')
      commit = project.repository.commit(ref.target)

      if action.to_s == 'add'
        before = '00000000'
        after = commit.id
      else
        before = commit.id
        after = '00000000'
      end

      Event.create(
        project: project,
        action: Event::PUSHED,
        data: {
          ref: "#{prefix}/#{ref.name}",
          before: before,
          after: after
        },
        author_id: user.id
      )
    end
  end

  def proper?
    if push?
      true
    elsif membership_changed?
      true
    else
      (issue? || merge_request? || note? || milestone?) && target
    end
  end

  def project_name
    if project
      project.name_with_namespace
    else
      "(deleted project)"
    end
  end

  def target_title
    if target && target.respond_to?(:title)
      target.title
    end
  end

  def push?
    action == self.class::PUSHED && valid_push?
  end

  def merged?
    action == self.class::MERGED
  end

  def closed?
    action == self.class::CLOSED
  end

  def reopened?
    action == self.class::REOPENED
  end

  def milestone?
    target_type == "Milestone"
  end

  def note?
    target_type == "Note"
  end

  def issue?
    target_type == "Issue"
  end

  def merge_request?
    target_type == "MergeRequest"
  end

  def joined?
    action == JOINED
  end

  def left?
    action == LEFT
  end

  def membership_changed?
    joined? || left?
  end

  def issue
    target if target_type == "Issue"
  end

  def merge_request
    target if target_type == "MergeRequest"
  end

  def action_name
    if closed?
      "closed"
    elsif merged?
      "accepted"
    elsif joined?
      'joined'
    elsif left?
      'left'
    else
      "opened"
    end
  end

  def valid_push?
    data[:ref] && ref_name.present?
  rescue => ex
    false
  end

  def tag?
    data[:ref]["refs/tags"]
  end

  def branch?
    data[:ref]["refs/heads"]
  end

  def new_branch?
    commit_from =~ /^00000/
  end

  def new_ref?
    commit_from =~ /^00000/
  end

  def rm_ref?
    commit_to =~ /^00000/
  end

  def md_ref?
    !(rm_ref? || new_ref?)
  end

  def commit_from
    data[:before]
  end

  def commit_to
    data[:after]
  end

  def ref_name
    if tag?
      tag_name
    else
      branch_name
    end
  end

  def branch_name
    @branch_name ||= data[:ref].gsub("refs/heads/", "")
  end

  def tag_name
    @tag_name ||= data[:ref].gsub("refs/tags/", "")
  end

  # Max 20 commits from push DESC
  def commits
    @commits ||= (data[:commits] || []).reverse
  end

  def commits_count
    data[:total_commits_count] || commits.count || 0
  end

  def ref_type
    tag? ? "tag" : "branch"
  end

  def push_action_name
    if new_ref?
      "pushed new"
    elsif rm_ref?
      "deleted"
    else
      "pushed to"
    end
  end

  def push_with_commits?
    md_ref? && commits.any? && commit_from && commit_to
  end

  def last_push_to_non_root?
    branch? && project.default_branch != branch_name
  end

  def note_commit_id
    target.commit_id
  end

  def target_iid
    target.respond_to?(:iid) ? target.iid : target_id
  end

  def note_short_commit_id
    note_commit_id[0..8]
  end

  def note_commit?
    target.noteable_type == "Commit"
  end

  def note_project_snippet?
    target.noteable_type == "Snippet"
  end

  def note_target
    target.noteable
  end

  def note_target_id
    if note_commit?
      target.commit_id
    else
      target.noteable_id.to_s
    end
  end

  def note_target_iid
    if note_target.respond_to?(:iid)
      note_target.iid
    else
      note_target_id
    end.to_s
  end

  def wall_note?
    target.noteable_type.blank?
  end

  def note_target_type
    if target.noteable_type.present?
      target.noteable_type.titleize
    else
      "Wall"
    end.downcase
  end

  def body?
    if push?
      push_with_commits?
    elsif note?
      true
    else
      target.respond_to? :title
    end
  end
end

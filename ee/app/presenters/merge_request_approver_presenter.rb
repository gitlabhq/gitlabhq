# frozen_string_literal: true

# A view object to ONLY handle approver list display.
# Keeps internal states for performance purpose.
#
# Initialize with following params:
# - skip_user
class MergeRequestApproverPresenter < Gitlab::View::Presenter::Simple
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::RecordIdentifier
  include Gitlab::Utils::StrongMemoize

  presents :merge_request

  attr_reader :skip_user

  def initialize(subject, **attributes)
    @skip_user = subject.author || attributes.delete(:skip_user)
    super
  end

  def any?
    users.any?
  end

  def render
    safe_join(users.map { |user| render_user(user) }, ', ')
  end

  def render_user(user)
    if eligible_approver?(user)
      link_to user.name, '#', id: dom_id(user)
    else
      content_tag(:span, user.name, title: 'Not an eligible approver', class: 'has-tooltip')
    end
  end

  def show_code_owner_tips?
    code_owner_enabled? && code_owner_loader.empty_code_owners?
  end

  private

  def users
    return @users if defined?(@users)

    load_users
    @users
  end

  def authorized_users
    return @authorized_users if defined?(@authorized_users)

    load_users
    @authorized_users
  end

  def load_users
    set_users_from_code_owners if code_owner_enabled?
    set_users_from_git_log_authors if @users.blank?
  end

  def code_owner_enabled?
    strong_memoize(:code_owner_enabled) do
      merge_request.project.feature_available?(:code_owner_as_approver_suggestion)
    end
  end

  def eligible_approver?(user)
    authorized_users.include?(user)
  end

  def set_users_from_code_owners
    @authorized_users = code_owner_loader.members.to_a
    @users = @authorized_users + code_owner_loader.non_members
    @users.delete(skip_user)
  end

  def set_users_from_git_log_authors
    @users = ::Gitlab::AuthorityAnalyzer.new(merge_request, skip_user).calculate.first(merge_request.approvals_required)

    @authorized_users = @users
  end

  def related_paths_for_code_owners
    diffs = merge_request.diffs

    return unless diffs

    paths = []

    diffs.diff_files.each do |diff|
      paths << diff.old_path
      paths << diff.new_path
    end

    paths.compact!
    paths.uniq!
    paths
  end

  def code_owner_loader
    @code_owner_loader ||= Gitlab::CodeOwners::Loader.new(
      merge_request.target_project,
      merge_request.target_branch,
      related_paths_for_code_owners
    )
  end
end

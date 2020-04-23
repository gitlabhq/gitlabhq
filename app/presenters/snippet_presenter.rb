# frozen_string_literal: true

class SnippetPresenter < Gitlab::View::Presenter::Delegated
  presents :snippet

  def web_url
    Gitlab::UrlBuilder.build(snippet)
  end

  def raw_url
    Gitlab::UrlBuilder.build(snippet, raw: true)
  end

  def ssh_url_to_repo
    snippet.ssh_url_to_repo if snippet.repository_exists?
  end

  def http_url_to_repo
    snippet.http_url_to_repo if snippet.repository_exists?
  end

  def can_read_snippet?
    can_access_resource?("read")
  end

  def can_update_snippet?
    can_access_resource?("update")
  end

  def can_admin_snippet?
    can_access_resource?("admin")
  end

  def can_report_as_spam?
    snippet.submittable_as_spam_by?(current_user)
  end

  def blob
    if snippet.empty_repo?
      snippet.blob
    else
      snippet.blobs.first
    end
  end

  private

  def can_access_resource?(ability_prefix)
    can?(current_user, ability_name(ability_prefix), snippet)
  end

  def ability_name(ability_prefix)
    "#{ability_prefix}_#{snippet.to_ability_name}".to_sym
  end
end

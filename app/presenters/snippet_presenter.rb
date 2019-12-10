# frozen_string_literal: true

class SnippetPresenter < Gitlab::View::Presenter::Delegated
  presents :snippet

  def web_url
    Gitlab::UrlBuilder.build(snippet)
  end

  def raw_url
    Gitlab::UrlBuilder.build(snippet, raw: true)
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

  private

  def can_access_resource?(ability_prefix)
    can?(current_user, ability_name(ability_prefix), snippet)
  end

  def ability_name(ability_prefix)
    "#{ability_prefix}_#{snippet.class.underscore}".to_sym
  end
end

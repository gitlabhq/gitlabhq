# frozen_string_literal: true

class IssuePresenter < Gitlab::View::Presenter::Delegated
  presents :issue

  def web_url
    Gitlab::UrlBuilder.build(issue)
  end
end

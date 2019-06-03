# frozen_string_literal: true

class IssuePresenter < Gitlab::View::Presenter::Delegated
  presents :issue

  def web_url
    url_builder.url
  end

  def issue_path
    url_builder.issue_path(issue)
  end

  private

  def url_builder
    @url_builder ||= Gitlab::UrlBuilder.new(issue)
  end
end
